#!/bin/bash
# =============================================================================
# Script 08: Pull DeepSeek Model
# =============================================================================
# Purpose: Downloads DeepSeek model into Ollama container
# Dependencies: Ollama container running
# Output: DeepSeek model (~4GB) stored in Docker volume
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Downloading DeepSeek Model"

MODEL_SIZE="~4GB"

# Check if Ollama container is running
if ! sudo docker ps | grep -q ollama; then
    die 1 "Ollama container is not running" \
           "Start it with: cd $DOCKER_DIR && docker compose up -d ollama"
fi

print_step "Checking if model already exists..."

# Check if model is already pulled
MODEL_EXISTS=$(sudo docker exec ollama ollama list | grep -c "$MODEL_NAME" || echo "0")

if [ "$MODEL_EXISTS" -gt 0 ]; then
    print_warning "Model $MODEL_NAME already exists"
    read -p "Redownload? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing model"
        exit 0
    fi
fi

echo ""
echo "Downloading $MODEL_NAME ($MODEL_SIZE)"
echo "This may take 5-15 minutes depending on your internet speed..."
echo ""

print_step "Pulling model from Ollama registry..."

# Pull the model
sudo docker exec ollama ollama pull $MODEL_NAME

if [ $? -ne 0 ]; then
    die 1 "Failed to download model" \
           "Check:"
           "  1. Internet connection"
           "  2. Docker container is running: sudo docker ps | grep ollama"
           "  3. Try manual pull: sudo docker exec ollama ollama pull $MODEL_NAME"
fi

# Verify model is available
print_step "Verifying model..."
sudo docker exec ollama ollama list | grep "$MODEL_NAME" > /dev/null

if [ $? -eq 0 ]; then
    echo "  ✓ Model $MODEL_NAME successfully downloaded"
else
    die 1 "Model verification failed" "Model not found in Ollama list"
fi

# Test model with a simple prompt
print_step "Testing model with a simple prompt..."
TEST_OUTPUT=$(sudo docker exec ollama ollama run $MODEL_NAME "Say 'OK' in one word" 2>/dev/null | head -1)

if [ -n "$TEST_OUTPUT" ]; then
    echo "  ✓ Model responds: $TEST_OUTPUT"
else
    print_warning "Model test failed - may need more time to initialize"
fi

echo ""
print_step "DeepSeek model ready for use"
echo ""
echo "Model details:"
echo "  Name: $MODEL_NAME"
echo "  Size: $MODEL_SIZE"
echo "  Location: Docker volume 'ollama-data'"
