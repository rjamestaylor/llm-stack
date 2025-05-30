#!/bin/bash
# Start Ollama with Metal acceleration for Apple Silicon GPUs

# Check if Ollama is already installed
if ! command -v ollama &> /dev/null; then
    echo "Ollama is not installed. Please install it with: brew install ollama"
    echo "Then run this script again."
    exit 1
fi

# Use default Ollama models directory if not already set
if [ -z "$OLLAMA_DATA_DIR" ]; then
    OLLAMA_DATA_DIR="$HOME/.ollama"
fi

# Ensure the directory exists
mkdir -p "$OLLAMA_DATA_DIR"

# Environment variables for Metal optimization
export OLLAMA_HOST=0.0.0.0     # Make accessible from Docker
export OLLAMA_MODELS="$OLLAMA_DATA_DIR/models"
export METAL_DEVICE_WRAPPER_ENABLED=1  # Enable Metal acceleration
export METAL_DEBUG_ERROR_MODE=1        # Show detailed Metal errors

# Optional: Set number of threads based on CPU cores
# Adjust these values based on your specific M2 Ultra configuration
export OLLAMA_NUM_CPU=20

# Check if Ollama is already running
if curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "Ollama is already running on port 11434."
    echo "If you want to restart with new settings, please stop it first."
    exit 0
fi

# Start Ollama service
echo "Starting Ollama with Metal acceleration..."
echo "Models will be stored in: $OLLAMA_DATA_DIR"
echo "API will be available at: http://localhost:11434"
echo "Metal acceleration: ENABLED"

# Run ollama serve in the background using nohup
LOG_FILE="$OLLAMA_DATA_DIR/ollama.log"
echo "Starting Ollama in background mode. Logs will be written to: $LOG_FILE"
nohup ollama serve > "$LOG_FILE" 2>&1 &
PID=$!
echo "Ollama started with PID: $PID"