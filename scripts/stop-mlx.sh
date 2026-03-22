#!/bin/bash
# Stop the MLX server

# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

PID_FILE="$HOME/.mlx/mlx.pid"

if [[ ! -f "$PID_FILE" ]]; then
    echo -e "${Y}No MLX PID file found — server may not be running${NC}"
    # Try to find and kill any stray mlx_lm.server processes
    PIDS=$(pgrep -f "mlx_lm.server" 2>/dev/null)
    if [[ -n "$PIDS" ]]; then
        echo -e "Found stray mlx_lm.server processes: $PIDS — killing them"
        kill $PIDS 2>/dev/null
        echo -e "${G}✓ Stopped${NC}"
    fi
    exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null 2>&1; then
    echo -e "Stopping MLX server (PID $PID)…"
    kill "$PID"
    for i in {1..5}; do
        sleep 1
        ps -p "$PID" > /dev/null 2>&1 || break
    done
    if ps -p "$PID" > /dev/null 2>&1; then
        kill -9 "$PID" 2>/dev/null
    fi
    echo -e "${G}✓ MLX server stopped${NC}"
else
    echo -e "${Y}Process $PID not running (stale PID file)${NC}"
fi

rm -f "$PID_FILE" "$HOME/.mlx/mlx.model"
