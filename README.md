# LLM Stack with Ollama and Open WebUI

Local LLM setup using Ollama with Metal acceleration (default) and Docker-based Open WebUI, optimized for MacStudio Pro M2 Ultra. This stack is designed to provide the best performance for Apple Silicon by leveraging Metal GPU acceleration.

## Quick Start

1. **Install Ollama**: `brew install ollama` (if not already installed)
2. **Launch Stack**: `./scripts/start-stack.sh`
3. **Pull Models**: `./scripts/pull-models.sh`
4. **Access WebUI**: http://localhost:3000

## Scripts

### Main Scripts
- `start-stack.sh` - Start both Ollama and Open WebUI
- `stop-stack.sh` - Stop both Ollama and WebUI services
- `restart-stack.sh` - Restart all services
- `update-stack.sh` - Update Ollama and WebUI to latest versions
- `status.sh` - Check system status

### Independent Component Management
All components can be managed independently, allowing you to start, stop, or restart individual parts of the stack as needed:

- `start-ollama.sh` - Start only Ollama with Metal acceleration
- `stop-ollama.sh` - Stop only Ollama
- `start-webui.sh` - Start only the Open WebUI container
- `stop-webui.sh` - Stop only the Open WebUI container

### Model Management
- `pull-models.sh` - Download recommended quantized models optimized for Metal acceleration
- `pull-models-fp16.sh` - Download recommended FP16 models for optimal quality (larger but more accurate)
- `list-models.sh` - List available models

## Recommended Models

- **Llama 3.1 70B**: Best general-purpose model
- **Mixtral 8x7B**: Excellent for coding tasks
- **Qwen2.5 72B**: Strong reasoning capabilities
- **Codestral 22B**: Specialized for code generation

## System Requirements

- MacStudio Pro M2 Ultra with 128GB RAM (recommended)
- Native Ollama installation (for Metal acceleration)
- Docker Desktop (for Open WebUI)
- 200GB available disk space

## Metal Acceleration

This stack uses Ollama with Metal acceleration by default for optimal performance on Apple Silicon. All scripts are configured to leverage the GPU capabilities of Apple Silicon for significantly faster inference. The Metal backend is automatically used when running Ollama on macOS with Apple Silicon.

## Benchmarking

Use the benchmarking scripts to test and compare model performance:

```bash
# Standard benchmarking with Metal acceleration
./benchmarking/benchmark-models.sh

# Sequential benchmarking (one model at a time)
./benchmarking/benchmark-models-sequential.sh

# Benchmark native Ollama performance
./benchmarking/benchmark-models-native.sh
```

Additional benchmarking utilities:
- `model-memory-report.sh` - Generate memory usage reports for models
- `model-performance-report.sh` - Create detailed performance metrics
- `run-benchmark-debug.sh` - Run benchmarks with additional debug information

Results will show token generation speed, memory usage, and CPU utilization for each model, helping you choose the best models for your specific hardware.

## Troubleshooting

- Run `./scripts/status.sh` to check system status
- Check Ollama logs: `cat ~/ollama-native/ollama.log`
- Check WebUI logs: `docker logs open-webui`
- Restart stack: `./scripts/restart-stack.sh`
