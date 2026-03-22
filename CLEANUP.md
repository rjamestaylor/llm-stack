# llm-stack Cleanup Plan

This document describes the cleanup work needed to bring the repo into sync with
its current state. The stack has evolved significantly — `gollm` is now the single
entry point, MLX is a first-class component, and several legacy artifacts remain.
Execute tasks in order; each section is independently completable.

---

## Context: What Changed

The stack was refactored from a collection of loose scripts into a unified CLI:

- **`gollm`** — new single entry point (renamed from `llm` to avoid conflict with
  Simon Willison's `llm` CLI). All day-to-day operations go through this.
- **MLX** — added as a first-class inference backend alongside Ollama. Configured
  via `mlx.conf`, managed via `gollm mlx start|stop|restart|status|log`.
- **`models.conf`** — introduced as single source of truth for Ollama model registry.
- **`mlx.conf`** — introduced for MLX server configuration.
- **Open WebUI** — now connects to both Ollama (`:11434`) and MLX (`:8080/v1`).

---

## Task 1: Fix `gollm` Internal Comments

**File:** `gollm` (repo root)

The script header still says `llm` in places and has a typo in the mlx error message.

Fix the following:

1. **Lines 3–18 (comment header):** Replace all references to `llm` with `gollm`.
   The install instruction on line 5 still reads:
   ```
   # Install once:  ln -sf ~/projects/llm-stack/llm /usr/local/bin/gollm
   ```
   Should be:
   ```
   # Install once:  ln -sf ~/projects/llm-stack/gollm /usr/local/bin/gollm
   ```
   The usage examples (`llm status`, `llm start`, etc.) in lines 8–18 should all
   use `gollm`.

2. **Line 253 (mlx error message):** Currently reads `gogollm` (typo):
   ```bash
   *)  die "Usage: gogollm mlx start|stop|restart|status|log [model]" ;;
   ```
   Should be:
   ```bash
   *)  die "Usage: gollm mlx start|stop|restart|status|log [model]" ;;
   ```

3. **Line 4 (`mlx.conf` comment):** The comment at the top of `mlx.conf` still
   says `Run "llm mlx restart" after editing.` — update to `gollm mlx restart`.

---

## Task 2: Update `models.conf`

**File:** `models.conf`

Add a section for MLX models for reference parity with the non-Ollama section:

```
# MLX models (served via gollm mlx, not Ollama — tracked here for reference)
# qwen3.5-27b-opus-distilled-8bit | Qwen3.5 27B 8-bit MLX (Claude-distilled) | mlx,reasoning,default-mlx
# path: ~/models/mlx/qwen3.5-27b-opus-distilled-8bit
```

---

## Task 3: Rewrite `README.md`

**File:** `README.md`

The README is significantly out of date. It describes the old script-per-action
interface, lists outdated model recommendations, and has no mention of `gollm`,
MLX, or `mlx.conf`. Rewrite it to reflect the current stack.

### New README structure:

**Header / Overview**
- Brief description: local LLM stack with Ollama + MLX on Apple Silicon, managed
  via `gollm` CLI, with Open WebUI as the chat interface.

**Quick Start**
```bash
# Start everything
gollm start all
gollm mlx start

# Check status
gollm status
```

**The `gollm` CLI** — reference the command table already in `CLAUDE.md`
(do not duplicate it; link or reproduce as appropriate for README audience).

**Architecture**
- Ollama: native binary, Metal acceleration, API at `http://localhost:11434`
- MLX (`mlx-lm`): Apple Silicon-native inference, faster than Ollama for large
  models, OpenAI-compatible API at `http://localhost:8080/v1`
- Open WebUI: Docker, connects to both backends at `http://localhost:3000`

**Configuration**
- `models.conf` — Ollama model registry
- `mlx.conf` — MLX server settings (model path, thinking mode, KV cache, etc.)

**When to use Ollama vs MLX**
- MLX: primary path for large models on M-series Mac, faster throughput,
  thinking mode support
- Ollama: convenient for quick CLI interactions, smaller models, broader model
  format support (GGUF)

**Model recommendations** — replace the stale Llama/Codestral list with current
reality: Qwen3.5 family (27B–122B) for reasoning, MLX 8-bit for quality,
4-bit for speed.

**Troubleshooting**
```bash
gollm status                   # service health at a glance
cat ~/.ollama/ollama.log        # Ollama logs
gollm mlx log                  # MLX logs (warnings filtered)
docker logs open-webui          # WebUI logs
```

**Benchmarking** — keep the existing llm-bench reference, it's still accurate.

**System Requirements** — update RAM recommendation to 32GB minimum, 64GB+
recommended for 27B+ models. Note MLX requires Apple Silicon.

---

## Task 4: Audit and Retire Legacy Scripts

**Directory:** `scripts/`

Several scripts predate `gollm` and are now only called by it internally. Assess
each:

| Script | Status | Action |
|---|---|---|
| `start-ollama.sh` | Active — called by `gollm start` | Keep |
| `stop-ollama.sh` | Active — called by `gollm stop` | Keep |
| `start-webui.sh` | Active — called by `gollm start webui` | Keep |
| `stop-webui.sh` | Active — called by `gollm stop webui` | Keep |
| `start-mlx.sh` | Active — called by `gollm mlx start` | Keep |
| `stop-mlx.sh` | Active — called by `gollm mlx stop` | Keep |
| `status.sh` | Active — called by `gollm status` | Keep |
| `list-models.sh` | Superseded by `gollm models` | Candidate for removal |
| `pull-models-fp16.sh` | Useful for bulk pulls; review contents | Keep if still accurate |
| `pull-models.sh` | Deprecated (noted in CLAUDE.md) | Remove |
| `start-stack.sh` | Superseded by `gollm start all` | Remove or leave with deprecation note |
| `stop-stack.sh` | Superseded by `gollm stop all` | Remove or leave with deprecation note |
| `restart-stack.sh` | Superseded by `gollm restart` | Remove or leave with deprecation note |
| `update-stack.sh` | Functionality unclear — review | Review before deciding |

For any script you remove, verify first that `gollm` covers the same functionality.
Removal is preferable to accumulating dead code, but a deprecation comment at the
top of the file is acceptable if uncertain.

Also check `pull-models-fp16.sh` — the model list inside it likely references old
models (Llama 3.1, Codestral, etc.) and should be updated to reflect the Qwen3.5
family if you want to keep it.

---

## Task 5: Clean Up `nohup.out`

**File:** `nohup.out` (repo root)

This file is almost certainly a leftover from running a script in the foreground
with nohup before the MLX server was properly daemonized. It does not belong in
the repo.

1. Check whether it is gitignored: `git check-ignore -v nohup.out`
2. If not gitignored, add it: echo `nohup.out` to `.gitignore`
3. If the file is already tracked by git: `git rm --cached nohup.out`

---

## Task 6: Verify `.gitignore`

**File:** `.gitignore` (create if absent)

Ensure the following are ignored:

```
nohup.out
*.log
.DS_Store
__pycache__/
*.pyc
```

The MLX log lives at `~/.mlx/mlx.log` (outside the repo) so it doesn't need
ignoring, but any local log files that might appear at the repo root should be
covered.

---

## Task 7: Update `CLAUDE.md`

**File:** `CLAUDE.md`

Minor fixes only — this file was updated during the refactor and is mostly current:

1. The command table references `gollm mlx` but the Tips section doesn't mention
   `mlx.conf`. Add a tip:
   ```
   - MLX config is in `mlx.conf` — edit it, then run `gollm mlx restart` to apply.
   ```

2. The Architecture section lists three components but describes z-image inline.
   Consider adding MLX as a named component alongside Ollama and Open WebUI, e.g.:
   ```
   - **MLX (mlx-lm)** — Apple Silicon-native inference, OpenAI-compatible API at
     http://localhost:8080/v1, faster than Ollama for large models on M-series Mac
   ```

---

## Suggested Commit Sequence

Once all tasks are done:

```bash
git add -p                  # stage selectively, review each change
git commit -m "refactor: reflect gollm CLI and MLX as first-class components

- Fix gollm internal comments (llm→gollm, typo in mlx error msg)
- Rewrite README for current architecture
- Update models.conf (remove stale qwen3.5:27b-q8_0, add MLX section)
- Remove deprecated scripts (pull-models.sh, *-stack.sh)
- Add nohup.out to .gitignore
- Update CLAUDE.md with MLX tip and architecture entry"
```

---

## What to Leave Alone

- `gollm` — logic is correct, only comments needed fixing (Task 1)
- `mlx.conf` — current and well-commented; one comment fix in Task 1
- `scripts/start-mlx.sh`, `stop-mlx.sh` — working correctly
- `scripts/status.sh` — was rewritten during refactor, leave as-is
- `benchmarking/` — separate concern, not in scope for this cleanup
- `docker/` — review separately if Open WebUI config lives here
