#!/bin/bash
# LLM Model Memory Report
# Displays models ranked by memory utilization and efficiency

# Styles for output
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Benchmark directory
BENCHMARK_DIR="$(dirname "$0")"

# Reports directory
REPORTS_DIR="$BENCHMARK_DIR/benchmark-reports"

echo -e "${BOLD}${GREEN}LLM Models Memory Utilization Report${NC}"
echo "============================================================"

# Ensure reports directory exists
mkdir -p "$REPORTS_DIR"

# Check if summary.csv exists
if [ ! -f "${REPORTS_DIR}/summary.csv" ]; then
    echo -e "${RED}Error: ${REPORTS_DIR}/summary.csv not found. Please run benchmark tests first.${NC}"
    exit 1
fi

# Extract and display memory metrics
echo -e "${BOLD}Model Name                      | Parameters | Memory (MB) | Memory Efficiency${NC}"
echo "------------------------------------------------------------"

# Process summary.csv to get memory metrics
while IFS=, read -r model memory cpu_peak cpu_avg tokens tokens_per_mb throughput time; do
    # Skip header
    if [[ "$model" == "Model" ]]; then
        continue
    fi
    
    # Extract parameter size from model name if possible
    param_size="Unknown"
    if [[ "$model" == *"70b"* ]]; then
        param_size="70B"
    elif [[ "$model" == *"72b"* ]]; then
        param_size="72B"
    elif [[ "$model" == *"8x7b"* ]]; then
        param_size="8x7B"
    elif [[ "$model" == *"7b"* ]]; then
        param_size="7B"
    fi
    
    # Calculate memory efficiency rating (tokens per MB)
    if [[ "$tokens_per_mb" == "N/A" ]]; then
        efficiency="N/A"
    elif (( $(echo "$tokens_per_mb > 1.0" | bc -l) )); then
        efficiency="${GREEN}Excellent${NC}"
    elif (( $(echo "$tokens_per_mb > 0.5" | bc -l) )); then
        efficiency="${BLUE}Good${NC}"
    elif (( $(echo "$tokens_per_mb > 0.2" | bc -l) )); then
        efficiency="${YELLOW}Average${NC}"
    else
        efficiency="${RED}Poor${NC}"
    fi
    
    # Format model name with padding
    printf "%-30s | %-10s | %-10s | %s\n" "$model" "$param_size" "$memory" "$efficiency"
done < "${REPORTS_DIR}/summary.csv"

echo "------------------------------------------------------------"

# Read hardware info if available
if [ -f "${REPORTS_DIR}/hardware_info.txt" ]; then
    echo -e "\n${BOLD}${BLUE}System Memory Context${NC}"
    echo "============================================================"
    grep "Total System Memory" "${REPORTS_DIR}/hardware_info.txt"
    grep "GPU" "${REPORTS_DIR}/hardware_info.txt"
fi

# Calculate memory utilization percentages if possible
if [ -f "${REPORTS_DIR}/hardware_info.txt" ] && [ -f "${REPORTS_DIR}/summary.csv" ]; then
    # Extract total system memory
    total_mem=$(grep "Total System Memory" "${REPORTS_DIR}/hardware_info.txt" | sed 's/[^0-9]//g')
    
    if [[ ! -z "$total_mem" ]]; then
        echo -e "\n${BOLD}Memory Utilization Percentages${NC}"
        echo "------------------------------------------------------------"
        echo -e "${BOLD}Model                         | % of System Memory${NC}"
        
        # Skip header
        tail -n +2 "${REPORTS_DIR}/summary.csv" | while IFS=, read -r model memory rest; do
            percent=$(echo "scale=1; ($memory / $total_mem) * 100" | bc)
            
            # Color code the percentage
            if (( $(echo "$percent > 75" | bc -l) )); then
                color="${RED}"
            elif (( $(echo "$percent > 50" | bc -l) )); then
                color="${YELLOW}"
            elif (( $(echo "$percent > 25" | bc -l) )); then
                color="${BLUE}"
            else
                color="${GREEN}"
            fi
            
            printf "%-30s | ${color}%5.1f%%${NC}\n" "$model" "$percent"
        done
    fi
fi

echo -e "\n${BOLD}${YELLOW}Memory Usage Analysis${NC}"
echo "============================================================"
echo "- Memory footprint is primarily determined by model size (parameters)"
echo "- Quantized models (q4, q5, q6) use less memory than full precision (fp16)"
echo "- Memory efficiency (tokens/MB) measures how well a model uses its memory"
echo "- Models with mixture-of-experts architecture may have higher memory needs"
echo "- Memory usage increases with context length and batch size"

# Create a detailed memory analysis report
echo -e "\n${BOLD}Creating detailed memory analysis...${NC}"

cat > "${REPORTS_DIR}/memory_analysis.txt" << EOF
# LLM MODEL MEMORY ANALYSIS

## Memory Metrics Explained

1. **Base Memory**: Minimum memory required to load the model
2. **Peak Memory**: Maximum memory used during inference
3. **Memory Delta**: Additional memory required for inference (Peak - Base)
4. **Tokens per MB**: Efficiency metric showing tokens generated per MB of memory
5. **System Memory %**: Percentage of total system memory used by the model

## Memory Optimization Techniques

1. **Quantization**: Reducing precision (fp16 → q8 → q6 → q5 → q4)
   - Each step down saves memory but may impact quality
   - Example: fp16 → q4 can reduce memory by 75%

2. **Model Pruning**: Removing unnecessary weights
   - Can reduce size by 20-30% with minimal quality impact

3. **Efficient Architectures**:
   - Mixture of Experts: Activates only relevant parts of model
   - Attention optimizations: Reduce memory needs for long contexts

4. **Hardware Considerations**:
   - CPU vs GPU memory characteristics
   - Dedicated vs shared memory systems
   - Memory bandwidth vs capacity tradeoffs

## Recommendations for Memory-Constrained Environments

1. Use smaller parameter models when possible (7B vs 70B)
2. Choose higher quantization levels (q4_K_M)
3. Limit context length for inference
4. Consider models specifically optimized for efficiency
EOF

echo -e "${BLUE}Memory analysis report saved to: ${REPORTS_DIR}/memory_analysis.txt${NC}"

# Generate a visualization suggestion using the standalone script
echo -e "\n${YELLOW}To visualize memory metrics:${NC}"
echo "Run the visualization script to generate memory charts:"
echo "python ./visualize_benchmarks.py --memory --summary-path '${REPORTS_DIR}/summary.csv' --output-dir '${REPORTS_DIR}'"
echo ""
echo "For all visualization options, run:"
echo "python ./visualize_benchmarks.py --help"