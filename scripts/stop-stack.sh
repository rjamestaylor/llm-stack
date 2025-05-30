#!/bin/bash
# Stop the complete LLM stack (Ollama and Docker-based WebUI)

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(dirname "$0")"

echo -e "${YELLOW}Stopping LLM Stack${NC}"
echo "===================================================="

# Stop WebUI first
echo -e "${BLUE}Stopping Open WebUI...${NC}"
"$SCRIPT_DIR/stop-webui.sh"

# Stop Ollama 
echo -e "${BLUE}Stopping Ollama...${NC}"
"$SCRIPT_DIR/stop-ollama.sh"

echo ""
echo -e "${GREEN}Complete stack stopped.${NC}"
echo "===================================================="