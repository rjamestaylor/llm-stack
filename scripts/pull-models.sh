#!/bin/bash
# Pull recommended models for Ollama with Metal acceleration
# Prioritizing quantized models for better performance
# Optimized for MacStudio Pro M2 Ultra

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Deprecated: use pull-models-fp16.sh
echo -e "${YELLOW}Deprecated: use pull-models-fp16.sh${NC}"

read -p "Enter any key to quit or 'proceed' to continue, anyway: " selection
    
    # Default quit
    if [[ -z "$selection" ]]; then
        selection='quit'
    fi

case "$selection" in
    "proceed")
        echo "...continuing..."
        ;;
    *)
        # If no arguments, just list models
        exit 0
        ;;
esac

echo "===================================================="
echo -e "${GREEN}Pulling LLM Models with Metal Acceleration${NC}"
echo -e "${BLUE}Optimized for MacStudio Pro M2 Ultra${NC}"
echo "===================================================="

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}Error: Ollama is not installed.${NC}"
    echo "Please install Ollama with: brew install ollama"
    exit 1
fi

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo -e "${RED}Error: Ollama is not running.${NC}"
    echo "Please start Ollama first with: ./scripts/start-stack.sh"
    exit 1
fi

# Define models optimized for Apple Silicon with Metal
# For best performance, prefer quantized models over fp16
# fp16 models tend to run too slowly on this machine
models=(
    "llama3.1:70b-instruct"       # Quantized model performs better than fp16
    "mixtral:8x7b-instruct-v0.1"  # Quantized model performs better than fp16
    "qwen2.5:72b-instruct"
    "codestral:22b-instruct-v0.1"
    "llama3.1:8b-instruct"
    "mistral:7b-instruct"
)

# Get list of already pulled models
echo -e "${BLUE}Checking existing models...${NC}"
existing_models=$(ollama list | tail -n +2 | awk '{print $1}')

# Counter for pulled models
pulled_count=0

# Pull each model
for model in "${models[@]}"; do
    # Check if model is already pulled
    if echo "$existing_models" | grep -q "$model"; then
        echo -e "${YELLOW}Model $model is already pulled. Skipping.${NC}"
        continue
    fi
    
    # Pull the model
    echo -e "${BLUE}Pulling $model...${NC}"
    if ollama pull "$model"; then
        echo -e "${GREEN}Successfully pulled $model${NC}"
        pulled_count=$((pulled_count + 1))
    else
        echo -e "${RED}Failed to pull $model${NC}"
    fi
    
    echo "----------------------------------------------------"
done

# Show summary
echo -e "${GREEN}Model pulling complete!${NC}"
if [ $pulled_count -gt 0 ]; then
    echo -e "${BLUE}Pulled $pulled_count new models.${NC}"
else
    echo -e "${YELLOW}No new models were pulled. All requested models were already available.${NC}"
fi

echo -e "${BLUE}Available models with Metal acceleration:${NC}"
ollama list

echo ""
echo -e "${YELLOW}IMPORTANT NOTES:${NC}"
echo -e "• Models are optimized for Metal acceleration on Apple Silicon"
echo -e "• These models use quantized versions for optimal performance on this machine"
echo -e "• fp16 models are available but tend to run too slowly on this machine"
echo -e "• The models are stored in ~/ollama-data"
echo "===================================================="