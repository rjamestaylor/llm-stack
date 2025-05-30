#!/bin/bash
# LLM Model Performance Report
# Displays models ranked by processing speed and efficiency metrics

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

echo -e "${BOLD}${GREEN}LLM Models Performance Analysis${NC}"
echo "============================================================"

# Ensure reports directory exists
mkdir -p "$REPORTS_DIR"

# Check if summary.csv exists
if [ ! -f "${REPORTS_DIR}/summary.csv" ]; then
    echo -e "${RED}Error: ${REPORTS_DIR}/summary.csv not found. Please run benchmark tests first.${NC}"
    exit 1
fi

# Extract and display performance metrics
echo -e "${BOLD}Model Name                      | Tokens/Second | CPU % | Throughput Score${NC}"
echo "------------------------------------------------------------"

# Process summary.csv to get performance metrics
while IFS=, read -r model memory cpu_peak cpu_avg tokens_per_sec tokens_per_mb throughput time; do
    # Skip header
    if [[ "$model" == "Model" ]]; then
        continue
    fi
    
    # Format model name with padding and handle null values
    if [[ "$tokens_per_sec" == "N/A" ]]; then
        tokens_per_sec="N/A      "
    else
        tokens_per_sec=$(printf "%.2f" $tokens_per_sec)
    fi
    
    if [[ "$cpu_avg" == "N/A" ]]; then
        cpu_avg="N/A   "
    else
        cpu_avg=$(printf "%.1f" $cpu_avg)
    fi
    
    if [[ "$throughput" == "N/A" ]]; then
        throughput="N/A      "
    else
        throughput=$(printf "%.2f" $throughput)
    fi
    
    printf "%-30s | %-12s | %-5s | %-15s\n" "$model" "$tokens_per_sec" "$cpu_avg" "$throughput"
done < "${REPORTS_DIR}/summary.csv"

echo "------------------------------------------------------------"

# Find the fastest model
fastest_model=$(tail -n +2 "${REPORTS_DIR}/summary.csv" | sort -t, -k5 -nr | head -n1)
if [[ ! -z "$fastest_model" ]]; then
    fastest_name=$(echo "$fastest_model" | cut -d, -f1)
    fastest_speed=$(echo "$fastest_model" | cut -d, -f5)
    echo -e "\n${BOLD}Fastest Model:${NC} $fastest_name ($fastest_speed tokens/sec)"
fi

# Find the most efficient model
efficient_model=$(tail -n +2 "${REPORTS_DIR}/summary.csv" | sort -t, -k7 -nr | head -n1)
if [[ ! -z "$efficient_model" ]]; then
    efficient_name=$(echo "$efficient_model" | cut -d, -f1)
    efficient_score=$(echo "$efficient_model" | cut -d, -f7)
    echo -e "${BOLD}Most Efficient Model:${NC} $efficient_name (throughput score: $efficient_score)"
fi

# Read hardware info if available
if [ -f "${REPORTS_DIR}/hardware_info.txt" ]; then
    echo -e "\n${BOLD}${BLUE}Hardware Context${NC}"
    echo "============================================================"
    grep "CPU" "${REPORTS_DIR}/hardware_info.txt"
    grep "GPU" "${REPORTS_DIR}/hardware_info.txt"
fi

echo -e "\n${BOLD}${YELLOW}Performance Metrics Explained${NC}"
echo "============================================================"
echo "- Tokens/Second: Raw generation speed (higher is better)"
echo "- CPU %: Average processor utilization during inference"
echo "- Throughput Score: Efficiency metric - tokens/sec per CPU% (higher is better)"

# Performance analysis based on model architecture
echo -e "\n${BOLD}Model Architecture Performance Analysis${NC}"
echo "------------------------------------------------------------"
echo "- Larger models (70B+) typically have higher throughput but require more resources"
echo "- Mixture-of-experts models (like Mixtral) often show better efficiency scores"
echo "- Quantized models may have slightly lower tokens/sec but better efficiency"
echo "- Instruction-tuned models (-instruct) prioritize quality over raw speed"

# Create a detailed performance analysis report
echo -e "\n${BOLD}Creating detailed performance analysis...${NC}"

cat > "${REPORTS_DIR}/performance_analysis.txt" << EOF
# LLM MODEL PERFORMANCE ANALYSIS

## Performance Metrics Explained

1. **Tokens per Second**: Raw text generation speed
   - Higher values indicate faster text generation
   - Directly impacts user-perceived response time
   - Varies by prompt complexity and model architecture

2. **CPU Utilization**: Processor resources consumed during inference
   - Lower values allow for better multitasking
   - High values indicate computation-intensive operations
   - Measured as percentage of available CPU resources

3. **Throughput Score**: Efficiency metric (tokens/sec ÷ CPU%)
   - Higher values indicate better performance per unit of compute
   - Useful for comparing models across different hardware
   - Key metric for cost-effective deployment

## Performance Optimization Strategies

1. **Quantization Tradeoffs**:
   - Each quantization level balances speed vs quality
   - fp16 → q8 → q6 → q5 → q4 progression shows increasing speed
   - Lower precision (q4) may show artifacts in complex reasoning

2. **Batching Requests**:
   - Processing multiple prompts simultaneously increases throughput
   - Increases memory requirements but improves overall efficiency
   - Optimal for high-volume applications

3. **Context Length Management**:
   - Shorter contexts process faster than longer ones
   - Consider splitting very long contexts when possible
   - Look for models with optimized attention mechanisms for long contexts

4. **Hardware Acceleration**:
   - GPU acceleration can provide 5-10x performance boost
   - Tensor processing units (TPUs) offer specialized acceleration
   - Model-specific optimizations can leverage specific hardware features

## Recommendations for Performance-Critical Applications

1. Choose models with higher throughput scores for cost-efficiency
2. Consider smaller parameter models for latency-sensitive applications
3. Use quantized models when generation speed is the primary concern
4. Evaluate hardware acceleration options for deployment
EOF

echo -e "${BLUE}Performance analysis report saved to: ${REPORTS_DIR}/performance_analysis.txt${NC}"

# Generate a visualization suggestion using the standalone script
echo -e "\n${YELLOW}To visualize performance metrics:${NC}"
echo "Run the visualization script to generate performance charts:"
echo "python ./visualize_benchmarks.py --performance --efficiency --summary-path '${REPORTS_DIR}/summary.csv' --output-dir '${REPORTS_DIR}'"
echo ""
echo "For all visualization options, run:"
echo "python ./visualize_benchmarks.py --help"