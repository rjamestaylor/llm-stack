# LLM Model Benchmarking with Native Ollama

This directory contains scripts for benchmarking the performance of Large Language Models (LLMs) using native Ollama with Metal acceleration on Apple Silicon.

## Benchmarking with Metal Acceleration

All benchmarking scripts now use native Ollama (not Docker-based) to leverage the full capabilities of Apple Silicon:

- Metal GPU acceleration for significantly faster inference
- Optimized memory usage for Apple hardware
- Direct access to Apple Silicon's Neural Engine
- Enhanced performance metrics specific to Metal acceleration

## Available Benchmarking Scripts

### 1. `benchmark-models.sh`

The main benchmarking script that tests all available models with Metal acceleration. This script:
- Fetches all available models from the native Ollama API
- Runs performance tests on each model using standardized prompts
- Measures memory usage, inference speed, and token generation metrics
- Provides Metal-specific acceleration metrics

### 2. `benchmark-models-sequential.sh`

A resource-optimized benchmarking script that tests one model at a time with enhanced hardware metrics. This script:
- Identifies all available models from the Ollama API
- Loads only one model at a time, preserving system resources
- Collects detailed hardware utilization metrics (CPU, memory, GPU)
- Measures efficiency scores relating performance to resource usage
- Analyzes Metal acceleration benefits per model

### Analysis Scripts

#### 3. `model-performance-report.sh`

A specialized script focused on performance analysis that:
- Analyzes benchmark results to rank models by processing speed
- Calculates throughput scores and efficiency metrics
- Provides detailed performance optimization recommendations
- Identifies which models benefit most from Metal acceleration

#### 4. `model-memory-report.sh`

A specialized script focused on memory utilization analysis that:
- Analyzes benchmark results to rank models by memory efficiency
- Calculates memory utilization as percentage of system resources
- Provides memory optimization recommendations
- Identifies optimal memory/performance trade-offs for Metal acceleration

## Running Benchmarks

To run benchmarks with native Ollama and Metal acceleration:

1. **Install Ollama natively:**
   ```bash
   brew install ollama
   ```

2. **Start the stack:**
   ```bash
   ./scripts/start-stack.sh
   ```
   This starts native Ollama with Metal acceleration and Docker-based Open WebUI.

3. **Pull models for native Ollama:**
   ```bash
   ./scripts/pull-models.sh
   ```

4. **Run benchmarks with Metal acceleration:**
   ```bash
   ./benchmarking/benchmark-models.sh
   ```

5. **For sequential testing of models:**
   ```bash
   ./benchmarking/benchmark-models-sequential.sh
   ```

6. **Stop the stack when finished:**
   ```bash
   ./scripts/stop-stack.sh
   ```

## Metrics Collected

### Performance Metrics
- Token generation speed (tokens per second)
- Execution time for standardized prompts
- Token counts (prompt tokens and generated tokens)
- Throughput score (tokens/sec per CPU%)
- Tokens per MB (memory efficiency)
- Metal acceleration efficiency

### Hardware Utilization Metrics
- Memory usage (baseline, peak, and used)
- CPU usage (baseline, peak, and average)
- System memory utilization percentage
- Metal acceleration status and performance
- Hardware efficiency ratings

### Analysis Reports
- Performance optimization recommendations
- Memory efficiency analysis
- Hardware utilization insights
- Metal acceleration benefits
- Deployment recommendations for different environments

## Visualizing Results

After running benchmarks, you can generate visualizations with the provided Python scripts:

```bash
python -c "
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Read the data
data = pd.read_csv('native_summary.csv')

# Set up the figure with subplots
fig, axs = plt.subplots(2, 2, figsize=(15, 10))

# Plot memory usage
sns.barplot(x='Model', y='Avg Memory (MB)', data=data, ax=axs[0,0], palette='Blues_d')
axs[0,0].set_title('Memory Usage by Model (Native with Metal)')
axs[0,0].set_xticklabels(axs[0,0].get_xticklabels(), rotation=45, ha='right')

# Plot tokens per second
sns.barplot(x='Model', y='Avg Tokens/sec', data=data, ax=axs[0,1], palette='Greens_d')
axs[0,1].set_title('Token Generation Speed by Model (Native with Metal)')
axs[0,1].set_xticklabels(axs[0,1].get_xticklabels(), rotation=45, ha='right')

# Plot CPU usage
sns.barplot(x='Model', y='Avg Peak CPU (%)', data=data, ax=axs[1,0], palette='Reds_d')
axs[1,0].set_title('Peak CPU Usage by Model (Native with Metal)')
axs[1,0].set_xticklabels(axs[1,0].get_xticklabels(), rotation=45, ha='right')

# Plot efficiency score
sns.barplot(x='Model', y='Avg Throughput Score', data=data, ax=axs[1,1], palette='Purples_d')
axs[1,1].set_title('Efficiency Score by Model (Native with Metal)')
axs[1,1].set_xticklabels(axs[1,1].get_xticklabels(), rotation=45, ha='right')

plt.tight_layout()
plt.savefig('native_model_performance_comparison.png')
plt.close()

print('Visualization saved as native_model_performance_comparison.png')
"
```