#!/bin/bash
# =============================================================================
# Script 01: Install System Dependencies
# =============================================================================
# Purpose: Installs basic system packages required for Docker, Python, and Git
# Dependencies: Internet connection, sudo access
# Output: Installed packages (git, curl, build-essential, etc.)
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Installing System Dependencies"

# Update package list
print_step "Updating package lists..."
sudo apt-get update -qq
check_error "Failed to update package lists"

# Install required packages
print_step "Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    build-essential \
    software-properties-common \
    wget \
    vim \
    htop

check_error "Failed to install system packages"

print_step "Verifying installations..."

# Verify git
if check_command git; then
    echo "  ✓ git $(git --version | cut -d' ' -f3)"
else
    die 1 "git not installed" "Run: sudo apt-get install -y git"
fi

# Verify curl
if check_command curl; then
    echo "  ✓ curl $(curl --version | head -n1 | cut -d' ' -f2)"
else
    die 1 "curl not installed" "Run: sudo apt-get install -y curl"
fi

echo ""
print_step "System dependencies installed successfully"