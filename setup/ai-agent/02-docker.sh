#!/bin/bash
# =============================================================================
# Script 02: Install Docker Engine and Docker Compose
# =============================================================================
# Purpose: Installs Docker from official repository and Docker Compose plugin
# Dependencies: System dependencies from script 01
# Output: Docker daemon running, docker compose command available
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Installing Docker"

# Check if Docker is already installed
if check_command docker; then
    print_warning "Docker is already installed"
    docker --version
    read -p "Reinstall? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping Docker installation"
        exit 0
    fi
fi

# Remove old versions if any
print_step "Removing old Docker versions..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
print_step "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
check_error "Failed to add Docker GPG key"

# Add Docker repository
print_step "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check_error "Failed to add Docker repository"

# Install Docker Engine
print_step "Installing Docker Engine..."
sudo apt-get update -qq
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
check_error "Failed to install Docker"

# Start Docker service
print_step "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker
check_error "Failed to start Docker service"

# Verify installation
print_step "Verifying Docker installation..."
if docker --version &> /dev/null; then
    echo "  ✓ Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
else
    die 1 "Docker installation failed" "Check: systemctl status docker"
fi

if docker compose version &> /dev/null; then
    echo "  ✓ Docker Compose $(docker compose version | cut -d' ' -f4)"
else
    die 1 "Docker Compose plugin not found" "Run: sudo apt-get install -y docker-compose-plugin"
fi

# Test Docker
print_step "Testing Docker (running hello-world)..."
sudo docker run --rm hello-world > /dev/null 2>&1
check_error "Docker cannot run containers. Check: sudo usermod -aG docker $USER and logout/login"

echo ""
print_step "Docker installed successfully"