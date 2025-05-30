#!/bin/bash
# Start the complete LLM stack with native Ollama and Docker-based WebUI

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(dirname "$0")"
MODEL="mistral:7b-instruct"  # Default model

show_usage() {
  echo "Usage: $0 [OPTIONS] [MODEL]"
  echo ""
  echo "Options:"
  echo "  --list-models, -l     List available models and exit"
  echo "  --select-model, -s    Interactively select a model"
  echo "  --help, -h            Show this help message"
  echo ""
  echo "If MODEL is provided, it will be loaded. Otherwise, mistral:7b-instruct is used."
  exit 0
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list-models|-l)
      "$SCRIPT_DIR/list-models.sh" --list
      exit 0
      ;;
    --select-model|-s)
      MODEL=$("$SCRIPT_DIR/list-models.sh" --select)
      shift
      ;;
    --help|-h)
      show_usage
      ;;
    *)
      # If it's not an option, assume it's the model name
      if [[ "$1" != -* ]]; then
        MODEL="$1"
      fi
      shift
      ;;
  esac
done

echo -e "${GREEN}Starting LLM Stack${NC}"
echo -e "${BLUE}• Ollama with Metal acceleration${NC}"
echo -e "${BLUE}• Docker-based Open WebUI${NC}"
echo "===================================================="

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    echo "Please start Docker Desktop first."
    exit 1
fi

# Start Ollama if not already running
if curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo -e "${YELLOW}Ollama is already running on port 11434.${NC}"
    echo "Continuing with existing Ollama instance."
else
    echo -e "${BLUE}Starting Ollama...${NC}"
    "$SCRIPT_DIR/start-ollama.sh"
    
    # Wait for Ollama to initialize
    echo "Waiting for Ollama to initialize..."
    for i in {1..10}; do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            echo -e "${GREEN}Ollama API is now responsive.${NC}"
            break
        fi
        if [ $i -eq 10 ]; then
            echo -e "${RED}Error: Ollama API not responding after 10 attempts.${NC}"
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    echo ""
fi

# Start Open WebUI
echo -e "${BLUE}Starting Open WebUI...${NC}"
"$SCRIPT_DIR/start-webui.sh"

# Load the specified model
echo -e "${BLUE}Loading model: $MODEL${NC}"

# Check if model is already loaded
if ollama list | grep -q "$MODEL"; then
    echo -e "${YELLOW}Model $MODEL is already loaded.${NC}"
else
    echo -e "Pulling model $MODEL..."
    ollama pull "$MODEL"
    echo -e "${GREEN}Model $MODEL loaded and ready!${NC}"
fi

echo ""
echo -e "${GREEN}Stack started!${NC}"
echo -e "${BLUE}Access Open WebUI at:${NC} http://localhost:3000"
echo -e "${BLUE}Ollama API available at:${NC} http://localhost:11434"
echo ""
echo -e "${YELLOW}IMPORTANT: Metal acceleration is active for Apple Silicon GPUs${NC}"
echo -e "${YELLOW}For best performance on Apple Silicon Macs${NC}"
echo "===================================================="