import pandas as pd
import matplotlib.pyplot as plt
import argparse
import os
import re
from datetime import datetime

def list_available_sessions(base_dir):
    """List all available benchmark sessions in the given directory."""
    if not os.path.exists(base_dir):
        return []
    
    sessions = []
    for item in os.listdir(base_dir):
        item_path = os.path.join(base_dir, item)
        # Check if it's a directory and matches the timestamp format
        if os.path.isdir(item_path) and re.match(r'\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}', item):
            sessions.append(item)
    
    # Sort sessions by timestamp (most recent first)
    sessions.sort(reverse=True)
    return sessions

def get_latest_session(base_dir):
    """Get the most recent benchmark session."""
    sessions = list_available_sessions(base_dir)
    return sessions[0] if sessions else None

# Set up command line argument parsing
parser = argparse.ArgumentParser(description='Visualize benchmark summaries for specific sessions.')
parser.add_argument('--summary-path', help='Path to summary CSV (overrides session-based path)')
parser.add_argument('--output-dir', help='Directory to save output charts (overrides session-based path)')
parser.add_argument('--session', help='Specific session timestamp to visualize (YYYY-mm-dd_HH:MM:SS format)')
parser.add_argument('--latest', action='store_true', help='Use the latest session automatically')
parser.add_argument('--list-sessions', action='store_true', help='List all available sessions and exit')
parser.add_argument('--include-gpu', action='store_true', help='Include GPU metrics in charts')
parser.add_argument('--gpu-chart', action='store_true', help='Generate dedicated GPU power usage chart')
args = parser.parse_args()

# Base directory for reports
base_reports_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'benchmark-reports')

# Handle listing sessions if requested
if args.list_sessions:
    sessions = list_available_sessions(base_reports_dir)
    if sessions:
        print(f"Available benchmark sessions ({len(sessions)}):")
        for session in sessions:
            # Get the summary file path for this session
            summary_path = os.path.join(base_reports_dir, session, 'summary.csv')
            session_status = "✓" if os.path.exists(summary_path) else "✗"
            print(f"  {session_status} {session}")
    else:
        print("No benchmark sessions found.")
    exit(0)

# Determine which session to use
selected_session = None
if args.session:
    selected_session = args.session
elif args.latest:
    selected_session = get_latest_session(base_reports_dir)
    if selected_session:
        print(f"Using latest session: {selected_session}")
    else:
        print("No sessions found. Using sample data.")

# Determine paths based on arguments or selected session
summary_path = args.summary_path
output_dir = args.output_dir

if not summary_path:
    if selected_session:
        summary_path = os.path.join(base_reports_dir, selected_session, 'summary.csv')
    else:
        summary_path = os.path.join(base_reports_dir, 'sample_summary.csv')

if not output_dir:
    if selected_session:
        output_dir = os.path.join(base_reports_dir, selected_session)
    else:
        output_dir = base_reports_dir

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

print(f"Using summary file: {summary_path}")
print(f"Saving charts to: {output_dir}")

# Read the benchmark data
try:
    df = pd.read_csv(summary_path)
except FileNotFoundError:
    print(f"Error: Could not find summary file at {summary_path}")
    exit(1)
except Exception as e:
    print(f"Error reading {summary_path}: {str(e)}")
    exit(1)

# Create charts
plt.figure()
df.plot(x='Model', y='Avg Tokens/sec', kind='bar', title='Average Tokens per Second')
plt.ylabel('Tokens/sec')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig(f"{output_dir}/tokens_per_second.png")

if args.include_gpu or args.gpu_chart:
    if 'Avg GPU Power (W)' in df.columns:
        df_gpu = df[df['Avg GPU Power (W)'] != 'N/A'].copy()
        df_gpu['Avg GPU Power (W)'] = pd.to_numeric(df_gpu['Avg GPU Power (W)'], errors='coerce')

        if args.include_gpu:
            plt.figure()
            ax = df_gpu.plot(x='Model', y='Avg Tokens/sec', kind='bar', label='Tokens/sec')
            df_gpu.plot(x='Model', y='Avg GPU Power (W)', kind='line', color='red', marker='o', secondary_y=True, ax=ax, label='Avg GPU Power (W)')
            ax.set_ylabel('Tokens/sec')
            ax.right_ax.set_ylabel('GPU Power (W)')
            plt.title('Performance vs. GPU Power')
            plt.xticks(rotation=45)
            plt.tight_layout()
            plt.savefig(f"{output_dir}/performance_vs_gpu_power.png")

        if args.gpu_chart:
            plt.figure()
            df_gpu.plot(x='Model', y='Avg GPU Power (W)', kind='bar', color='orange', title='Average GPU Power Usage')
            plt.ylabel('GPU Power (W)')
            plt.xticks(rotation=45)
            plt.tight_layout()
            plt.savefig(f"{output_dir}/gpu_power_usage.png")

print("Visualization complete! Check the output directory for generated charts.")
