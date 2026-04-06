#!/bin/bash
# =============================================================================
# Script 07: Setup Docker Compose
# =============================================================================
# Purpose: Builds and starts Docker containers for Ollama, Agent, and Redis
# Dependencies: Docker installed, .env file exists
# Output: Running containers: ollama, langgraph-agent, redis
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Setting Up Docker Containers"

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    die 1 "docker-compose.yml not found at $COMPOSE_FILE" \
           "Make sure the docker folder was copied correctly in script 06"
fi

# Switch to ai user context for Docker operations
print_step "Building Docker images (this may take a few minutes)..."

# Run docker commands as aiuser
sudo -u $AI_USER bash << EOF
    cd $DOCKER_DIR
    docker compose build
    if [ \$? -ne 0 ]; then
        echo "Docker build failed"
        exit 1
    fi
EOF

check_error "Docker build failed"

print_step "Starting containers..."
sudo -u $AI_USER bash << EOF
    cd $DOCKER_DIR
    docker compose up -d
    if [ \$? -ne 0 ]; then
        echo "Docker compose up failed"
        exit 1
    fi
EOF

check_error "Failed to start containers"

# Wait for containers to be ready
print_step "Waiting for containers to be ready..."
sleep 5

# Check container status
print_step "Verifying container status..."

CONTAINERS=("ollama" "langgraph-agent" "redis")
for container in "${CONTAINERS[@]}"; do
    if sudo docker ps --format 'table {{.Names}}' | grep -q "^$container$"; then
        STATUS=$(sudo docker ps --filter "name=$container" --format "{{.Status}}")
        echo "  ✓ $container - $STATUS"
    else
        print_warning "$container container is not running"
        echo "  Check logs: sudo docker logs $container"
    fi
done

echo ""
print_step "Docker containers started successfully"
echo ""
echo "Useful commands:"
echo "  cd $DOCKER_DIR && docker compose logs -f"
echo "  cd $DOCKER_DIR && docker compose ps"
echo "  cd $DOCKER_DIR && docker compose down"
