#!/bin/bash

# Example script to run the visualizer with various visualization options

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# If a session timestamp is provided, use it; otherwise, use the sample data
SESSION="${1:-sample}"

# Check if the provided session is "sample" or a timestamp
if [ "$SESSION" = "sample" ]; then
    SUMMARY_PATH="./benchmark-reports/sample/sample_summary.csv"
    OUTPUT_DIR="./benchmark-reports/sample"
    echo -e "${YELLOW}Using sample data${NC}"
else
    # Use the provided session timestamp
    SUMMARY_PATH="./benchmark-reports/${SESSION}/summary.csv"
    OUTPUT_DIR="./benchmark-reports/${SESSION}"
    echo -e "${GREEN}Using benchmark session: ${BOLD}$SESSION${NC}"
fi

echo -e "Summary file: $SUMMARY_PATH"
echo -e "Output directory: $OUTPUT_DIR"

# Display available options
echo -e "\n${BLUE}${BOLD}Available Visualization Options:${NC}"
echo -e "  1. Basic token performance (default)"
echo -e "  2. Overview (2x2 chart)"
echo -e "  3. Performance comparison"
echo -e "  4. Efficiency scores"
echo -e "  5. Memory usage"
echo -e "  6. All charts"
echo -e "  7. Include GPU metrics"

# Prompt for visualization type
read -p "Enter your choice (1-7, default is 1): " CHOICE

# Set visualization options based on choice
case "$CHOICE" in
    2)
        OPTS="--overview"
        echo -e "${GREEN}Generating overview chart...${NC}"
        ;;
    3)
        OPTS="--performance"
        echo -e "${GREEN}Generating performance comparison chart...${NC}"
        ;;
    4)
        OPTS="--efficiency"
        echo -e "${GREEN}Generating efficiency score chart...${NC}"
        ;;
    5)
        OPTS="--memory"
        echo -e "${GREEN}Generating memory usage chart...${NC}"
        ;;
    6)
        OPTS="--all"
        echo -e "${GREEN}Generating all charts...${NC}"
        ;;
    7)
        OPTS="--include-gpu --gpu-chart"
        echo -e "${GREEN}Generating charts with GPU metrics...${NC}"
        echo -e "${YELLOW}Note: GPU metrics must be collected during benchmark run${NC}"
        echo -e "${YELLOW}To collect GPU metrics, run benchmark with: ./benchmark-models.sh --gpu-metrics${NC}"
        ;;
    *)
        OPTS=""
        echo -e "${GREEN}Generating basic token performance chart...${NC}"
        ;;
esac

# Prompt for output format
echo -e "\n${BLUE}${BOLD}Available Output Formats:${NC}"
echo -e "  1. PNG (default)"
echo -e "  2. PDF"
echo -e "  3. SVG"

read -p "Enter format (1-3, default is 1): " FORMAT_CHOICE

# Set format based on choice
case "$FORMAT_CHOICE" in
    2)
        FORMAT="--format pdf"
        echo -e "${GREEN}Using PDF format${NC}"
        ;;
    3)
        FORMAT="--format svg"
        echo -e "${GREEN}Using SVG format${NC}"
        ;;
    *)
        FORMAT="--format png"
        echo -e "${GREEN}Using PNG format${NC}"
        ;;
esac

echo -e "\n${BLUE}Running visualization...${NC}"

# Run the visualization script with the selected options
python3 visualize_benchmarks.py \
    --summary-path "$SUMMARY_PATH" \
    --output-dir "$OUTPUT_DIR" \
    $OPTS \
    $FORMAT

echo -e "\n${GREEN}${BOLD}Visualization completed!${NC}"
echo -e "Charts saved to: $OUTPUT_DIR"
