#!/bin/bash
# LLM Stack status — comprehensive context snapshot
# Usage: status.sh [--short]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MODELS_CONF="$REPO_DIR/models.conf"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

SHORT=false
[[ "$1" == "--short" ]] && SHORT=true

sep() { echo -e "${D}────────────────────────────────────────────${NC}"; }

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}LLM Stack${NC}  $(date '+%Y-%m-%d %H:%M')"
sep

# ── Ollama ────────────────────────────────────────────────────────────────────
echo -e "${B}Ollama${NC}"

OLLAMA_RUNNING=false
if pgrep -x "ollama" > /dev/null; then
    if ollama_running; then
        OLLAMA_RUNNING=true
        echo -e "  ${G}●${NC} running   ${D}http://localhost:11434${NC}"
    else
        echo -e "  ${Y}●${NC} process up, API not responding"
    fi
else
    echo -e "  ${R}●${NC} stopped"
fi

if $OLLAMA_RUNNING; then
    # Currently loaded in VRAM (ollama ps)
    PS_OUTPUT=$(ollama ps 2>/dev/null | tail -n +2)
    if [[ -n "$PS_OUTPUT" ]]; then
        echo -e "\n  ${BOLD}In memory (VRAM):${NC}"
        while IFS= read -r line; do
            model=$(awk '{print $1}' <<< "$line")
            size=$(awk '{print $2" "$3}' <<< "$line")
            proc=$(awk '{print $4}' <<< "$line")
            until=$(awk '{$1=$2=$3=$4=""; print $0}' <<< "$line" | xargs)
            echo -e "    ${G}▶${NC} ${BOLD}$model${NC}  ${D}$size · $proc · expires $until${NC}"
        done <<< "$PS_OUTPUT"
    else
        echo -e "\n  ${D}No model loaded in memory${NC}"
    fi

    # All local models — parse each line once with read instead of 3 awk calls
    echo -e "\n  ${BOLD}Local models:${NC}"
    while read -r name _id size unit mod1 mod2 mod3 _; do
        echo "$PS_OUTPUT" | grep -q "^$name " && marker="${G}▶${NC}" || marker=" "
        printf "    %b %-28s %6s  ${D}%s${NC}\n" "$marker" "$name" "$size $unit" "$mod1 $mod2 $mod3"
    done < <(ollama list 2>/dev/null | tail -n +2)
fi

sep

# ── Open WebUI ────────────────────────────────────────────────────────────────
echo -e "${B}Open WebUI${NC}"

STATUS=$(docker ps --filter "name=^open-webui$" --format "{{.Status}}" 2>/dev/null)
if [[ -n "$STATUS" ]]; then
    echo -e "  ${G}●${NC} running   ${D}http://localhost:3000${NC}  ${D}($STATUS)${NC}"
else
    if docker info > /dev/null 2>&1; then
        echo -e "  ${R}●${NC} container stopped  ${D}start with: gollm start webui${NC}"
    else
        echo -e "  ${R}●${NC} Docker not running"
    fi
fi

sep

# ── MLX Server ────────────────────────────────────────────────────────────────
echo -e "${B}MLX Server${NC}"

MLX_PID_FILE="$HOME/.mlx/mlx.pid"
MLX_CONF="$REPO_DIR/mlx.conf"

if [[ -f "$MLX_PID_FILE" ]] && ps -p "$(cat "$MLX_PID_FILE")" > /dev/null 2>&1; then
    MLX_PID=$(cat "$MLX_PID_FILE")
    MLX_MODEL=$(cat "$HOME/.mlx/mlx.model" 2>/dev/null || echo "unknown")
    MLX_PORT=$(grep 'MLX_PORT=' "$MLX_CONF" 2>/dev/null | grep -v '#' | head -1 | cut -d'"' -f2 || echo "8080")
    echo -e "  ${G}●${NC} running (PID $MLX_PID)   ${D}http://localhost:${MLX_PORT}/v1${NC}"
    echo -e "  ${BOLD}Model:${NC} $MLX_MODEL"
else
    echo -e "  ${R}●${NC} stopped  ${D}start with: gollm mlx start${NC}"
    # Show configured model even when stopped
    if [[ -f "$MLX_CONF" ]]; then
        CONF_MODEL=$(grep 'MLX_MODEL=' "$MLX_CONF" | grep -v '#' | head -1 | cut -d'"' -f2)
        [[ -n "$CONF_MODEL" ]] && echo -e "  ${D}Configured: $CONF_MODEL${NC}"
    fi
fi

sep

# ── Non-Ollama models ─────────────────────────────────────────────────────────
echo -e "${B}Image / Other Models${NC}"

Z_IMAGE_PATH="$HOME/models/z-image/z-image-model"
if [[ -d "$Z_IMAGE_PATH" ]]; then
    SIZE=$(du -sh "$Z_IMAGE_PATH" 2>/dev/null | awk '{print $1}')
    echo -e "  ${G}●${NC} z-image   ${D}$Z_IMAGE_PATH  ($SIZE)${NC}"
else
    echo -e "  ${D}z-image path not found: $Z_IMAGE_PATH${NC}"
fi

sep

# ── Quick reference ───────────────────────────────────────────────────────────
if ! $SHORT; then
    echo -e "${B}Commands${NC}  ${D}(run from anywhere)${NC}"
    echo -e "  gollm ${BOLD}status${NC}               this view"
    echo -e "  gollm ${BOLD}start${NC}  [webui|all]   start Ollama (+ Open WebUI)"
    echo -e "  gollm ${BOLD}stop${NC}   [webui|all]   stop services"
    echo -e "  gollm ${BOLD}mlx${NC}    start|stop     manage MLX server (:8080)"
    echo -e "  gollm ${BOLD}pull${NC}   <model>        pull a model into Ollama"
    echo -e "  gollm ${BOLD}import${NC} <file.gguf>   import a local GGUF file"
    echo -e "  gollm ${BOLD}models${NC}               list Ollama models"
    echo -e "  gollm ${BOLD}help${NC}                 full command reference"
    sep
fi

echo ""
