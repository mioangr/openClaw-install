#!/bin/bash
# =============================================================================
# Script 03: Install Python Dependencies
# =============================================================================
# Purpose: Installs Python tooling needed by host-side helper scripts
# Dependencies: System dependencies from script 01
# Output: python3, pip3, venv support, and redis client package installed
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Installing Python Dependencies"

print_step "Installing Python packages from apt..."
sudo apt-get update -qq
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-redis
check_error "Failed to install Python packages"

print_step "Verifying Python installation..."
if check_command python3; then
    echo "  ✓ Python $(python3 --version | cut -d' ' -f2)"
else
    die 1 "python3 not installed" "Run: sudo apt-get install -y python3"
fi

if check_command pip3; then
    echo "  ✓ pip $(pip3 --version | awk '{print $2}')"
else
    die 1 "pip3 not installed" "Run: sudo apt-get install -y python3-pip"
fi

python3 -c "import redis" >/dev/null 2>&1
check_error "Python redis package is not available"
echo "  ✓ Python redis client available"

echo ""
print_step "Python dependencies installed successfully"
