#!/bin/bash
# Stop Open WebUI in Docker with GPU support
# Note that Ollama will continue running independently

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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