#!/bin/bash
# =============================================================================
# OpenClaw One-Liner Install Script
# =============================================================================
# Usage: curl -s https://raw.githubusercontent.com/mioangr/local-ai-agent/main/setup/install-from-web.sh | bash
#
# This script creates a temporary 'temp-web-install' subfolder in the current
# directory, clones the repository there, and runs the main setup script.
# =============================================================================

set -e

# Run as the main linux user, NOT as root if we can help it for cloning
# but setup.sh will require sudo
echo "Starting local-ai-agent automated installation..."

if [ -d "temp-web-install" ]; then
    echo "Warning: 'temp-web-install' directory already exists. Please run this script in a directory without a 'temp-web-install' folder."
    exit 1
fi

echo "Cloning local-ai-agent repository into temporary 'temp-web-install' folder..."
git clone https://github.com/mioangr/local-ai-agent.git temp-web-install
cd temp-web-install

echo "Making setup script executable..."
chmod +x setup/setup.sh

echo "Running main setup script..."
# Run the setup script with sudo
sudo ./setup/setup.sh
