#!/bin/bash
# Debug wrapper for benchmark-models.sh
# Runs the benchmark with DEBUG mode enabled

# Colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running benchmark in DEBUG mode${NC}"
echo -e "${YELLOW}This will show detailed API responses for troubleshooting${NC}"
echo "============================================================"

# Path to the benchmark script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_SCRIPT="$SCRIPT_DIR/benchmark-models.sh"

# Create a temporary modified version with DEBUG=true
TMP_SCRIPT="/tmp/benchmark-debug-$$.sh"
cat "$BENCHMARK_SCRIPT" | sed 's/DEBUG=false/DEBUG=true/' > "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

echo -e "${GREEN}Starting benchmark with debugging enabled...${NC}"
# Ensure benchmark-reports directory exists

# Reports directory
REPORTS_DIR="$BENCHMARK_DIR/benchmark-reports"
mkdir -p "$REPORTS_DIR"
echo "Output will be logged to $REPORTS_DIR/benchmark-debug.log"

# Run the modified script and capture output
"$TMP_SCRIPT" | tee "$REPORTS_DIR/benchmark-debug.log"

# Clean up
rm "$TMP_SCRIPT"

echo -e "${GREEN}Debug run complete!${NC}"
echo "Check $REPORTS_DIR/benchmark-debug.log for the full output including API responses"