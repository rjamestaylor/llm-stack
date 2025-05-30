#!/bin/bash
# Configuration for llm-bench
# Handles dependencies and integration with llm-stack if available

# Styles for output
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ollama API endpoint (can be overridden with environment variable)
OLLAMA_API="${OLLAMA_API:-http://127.0.0.1:11434}"

# Base directory for llm-bench
LLM_BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default reports directory
REPORTS_BASE_DIR="${REPORTS_BASE_DIR:-$LLM_BENCH_DIR/benchmark-reports}"

# Directory for utility scripts
UTILS_DIR="$LLM_BENCH_DIR/utils"

# Integration with llm-stack (if installed)
LLM_STACK_DIR="${LLM_STACK_DIR:-}"

# Auto-detect llm-stack if not specified
if [ -z "$LLM_STACK_DIR" ]; then
  # Check common locations
  if [ -d "../llm-stack" ]; then
    LLM_STACK_DIR="$(cd "../llm-stack" && pwd)"
    echo -e "${GREEN}Found llm-stack in '../llm-stack'${NC}"
  elif [ -d "$(dirname "$LLM_BENCH_DIR")/llm-stack" ]; then
    LLM_STACK_DIR="$(cd "$(dirname "$LLM_BENCH_DIR")/llm-stack" && pwd)"
    echo -e "${GREEN}Found llm-stack in '$(dirname "$LLM_BENCH_DIR")/llm-stack'${NC}"
  fi
fi

# Use llm-stack scripts if available, otherwise use local utils
if [ -n "$LLM_STACK_DIR" ] && [ -d "$LLM_STACK_DIR/scripts" ]; then
  USE_LLM_STACK_SCRIPTS=true
  LLM_STACK_SCRIPTS_DIR="$LLM_STACK_DIR/scripts"
  echo -e "${BLUE}Using llm-stack scripts from: $LLM_STACK_SCRIPTS_DIR${NC}"
else
  USE_LLM_STACK_SCRIPTS=false
  echo -e "${BLUE}Using local utility scripts from: $UTILS_DIR${NC}"
fi

# Function to safely find script path
get_script_path() {
  local script_name=$1
  local fallback_path="$UTILS_DIR/$script_name"
  
  if [ "$USE_LLM_STACK_SCRIPTS" = true ] && [ -f "$LLM_STACK_SCRIPTS_DIR/$script_name" ]; then
    echo "$LLM_STACK_SCRIPTS_DIR/$script_name"
  elif [ -f "$fallback_path" ]; then
    echo "$fallback_path"
  else
    echo ""
  fi
}

# Debug mode (set to true to see API responses)
DEBUG=false