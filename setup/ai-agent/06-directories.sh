#!/bin/bash
# =============================================================================
# Script 06: Create Directory Structure
# =============================================================================
# Purpose: Creates all necessary directories for the AI agent
# Dependencies: User 'aiuser' exists
# Output: Complete folder structure under $INSTALL_ROOT
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Creating Directory Structure"

# List of directories to create
DIRECTORIES=(
    "$INSTALL_ROOT"
    "$DOCKER_DIR"
    "$AGENT_DIR"
    "$SCRIPTS_DIR"
    "$REPOS_DIR"
    "$LOGS_DIR"
    "$WORKSPACE_DIR"
)

# Create directories
for dir in "${DIRECTORIES[@]}"; do
    print_step "Creating $dir"
    sudo mkdir -p "$dir"
    sudo chown $AI_USER:$AI_USER "$dir"
    sudo chmod 755 "$dir"
done

# Copy files from project to AI user's home
print_step "Copying project files to $INSTALL_ROOT..."

# Copy docker files
if [ -d "$PROJECT_ROOT/setup/docker" ]; then
    sudo cp -r "$PROJECT_ROOT/setup/docker/"* "$DOCKER_DIR/"
    sudo chown -R "$AI_USER:$AI_USER" "$DOCKER_DIR"
    echo "  ✓ Copied docker files"
fi

# Copy agent files
if [ -d "$PROJECT_ROOT/agent" ]; then
    sudo cp -r "$PROJECT_ROOT/agent/"* "$AGENT_DIR/"
    sudo chown -R "$AI_USER:$AI_USER" "$AGENT_DIR"
    echo "  ✓ Copied agent files"
fi

# Copy scripts
if [ -d "$PROJECT_ROOT/scripts" ]; then
    sudo cp -r "$PROJECT_ROOT/scripts/"* "$SCRIPTS_DIR/"
    sudo chmod +x "$SCRIPTS_DIR/"*.py 2>/dev/null || true
    sudo chown -R "$AI_USER:$AI_USER" "$SCRIPTS_DIR"
    echo "  ✓ Copied utility scripts"
fi

# Copy settings/repos template
if [ -d "$PROJECT_ROOT/settings/repos" ]; then
    sudo cp -r "$PROJECT_ROOT/settings/repos/"* "$REPOS_DIR/"
    sudo chown -R "$AI_USER:$AI_USER" "$REPOS_DIR"
    echo "  ✓ Copied repository configuration"
fi

if [ -f "$PROJECT_ROOT/install.conf" ]; then
    sudo cp "$PROJECT_ROOT/install.conf" "$INSTALL_ROOT/install.conf"
    sudo chown "$AI_USER:$AI_USER" "$INSTALL_ROOT/install.conf"
    echo "  ✓ Copied shared install configuration"
fi

echo ""
print_step "Directory structure created successfully"
echo ""
echo "Directory layout:"
echo "  $INSTALL_ROOT/"
echo "  ├── docker/          - Docker compose and container files"
echo "  ├── agent/           - AI agent Python code"
echo "  ├── scripts/         - Utility scripts (send_task, etc.)"
echo "  ├── settings/repos/  - Repository configurations"
echo "  ├── logs/            - Runtime logs"
echo "  ├── workspace/       - Temporary clones of repositories"
echo "  ├── install.conf     - Shared install configuration"
echo "  └── .env             - Secrets (created earlier)"
