#!/bin/bash
# Start MLX LLM server (OpenAI-compatible API)
# Optimized for MacStudio Pro M2 Ultra, 128GB unified memory
#
# Usage:
#   ./scripts/start-mlx.sh [model] [--no-thinking]
#
# Model can be:
#   - A HuggingFace repo (mlx-community/...)
#   - A local path (~/models/mlx/...)
#   Defaults to the value in mlx.conf or the built-in default below

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VENV="$REPO_DIR/.venv"
MLX_CONF="$REPO_DIR/mlx.conf"
LOG_FILE="$HOME/.mlx/mlx.log"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# ── Defaults (override in mlx.conf) ──────────────────────────────────────────
MLX_MODEL="mlx-community/Qwen3.5-27B-Claude-4.6-Opus-Distilled-MLX-4bit"
MLX_HOST="0.0.0.0"
MLX_PORT="8080"
MLX_MAX_TOKENS="32768"
MLX_TEMP="0.7"
MLX_PROMPT_CACHE_SIZE="8"
MLX_PROMPT_CACHE_BYTES="12884901888"   # 12 GB
MLX_THINKING="true"
MLX_DRAFT_MODEL=""                      # optional: set to a small model for speculative decoding
MLX_DRAFT_TOKENS="5"

# Load config overrides if present
if [[ -f "$MLX_CONF" ]]; then
    # shellcheck source=/dev/null
    source "$MLX_CONF"
fi

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --no-thinking)  MLX_THINKING="false" ;;
        --thinking)     MLX_THINKING="true"  ;;
        --*)            echo -e "${Y}Unknown flag: $arg${NC}" ;;
        *)              MLX_MODEL="$arg"     ;;
    esac
done

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if [[ ! -d "$VENV" ]]; then
    echo -e "${R}Error:${NC} virtualenv not found at $VENV"
    echo "Run: python3 -m venv $VENV && source $VENV/bin/activate && pip install mlx-lm"
    exit 1
fi

if [[ -f "$HOME/.mlx/mlx.pid" ]]; then
    EXISTING_PID=$(cat "$HOME/.mlx/mlx.pid")
    if ps -p "$EXISTING_PID" > /dev/null 2>&1; then
        echo -e "${Y}MLX server already running (PID $EXISTING_PID) on port $MLX_PORT${NC}"
        echo -e "  Stop it first with: gollm mlx stop"
        exit 0
    else
        rm -f "$HOME/.mlx/mlx.pid"
    fi
fi

# ── Build command ─────────────────────────────────────────────────────────────
mkdir -p "$HOME/.mlx"

CMD=(
    "$VENV/bin/mlx_lm.server"
    "--model"    "$MLX_MODEL"
    "--host"     "$MLX_HOST"
    "--port"     "$MLX_PORT"
    "--max-tokens" "$MLX_MAX_TOKENS"
    "--temp"     "$MLX_TEMP"
    "--prompt-cache-size" "$MLX_PROMPT_CACHE_SIZE"
    "--prompt-cache-bytes" "$MLX_PROMPT_CACHE_BYTES"
    "--chat-template-args" "{\"enable_thinking\":$MLX_THINKING}"
)

if [[ -n "$MLX_DRAFT_MODEL" ]]; then
    CMD+=("--draft-model" "$MLX_DRAFT_MODEL" "--num-draft-tokens" "$MLX_DRAFT_TOKENS")
fi

# ── Launch ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}Starting MLX server${NC}"
echo -e "  Model:    ${B}$MLX_MODEL${NC}"
echo -e "  Endpoint: ${G}http://localhost:$MLX_PORT/v1${NC}"
echo -e "  Thinking: $MLX_THINKING"
echo -e "  Max ctx:  $MLX_MAX_TOKENS tokens"
[[ -n "$MLX_DRAFT_MODEL" ]] && echo -e "  Draft:    $MLX_DRAFT_MODEL ($MLX_DRAFT_TOKENS tokens)"
echo -e "  Log:      $LOG_FILE"
echo ""

nohup "${CMD[@]}" >> "$LOG_FILE" 2>&1 &
MLX_PID=$!
echo "$MLX_PID" > "$HOME/.mlx/mlx.pid"
echo "$MLX_MODEL" > "$HOME/.mlx/mlx.model"

# Wait briefly to catch immediate failures
sleep 2
if ! ps -p "$MLX_PID" > /dev/null 2>&1; then
    echo -e "${R}MLX server failed to start. Check log:${NC}"
    tail -20 "$LOG_FILE"
    exit 1
fi

echo -e "${G}✓${NC} MLX server running (PID $MLX_PID)"
echo -e "${Y}Note:${NC} First run downloads the model — watch progress with:"
echo -e "  tail -f $LOG_FILE"
