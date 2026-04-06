#!/bin/bash
# =============================================================================
# OpenClaw One-Liner Install Script
# =============================================================================
# Usage: curl -s https://raw.githubusercontent.com/mioangr/local-ai-agent/main/setup/install-from-web.sh | bash
#
# This script creates a 'setup' subfolder in the current directory, clones the
# repository there, and runs the main setup script.
# =============================================================================

set -e

# Run as the main linux user, NOT as root if we can help it for cloning
# but setup.sh will require sudo
echo "Starting local-ai-agent automated installation..."

if [ -d "setup" ]; then
    echo "Warning: 'setup' directory already exists. Please run this script in a directory without a 'setup' folder."
    exit 1
fi

echo "Cloning local-ai-agent repository into 'setup' folder..."
git clone https://github.com/mioangr/local-ai-agent.git setup
cd setup

echo "Making setup script executable..."
chmod +x setup/setup.sh

echo "Running main setup script..."
# Run the setup script with sudo
sudo ./setup/setup.sh
