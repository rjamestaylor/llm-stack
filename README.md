# llm-stack

Local LLM inference stack for Apple Silicon — Ollama + MLX as inference backends,
Open WebUI as the chat interface, managed through the `gollm` CLI.

## Quick Start

```bash
# Start everything
gollm start all
gollm mlx start

# Check status
gollm status
```

Access Open WebUI at **http://localhost:3000**

## The `gollm` CLI

Install once to use from anywhere:

```bash
ln -sf ~/projects/llm-stack/gollm /usr/local/bin/gollm
```

| Command | What it does |
|---|---|
| `gollm status` | Full context snapshot: services, loaded model, all local models |
| `gollm start` | Start Ollama |
| `gollm start webui` | Start Open WebUI (Docker) |
| `gollm start all` | Start both |
| `gollm stop` | Stop Ollama |
| `gollm stop all` | Stop both services |
| `gollm restart` | Restart Ollama (+ WebUI if running) |
| `gollm pull <model>` | Pull a model from Ollama registry |
| `gollm import <file.gguf> [name]` | Import a local GGUF file into Ollama |
| `gollm models` | List local models with what's in VRAM |
| `gollm ps` | Show which model is currently loaded in memory |
| `gollm rm <model>` | Remove a model |
| `gollm mlx start\|stop\|restart\|status\|log` | Manage MLX server |
| `gollm webui start\|stop` | Manage Open WebUI independently |
| `gollm help` | Full command reference |

## Architecture

- **Ollama** — native binary at `/usr/local/bin/ollama`, Metal acceleration on Apple Silicon, API at `http://localhost:11434`
- **MLX (`mlx-lm`)** — Apple Silicon-native inference, faster than Ollama for large models, OpenAI-compatible API at `http://localhost:8080/v1`
- **Open WebUI** — Docker container, connects to both Ollama and MLX backends at `http://localhost:3000`

## Configuration

- **`models.conf`** — Ollama model registry: the single source of truth for which models you actively manage. Format: `name | description | tags`
- **`mlx.conf`** — MLX server settings: model path, thinking mode, KV cache size, etc. Edit then run `gollm mlx restart` to apply.

## When to Use Ollama vs MLX

| | Ollama | MLX |
|---|---|---|
| **Best for** | Quick CLI interactions, smaller models, broad format support (GGUF) | Large models on M-series Mac, thinking mode, high throughput |
| **Formats** | GGUF (quantized) | MLX-converted weights |
| **Requires** | macOS or Linux | Apple Silicon only |

**MLX is the primary path for large models** — it uses Apple Silicon more efficiently and supports thinking mode with extended reasoning chains.

## Model Recommendations

Current recommended models:

| Model | Backend | Use case |
|---|---|---|
| `qwen3.5:122b` | Ollama or MLX 8-bit | Largest reasoning, best quality |
| `qwen3.5:35b` | Ollama or MLX 8-bit | Strong reasoning, faster |
| `qwen3.5:27b` (MLX 8-bit) | MLX | Balanced quality + speed |
| `gpt-oss:120b` | Ollama | Large general-purpose |

For MLX: prefer 8-bit quantization for quality, 4-bit for speed. The Qwen3.5 family
excels at reasoning tasks and extended thinking chains.

## Troubleshooting

```bash
gollm status               # service health at a glance
cat ~/.ollama/ollama.log   # Ollama logs
gollm mlx log              # MLX logs (warnings filtered)
docker logs open-webui     # WebUI logs
```

## Benchmarking

For model benchmarking, use the dedicated [llm-bench](https://github.com/rjamestaylor/llm-bench) repository. It provides throughput measurement, model comparison, and visualization tools.

## System Requirements

- **Hardware**: Apple Silicon Mac (M1 or later) — required for MLX, recommended for Ollama Metal acceleration
- **RAM**: 32GB minimum; 64GB+ recommended for 27B+ models
- **Storage**: 20GB+ for tooling; plan ~70GB per large model (8-bit, 120B class)
- **Software**: Native Ollama, Docker Desktop, Python 3.10+ with `mlx-lm`
