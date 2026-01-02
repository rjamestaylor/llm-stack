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
3. **Pull Models**: `./scripts/pull-models-fp16.sh`
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

## Benchmarking with llm-bench

For model benchmarking, we recommend using the dedicated [llm-bench](https://github.com/rjamestaylor/llm-bench) repository which has been extracted from this project. 

### llm-bench Features
- **Comprehensive Performance Testing**: Measure token generation speed, memory usage, CPU utilization
- **Model Comparison**: Compare different models on the same hardware
- **Visualization Tools**: Generate charts and reports for easy analysis
- **Hardware Optimization**: Identify the best models for your specific system

The llm-bench repository provides a complete set of tools for benchmarking LLM performance with Ollama, including detailed documentation, visualization tools, and analysis capabilities.

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