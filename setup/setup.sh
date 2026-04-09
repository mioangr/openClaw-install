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
SETUP_DIR="$SCRIPT_DIR/components"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header "Local AI Agent Setup"
echo "This script will install and configure your AI agent environment."
echo "Estimated time: 10-15 minutes (depends on download speeds)"
echo ""
echo "Configuration:"
echo "  - AI user: $AI_USER"
echo "  - Install root: $INSTALL_ROOT"
echo "  - Model: $MODEL_NAME"
echo ""
echo "The following will be installed:"
echo "  ✓ System dependencies (git, curl, etc.)"
echo "  ✓ Docker and Docker Compose"
echo "  ✓ Python and required packages"
echo "  ✓ Dedicated AI user for running the agent"
echo "  ✓ Configured Ollama model download"
echo ""
prompt_yes_no "Continue? (y/n) " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

run_subscript() {
    local step_label="$1"
    local script_name="$2"
    local error_message="$3"

    echo ""
    echo ">>> Starting $script_name ($step_label)"
    bash "$SETUP_DIR/$script_name"
    check_error "$error_message"
}

# Step 1: System dependencies
print_step "Step 1/8: Installing system dependencies"
run_subscript "Step 1/8" "01-system-deps.sh" "System dependencies installation failed"

# Step 2: Docker
print_step "Step 2/8: Installing Docker"
run_subscript "Step 2/8" "02-docker.sh" "Docker installation failed"

# Step 3: Python dependencies
print_step "Step 3/8: Installing Python and packages"
run_subscript "Step 3/8" "03-python-deps.sh" "Python setup failed"

# Step 4: Create AI user
print_step "Step 4/8: Creating dedicated AI user"
run_subscript "Step 4/8" "04-create-user.sh" "User creation failed"

# Step 5: Configure secrets
print_step "Step 5/8: Configuring secrets"
run_subscript "Step 5/8" "05-secrets.sh" "Secrets configuration failed"

# Step 6: Create directory structure
print_step "Step 6/8: Creating directory structure"
run_subscript "Step 6/8" "06-directories.sh" "Directory creation failed"

# Step 7: Setup Docker Compose
print_step "Step 7/8: Setting up Docker containers"
run_subscript "Step 7/8" "07-docker-compose.sh" "Docker Compose setup failed"

# Step 8: Pull LLM model
print_step "Step 8/8: Downloading configured Ollama model (this may take several minutes)"
run_subscript "Step 8/8" "08-pull-model.sh" "Model download failed"

print_header "Setup Complete! 🎉"
echo ""
echo "The services have already been started by the setup process."
echo "No reboot is required before you use the system."
echo ""
echo "Next steps:"
echo "1. Add your repositories to settings/repos/repos.json"
echo "2. Open the web UI: http://<vm-ip>:8000"
echo "3. Send a test task from CLI: $RUN_DIR/send_task.py --project my-project --instruction 'Add README'"
echo "4. Services will auto-start after reboot via Docker (system service), not via an aiuser login shell"
echo ""
echo "For more information, see:"
echo "  - agent/README.md - How the agent works"
echo "  - run/README.md - Runtime commands"
echo "  - setup/docker/README.md - Container management"
