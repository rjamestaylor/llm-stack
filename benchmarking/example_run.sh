#!/bin/bash

# Example script to run the visualizer with GPU metrics included

# If a session timestamp is provided, use it; otherwise, use the sample data
SESSION="${1:-sample}"

# Check if the provided session is "sample" or a timestamp
if [ "$SESSION" = "sample" ]; then
    SUMMARY_PATH="./benchmark-reports/sample_summary.csv"
    OUTPUT_DIR="./"
else
    # Use the provided session timestamp
    SUMMARY_PATH="./benchmark-reports/${SESSION}/summary.csv"
    OUTPUT_DIR="./benchmark-reports/${SESSION}"
fi

echo "Using summary file: $SUMMARY_PATH"
echo "Output directory: $OUTPUT_DIR"

# Run the visualization script
python3 visualize_benchmarks.py \
    --summary-path "$SUMMARY_PATH" \
    --output-dir "$OUTPUT_DIR" \
    --include-gpu \
    --gpu-chart

echo "Visualization completed. Charts saved to $OUTPUT_DIR"
