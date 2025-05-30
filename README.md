# LLM Stack with Ollama and Open WebUI

A complete local LLM setup combining Ollama with Metal acceleration (for Apple Silicon) and Docker-based Open WebUI. This stack enables running powerful large language models locally with an intuitive web interface, optimized performance, and comprehensive benchmarking tools.

## Overview

This repository provides:

1. **Local LLM Inference**: Run state-of-the-art language models on your local machine
2. **Metal Acceleration**: Optimized for Apple Silicon GPUs with Metal acceleration
3. **User-Friendly Interface**: Web-based UI for interacting with models
4. **Performance Benchmarking**: Tools to measure and compare model performance
5. **Model Management**: Scripts for downloading and organizing models

## Quick Start

1. **Install Ollama**: `brew install ollama` (if not already installed)
2. **Launch Stack**: `./scripts/start-stack.sh`
3. **Pull Models**: `./scripts/pull-models.sh`
4. **Access WebUI**: http://localhost:3000

## Management Scripts

### Main Stack Management
- `start-stack.sh` - Start both Ollama and Open WebUI
- `stop-stack.sh` - Stop both Ollama and WebUI services
- `restart-stack.sh` - Restart all services
- `update-stack.sh` - Update Ollama and WebUI to latest versions
- `status.sh` - Check system status

### Component Management
All components can be managed independently:

- `start-ollama.sh` - Start only Ollama with Metal acceleration
- `stop-ollama.sh` - Stop only Ollama
- `start-webui.sh` - Start only the Open WebUI container
- `stop-webui.sh` - Stop only the Open WebUI container

### Model Management
- `pull-models.sh` - Download recommended quantized models optimized for Metal acceleration
- `pull-models-fp16.sh` - Download recommended FP16 models for optimal quality (larger but more accurate)
- `list-models.sh` - List available models

## Benchmarking Tools

This repository includes comprehensive benchmarking tools to test and compare model performance:

```bash
# Standard benchmarking
./benchmarking/benchmark-models.sh

# Run models sequentially (one at a time)
./benchmarking/benchmark-models.sh --sequential

# Include GPU metrics (requires sudo)
./benchmarking/benchmark-models.sh --gpu-metrics
```

### Benchmarking Features
- **Performance Metrics**: Token generation speed, memory usage, CPU utilization
- **Efficiency Analysis**: Throughput scores, tokens per MB, Metal acceleration efficiency
- **Visualization**: Generate charts and reports for easy comparison
- **Hardware Optimization**: Identify the best models for your specific hardware

### Visualization Tools
```bash
# Generate visualizations from latest benchmark
python benchmarking/visualize_benchmarks.py --latest

# Run interactive visualization tool
./benchmarking/example_run.sh

# Generate specific chart types
python benchmarking/visualize_benchmarks.py --all
```

### Analysis Reports
```bash
# Memory usage analysis
./benchmarking/model-memory-report.sh SESSION_TIMESTAMP

# Performance metrics analysis
./benchmarking/model-performance-report.sh SESSION_TIMESTAMP
```

For more detailed benchmarking information, see [benchmarking/README.md](benchmarking/README.md).

## System Requirements

- **Supported Hardware**: 
  - Apple Silicon Macs (with Metal acceleration)
  - x86 systems (with reduced performance)
- **Recommended RAM**: 16GB+ (32GB+ for larger models)
- **Storage**: 20GB+ for Ollama + WebUI, additional space for models
- **Software**:
  - Native Ollama installation
  - Docker Desktop
  - Python 3.6+ (for visualization tools)

## Metal Acceleration

This stack automatically utilizes Metal acceleration on Apple Silicon Macs for significantly improved performance:

- **Automatic Detection**: The stack detects Apple Silicon and enables Metal acceleration
- **Environment Variables**: Key optimizations are pre-configured in scripts
- **Performance Metrics**: Benchmarking tools measure Metal acceleration benefits

## Recommended Models

For the best balance of performance and quality:

- **General Purpose**: Llama 3.1 (8B or 70B quantized versions)
- **Coding**: Codestral 22B or Mixtral 8x7B
- **Reasoning**: Qwen2.5 72B or similar
- **Smaller Models**: Phi-3, Mistral 7B, or Llama3 8B

Model recommendations may change as new models are released.

## Troubleshooting

- Run `./scripts/status.sh` to check system status
- Check Ollama logs: `cat ~/.ollama/ollama.log`
- Check WebUI logs: `docker logs open-webui`
- Restart the stack: `./scripts/restart-stack.sh`

For more specific issues, see the Ollama and Open WebUI documentation.