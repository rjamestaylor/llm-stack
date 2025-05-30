#!/bin/bash
# LLM Model Benchmarking Script for Apple Silicon
# Tests the speed and memory footprint of Ollama models
# Optimized for Metal acceleration on Apple Silicon GPUs

# Styles for output
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Debug mode (set to true to see API responses)
DEBUG=false

# Benchmark directory
BENCHMARK_DIR="$(dirname "$0")"

# Script directory
SCRIPT_DIR="$BENCHMARK_DIR/../scripts"


# Ollama API endpoint
OLLAMA_API="http://127.0.0.1:11434"

# Reports directory and result file
REPORTS_DIR="$BENCHMARK_DIR/benchmark-reports"

RESULT_FILE="${REPORTS_DIR}/model_benchmark_results.csv"

# Function to safely extract values from JSON with fallback
safe_jq_extract() {
    local json=$1
    local query=$2
    local fallback=$3
    
    # Extract the field name from the query (remove leading dot if present)
    local field_name=$(echo "$query" | sed 's/^\.//')
    
    # First check if the field exists
    if echo "$json" | jq "has(\"$field_name\")" 2>/dev/null | grep -q "true"; then
        # Field exists, check if it's null
        local value=$(echo "$json" | jq -r "$query" 2>/dev/null)
        if [[ "$value" == "null" || -z "$value" || "$value" == "undefined" ]]; then
            echo "$fallback"
        else
            echo "$value"
        fi
    else
        # Field doesn't exist
        echo "$fallback"
    fi
}

# Get available models from Ollama using list-models.sh
get_available_models() {
    echo "Fetching available models from Ollama..."
    
    # Use list-models.sh to get installed models
    if [ -f "$SCRIPT_DIR/list-models.sh" ]; then
        echo -e "${BLUE}Using list-models.sh to get installed models${NC}"
        # Get models from list-models.sh but only extract actual model lines
        models=()
        local capture_models=false
        
        while IFS= read -r line; do
            # Start capturing models after the header line
            if [[ "$line" == "NAME"* ]]; then
                capture_models=true
                continue
            fi
            
            # Stop capturing models if we hit a divider or text line
            if [[ "$line" == "--"* || "$line" == "Default"* || "$line" == "Currently"* || -z "$line" ]]; then
                capture_models=false
                continue
            fi
            
            # Only process lines when in capture mode and has content
            if [[ "$capture_models" == "true" && -n "$line" ]]; then
                # Extract just the model name (first column)
                model=$(echo "$line" | awk '{print $1}')
                if [[ -n "$model" ]]; then
                    models+=("$model")
                fi
            fi
        done < <("$SCRIPT_DIR/list-models.sh" 2>/dev/null)
        
        # Check if any models were found
        if [ ${#models[@]} -gt 0 ]; then
            echo -e "${GREEN}Found ${#models[@]} models:${NC}"
            for model in "${models[@]}"; do
                echo "  - $model"
            done
        else
            echo -e "${YELLOW}No models found from list-models.sh, trying API fallback...${NC}"
            models_from_api
        fi
    else
        echo -e "${YELLOW}list-models.sh not found, using API fallback...${NC}"
        models_from_api
    fi
    
    # If no models were found, use fallback
    if [ ${#models[@]} -eq 0 ]; then
        echo -e "${RED}No models found, using fallback model list...${NC}"
        # Fallback to default models (using quantized versions found on the system)
        models=(
            "llama3.1:70b-instruct-q5_K_M"
            "mixtral:8x7b-instruct-v0.1-q6_K"
            "qwen2.5:72b-instruct-q4_K_M"
            "mistral:7b-instruct"
        )
    fi
}

# Fallback function to get models from API
models_from_api() {
    echo "Fetching available models from Ollama API..."
    
    # Get models from API using curl
    local response=$(curl -s "${OLLAMA_API}/api/tags")
    
    if $DEBUG; then
        echo -e "${YELLOW}DEBUG: API Tags Response:${NC}"
        echo "$response" | jq '.'
    fi
    
    # Check if response is valid JSON
    if ! echo "$response" | jq '.' &>/dev/null; then
        echo -e "${RED}ERROR: Invalid JSON response from API when fetching models${NC}"
        echo -e "${YELLOW}Raw response:${NC} $response"
        # Models array will be empty, fallback will be applied later
    else
        # Extract model names from the response
        models=()
        while IFS= read -r model_name; do
            models+=("$model_name")
        done < <(echo "$response" | jq -r '.models[] | .name')
        
        # Check if any models were found
        if [ ${#models[@]} -eq 0 ]; then
            echo -e "${RED}ERROR: No models found in the API response${NC}"
            # Models array will be empty, fallback will be applied later
        else
            echo -e "${GREEN}Found ${#models[@]} models:${NC}"
            for model in "${models[@]}"; do
                echo "  - $model"
            done
        fi
    fi
}

# Standardized prompts for consistent testing
SHORT_PROMPT="Explain the concept of machine learning in one paragraph."
MEDIUM_PROMPT="Write a detailed explanation of how transformer neural networks work, including attention mechanisms and their advantages over RNNs."
LONG_PROMPT="Write a 500-word essay on the ethical implications of artificial intelligence in healthcare, considering patient privacy, algorithmic bias, and the role of human oversight."
CODE_PROMPT="Write a Python function that implements a binary search tree with insert, delete, and search operations. Include proper documentation and example usage."

# Function to measure memory usage of Ollama process
get_memory_usage() {
    # Extract memory usage in MB using ps
    ps -o rss= -p $(pgrep -f "ollama serve") | awk '{sum+=$1} END {printf "%.1f", sum/1024}'
}

# Function to measure CPU usage of Ollama process
get_cpu_usage() {
    # Extract CPU usage percentage using ps
    ps -o %cpu= -p $(pgrep -f "ollama serve") | awk '{sum+=$1} END {printf "%.2f", sum}'
}

# Function to get hardware information with Apple Silicon support
get_hardware_info() {
    echo "Collecting system hardware information..."
    
    # CPU info
    echo "CPU Model: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
    echo "CPU Cores: $(sysctl -n hw.ncpu 2>/dev/null || echo 'Unknown')"
    
    # Memory info
    local total_mem=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}' || echo 'Unknown')
    echo "Total System Memory: ${total_mem}MB"
    
    # Apple Silicon GPU detection
    if sysctl -a 2>/dev/null | grep -q "machdep.cpu.brand_string" && sysctl -n machdep.cpu.brand_string | grep -q "Apple"; then
        # Check if Metal is enabled for running Ollama process
        local metal_enabled=false
        
        # Method 1: Check if Ollama was started by our scripts that enable Metal
        if pgrep -f "ollama serve" > /dev/null; then
            # Get the parent process of ollama
            local ollama_pid=$(pgrep -f "ollama serve")
            local parent_cmd=$(ps -o command= -p $(ps -o ppid= -p $ollama_pid))
            
            # If started by our script, it likely has Metal enabled
            if echo "$parent_cmd" | grep -q "start-ollama.sh\|restart-stack.sh"; then
                metal_enabled=true
            fi
            
            # Method 2: Check for Metal-related process
            if ps aux | grep -i "[M]etal" > /dev/null; then
                metal_enabled=true
            fi
        fi
        
        # Also check current shell's env var as fallback
        if [ -n "$METAL_DEVICE_WRAPPER_ENABLED" ] && [ "$METAL_DEVICE_WRAPPER_ENABLED" -eq 1 ]; then
            metal_enabled=true
        fi
        
        if [ "$metal_enabled" = true ]; then
            echo "GPU: Apple Silicon GPU with Metal acceleration ENABLED"
            # Get more GPU details if available
            GPU_CORE_COUNT=$(sysctl -a 2>/dev/null | grep "gpu.control" | grep "cores" | head -1 | awk '{print $2}' || echo "Unknown")
            if [ "$GPU_CORE_COUNT" != "Unknown" ]; then
                echo "GPU Cores: $GPU_CORE_COUNT"
            fi
        else
            echo "GPU: Apple Silicon GPU detected (Metal acceleration NOT ENABLED)"
            echo "To enable Metal, set METAL_DEVICE_WRAPPER_ENABLED=1 before starting Ollama"
        fi
    elif command -v nvidia-smi &> /dev/null; then
        echo "GPU Detected: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
        echo "GPU Memory: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader)"
    else
        echo "GPU: Not detected (CPU inference only)"
    fi
}

# Function to run a benchmark for a specific model and prompt
benchmark_model_prompt() {
    local model=$1
    local prompt=$2
    local prompt_name=$3
    local result_file=$4
    
    echo -e "${BLUE}Testing ${BOLD}$model${NC} with ${YELLOW}$prompt_name prompt${NC}..."
    
    # Get baseline metrics
    sleep 2
    local baseline_memory=$(get_memory_usage)
    local baseline_cpu=$(get_cpu_usage)
    echo "Baseline memory usage: ${baseline_memory}MB"
    echo "Baseline CPU usage: ${baseline_cpu}%"
    
    # Start timing
    local start_time=$(date +%s.%N)
    
    # Start CPU sampling in background
    local cpu_samples=()
    # Create pid file in the benchmarking tmp directory
    mkdir -p "$BENCHMARK_DIR/tmp"
    # Sanitize model and prompt name for safe filename
    local safe_model_name=$(echo "$model" | tr -dc '[:alnum:]._-')
    local safe_prompt_name=$(echo "$prompt_name" | tr -dc '[:alnum:]._-')
    local pid_file="$BENCHMARK_DIR/tmp/cpu_samples_${safe_model_name}_${safe_prompt_name}.txt"
    
    # Function to sample CPU in background
    (
        while true; do
            local cpu=$(get_cpu_usage)
            echo "$cpu" >> "$pid_file"
            sleep 0.5
        done
    ) &
    local sampler_pid=$!
    
    # Make the actual request (no streaming for accurate timing)
    local response=$(curl -s -X POST "${OLLAMA_API}/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"stream\": false}")
    
    # End timing and CPU sampling
    local end_time=$(date +%s.%N)
    kill $sampler_pid 2>/dev/null
    wait $sampler_pid 2>/dev/null
    
    # Process CPU samples
    local max_cpu=0
    local sum_cpu=0
    local count=0
    
    while IFS= read -r cpu_value; do
        if [[ "$cpu_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            sum_cpu=$(echo "$sum_cpu + $cpu_value" | bc)
            count=$((count + 1))
            if (( $(echo "$cpu_value > $max_cpu" | bc -l) )); then
                max_cpu=$cpu_value
            fi
        fi
    done < "$pid_file"
    
    local avg_cpu="N/A"
    if [[ $count -gt 0 ]]; then
        avg_cpu=$(echo "scale=2; $sum_cpu / $count" | bc)
    fi
    
    rm -f "$pid_file"
    
    # Calculate time metrics
    local total_time=$(echo "$end_time - $start_time" | bc)
    
    # Check if response is valid JSON
    if ! echo "$response" | jq '.' &>/dev/null; then
        echo -e "${RED}ERROR: Invalid JSON response from API${NC}"
        echo -e "${YELLOW}Raw response:${NC} $response"
        
        # Use fallback values for token metrics
        local total_tokens="N/A"
        local prompt_tokens="N/A"
        local generated_tokens="N/A"
        local tokens_per_second="N/A"
    else
        # If debugging, show full API response
        if $DEBUG; then
            echo -e "${YELLOW}DEBUG: Full API Response:${NC}"
            echo "$response" | jq '.'
        fi
        
        # Safely extract token metrics with fallbacks - try multiple possible field names
        # Try multiple field names for total tokens
        local total_tokens=$(safe_jq_extract "$response" '.total_tokens' "N/A")
        # If total_tokens is N/A, try eval_count
        if [[ "$total_tokens" == "N/A" ]]; then
            total_tokens=$(safe_jq_extract "$response" '.eval_count' "N/A")
        fi
        # If still N/A, try token_count
        if [[ "$total_tokens" == "N/A" ]]; then
            total_tokens=$(safe_jq_extract "$response" '.token_count' "N/A")
        fi
        
        # Try multiple field names for prompt tokens
        local prompt_tokens=$(safe_jq_extract "$response" '.prompt_tokens' "N/A")
        # If prompt_tokens is N/A, try prompt_eval_count
        if [[ "$prompt_tokens" == "N/A" ]]; then
            prompt_tokens=$(safe_jq_extract "$response" '.prompt_eval_count' "N/A")
        fi
        # If still N/A, try input_tokens
        if [[ "$prompt_tokens" == "N/A" ]]; then
            prompt_tokens=$(safe_jq_extract "$response" '.input_tokens' "N/A")
        fi
        
        # Handle calculated metrics
        if [[ "$total_tokens" != "N/A" && "$prompt_tokens" != "N/A" ]]; then
            # Only calculate if both values are available and numeric
            if [[ "$total_tokens" =~ ^[0-9]+$ && "$prompt_tokens" =~ ^[0-9]+$ ]]; then
                local generated_tokens=$((total_tokens - prompt_tokens))
                local tokens_per_second=$(echo "scale=2; $generated_tokens / $total_time" | bc 2>/dev/null || echo "N/A")
                local tokens_per_mb=$(echo "scale=2; $generated_tokens / $memory_used" | bc 2>/dev/null || echo "N/A")
                local throughput_score=$(echo "scale=2; $tokens_per_second * (100 / $max_cpu)" | bc 2>/dev/null || echo "N/A")
                
                # Metal acceleration metrics (detected using multiple methods)
                local metal_boost="Unknown"
                
                # Use the same detection logic as in get_hardware_info
                local metal_enabled=false
                
                # Method 1: Check if Ollama was started by our scripts that enable Metal
                if pgrep -f "ollama serve" > /dev/null; then
                    # Get the parent process of ollama
                    local ollama_parent_pid=$(pgrep -f "ollama serve")
                    local parent_cmd=$(ps -o command= -p $(ps -o ppid= -p $ollama_parent_pid))
                    
                    # If started by our script, it likely has Metal enabled
                    if echo "$parent_cmd" | grep -q "start-ollama.sh\|restart-stack.sh"; then
                        metal_enabled=true
                    fi
                    
                    # Method 2: Check for Metal-related processes
                    if ps aux | grep -i "[M]etal" > /dev/null; then
                        metal_enabled=true
                    fi
                fi
                
                # Also check current shell's env var as fallback
                if [ -n "$METAL_DEVICE_WRAPPER_ENABLED" ] && [ "$METAL_DEVICE_WRAPPER_ENABLED" -eq 1 ]; then
                    metal_enabled=true
                fi
                
                if [ "$metal_enabled" = true ]; then
                    metal_boost="Enabled"
                else
                    metal_boost="Disabled"
                fi
            else
                local generated_tokens="N/A"
                local tokens_per_second="N/A"
                local tokens_per_mb="N/A"
                local throughput_score="N/A"
                local metal_boost="Unknown"
                
                # Show the problematic values for debugging
                echo -e "${YELLOW}WARNING: Non-numeric token counts - total_tokens: $total_tokens, prompt_tokens: $prompt_tokens${NC}"
            fi
        else
            local generated_tokens="N/A"
            local tokens_per_second="N/A"
            local tokens_per_mb="N/A"
            local throughput_score="N/A"
            local metal_boost="Unknown"
        fi
    fi
    
    # Get peak memory during generation
    local peak_memory=$(get_memory_usage)
    local memory_used=$(echo "$peak_memory - $baseline_memory" | bc)
    
    # Append results to the result file with new metrics
    echo "$model,$prompt_name,$baseline_memory,$peak_memory,$memory_used,$baseline_cpu,$max_cpu,$avg_cpu,$total_tokens,$generated_tokens,$tokens_per_second,$tokens_per_mb,$throughput_score,$metal_boost,$total_time" >> $result_file
    
    # Format output
    echo -e "${GREEN}Completed in ${BOLD}$(printf "%.2f" $total_time)s${NC}"
    
    if [[ "$tokens_per_second" != "N/A" ]]; then
        echo -e "Speed: ${BOLD}$(printf "%.2f" $tokens_per_second) tokens/sec${NC}"
    else
        echo -e "Speed: ${YELLOW}Could not calculate tokens/sec${NC}"
    fi
    
    echo -e "Memory usage: ${BOLD}$(printf "%.1f" $memory_used)MB${NC} (baseline: ${baseline_memory}MB, peak: ${peak_memory}MB)"
    echo -e "CPU usage: Peak ${BOLD}${max_cpu}%${NC}, Avg ${BOLD}${avg_cpu}%${NC}"
    
    if [[ "$throughput_score" != "N/A" ]]; then
        echo -e "Efficiency score: ${BOLD}$(printf "%.2f" $throughput_score)${NC} (tokens/sec per CPU%)"
    fi
    
    if [[ "$metal_boost" == "Enabled" ]]; then
        echo -e "${GREEN}Metal acceleration: ENABLED${NC}"
    fi
    
    if [[ "$generated_tokens" != "N/A" && "$prompt_tokens" != "N/A" ]]; then
        echo -e "Generated ${BOLD}$generated_tokens${NC} tokens from prompt of ${BOLD}$prompt_tokens${NC} tokens"
    else
        echo -e "${YELLOW}Token metrics unavailable - API did not return expected fields${NC}"
        echo -e "${YELLOW}Try enabling DEBUG mode for more details${NC}"
    fi
    
    echo "------------------------------------------------------------"
}

# Function to benchmark a single model
benchmark_single_model() {
    local model=$1
    # Use a sanitized filename with no special characters or color codes
    local safe_model_name=$(echo "$model" | tr -dc '[:alnum:]._-')
    local temp_result_file="${safe_model_name}-benchmark.csv"
    
    echo -e "\n${BOLD}${GREEN}Benchmarking model: $model${NC}"
    
    # Create empty temp file in the benchmark tmp directory
    BENCHMARK_TEMP="$BENCHMARK_DIR/tmp"
    mkdir -p "$BENCHMARK_TEMP"
    # Add timestamp to avoid collisions
    local timestamp=$(date +%s)
    TEMP_RESULT="$BENCHMARK_TEMP/${safe_model_name}_benchmark_${timestamp}.csv"
    touch "$TEMP_RESULT"
    
    # Clean up any stray temp files older than 1 day
    find "$BENCHMARK_TEMP" -name "*.csv" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Run tests with different prompt types
    benchmark_model_prompt "$model" "$SHORT_PROMPT" "Short" "$TEMP_RESULT"
    benchmark_model_prompt "$model" "$MEDIUM_PROMPT" "Medium" "$TEMP_RESULT"
    benchmark_model_prompt "$model" "$CODE_PROMPT" "Code" "$TEMP_RESULT"
    
    echo -e "\n${BLUE}Completed all tests for $model${NC}"
    echo "============================================================"
    
    # Add header to the combined result file if it doesn't exist
    if [ ! -f "$RESULT_FILE" ]; then
        echo "Model,Prompt,Baseline Memory (MB),Peak Memory (MB),Memory Used (MB),Baseline CPU (%),Peak CPU (%),Avg CPU (%),Total Tokens,Generated Tokens,Tokens per Second,Tokens per MB,Throughput Score,Metal Acceleration,Total Time (s)" > "$RESULT_FILE"
    fi
    
    # Check if temp file exists and has content before appending
    if [ -f "$TEMP_RESULT" ] && [ -s "$TEMP_RESULT" ]; then
        # Make sure reports directory exists
        mkdir -p "$REPORTS_DIR"
        # Append the temporary results to the combined result file
        cat "$TEMP_RESULT" >> "$RESULT_FILE"
        
        # Remove the temporary file
        rm -f "$TEMP_RESULT"
    else
        echo "Warning: No benchmark results collected for $model"
    fi
}

# Process command line arguments
SEQUENTIAL_MODE=false

process_args() {
    for arg in "$@"; do
        case $arg in
            --sequential)
                SEQUENTIAL_MODE=true
                echo -e "${BLUE}Running in sequential mode - models will be unloaded between tests${NC}"
                ;;
        esac
    done
}

# Main benchmark function
run_benchmarks() {
    # Process command line arguments
    process_args "$@"
    
    # Ensure reports directory and temp directory exist
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$BENCHMARK_DIR/tmp"
    
    # Clean up any old temp files
    find "$BENCHMARK_DIR/tmp" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Collect hardware information
    get_hardware_info > "${REPORTS_DIR}/hardware_info.txt"
    echo "Hardware information saved to ${REPORTS_DIR}/hardware_info.txt"
    echo "------------------------------------------------------------"
    
    # Create/overwrite results file with enhanced header
    echo "Model,Prompt,Baseline Memory (MB),Peak Memory (MB),Memory Used (MB),Baseline CPU (%),Peak CPU (%),Avg CPU (%),Total Tokens,Generated Tokens,Tokens per Second,Tokens per MB,Throughput Score,Metal Acceleration,Total Time (s)" > "$RESULT_FILE"
    
    # Check if Ollama is running
    if ! curl -s "${OLLAMA_API}/api/tags" > /dev/null; then
        echo -e "${RED}Error: Ollama API not responding.${NC}"
        echo "Please start Ollama with: ./scripts/start-stack.sh"
        exit 1
    fi
    
    # Check if Metal is enabled using the same improved detection logic
    local metal_enabled=false
    
    # Method 1: Check if Ollama was started by our scripts that enable Metal
    if pgrep -f "ollama serve" > /dev/null; then
        # Get the parent process of ollama
        local ollama_pid=$(pgrep -f "ollama serve")
        local parent_cmd=$(ps -o command= -p $(ps -o ppid= -p $ollama_pid))
        
        # If started by our script, it likely has Metal enabled
        if echo "$parent_cmd" | grep -q "start-ollama.sh\|restart-stack.sh"; then
            metal_enabled=true
        fi
        
        # Method 2: Check for Metal-related process
        if ps aux | grep -i "[M]etal" > /dev/null; then
            metal_enabled=true
        fi
    fi
    
    # Also check current shell's env var as fallback
    if [ -n "$METAL_DEVICE_WRAPPER_ENABLED" ] && [ "$METAL_DEVICE_WRAPPER_ENABLED" -eq 1 ]; then
        metal_enabled=true
    fi
    
    # Display Metal acceleration status
    if [ "$metal_enabled" = true ]; then
        echo -e "${GREEN}Metal acceleration is ENABLED for Apple Silicon GPUs${NC}"
    else
        echo -e "${YELLOW}Metal acceleration is NOT enabled for these benchmarks${NC}"
        echo -e "${YELLOW}For better performance, restart Ollama with METAL_DEVICE_WRAPPER_ENABLED=1${NC}"
    fi
    
    # Get available models
    get_available_models
    
    # If no models were found, use a fallback
    if [ ${#models[@]} -eq 0 ]; then
        echo -e "${YELLOW}No valid models detected, using fallback...${NC}"
        models=("mistral:7b-instruct")
    fi
    
    # Benchmark each model
    for model in "${models[@]}"; do
        echo -e "\n${BOLD}${GREEN}Starting benchmark for: $model${NC}"
        
        # Verify model is available
        if ! curl -s "${OLLAMA_API}/api/tags" | jq -r '.models[].name' | grep -q "^$model\$"; then
            echo -e "${YELLOW}Model $model not found, pulling it now...${NC}"
            ollama pull "$model"
        fi
        
        # Run benchmarks for this model
        benchmark_single_model "$model"
        
        echo "Completed benchmarks for $model"
        
        # If in sequential mode, unload the model to free resources before the next model
        if [ "$SEQUENTIAL_MODE" = true ] && [ "$model" != "${models[-1]}" ]; then
            echo -e "${BLUE}Sequential mode: Unloading model $model to free resources...${NC}"
            ollama rm "$model" >/dev/null 2>&1 || true
            sleep 2  # Give system time to free resources
        fi
    done
    
    # Process and display summary
    display_results "$RESULT_FILE" "$REPORTS_DIR"
}

# Function to display results in a readable format
display_results() {
    local result_file=$1
    local reports_dir=$2
    
    echo -e "\n${BOLD}${GREEN}BENCHMARK RESULTS SUMMARY${NC}"
    echo "============================================================"
    
    # Calculate averages for each model with enhanced metrics
    echo -e "${BOLD}Models Performance Analysis (with Metal):${NC}"
    
    # Use awk to calculate averages from the CSV with enhanced metrics
    awk -F, 'NR>1 {
        sum_memory[$1] += $5; 
        sum_peak_cpu[$1] += $7;
        sum_avg_cpu[$1] += $8;
        sum_tokens[$1] += $11; 
        sum_tokens_per_mb[$1] += $12;
        sum_throughput[$1] += $13;
        sum_time[$1] += $15; 
        count[$1]++
    } 
    END {
        print "Model,Avg Memory (MB),Avg Peak CPU (%),Avg CPU (%),Avg Tokens/sec,Avg Tokens/MB,Avg Throughput Score,Metal Acceleration,Avg Time (s)";
        for (model in count) {
            printf "%s,%.1f,%.2f,%.2f,%.2f,%.2f,%.2f,%s,%.2f\n", 
                model, 
                sum_memory[model]/count[model],
                sum_peak_cpu[model]/count[model],
                sum_avg_cpu[model]/count[model],
                sum_tokens[model]/count[model],
                sum_tokens_per_mb[model]/count[model],
                sum_throughput[model]/count[model],
                "Enabled",
                sum_time[model]/count[model]
        }
    }' "$result_file" > "${reports_dir}/summary.csv"
    
    # Sort by memory usage (highest to lowest)
    echo -e "\n${BOLD}By Memory Usage (Highest to Lowest):${NC}"
    sort -t, -k2 -nr "${reports_dir}/summary.csv" | column -t -s, | head -n 1
    echo "--------------------------------------------------------------"
    sort -t, -k2 -nr "${reports_dir}/summary.csv" | tail -n +2 | column -t -s,
    
    # Sort by tokens per second (highest to lowest)
    echo -e "\n${BOLD}By Inference Speed (Fastest to Slowest):${NC}"
    sort -t, -k5 -nr "${reports_dir}/summary.csv" | column -t -s, | head -n 1
    echo "--------------------------------------------------------------"
    sort -t, -k5 -nr "${reports_dir}/summary.csv" | tail -n +2 | column -t -s,
    
    # Sort by efficiency (throughput score - highest to lowest)
    echo -e "\n${BOLD}By Hardware Efficiency (Best to Worst):${NC}"
    sort -t, -k7 -nr "${reports_dir}/summary.csv" | column -t -s, | head -n 1
    echo "--------------------------------------------------------------"
    sort -t, -k7 -nr "${reports_dir}/summary.csv" | tail -n +2 | column -t -s,
    
    # Create performance summary text file
    echo -e "${BOLD}${GREEN}PERFORMANCE METRICS EXPLAINED${NC}" > "${reports_dir}/performance_metrics.txt"
    echo "============================================================" >> "${reports_dir}/performance_metrics.txt"
    echo "- Tokens/second: Raw generation speed (higher is better)" >> "${reports_dir}/performance_metrics.txt"
    echo "- Memory Usage: RAM required during inference (lower is better for resource constraints)" >> "${reports_dir}/performance_metrics.txt"
    echo "- CPU Usage: Processor utilization during inference (lower is better for multi-tasking)" >> "${reports_dir}/performance_metrics.txt"
    echo "- Tokens/MB: Memory efficiency - tokens generated per MB of RAM (higher is better)" >> "${reports_dir}/performance_metrics.txt"
    echo "- Throughput Score: Overall efficiency metric - tokens/sec per CPU% (higher is better)" >> "${reports_dir}/performance_metrics.txt"
    echo "- Metal Acceleration: Whether Apple Silicon GPU acceleration was enabled" >> "${reports_dir}/performance_metrics.txt"
    echo "" >> "${reports_dir}/performance_metrics.txt"
    echo "HARDWARE UTILIZATION FACTORS" >> "${reports_dir}/performance_metrics.txt"
    echo "============================================================" >> "${reports_dir}/performance_metrics.txt"
    echo "- Peak CPU %: Maximum CPU utilization during inference" >> "${reports_dir}/performance_metrics.txt"
    echo "- Average CPU %: Sustained processor load during generation" >> "${reports_dir}/performance_metrics.txt"
    echo "- Memory Footprint: Additional RAM required beyond baseline" >> "${reports_dir}/performance_metrics.txt"
    echo "- Metal GPU: Apple Silicon GPU with Metal API acceleration" >> "${reports_dir}/performance_metrics.txt"
    cat "${reports_dir}/hardware_info.txt" >> "${reports_dir}/performance_metrics.txt"
    
    echo -e "\n${BLUE}Detailed results saved to: $result_file${NC}"
    echo -e "${BLUE}Summary results saved to: ${reports_dir}/summary.csv${NC}"
    echo -e "${BLUE}Performance metrics explanation saved to: ${reports_dir}/performance_metrics.txt${NC}"
    
    # Generate visualization prompt using the standalone script
    echo -e "\n${YELLOW}To visualize these results:${NC}"
    echo "Run the visualization script to generate charts:"
    echo "python ./visualize_benchmarks.py --summary-path '${reports_dir}/summary.csv' --output-dir '${reports_dir}'"
    echo ""
    echo "Available visualization options:"
    echo "  --overview     Generate 2x2 overview chart (default)"
    echo "  --memory       Generate memory usage chart with efficiency annotations"
    echo "  --performance  Generate performance comparison chart"
    echo "  --efficiency   Generate efficiency score chart"
    echo "  --all          Generate all visualization types"
    echo "  --format {png,pdf,svg}  Output file format (default: png)"
    echo ""
    echo "Example: python ./visualize_benchmarks.py --all"
}

# Check for required tools
check_requirements() {
    for cmd in curl jq bc awk column; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: Required tool '$cmd' is not installed"
            exit 1
        fi
    done
    
    # Check for ollama
    if ! command -v ollama &> /dev/null; then
        echo "Error: Ollama is not installed"
        echo "Please install with: brew install ollama"
        exit 1
    fi
}

# Main execution
echo -e "${BOLD}${GREEN}LLM Model Benchmarking Tool with Metal Acceleration${NC}"
echo -e "${BLUE}Optimized for Apple Silicon GPUs${NC}"
echo "============================================================"

check_requirements
run_benchmarks

echo -e "\n${GREEN}All benchmarks completed!${NC}"