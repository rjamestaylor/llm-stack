#!/bin/bash
# Restart the LLM stack with native Ollama and GPU-enabled Docker WebUI

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

echo -e "${YELLOW}Restarting LLM Stack with GPU Support${NC}"
echo "===================================================="

# First stop the stack
echo -e "${BLUE}Stopping services...${NC}"
"$SCRIPT_DIR/stop-stack.sh"

# Wait a moment to ensure everything is stopped
sleep 5

# Start the stack again
echo -e "${BLUE}Starting services with GPU support...${NC}"

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}Error: Ollama is not installed.${NC}"
    echo "Please install Ollama with: brew install ollama"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    echo "Please start Docker Desktop first."
    exit 1
fi

# Create data directory if it doesn't exist
OLLAMA_DATA_DIR="$HOME/ollama-native"
mkdir -p "$OLLAMA_DATA_DIR"
echo -e "${BLUE}Ollama data directory: ${OLLAMA_DATA_DIR}${NC}"

# Start native Ollama in the background
echo -e "${GREEN}Starting native Ollama with Metal acceleration for Apple Silicon...${NC}"

# Set environment variables for Metal support
export OLLAMA_HOST=0.0.0.0
export OLLAMA_MODELS="$OLLAMA_DATA_DIR"
export METAL_DEVICE_WRAPPER_ENABLED=1
export METAL_DEBUG_ERROR_MODE=1

# Start in background, redirect output to log file
nohup ollama serve > "$OLLAMA_DATA_DIR/ollama.log" 2>&1 &
OLLAMA_PID=$!

echo -e "${BLUE}Ollama started with PID: $OLLAMA_PID${NC}"
echo -e "${BLUE}Log file: $OLLAMA_DATA_DIR/ollama.log${NC}"

# Wait for Ollama to initialize
echo "Waiting for Ollama to initialize..."
for i in {1..10}; do
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        echo -e "${GREEN}Ollama API is now responsive.${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}Error: Ollama API not responding after 10 attempts.${NC}"
        echo "Check the log file: $OLLAMA_DATA_DIR/ollama.log"
        exit 1
    fi
    echo -n "."
    sleep 1
done
echo ""

# Start Open WebUI in Docker with GPU support
echo -e "${GREEN}Starting GPU-enabled Open WebUI in Docker...${NC}"
cd "$SCRIPT_DIR/../docker"
docker compose -f docker-compose-webui.yml up -d

# Check if WebUI started successfully
if docker ps | grep -q open-webui; then
    echo -e "${GREEN}GPU-enabled Open WebUI started successfully.${NC}"
    # Tools are automatically mounted via Docker volume
else
    echo -e "${RED}Error: Failed to start Open WebUI container.${NC}"
    echo "Check Docker logs: docker logs open-webui"
fi

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
echo -e "${GREEN}Stack restarted with GPU support!${NC}"
echo -e "${BLUE}Access Open WebUI at:${NC} http://localhost:3000"
echo -e "${BLUE}Ollama API available at:${NC} http://localhost:11434"
echo ""
echo -e "${YELLOW}IMPORTANT: This configuration uses native Apple Silicon GPU acceleration${NC}"
echo -e "${YELLOW}through the :ollama container tag for optimal performance${NC}"
echo "===================================================="