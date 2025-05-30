import pandas as pd
import matplotlib.pyplot as plt
import argparse
import os
import re
from datetime import datetime
import numpy as np

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

def create_tokens_per_second_chart(df, output_dir, file_format='png'):
    """Create a simple tokens per second bar chart."""
    plt.figure(figsize=(10, 6))
    ax = df.plot(x='Model', y='Avg Tokens/sec', kind='bar', color='#1f77b4')
    plt.title('Average Tokens per Second', fontsize=14, fontweight='bold')
    plt.ylabel('Tokens/sec', fontsize=12)
    plt.xlabel('Model', fontsize=12)
    plt.xticks(rotation=45, ha='right')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Add value labels on top of bars
    for i, v in enumerate(df['Avg Tokens/sec']):
        ax.text(i, v + 1, f"{v:.1f}", ha='center', fontsize=9)
    
    plt.tight_layout()
    plt.savefig(f"{output_dir}/tokens_per_second.{file_format}")
    plt.close()

def create_memory_chart(df, output_dir, file_format='png'):
    """Create a memory usage chart with efficiency annotations."""
    plt.figure(figsize=(10, 6))
    ax = df.plot(x='Model', y='Avg Memory (MB)', kind='bar', color='#ff7f0e')
    plt.title('Memory Usage with Efficiency', fontsize=14, fontweight='bold')
    plt.ylabel('Memory Usage (MB)', fontsize=12)
    plt.xlabel('Model', fontsize=12)
    plt.xticks(rotation=45, ha='right')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Add efficiency annotation to bars if column exists
    if 'Avg Tokens/MB' in df.columns:
        # Create a colormap for efficiency
        cmap = plt.cm.RdYlGn
        norm = plt.Normalize(df['Avg Tokens/MB'].min(), df['Avg Tokens/MB'].max())
        
        # Add efficiency labels
        for i, (memory, efficiency) in enumerate(zip(df['Avg Memory (MB)'], df['Avg Tokens/MB'])):
            ax.text(i, memory + memory*0.05, f"Efficiency: {efficiency:.3f}", 
                   ha='center', fontsize=8, 
                   color=cmap(norm(efficiency)) if not pd.isna(efficiency) else 'black')
    
    plt.tight_layout()
    plt.savefig(f"{output_dir}/memory_usage.{file_format}")
    plt.close()

def create_performance_chart(df, output_dir, file_format='png'):
    """Create a performance comparison chart showing tokens/sec and CPU usage."""
    plt.figure(figsize=(10, 6))
    ax = df.plot(x='Model', y='Avg Tokens/sec', kind='bar', color='#2ca02c')
    
    # Add CPU usage as a line on secondary y-axis if column exists
    if 'Avg CPU (%)' in df.columns:
        df.plot(x='Model', y='Avg CPU (%)', kind='line', marker='o', color='#d62728', 
                secondary_y=True, ax=ax)
        ax.right_ax.set_ylabel('CPU Usage (%)', fontsize=12, color='#d62728')
        ax.right_ax.tick_params(axis='y', colors='#d62728')
    
    plt.title('Performance Comparison', fontsize=14, fontweight='bold')
    ax.set_ylabel('Tokens per Second', fontsize=12, color='#2ca02c')
    ax.tick_params(axis='y', colors='#2ca02c')
    plt.xlabel('Model', fontsize=12)
    plt.xticks(rotation=45, ha='right')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.legend()
    
    plt.tight_layout()
    plt.savefig(f"{output_dir}/performance_comparison.{file_format}")
    plt.close()

def create_efficiency_chart(df, output_dir, file_format='png'):
    """Create an efficiency score chart."""
    plt.figure(figsize=(10, 6))
    
    if 'Avg Throughput Score' in df.columns:
        ax = df.plot(x='Model', y='Avg Throughput Score', kind='bar', color='#9467bd')
        plt.title('Efficiency Score (Higher is Better)', fontsize=14, fontweight='bold')
        plt.ylabel('Throughput Score (tokens/sec per CPU%)', fontsize=12)
        plt.xlabel('Model', fontsize=12)
        plt.xticks(rotation=45, ha='right')
        plt.grid(axis='y', linestyle='--', alpha=0.7)
        
        # Add value labels on top of bars
        for i, v in enumerate(df['Avg Throughput Score']):
            ax.text(i, v + v*0.05, f"{v:.2f}", ha='center', fontsize=9)
    else:
        plt.text(0.5, 0.5, 'Throughput Score data not available', 
                 ha='center', va='center', fontsize=14)
    
    plt.tight_layout()
    plt.savefig(f"{output_dir}/efficiency_score.{file_format}")
    plt.close()

def create_overview_chart(df, output_dir, file_format='png'):
    """Create a 2x2 overview chart with key metrics."""
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    
    # 1. Tokens per Second (Top Left)
    df.plot(x='Model', y='Avg Tokens/sec', kind='bar', ax=axes[0, 0], color='#1f77b4')
    axes[0, 0].set_title('Tokens per Second', fontsize=12, fontweight='bold')
    axes[0, 0].set_ylabel('Tokens/sec')
    axes[0, 0].tick_params(axis='x', rotation=45)
    
    # 2. Memory Usage (Top Right)
    df.plot(x='Model', y='Avg Memory (MB)', kind='bar', ax=axes[0, 1], color='#ff7f0e')
    axes[0, 1].set_title('Memory Usage', fontsize=12, fontweight='bold')
    axes[0, 1].set_ylabel('Memory (MB)')
    axes[0, 1].tick_params(axis='x', rotation=45)
    
    # 3. CPU Usage (Bottom Left)
    if 'Avg CPU (%)' in df.columns:
        df.plot(x='Model', y='Avg CPU (%)', kind='bar', ax=axes[1, 0], color='#d62728')
        axes[1, 0].set_title('CPU Usage', fontsize=12, fontweight='bold')
        axes[1, 0].set_ylabel('CPU (%)')
    else:
        axes[1, 0].text(0.5, 0.5, 'CPU data not available', ha='center', va='center', fontsize=12)
    axes[1, 0].tick_params(axis='x', rotation=45)
    
    # 4. Efficiency Score (Bottom Right)
    if 'Avg Throughput Score' in df.columns:
        df.plot(x='Model', y='Avg Throughput Score', kind='bar', ax=axes[1, 1], color='#9467bd')
        axes[1, 1].set_title('Efficiency Score', fontsize=12, fontweight='bold')
        axes[1, 1].set_ylabel('Throughput Score')
    else:
        axes[1, 1].text(0.5, 0.5, 'Throughput data not available', ha='center', va='center', fontsize=12)
    axes[1, 1].tick_params(axis='x', rotation=45)
    
    plt.tight_layout()
    plt.savefig(f"{output_dir}/overview.{file_format}")
    plt.close()

def create_gpu_charts(df, output_dir, include_gpu=False, gpu_chart=False, file_format='png'):
    """Create GPU-related charts if the data is available."""
    if 'Avg GPU Power (W)' not in df.columns:
        print("GPU power data column not found in summary file. Skipping GPU charts.")
        print("Note: To collect GPU metrics, run benchmark with --gpu-metrics flag.")
        return
    
    # Filter out rows with N/A GPU power
    df_gpu = df[df['Avg GPU Power (W)'] != 'N/A'].copy()
    if df_gpu.empty:
        print("No valid GPU power data found in summary file. All values are 'N/A'.")
        print("Note: To collect GPU metrics, run benchmark with --gpu-metrics flag.")
        print("Example: ./benchmark-models.sh --gpu-metrics")
        return
    
    # Convert to numeric
    df_gpu['Avg GPU Power (W)'] = pd.to_numeric(df_gpu['Avg GPU Power (W)'], errors='coerce')
    
    if include_gpu:
        plt.figure(figsize=(10, 6))
        ax = df_gpu.plot(x='Model', y='Avg Tokens/sec', kind='bar', label='Tokens/sec')
        df_gpu.plot(x='Model', y='Avg GPU Power (W)', kind='line', color='red', marker='o', 
                   secondary_y=True, ax=ax, label='Avg GPU Power (W)')
        ax.set_ylabel('Tokens/sec')
        ax.right_ax.set_ylabel('GPU Power (W)')
        plt.title('Performance vs. GPU Power', fontsize=14, fontweight='bold')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(f"{output_dir}/performance_vs_gpu_power.{file_format}")
        plt.close()

    if gpu_chart:
        plt.figure(figsize=(10, 6))
        df_gpu.plot(x='Model', y='Avg GPU Power (W)', kind='bar', color='orange', 
                   title='Average GPU Power Usage')
        plt.ylabel('GPU Power (W)')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(f"{output_dir}/gpu_power_usage.{file_format}")
        plt.close()

# Get the script directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Base directory for reports
base_reports_dir = os.path.join(script_dir, 'benchmark-reports')

if __name__ == "__main__":
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(description='Visualize benchmark summaries for specific sessions.')
    parser.add_argument('--summary-path', help='Path to summary CSV (overrides session-based path)')
    parser.add_argument('--output-dir', help='Directory to save output charts (overrides session-based path)')
    parser.add_argument('--session', help='Specific session timestamp to visualize (YYYY-mm-dd_HH:MM:SS format)')
    parser.add_argument('--latest', action='store_true', help='Use the latest session automatically')
    parser.add_argument('--list-sessions', action='store_true', help='List all available sessions and exit')

    # Visualization types
    parser.add_argument('--overview', action='store_true', help='Generate 2x2 overview chart')
    parser.add_argument('--performance', action='store_true', help='Generate performance comparison chart')
    parser.add_argument('--efficiency', action='store_true', help='Generate efficiency score chart')
    parser.add_argument('--memory', action='store_true', help='Generate memory usage chart with efficiency annotations')
    parser.add_argument('--all', action='store_true', help='Generate all visualization types')

    # GPU options
    parser.add_argument('--include-gpu', action='store_true', help='Include GPU metrics in charts')
    parser.add_argument('--gpu-chart', action='store_true', help='Generate dedicated GPU power usage chart')

    # Output format
    parser.add_argument('--format', choices=['png', 'pdf', 'svg'], default='png', help='Output file format')
    args = parser.parse_args()

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
            summary_path = os.path.join(base_reports_dir, 'sample', 'sample_summary.csv')

    if not output_dir:
        if selected_session:
            output_dir = os.path.join(base_reports_dir, selected_session)
        else:
            output_dir = os.path.join(base_reports_dir, 'sample')

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

    # If no specific charts are requested, default to tokens per second chart
    if not (args.overview or args.performance or args.efficiency or args.memory or args.all):
        # Default to just the tokens per second chart
        create_tokens_per_second_chart(df, output_dir, args.format)
    else:
        # Generate requested visualizations
        if args.overview or args.all:
            print("Generating overview chart...")
            create_overview_chart(df, output_dir, args.format)
        
        if args.performance or args.all:
            print("Generating performance comparison chart...")
            create_performance_chart(df, output_dir, args.format)
        
        if args.efficiency or args.all:
            print("Generating efficiency score chart...")
            create_efficiency_chart(df, output_dir, args.format)
        
        if args.memory or args.all:
            print("Generating memory usage chart...")
            create_memory_chart(df, output_dir, args.format)
        
        # Always generate the tokens per second chart
        print("Generating tokens per second chart...")
        create_tokens_per_second_chart(df, output_dir, args.format)

    # Generate GPU charts if requested
    if args.include_gpu or args.gpu_chart:
        print("Generating GPU charts...")
        create_gpu_charts(df, output_dir, args.include_gpu, args.gpu_chart, args.format)

    print("Visualization complete! Check the output directory for generated charts.")