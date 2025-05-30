#!/usr/bin/env python3
"""
LLM Model Benchmark Visualization Tool

This script visualizes benchmark results for LLM models, creating various charts to help
analyze performance, memory usage, and efficiency metrics.

Usage:
    python visualize_benchmarks.py [options]

Options:
    --summary-path PATH         Path to summary.csv file (default: ../benchmark-reports/summary.csv)
    --output-dir PATH           Directory to save visualization files (default: ../benchmark-reports)
    --all                       Generate all visualization types
    --overview                  Generate 2x2 overview chart (default if no options specified)
    --memory                    Generate memory usage chart with efficiency annotations
    --performance               Generate performance comparison chart
    --efficiency                Generate efficiency score chart
    --format {png,pdf,svg}      Output file format (default: png)
    --no-display                Don't display plots, just save them
    --dpi DPI                   DPI for saved images (default: 100)
"""

import os
import sys
import argparse
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path


def setup_arg_parser():
    """Set up and return the argument parser."""
    parser = argparse.ArgumentParser(description='Visualize LLM benchmark results')
    
    parser.add_argument('--summary-path', type=str, 
                        default='./benchmark-reports/summary.csv',
                        help='Path to summary.csv file')
    
    parser.add_argument('--output-dir', type=str,
                        default='./benchmark-reports',
                        help='Directory to save visualization files')
    
    parser.add_argument('--all', action='store_true',
                        help='Generate all visualization types')
    
    parser.add_argument('--overview', action='store_true',
                        help='Generate 2x2 overview chart (default if no options specified)')
    
    parser.add_argument('--memory', action='store_true',
                        help='Generate memory usage chart with efficiency annotations')
    
    parser.add_argument('--performance', action='store_true',
                        help='Generate performance comparison chart')
    
    parser.add_argument('--efficiency', action='store_true',
                        help='Generate efficiency score chart')
    
    parser.add_argument('--format', type=str, choices=['png', 'pdf', 'svg'],
                        default='png', help='Output file format')
    
    parser.add_argument('--no-display', action='store_true',
                        help="Don't display plots, just save them")
    
    parser.add_argument('--dpi', type=int, default=100,
                        help='DPI for saved images')
    
    return parser


def load_data(summary_path):
    """Load and validate the benchmark data from CSV."""
    try:
        # Check if file exists
        if not os.path.exists(summary_path):
            print(f"Error: Summary file not found at {summary_path}")
            print("Please run benchmark tests first.")
            sys.exit(1)
            
        # Read the data
        data = pd.read_csv(summary_path)
        
        # Validate required columns
        required_columns = ['Model', 'Avg Memory (MB)', 'Avg Peak CPU (%)', 
                           'Avg CPU (%)', 'Avg Tokens/sec', 'Avg Tokens/MB', 
                           'Avg Throughput Score']
        
        missing_columns = [col for col in required_columns if col not in data.columns]
        if missing_columns:
            print(f"Warning: Missing columns in data: {', '.join(missing_columns)}")
            print("Some visualizations may be incomplete.")
        
        return data
    
    except Exception as e:
        print(f"Error loading data: {e}")
        sys.exit(1)


def generate_overview_visualization(data, output_dir, file_format='png', dpi=100):
    """
    Generate a 2x2 overview visualization showing memory usage, token generation speed,
    CPU usage, and efficiency score.
    """
    print("Generating overview visualization...")
    
    # Set up the figure with subplots
    fig, axs = plt.subplots(2, 2, figsize=(15, 10))
    
    # Plot memory usage
    sns.barplot(x='Model', y='Avg Memory (MB)', data=data, ax=axs[0,0], palette='Blues_d')
    axs[0,0].set_title('Memory Usage by Model (with Metal)')
    axs[0,0].set_xticklabels(axs[0,0].get_xticklabels(), rotation=45, ha='right')
    
    # Plot tokens per second
    sns.barplot(x='Model', y='Avg Tokens/sec', data=data, ax=axs[0,1], palette='Greens_d')
    axs[0,1].set_title('Token Generation Speed by Model (with Metal)')
    axs[0,1].set_xticklabels(axs[0,1].get_xticklabels(), rotation=45, ha='right')
    
    # Plot CPU usage
    sns.barplot(x='Model', y='Avg Peak CPU (%)', data=data, ax=axs[1,0], palette='Reds_d')
    axs[1,0].set_title('Peak CPU Usage by Model (with Metal)')
    axs[1,0].set_xticklabels(axs[1,0].get_xticklabels(), rotation=45, ha='right')
    
    # Plot efficiency score
    sns.barplot(x='Model', y='Avg Throughput Score', data=data, ax=axs[1,1], palette='Purples_d')
    axs[1,1].set_title('Efficiency Score by Model (with Metal)')
    axs[1,1].set_xticklabels(axs[1,1].get_xticklabels(), rotation=45, ha='right')
    
    plt.tight_layout()
    
    # Save the visualization
    output_path = os.path.join(output_dir, f'model_performance_comparison.{file_format}')
    plt.savefig(output_path, dpi=dpi)
    
    print(f"Overview visualization saved as {output_path}")
    return fig


def generate_memory_visualization(data, output_dir, file_format='png', dpi=100):
    """
    Generate a detailed memory usage visualization with efficiency annotations.
    """
    print("Generating memory usage visualization...")
    
    # Memory usage chart
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x='Model', y='Avg Memory (MB)', data=data, palette='Blues_d')
    ax.set_title('Memory Usage by Model', fontsize=16)
    ax.set_xlabel('Model', fontsize=14)
    ax.set_ylabel('Memory Usage (MB)', fontsize=14)
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    
    # Add memory efficiency (tokens/MB) as text annotations
    for i, row in data.iterrows():
        if 'Avg Tokens/MB' in row:
            efficiency = row['Avg Tokens/MB']
            if pd.notna(efficiency):
                ax.text(i, row['Avg Memory (MB)'] + 20, 
                        f'{efficiency:.2f} tokens/MB', 
                        ha='center', va='bottom', 
                        color='black', fontweight='bold')
    
    plt.tight_layout()
    
    # Save the visualization
    output_path = os.path.join(output_dir, f'model_memory_comparison.{file_format}')
    plt.savefig(output_path, dpi=dpi)
    
    print(f"Memory visualization saved as {output_path}")
    return plt.gcf()


def generate_performance_visualization(data, output_dir, file_format='png', dpi=100):
    """
    Generate a token generation speed visualization with CPU annotations.
    """
    print("Generating performance visualization...")
    
    # Speed comparison
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x='Model', y='Avg Tokens/sec', data=data, palette='Greens_d')
    ax.set_title('Token Generation Speed by Model', fontsize=16)
    ax.set_xlabel('Model', fontsize=14)
    ax.set_ylabel('Tokens per Second', fontsize=14)
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    
    # Add CPU usage as text annotations
    for i, row in data.iterrows():
        if 'Avg CPU (%)' in row:
            cpu = row['Avg CPU (%)']
            if pd.notna(cpu):
                ax.text(i, row['Avg Tokens/sec'] + 0.5, 
                        f'CPU: {cpu:.1f}%', 
                        ha='center', va='bottom', 
                        color='black', fontweight='bold')
    
    plt.tight_layout()
    
    # Save the visualization
    output_path = os.path.join(output_dir, f'model_performance_comparison.{file_format}')
    plt.savefig(output_path, dpi=dpi)
    
    print(f"Performance visualization saved as {output_path}")
    return plt.gcf()


def generate_efficiency_visualization(data, output_dir, file_format='png', dpi=100):
    """
    Generate an efficiency score visualization.
    """
    print("Generating efficiency visualization...")
    
    # Create efficiency chart
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x='Model', y='Avg Throughput Score', data=data, palette='Purples_d')
    ax.set_title('Model Efficiency (Throughput Score)', fontsize=16)
    ax.set_xlabel('Model', fontsize=14)
    ax.set_ylabel('Throughput Score (tokens/sec per CPU%)', fontsize=14)
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    
    plt.tight_layout()
    
    # Save the visualization
    output_path = os.path.join(output_dir, f'model_efficiency_comparison.{file_format}')
    plt.savefig(output_path, dpi=dpi)
    
    print(f"Efficiency visualization saved as {output_path}")
    return plt.gcf()


def main():
    """Main function to run the visualization script."""
    # Parse command line arguments
    parser = setup_arg_parser()
    args = parser.parse_args()
    
    # Ensure output directory exists
    output_dir = args.output_dir
    os.makedirs(output_dir, exist_ok=True)
    
    # Load the benchmark data
    data = load_data(args.summary_path)
    
    # Figure out which visualizations to generate
    # If no specific visualization is requested, generate the overview
    generate_all = args.all
    if not (args.overview or args.memory or args.performance or args.efficiency or generate_all):
        args.overview = True
    
    # Track generated figures
    figures = []
    
    # Generate requested visualizations
    if args.overview or generate_all:
        fig = generate_overview_visualization(data, output_dir, args.format, args.dpi)
        figures.append(fig)
    
    if args.memory or generate_all:
        fig = generate_memory_visualization(data, output_dir, args.format, args.dpi)
        figures.append(fig)
    
    if args.performance or generate_all:
        fig = generate_performance_visualization(data, output_dir, args.format, args.dpi)
        figures.append(fig)
    
    if args.efficiency or generate_all:
        fig = generate_efficiency_visualization(data, output_dir, args.format, args.dpi)
        figures.append(fig)
    
    # Display plots unless --no-display is set
    if not args.no_display:
        plt.show()
    else:
        # Close all figures to free memory
        for fig in figures:
            plt.close(fig)


if __name__ == "__main__":
    main()