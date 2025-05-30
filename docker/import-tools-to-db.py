#!/usr/bin/env python3
"""
Import Open WebUI tools directly into the SQLite database
This script reads JSON tool exports and inserts them into webui.db
"""

import json
import sqlite3
import uuid
import os
import time
from datetime import datetime
import sys

def connect_to_db(db_path="/app/backend/data/webui.db"):
    """Connect to the Open WebUI database"""
    try:
        conn = sqlite3.connect(db_path, timeout=30.0)
        # Test the connection
        conn.execute("SELECT 1")
        return conn
    except sqlite3.Error as e:
        print(f"Database connection error: {e}")
        raise

def create_tools_table_if_not_exists(conn):
    """Create tools table if it doesn't exist"""
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS tool (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            content TEXT NOT NULL,
            specs TEXT,
            meta TEXT,
            valves TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        )
    """)
    conn.commit()

def import_tool_from_json(conn, json_file_path, default_user_id):
    """Import a tool from JSON export into the database"""
    
    with open(json_file_path, 'r') as f:
        data = json.load(f)
    
    print(f"📋 JSON structure: {list(data.keys()) if isinstance(data, dict) else 'Array with ' + str(len(data)) + ' items'}")
    
    # Handle different JSON export formats
    tool_info = None
    
    if isinstance(data, list) and len(data) > 0:
        # Format: [{"tool": {...}, "userId": "...", ...}]
        if 'tool' in data[0]:
            tool_info = data[0]['tool']
            user_id = data[0].get('userId', default_user_id)
        else:
            print(f"❌ Unexpected array format, first item keys: {list(data[0].keys())}")
            return None
    elif isinstance(data, dict):
        if 'tool' in data:
            # Format: {"tool": {...}, "userId": "...", ...}
            tool_info = data['tool']
            user_id = data.get('userId', default_user_id)
        elif 'id' in data and 'name' in data and 'content' in data:
            # Format: Direct tool object {"id": "...", "name": "...", "content": "...", ...}
            tool_info = data
            user_id = default_user_id
        elif 'description' in data and 'manifest' in data:
            # This is a metadata file, skip it
            print(f"⏭️  Skipping metadata file")
            return None
        else:
            print(f"❌ Unexpected dict format, keys: {list(data.keys())}")
            return None
    else:
        print(f"❌ Unknown JSON format: {type(data)}")
        return None
    
    if not tool_info:
        print(f"❌ Could not extract tool info")
        return None
    
    # Validate required fields
    required_fields = ['id', 'name', 'content']
    missing_fields = [field for field in required_fields if field not in tool_info]
    if missing_fields:
        print(f"❌ Missing required fields: {missing_fields}")
        print(f"   Available fields: {list(tool_info.keys())}")
        return None
    
    # Generate timestamps
    timestamp = int(datetime.now().timestamp())
    
    # Prepare data for insertion
    tool_id = tool_info['id']
    name = tool_info['name']
    content = tool_info['content']
    meta = json.dumps(tool_info.get('meta', {}))
    specs = json.dumps([])  # Empty list, not dict
    valves = json.dumps({})  # Empty dict for valves
    
    # Insert into database
    cursor = conn.cursor()
    cursor.execute("""
        INSERT OR REPLACE INTO tool 
        (id, user_id, name, content, specs, meta, valves, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (tool_id, user_id, name, content, specs, meta, valves, timestamp, timestamp))
    
    conn.commit()
    print(f"✅ Imported tool: {name} (ID: {tool_id})")
    return tool_id

def get_default_user_id(conn):
    """Get the first admin user ID from the database"""
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM user WHERE role = 'admin' LIMIT 1")
    result = cursor.fetchone()
    if result:
        return result[0]
    
    # If no admin found, get any user
    cursor.execute("SELECT id FROM user LIMIT 1")
    result = cursor.fetchone()
    if result:
        return result[0]
    
    # Generate a default user ID if no users exist
    return str(uuid.uuid4())

def main():
    if len(sys.argv) < 2:
        print("Usage: python import-tools-to-db.py <path_to_tools_directory> [db_path]")
        print("Example: python import-tools-to-db.py /app/backend/data/tools/")
        sys.exit(1)
    
    tools_dir = sys.argv[1]
    db_path = sys.argv[2] if len(sys.argv) > 2 else "/app/backend/data/webui.db"
    
    print(f"Looking for tools in: {tools_dir}")
    print(f"Database path: {db_path}")
    
    # Check if tools directory exists
    if not os.path.exists(tools_dir):
        print(f"❌ Tools directory not found: {tools_dir}")
        sys.exit(1)
    
    # Wait for database to be ready
    max_retries = 60
    for i in range(max_retries):
        try:
            if os.path.exists(db_path):
                conn = connect_to_db(db_path)
                print(f"✅ Connected to database on attempt {i+1}")
                break
            else:
                print(f"⏳ Database file doesn't exist yet... ({i+1}/{max_retries})")
        except sqlite3.Error as e:
            print(f"⏳ Waiting for database to be ready... ({i+1}/{max_retries}): {e}")
            if i < max_retries - 1:
                time.sleep(3)
            else:
                print(f"❌ Failed to connect to database after {max_retries} attempts")
                sys.exit(1)
    
    try:
        # Create tools table if needed
        create_tools_table_if_not_exists(conn)
        
        # Get default user ID
        default_user_id = get_default_user_id(conn)
        print(f"Using user ID: {default_user_id}")
        
        # List all files in tools directory
        all_files = os.listdir(tools_dir)
        json_files = [f for f in all_files if f.endswith('.json')]
        
        print(f"Found files in {tools_dir}: {all_files}")
        print(f"JSON files to process: {json_files}")
        
        # Import all JSON files in the tools directory
        imported_count = 0
        for filename in json_files:
            json_file_path = os.path.join(tools_dir, filename)
            try:
                print(f"📥 Processing {filename}...")
                import_tool_from_json(conn, json_file_path, default_user_id)
                imported_count += 1
            except Exception as e:
                print(f"❌ Failed to import {filename}: {e}")
                import traceback
                traceback.print_exc()
        
        print(f"\n🎉 Successfully imported {imported_count} tools!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    main()