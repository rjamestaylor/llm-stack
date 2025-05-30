#!/bin/bash
# Start Open WebUI in Docker with GPU support for Apple Silicon
# Using the recommended Ollama-integrated container

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Open WebUI in Docker with GPU support${NC}"
echo "===================================================="

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    echo "Please start Docker Desktop first."
    exit 1
fi

# Ensure Ollama is running first for native Apple Silicon support
echo -e "${BLUE}Checking if Ollama is running...${NC}"
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo -e "${YELLOW}Ollama is not running. Starting Ollama first...${NC}"
    "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/start-ollama.sh"
    
    # Wait for Ollama to initialize
    echo "Waiting for Ollama to initialize..."
    for i in {1..10}; do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            echo -e "${GREEN}Ollama API is now responsive.${NC}"
            break
        fi
        if [ $i -eq 10 ]; then
            echo -e "${RED}Error: Ollama API not responding after 10 attempts.${NC}"
            echo "Please check Ollama's status and try again."
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    echo ""
else
    echo -e "${GREEN}Ollama is already running.${NC}"
fi

# Start Open WebUI with GPU support in Docker
echo -e "${BLUE}Starting Open WebUI Docker container with GPU support...${NC}"
cd "$(dirname "$0")/../docker"
docker compose -f docker-compose-webui.yml up -d

# Check if WebUI started successfully
if docker ps | grep -q open-webui; then
    echo -e "${GREEN}Open WebUI started successfully with GPU support.${NC}"
    # Tools are automatically mounted via Docker volume
else
    echo -e "${RED}Error: Failed to start Open WebUI container.${NC}"
    echo "Check Docker logs: docker logs open-webui"
    exit 1
fi

echo ""
echo -e "${GREEN}Open WebUI is now running with Apple Silicon GPU support!${NC}"
echo -e "${BLUE}Access Open WebUI at:${NC} http://localhost:3000"
echo ""
echo -e "${YELLOW}NOTE: This configuration uses the integrated Ollama container${NC}"
echo -e "${YELLOW}with native Apple Silicon GPU acceleration.${NC}"
echo "===================================================="