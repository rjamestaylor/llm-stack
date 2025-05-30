#!/bin/bash
# Debug wrapper for benchmark-models.sh
# Runs the benchmark with DEBUG mode enabled

# Get the llm-bench directory and load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running benchmark in DEBUG mode${NC}"
echo -e "${YELLOW}This will show detailed API responses for troubleshooting${NC}"
echo "============================================================"

# Path to the benchmark script
BENCHMARK_SCRIPT="$SCRIPT_DIR/benchmark-models.sh"

# Create a temporary modified version with DEBUG=true
TMP_SCRIPT="/tmp/benchmark-debug-$$.sh"
cat "$BENCHMARK_SCRIPT" | sed 's/DEBUG=false/DEBUG=true/' > "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

echo -e "${GREEN}Starting benchmark with debugging enabled...${NC}"
echo "The benchmark script will create a timestamped session directory for all output"

# Run the modified script with any passed arguments
"$TMP_SCRIPT" "$@"

# Clean up
rm "$TMP_SCRIPT"

echo -e "${GREEN}Debug run complete!${NC}"
echo "Check the timestamped session directory in benchmark-reports/ for the full output"
echo "To see available sessions, run: python $SCRIPT_DIR/visualize_benchmarks.py --list-sessions"