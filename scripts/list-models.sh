#!/bin/bash
# List and select available Ollama models for native installation

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the recommended models from pull-models-native.sh (without actually executing the script)
get_recommended_models() {
    # This extracts the model names from pull-models-native.sh without running the script
    local models=$(grep -A 10 "models=(" "$(dirname "$0")/pull-models-native.sh" | grep -v "models=(" | grep -v "^)" | grep "\".*\"" | sed 's/[[:space:]]*"\(.*\)".*#\(.*\)/\1|\2/' | sed 's/[[:space:]]*"\(.*\)"/\1/' | sed 's/[[:space:]]*$//')
    echo "$models"
}

print_recommended_models() {
    echo -e "${BLUE}Recommended models for your MacStudio Pro M2 Ultra:${NC}"
    echo "----------------------------------------------------"
    echo "(*) = Model already downloaded and available locally"
    echo "----------------------------------------------------"
    
    # Get array of local models if Ollama is running
    local local_models=()
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        while IFS= read -r line; do
            if [[ "$line" != "NAME"* ]]; then
                local_model=$(echo "$line" | awk '{print $1}')
                local_models+=("$local_model")
            fi
        done < <(ollama list 2>/dev/null | tail -n +2)
    else
        echo -e "${YELLOW}Ollama is not currently running. Cannot check installed models.${NC}"
    fi
    
    # Print the recommended models with indicator if they're local
    while IFS="|" read -r model_name description; do
        local indicator=" "
        for local_model in "${local_models[@]}"; do
            if [[ "$local_model" == "$model_name" ]]; then
                indicator="*"
                break
            fi
        done
        printf "(%s) %-30s %s\n" "$indicator" "$model_name" "${description:+# $description}"
    done < <(get_recommended_models)
    
    echo "----------------------------------------------------"
    echo -e "${GREEN}Default model: mistral:7b-instruct${NC}"
}

list_installed_models() {
    # Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}Error: Ollama is not installed.${NC}"
        echo "Please install Ollama with: brew install ollama"
        return 1
    fi

    # Check if Ollama is running
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        echo -e "${GREEN}Currently installed models:${NC}"
        echo "----------------------------------------------------"
        ollama list
        echo "----------------------------------------------------"
        echo -e "${GREEN}Default model: mistral:7b-instruct${NC}"
        return 0
    else
        echo -e "${YELLOW}Ollama is not currently running. Cannot list installed models.${NC}"
        echo -e "${YELLOW}Please start Ollama first with: ./scripts/start-ollama.sh${NC}"
        print_recommended_models
        return 1
    fi
}

interactive_select() {
    local models=()
    local descriptions=()
    local local_indicator=()
    
    # Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}Error: Ollama is not installed.${NC}"
        echo "Please install Ollama with: brew install ollama"
        echo "mistral:7b-instruct"  # Return default model name
        return 1
    fi
    
    # Check if Ollama is running to get actual models
    local has_local_models=false
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        has_local_models=true
        echo -e "${BLUE}Fetching installed models from running Ollama...${NC}"
        
        # Get locally installed models
        while IFS= read -r line; do
            if [[ "$line" != "NAME"* ]]; then
                model=$(echo "$line" | awk '{print $1}')
                models+=("$model")
                descriptions+=("Already downloaded")
                local_indicator+=("*")
            fi
        done < <(ollama list 2>/dev/null | tail -n +2)
    else
        echo -e "${YELLOW}Ollama is not running. Cannot check for locally available models.${NC}"
        echo -e "${YELLOW}Please start Ollama first with: ./scripts/start-ollama.sh${NC}"
    fi
    
    # If no local models or to add recommended models
    while IFS="|" read -r model_name description; do
        # Check if this model is already in our list
        local skip=false
        for existing_model in "${models[@]}"; do
            if [[ "$existing_model" == "$model_name" ]]; then
                skip=true
                break
            fi
        done
        
        if [[ "$skip" == "false" ]]; then
            models+=("$model_name")
            descriptions+=("$description")
            local_indicator+=(" ")
        fi
    done < <(get_recommended_models)
    
    echo -e "${BLUE}Select a model to load:${NC}"
    echo "----------------------------------------------------"
    echo "(*) = Model already downloaded and available locally"
    echo "----------------------------------------------------"
    
    local default_index=0
    for i in "${!models[@]}"; do
        # Find mistral:7b-instruct for default
        if [[ "${models[$i]}" == "mistral:7b-instruct" ]]; then
            default_index=$i
        fi
        printf "%2d. (%s) %-30s - %s\n" "$((i+1))" "${local_indicator[$i]}" "${models[$i]}" "${descriptions[$i]}"
    done
    echo "----------------------------------------------------"
    
    local selection
    read -p "Enter number (1-${#models[@]}) [default=$((default_index+1)) for mistral:7b-instruct]: " selection
    
    # Default to mistral:7b-instruct
    if [[ -z "$selection" ]]; then
        selection=$((default_index+1))
    fi
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#models[@]}" ]; then
        selected_model=${models[$((selection-1))]}
        selected_indicator=${local_indicator[$((selection-1))]}
        
        if [[ "$selected_indicator" == " " ]]; then
            echo -e "${YELLOW}Note: Selected model '$selected_model' will need to be downloaded first.${NC}"
        else
            echo -e "${GREEN}Selected model: $selected_model (already downloaded)${NC}"
        fi
        
        echo "$selected_model"
        return 0
    else
        echo -e "${YELLOW}Invalid selection. Using default: mistral:7b-instruct${NC}"
        echo "mistral:7b-instruct"
        return 1
    fi
}

# Main script logic
case "$1" in
    --list|-l)
        list_installed_models
        ;;
    --select|-s)
        interactive_select
        ;;
    *)
        # If no arguments, just list models
        list_installed_models
        ;;
esac