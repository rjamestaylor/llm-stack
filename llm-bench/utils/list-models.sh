#!/bin/bash
# Utility script to list available Ollama models
# Used by llm-bench in standalone mode

# Colors for output
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ollama API endpoint
OLLAMA_API="${OLLAMA_API:-http://127.0.0.1:11434}"

# Check if Ollama is running
if ! curl -s "${OLLAMA_API}/api/tags" &>/dev/null; then
    echo -e "${RED}Error: Ollama API not responding.${NC}"
    echo "Please start Ollama with: ollama serve"
    exit 1
fi

# Print header
echo -e "${BOLD}NAME${NC}                      ${BOLD}ID${NC}                ${BOLD}SIZE${NC}   ${BOLD}MODIFIED${NC}"

# Get model data from API
response=$(curl -s "${OLLAMA_API}/api/tags")

# Check if response is valid JSON
if ! echo "$response" | jq '.' &>/dev/null; then
    echo -e "${RED}Error: Invalid response from Ollama API${NC}"
    exit 1
fi

# Process each model
echo "$response" | jq -r '.models[] | "\(.name) \(.model) \(.size) \(.modified)"' | while read -r name model size modified; do
    # Format size
    size_human=$(numfmt --to=iec-i --suffix=B --format="%.1f" "$size" 2>/dev/null || echo "$size")
    
    # Format modified time
    modified_date=$(date -r "$modified" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$modified")
    
    # Print formatted line
    printf "%-28s %-18s %-7s %s\n" "$name" "$model" "$size_human" "$modified_date"
done

# Print instruction for additional information
echo -e "\nFor more details, use: ${GREEN}ollama list${NC}"