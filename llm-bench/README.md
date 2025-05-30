# LLM-Bench: LLM Benchmarking for Apple Silicon

A comprehensive benchmarking suite for Large Language Models with special optimization for Apple Silicon and Metal acceleration.

## Overview

LLM-Bench provides a sophisticated suite of tools for benchmarking, analyzing, and visualizing the performance of Large Language Models running on [Ollama](https://ollama.ai/), with specific optimizations for Apple Silicon hardware. This standalone benchmarking tool can work independently or alongside the [llm-stack](https://github.com/yourusername/llm-stack) project.

### Key Features

- **Performance Benchmarking**: Measure token generation speed, memory usage, and CPU utilization
- **Metal Acceleration**: Detect and leverage Apple Silicon's Metal GPU acceleration
- **Visualization Tools**: Generate charts and graphs to compare model performance
- **Analysis Reports**: Create detailed memory and performance analysis reports
- **Model Comparison**: Compare multiple models across different metrics
- **Standalone Operation**: Works independently or integrates with llm-stack

## Installation

### Prerequisites

- macOS (optimized for Apple Silicon)
- Ollama installed (`brew install ollama`)
- Python 3.6+ with matplotlib and pandas
- Required CLI tools: curl, jq, bc, awk, column

### Installation Options

#### Standalone Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/llm-bench.git
cd llm-bench

# Make scripts executable
chmod +x *.sh
chmod +x utils/*.sh
```

#### Installation with llm-stack

```bash
# Clone both repositories side by side
git clone https://github.com/yourusername/llm-stack.git
git clone https://github.com/yourusername/llm-bench.git

# llm-bench will automatically detect llm-stack if in sibling directory
```

## Usage

### Running Benchmarks

```bash
# Start Ollama (if not already running)
ollama serve

# Basic benchmark of all available models
./benchmark-models.sh

# Run with more efficient sequential mode
./benchmark-models.sh --sequential

# Include GPU metrics (requires sudo)
./benchmark-models.sh --gpu-metrics
```

### Visualizing Results

```bash
# Visualize the latest benchmark session
python visualize_benchmarks.py --latest

# Interactive visualization with options
./example_run.sh

# Create specific chart types
python visualize_benchmarks.py --performance --efficiency --summary-path 'benchmark-reports/SESSION_TIMESTAMP/summary.csv'
```

### Available Visualization Options

- `--overview`: Generate a 2x2 overview of key metrics
- `--performance`: Create performance comparison charts
- `--efficiency`: Display efficiency score charts
- `--memory`: Show memory usage with efficiency annotations
- `--all`: Generate all visualization types
- `--include-gpu`: Include GPU metrics in visualizations
- `--format {png,pdf,svg}`: Select output format

### Analyzing Results

```bash
# Generate memory utilization analysis
./model-memory-report.sh SESSION_TIMESTAMP

# Generate performance metrics analysis
./model-performance-report.sh SESSION_TIMESTAMP
```

### Debugging

For detailed API responses and troubleshooting:

```bash
# Run benchmark with debugging output
./run-benchmark-debug.sh
```

## Integration with llm-stack

LLM-Bench is designed to work seamlessly with the [llm-stack](https://github.com/yourusername/llm-stack) project, but can also operate completely independently.

### Automatic Detection

LLM-Bench will automatically detect if llm-stack is installed in a sibling directory and leverage its scripts and configuration when available. This provides the best of both worlds:

- **Standalone Mode**: All functionality works without requiring llm-stack
- **Integrated Mode**: Enhanced functionality when llm-stack is available

### Manual Configuration

You can explicitly set the path to llm-stack:

```bash
export LLM_STACK_DIR="/path/to/llm-stack"
./benchmark-models.sh
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

## Directory Structure

```
llm-bench/
├── benchmark-models.sh        # Main benchmarking script
├── example_run.sh             # Interactive visualization script
├── model-memory-report.sh     # Memory analysis tool
├── model-performance-report.sh # Performance analysis tool
├── run-benchmark-debug.sh     # Debugging tool
├── visualize_benchmarks.py    # Visualization script
├── config.sh                  # Configuration and integration settings
├── utils/                     # Utility scripts
│   └── list-models.sh         # Model listing utility
└── benchmark-reports/         # Reports and data
    └── sample/                # Sample benchmark data
```

## Example Workflow

```bash
# Start Ollama with Metal acceleration
METAL_DEVICE_WRAPPER_ENABLED=1 ollama serve

# Run benchmarks with GPU metrics
./benchmark-models.sh --gpu-metrics

# Generate visualizations
python visualize_benchmarks.py --latest --all

# Analyze memory efficiency
./model-memory-report.sh $(python visualize_benchmarks.py --list-sessions | head -2 | tail -1 | awk '{print $2}')
```

## Customizing Benchmarks

To modify the benchmark prompts or add new test scenarios, edit the `benchmark-models.sh` script:

- `SHORT_PROMPT`: Simple, quick responses
- `MEDIUM_PROMPT`: Moderate complexity responses
- `LONG_PROMPT`: Complex, detailed responses
- `CODE_PROMPT`: Programming and technical responses

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built to work with [Ollama](https://ollama.ai/)
- Originally developed as part of the [llm-stack](https://github.com/yourusername/llm-stack) project