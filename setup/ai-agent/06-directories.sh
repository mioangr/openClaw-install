#!/bin/bash
# =============================================================================
# Script 06: Create Directory Structure
# =============================================================================
# Purpose: Creates all necessary directories for the AI agent
# Dependencies: User 'aiuser' exists
# Output: Complete folder structure under /home/aiuser/
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Creating Directory Structure"

AI_USER="aiuser"
AI_HOME="/home/$AI_USER"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# List of directories to create
DIRECTORIES=(
    "$AI_HOME/docker"
    "$AI_HOME/agent"
    "$AI_HOME/scripts"
    "$AI_HOME/config-repos"
    "$AI_HOME/logs"
    "$AI_HOME/workspace"
)

# Create directories
for dir in "${DIRECTORIES[@]}"; do
    print_step "Creating $dir"
    sudo mkdir -p "$dir"
    sudo chown $AI_USER:$AI_USER "$dir"
    sudo chmod 755 "$dir"
done

# Copy files from project to AI user's home
print_step "Copying project files to $AI_HOME..."

# Copy docker files
if [ -d "$PROJECT_ROOT/docker" ]; then
    sudo cp -r "$PROJECT_ROOT/docker/"* "$AI_HOME/docker/"
    sudo chown -R $AI_USER:$AI_USER "$AI_HOME/docker"
    echo "  ✓ Copied docker files"
fi

# Copy agent files
if [ -d "$PROJECT_ROOT/agent" ]; then
    sudo cp -r "$PROJECT_ROOT/agent/"* "$AI_HOME/agent/"
    sudo chown -R $AI_USER:$AI_USER "$AI_HOME/agent"
    echo "  ✓ Copied agent files"
fi

# Copy scripts
if [ -d "$PROJECT_ROOT/scripts" ]; then
    sudo cp -r "$PROJECT_ROOT/scripts/"* "$AI_HOME/scripts/"
    sudo chmod +x "$AI_HOME/scripts/"*.py 2>/dev/null || true
    sudo chown -R $AI_USER:$AI_USER "$AI_HOME/scripts"
    echo "  ✓ Copied utility scripts"
fi

# Copy config-repos template
if [ -d "$PROJECT_ROOT/config-repos" ]; then
    sudo cp -r "$PROJECT_ROOT/config-repos/"* "$AI_HOME/config-repos/"
    sudo chown -R $AI_USER:$AI_USER "$AI_HOME/config-repos"
    echo "  ✓ Copied repository configuration"
fi

# Create initial repos.json if not exists
if [ ! -f "$AI_HOME/config-repos/repos.json" ]; then
    sudo tee "$AI_HOME/config-repos/repos.json" > /dev/null << 'EOF'
{
  "repos": [
    {
      "name": "example-project",
      "url": "https://github.com/YOUR_USERNAME/YOUR_REPO",
      "branch": "main",
      "description": "Example repository - replace with your own"
    }
  ]
}
EOF
    sudo chown $AI_USER:$AI_USER "$AI_HOME/config-repos/repos.json"
    echo "  ✓ Created example repos.json"
fi

echo ""
print_step "Directory structure created successfully"
echo ""
echo "Directory layout:"
echo "  $AI_HOME/"
echo "  ├── docker/          - Docker compose and container files"
echo "  ├── agent/           - AI agent Python code"
echo "  ├── scripts/         - Utility scripts (send_task, etc.)"
echo "  ├── config-repos/    - Repository configurations"
echo "  ├── logs/            - Runtime logs"
echo "  ├── workspace/       - Temporary clones of repositories"
echo "  └── .env             - Secrets (created earlier)"