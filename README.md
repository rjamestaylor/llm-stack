# LLM Stack with Ollama and Open WebUI

Local LLM setup using Ollama and Open WebUI, optimized for MacStudio Pro M2 Ultra.

## Setup Instructions

1. Install Colima: `brew install colima docker docker-compose`
2. Start optimized Colima instance: `colima start llm-runner --arch aarch64 --cpu 20 --memory 96 --disk 200 --vm-type vz`
3. Launch stack: `cd docker && docker compose up -d`
4. Optimize Ollama: `./scripts/optimize-ollama.sh`
5. Access WebUI at: http://localhost:3000

## Recommended Models

- Llama 3 70B: `docker exec -it ollama ollama pull llama3:70b-instruct-fp16`
- Mixtral 8x7B: `docker exec -it ollama ollama pull mixtral:8x7b-instruct-v0.1-fp16`
- Qwen2 72B: `docker exec -it ollama ollama pull qwen2:72b-instruct`
