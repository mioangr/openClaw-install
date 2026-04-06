
#### `setup.sh` (Umbrella Setup Script)

```bash
#!/bin/bash
# =============================================================================
# Umbrella Setup Script for Local AI Agent
# =============================================================================
# Purpose: Orchestrates the complete setup of the AI agent environment
# Usage:   ./setup.sh
# 
# This script runs all necessary setup steps in order. If any step fails,
# it stops and provides guidance on how to fix the issue.
# =============================================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/setup/ai-agent"

# Source common functions
source "$SETUP_DIR/common.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header "Local AI Agent Setup"
echo "This script will install and configure your AI agent environment."
echo "Estimated time: 10-15 minutes (depends on download speeds)"
echo ""
echo "The following will be installed:"
echo "  ✓ System dependencies (git, curl, etc.)"
echo "  ✓ Docker and Docker Compose"
echo "  ✓ Python 3.11 and required packages"
echo "  ✓ Dedicated 'aiuser' for running the agent"
echo "  ✓ DeepSeek LLM model (~4GB download)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: System dependencies
print_step "Step 1/8: Installing system dependencies"
bash "$SETUP_DIR/01-system-deps.sh"
check_error "System dependencies installation failed"

# Step 2: Docker
print_step "Step 2/8: Installing Docker"
bash "$SETUP_DIR/02-docker.sh"
check_error "Docker installation failed"

# Step 3: Python dependencies
print_step "Step 3/8: Installing Python and packages"
bash "$SETUP_DIR/03-python-deps.sh"
check_error "Python setup failed"

# Step 4: Create AI user
print_step "Step 4/8: Creating dedicated AI user"
bash "$SETUP_DIR/04-create-user.sh"
check_error "User creation failed"

# Step 5: Configure secrets
print_step "Step 5/8: Configuring secrets"
bash "$SETUP_DIR/05-secrets.sh"
check_error "Secrets configuration failed"

# Step 6: Create directory structure
print_step "Step 6/8: Creating directory structure"
bash "$SETUP_DIR/06-directories.sh"
check_error "Directory creation failed"

# Step 7: Setup Docker Compose
print_step "Step 7/8: Setting up Docker containers"
bash "$SETUP_DIR/07-docker-compose.sh"
check_error "Docker Compose setup failed"

# Step 8: Pull LLM model
print_step "Step 8/8: Downloading DeepSeek model (this may take several minutes)"
bash "$SETUP_DIR/08-pull-model.sh"
check_error "Model download failed"

print_header "Setup Complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Add your repositories to config-repos/repos.json"
echo "2. Start the agent: cd /home/aiuser && docker compose up -d"
echo "3. Send a test task: ./scripts/send_task.py --project my-project --instruction 'Add README'"
echo ""
echo "For more information, see:"
echo "  - agent/README.md - How the agent works"
echo "  - scripts/README.md - Available commands"
echo "  - docker/README.md - Container management"