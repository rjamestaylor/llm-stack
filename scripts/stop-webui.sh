#!/bin/bash
# Stop Open WebUI in Docker with GPU support
# Note that Ollama will continue running independently

# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

echo -e "${YELLOW}Stopping GPU-enabled Open WebUI in Docker${NC}"
echo "===================================================="

# Stop WebUI container
echo -e "${BLUE}Stopping GPU-enabled Open WebUI Docker container...${NC}"
cd "$(dirname "$0")/../docker"
if docker compose -f docker-compose-webui.yml down; then
    echo -e "${GREEN}GPU-enabled Open WebUI container stopped successfully.${NC}"
else
    echo -e "${RED}Error stopping Open WebUI container.${NC}"
    echo "You may need to stop it manually: docker rm -f open-webui"
    exit 1
fi

echo ""
echo -e "${GREEN}Open WebUI has been stopped.${NC}"
echo -e "${YELLOW}NOTE: Ollama is still running and will continue to provide${NC}"
echo -e "${YELLOW}native Apple Silicon GPU acceleration for other applications.${NC}"
echo -e "${YELLOW}To stop Ollama completely, use: ./scripts/stop-ollama.sh${NC}"
echo "===================================================="