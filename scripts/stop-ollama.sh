#!/bin/bash
# Stop Ollama without affecting WebUI
# This allows for independent management of Ollama

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping Ollama${NC}"
echo "===================================================="

# Stop Ollama process
echo -e "${BLUE}Stopping Ollama...${NC}"

# Find Ollama PID(s)
OLLAMA_PIDS=$(pgrep -f "ollama serve")

if [ -z "$OLLAMA_PIDS" ]; then
    echo -e "${YELLOW}No running Ollama processes found.${NC}"
else
    echo -e "Found Ollama process(es): $OLLAMA_PIDS"
    
    # Stop each process
    for pid in $OLLAMA_PIDS; do
        echo -e "Stopping Ollama process $pid..."
        if kill -15 "$pid" 2>/dev/null; then
            echo -e "${GREEN}Sent SIGTERM to process $pid${NC}"
            
            # Wait for process to terminate gracefully
            for i in {1..5}; do
                if ! ps -p "$pid" > /dev/null; then
                    echo -e "${GREEN}Process $pid terminated${NC}"
                    break
                fi
                sleep 1
            done
            
            # Force kill if still running
            if ps -p "$pid" > /dev/null; then
                echo -e "${YELLOW}Process $pid still running, sending SIGKILL...${NC}"
                kill -9 "$pid" 2>/dev/null
            fi
        else
            echo -e "${RED}Failed to send SIGTERM to process $pid${NC}"
        fi
    done
fi

# Double-check if any Ollama processes are still running
REMAINING_PIDS=$(pgrep -f "ollama serve")
if [ -n "$REMAINING_PIDS" ]; then
    echo -e "${RED}Warning: Some Ollama processes are still running: $REMAINING_PIDS${NC}"
    echo -e "You may need to manually kill these processes."
else
    echo -e "${GREEN}All Ollama processes stopped successfully.${NC}"
fi

# Check if API is still responsive (extra confirmation)
if curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo -e "${RED}Warning: Ollama API is still responsive on port 11434.${NC}"
    echo -e "Something may still be running on this port."
else
    echo -e "${GREEN}Ollama API is no longer responsive. Shutdown complete.${NC}"
fi

echo ""
echo -e "${GREEN}Ollama stopped.${NC}"
echo -e "${YELLOW}NOTE: Open WebUI is still running if it was started previously.${NC}"
echo -e "${YELLOW}To stop Open WebUI, use: ./scripts/stop-webui.sh${NC}"
echo "===================================================="