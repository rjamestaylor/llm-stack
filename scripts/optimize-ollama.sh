#!/bin/bash
docker exec -it ollama bash -c "echo 'export OLLAMA_NUM_GPU=1' >> /etc/environment"
docker exec -it ollama bash -c "echo 'export OLLAMA_NUM_CPU=20' >> /etc/environment"
docker exec -it ollama bash -c "echo 'export OLLAMA_KEEP_LOADED=true' >> /etc/environment"
docker exec -it ollama bash -c "echo 'export OLLAMA_PRELOAD_LARGE=true' >> /etc/environment"
docker restart ollama
