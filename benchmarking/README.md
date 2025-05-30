# LLM Model Benchmarking with Native Ollama

This directory contains scripts for benchmarking the performance of Large Language Models (LLMs) using native Ollama with Metal acceleration on Apple Silicon.

## Overview

The benchmarking system provides comprehensive tools to:
- Measure LLM performance across multiple models
- Analyze memory usage and efficiency
- Track CPU utilization and throughput
- Visualize results with customizable charts
- Optimize models for specific hardware configurations

## Running Simple Benchmarks

To run a basic benchmark with all available models:

1. **Ensure Ollama is running:**
   ```bash
   ./scripts/start-stack.sh
   ```

2. **Run the benchmark script:**
   ```bash
   ./benchmarking/benchmark-models.sh
   ```

3. **For more efficient sequential testing:**
   ```bash
   ./benchmarking/benchmark-models.sh --sequential
   ```

4. **To include GPU metrics (requires sudo):**
   ```bash
   ./benchmarking/benchmark-models.sh --gpu-metrics
   ```

The benchmark will:
- Test each available model with multiple prompt types
- Collect metrics on speed, memory usage, and CPU utilization
- Generate detailed reports in a timestamped session directory

## Visualizing Benchmark Results

After running benchmarks, you can visualize the results:

1. **Basic visualization with default options:**
   ```bash
   python benchmarking/visualize_benchmarks.py --latest
   ```

2. **Using the interactive example script:**
   ```bash
   ./benchmarking/example_run.sh
   ```

3. **Creating specific visualizations:**
   ```bash
   python benchmarking/visualize_benchmarks.py --summary-path 'benchmark-reports/SESSION_TIMESTAMP/summary.csv' --overview
   ```

4. **List available benchmark sessions:**
   ```bash
   python benchmarking/visualize_benchmarks.py --list-sessions
   ```

## Analyzing Benchmark Results

Generate specialized reports from your benchmark data:

1. **Memory utilization analysis:**
   ```bash
   ./benchmarking/model-memory-report.sh SESSION_TIMESTAMP
   ```

2. **Performance metrics analysis:**
   ```bash
   ./benchmarking/model-performance-report.sh SESSION_TIMESTAMP
   ```

These reports provide detailed insights and optimization recommendations based on your benchmark results.

## Advanced Usage

### GPU Acceleration Options

The benchmarking system automatically detects Metal acceleration on Apple Silicon:

- Set `METAL_DEVICE_WRAPPER_ENABLED=1` before starting Ollama for Metal acceleration
- Use `--gpu-metrics` to collect GPU power usage data (requires sudo)
- Generate GPU-specific visualizations with `--include-gpu` and `--gpu-chart` options

Example:
```bash
# Run benchmark with GPU metrics
./benchmarking/benchmark-models.sh --gpu-metrics

# Visualize GPU data
python benchmarking/visualize_benchmarks.py --latest --include-gpu --gpu-chart
```

### Visualization Options

The visualization tool supports multiple chart types and formats:

```bash
# Generate all chart types
python benchmarking/visualize_benchmarks.py --all --summary-path 'benchmark-reports/SESSION_TIMESTAMP/summary.csv'

# Generate specific chart types
python benchmarking/visualize_benchmarks.py --performance --efficiency --memory

# Change output format
python benchmarking/visualize_benchmarks.py --overview --format pdf
```

Available chart types:
- `--overview`: Generate a 2x2 overview of key metrics
- `--performance`: Create performance comparison charts
- `--efficiency`: Display efficiency score charts
- `--memory`: Show memory usage with efficiency annotations
- `--all`: Generate all visualization types

Output formats:
- PNG (default)
- PDF
- SVG

### Debugging Options

For troubleshooting or detailed analysis:

```bash
# Run benchmarks with detailed API responses
./benchmarking/run-benchmark-debug.sh
```

## Metrics Collected

### Performance Metrics
- Token generation speed (tokens per second)
- Execution time for standardized prompts
- Token counts (prompt tokens and generated tokens)
- Throughput score (tokens/sec per CPU%)
- Tokens per MB (memory efficiency)
- Metal acceleration efficiency

### Hardware Utilization Metrics
- Memory usage (baseline, peak, and used)
- CPU usage (baseline, peak, and average)
- System memory utilization percentage
- Metal acceleration status and performance
- GPU power usage (when --gpu-metrics is enabled)

## Example Workflow

Complete benchmark workflow example:

```bash
# Start Ollama with Metal acceleration
METAL_DEVICE_WRAPPER_ENABLED=1 ./scripts/start-stack.sh

# Pull models to benchmark
./scripts/pull-models.sh

# Run benchmarks with GPU metrics
./benchmarking/benchmark-models.sh --gpu-metrics

# Generate visualizations
python benchmarking/visualize_benchmarks.py --latest --all

# Analyze memory efficiency
./benchmarking/model-memory-report.sh $(python benchmarking/visualize_benchmarks.py --list-sessions | head -2 | tail -1 | awk '{print $2}')

# Analyze performance metrics
./benchmarking/model-performance-report.sh $(python benchmarking/visualize_benchmarks.py --list-sessions | head -2 | tail -1 | awk '{print $2}')
```

## Customizing Benchmarks

To modify the benchmark prompts or add new test scenarios, edit the `benchmark-models.sh` script:

- `SHORT_PROMPT`: Simple, quick responses
- `MEDIUM_PROMPT`: Moderate complexity responses
- `LONG_PROMPT`: Complex, detailed responses
- `CODE_PROMPT`: Programming and technical responses