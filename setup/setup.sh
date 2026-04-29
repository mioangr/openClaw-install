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

clear_staged_env

sudo mkdir -p "$LOGS_DIR"
sudo touch "$LOGS_DIR/activity.log"
exec > >(tee -a "$LOGS_DIR/activity.log") 2>&1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header "Local AI Agent Setup"
echo "This script will install and configure your AI agent environment."
echo "Estimated time: 5-10 minutes (depends on package download speeds)"
echo ""
echo "Configuration:"
echo "  - AI user: $AI_USER"
echo "  - Install root: $INSTALL_ROOT"
echo "  - Default model name: $MODEL_NAME"
echo ""
echo "The following will be installed:"
echo "  ✓ System dependencies (git, curl, etc.)"
echo "  ✓ Docker and Docker Compose"
echo "  ✓ Python and required packages"
echo "  ✓ Dedicated AI user for running the agent"
echo "  ✓ Web UI for installing or removing Ollama models after setup"
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
print_step "Step 1/7: Installing system dependencies"
run_subscript "Step 1/7" "01-system-deps.sh" "System dependencies installation failed"

# Step 2: Docker
print_step "Step 2/7: Installing Docker"
run_subscript "Step 2/7" "02-docker.sh" "Docker installation failed"

# Step 3: Python dependencies
print_step "Step 3/7: Installing Python and packages"
run_subscript "Step 3/7" "03-python-deps.sh" "Python setup failed"

# Step 4: Create AI user
print_step "Step 4/7: Creating dedicated AI user"
run_subscript "Step 4/7" "04-create-user.sh" "User creation failed"

# Step 5: Configure secrets
print_step "Step 5/7: Configuring secrets"
run_subscript "Step 5/7" "05-secrets.sh" "Secrets configuration failed"

# Step 6: Create directory structure
print_step "Step 6/7: Creating directory structure"
run_subscript "Step 6/7" "06-directories.sh" "Directory creation failed"

# Step 7: Setup Docker Compose
print_step "Step 7/7: Setting up Docker containers"
run_subscript "Step 7/7" "07-docker-compose.sh" "Docker Compose setup failed"

clear_staged_env

print_header "Setup Complete! 🎉"
echo ""
echo "The services have already been started by the setup process."
echo "No reboot is required before you use the system."
echo ""
echo "Next steps:"
echo "1. Open the web UI: http://<vm-ip>:8000"
echo "2. Install an AI model from http://<vm-ip>:8000/add-remove-components"
echo "3. You can manage your repositories from http://<vm-ip>:8000/repos after setup completes"
echo "4. Send a test task from CLI: $RUN_DIR/send_task.py --project my-project --instruction 'Add README'"
echo "5. Services will auto-start after reboot via Docker (system service), not via an aiuser login shell"
echo ""
echo "For more information, see:"
echo "  - runtime/agent/README.md - How the agent works"
echo "  - runtime/cli/README.md - CLI commands"
echo "  - setup/docker/README.md - Container management"
