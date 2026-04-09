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

TEMP_INSTALL_DIR="temp-web-install"

load_install_config() {
    if [ -f "install.conf" ]; then
        # shellcheck disable=SC1091
        source "install.conf"
    fi
}

confirm_action() {
    local prompt="$1"
    local reply

    if [ -t 0 ]; then
        read -p "$prompt" -n 1 -r reply
    elif [ -r /dev/tty ]; then
        read -p "$prompt" -n 1 -r reply < /dev/tty
    else
        echo "Confirmation required, but no terminal is attached."
        return 1
    fi
    echo

    [[ "$reply" =~ ^[Yy]$ ]]
}

load_install_config
AI_USER="${AI_USER:-aiuser}"
INSTALL_DEST_DIR="${INSTALL_DEST_DIR:-local-ai-agent}"
INSTALL_ROOT="/home/$AI_USER/$INSTALL_DEST_DIR"

# Run as the main linux user, NOT as root if we can help it for cloning
# but setup.sh will require sudo
echo "Starting local-ai-agent automated installation..."

if [ -d "$TEMP_INSTALL_DIR" ]; then
    echo "Found leftover temporary install folder '$TEMP_INSTALL_DIR'. Removing it before continuing..."
    rm -rf "$TEMP_INSTALL_DIR"
fi

if [ -d "$INSTALL_ROOT" ]; then
    echo "Detected an existing installation at $INSTALL_ROOT."
    echo "A reinstall should clean up the previous installation first."
    echo "The default cleanup preserves Docker volumes such as downloaded Ollama models."
    if ! confirm_action "Run the install cleanup now and continue? (y/n) "; then
        echo "Aborted. Existing installation was left unchanged."
        exit 1
    fi

    echo "Cloning local-ai-agent repository into temporary '$TEMP_INSTALL_DIR' folder for cleanup..."
    git clone https://github.com/mioangr/local-ai-agent.git "$TEMP_INSTALL_DIR"
    cd "$TEMP_INSTALL_DIR"

    echo "Requesting sudo access for cleanup and setup..."
    sudo -v

    echo "Running install cleanup (keeping Docker volumes)..."
    chmod +x setup/reset-install.sh
    sudo ./setup/reset-install.sh --force --keep-volumes

    cd ..
    echo "Removing temporary cleanup folder..."
    rm -rf "$TEMP_INSTALL_DIR"
fi

echo "Cloning local-ai-agent repository into temporary '$TEMP_INSTALL_DIR' folder..."
git clone https://github.com/mioangr/local-ai-agent.git "$TEMP_INSTALL_DIR"
cd "$TEMP_INSTALL_DIR"

echo "Making setup script executable..."
chmod +x setup/setup.sh

echo "Requesting sudo access for system setup..."
sudo -v

echo "Running main setup script..."
# Run the setup script with sudo
sudo ./setup/setup.sh
