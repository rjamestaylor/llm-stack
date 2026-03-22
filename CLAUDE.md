# CLAUDE.md

This file provides guidance when working with code in this repository.

## Primary Interface

All stack operations go through the `gollm` script at the repo root.
Install it once to use from anywhere:

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
| `gollm mlx start\|stop\|restart\|status\|log` | Manage MLX inference server |
| `gollm webui start\|stop` | Manage Open WebUI independently |
| `gollm help` | Full command reference |

## Model Configuration

**`models.conf`** is the single source of truth for which models you actively manage.
Edit it to add/remove/annotate models. Format: `name | description | tags`

The first model tagged `default` is used when no model is specified.

## Architecture

- **Ollama** — native binary at `/usr/local/bin/ollama`, Metal acceleration on Apple Silicon, API at `http://localhost:11434`
- **MLX (mlx-lm)** — Apple Silicon-native inference, OpenAI-compatible API at `http://localhost:8080/v1`, faster than Ollama for large models on M-series Mac
- **Open WebUI** — Docker container, connects to both Ollama and MLX backends at `http://localhost:3000`
- **z-image** — Tongyi diffusion model at `~/models/z-image/z-image-model`, used via Python/diffusers (not Ollama)

## Script Reference

Individual scripts in `scripts/` still work standalone but prefer `gollm` for day-to-day use.
Only reach into `scripts/` directly when developing or debugging individual components.

| Script | Purpose |
|---|---|
| `scripts/status.sh` | Service status (called by `gollm status`) |
| `scripts/start-ollama.sh` | Start Ollama with Metal env vars |
| `scripts/stop-ollama.sh` | Gracefully stop Ollama |
| `scripts/start-webui.sh` | Start Open WebUI Docker container |
| `scripts/stop-webui.sh` | Stop Open WebUI |
| `scripts/start-mlx.sh` | Start MLX server (called by `gollm mlx start`) |
| `scripts/stop-mlx.sh` | Stop MLX server (called by `gollm mlx stop`) |
| `scripts/pull-models-fp16.sh` | Pull a curated set of Ollama models in bulk |

## Logs & Debugging

```bash
cat ~/.ollama/ollama.log      # Ollama logs
docker logs open-webui        # WebUI logs
gollm status                  # Service health at a glance
```

## Tips for Claude

- Use `gollm` commands rather than invoking scripts or `ollama` directly.
- Model list is in `models.conf` — update it when adding/removing models.
- MLX config is in `mlx.conf` — edit it, then run `gollm mlx restart` to apply.
- `ollama ps` (or `gollm ps`) shows what's actually in VRAM, not just what's downloaded.
- Ollama uses `~/.ollama/models/` for storage; don't manage those files manually.
- The `gollm import` command handles GGUF imports and generates a Modelfile automatically.
