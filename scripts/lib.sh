#!/bin/bash
# Shared constants and helpers for llm-stack scripts

# Colors — compact names (G/B/Y/R) plus verbose aliases (GREEN/BLUE/YELLOW/RED)
G='\033[0;32m';  GREEN="$G"
B='\033[0;34m';  BLUE="$B"
Y='\033[1;33m';  YELLOW="$Y"
R='\033[0;31m';  RED="$R"
BOLD='\033[1m'
D='\033[2m'
NC='\033[0m'

# Returns true if Ollama API is reachable (2-second timeout prevents hangs)
ollama_running() {
    curl -s --max-time 2 http://localhost:11434/api/tags > /dev/null 2>&1
}
