#!/bin/bash
# Status checker for LLM stack with locally-running Ollama and Open WebUI in Docker

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}=== LLM Stack Status ===${NC}"
echo "==============================="

# Check for locally-running Ollama (not in container)
echo -e "\n${BLUE}=== Ollama Status (Local Process) ===${NC}"
if pgrep -x "ollama" > /dev/null; then
    echo -e "${GREEN}✓ Ollama process is running locally${NC}"
    
    # Check Ollama API
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        echo -e "${GREEN}✓ Ollama API is responsive at http://localhost:11434${NC}"
        
        # Show available models
        echo -e "\n${BLUE}=== Available Ollama Models ===${NC}"
        ollama list
    else
        echo -e "${RED}✗ Ollama API is not responding at http://localhost:11434${NC}"
        echo -e "${YELLOW}Process is running but API may not be ready or is having issues${NC}"
    fi
else
    echo -e "${RED}✗ Ollama process is not running locally${NC}"
    echo -e "${YELLOW}To start Ollama: ./scripts/start-ollama.sh${NC}"
fi

# Check for Open WebUI running in Docker
echo -e "\n${BLUE}=== Open WebUI Status (Docker) ===${NC}"
if docker ps --format "{{.Names}}" | grep -q "open-webui"; then
    WEBUI_CONTAINER_ID=$(docker ps --filter "name=open-webui" --format "{{.ID}}")
    echo -e "${GREEN}✓ Open WebUI container is running${NC}"
    echo -e "Container ID: ${WEBUI_CONTAINER_ID}"
    
    # Get container details
    echo -e "\n${BLUE}=== Open WebUI Container Details ===${NC}"
    docker ps --filter "name=open-webui" --format "ID: {{.ID}}\nName: {{.Names}}\nImage: {{.Image}}\nStatus: {{.Status}}\nPorts: {{.Ports}}"
else
    echo -e "${RED}✗ Open WebUI container is not running${NC}"
    echo -e "${YELLOW}To start Open WebUI: ./scripts/start-webui.sh${NC}"
fi

# Show Docker context
echo -e "\n${BLUE}=== Docker Context ===${NC}"
docker context show

# Show resource usage for running containers
echo -e "\n${BLUE}=== Resource Usage ===${NC}"
if docker ps -q | grep -q .; then
    docker stats --no-stream
else
    echo -e "${YELLOW}No Docker containers are currently running${NC}"
fi

# Show service URLs
echo -e "\n${BLUE}=== Service URLs ===${NC}"
echo -e "Open WebUI: ${GREEN}http://localhost:3000${NC}"
echo -e "Ollama API: ${GREEN}http://localhost:11434${NC}"
echo -e "\n${YELLOW}NOTE: Ollama runs locally (not in container) with Metal acceleration${NC}"
echo -e "${YELLOW}Open WebUI runs in Docker container and connects to local Ollama${NC}"
echo "==============================="