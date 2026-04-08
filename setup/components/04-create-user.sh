#!/bin/bash
# =============================================================================
# Script 04: Create Dedicated AI User
# =============================================================================
# Purpose: Creates the configured AI user for running the agent
# Dependencies: Docker installed (for group membership)
# Output: User 'aiuser' created, added to docker group
# =============================================================================

source "$(dirname "$0")/../common.sh"

print_header "Creating AI User"

# Check if user already exists
if id "$AI_USER" &>/dev/null; then
    print_warning "User $AI_USER already exists"
    prompt_yes_no "Recreate user? (y/n) " REPLY
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping user creation"
        exit 0
    fi
    
    # Remove existing user
    print_step "Removing existing $AI_USER..."
    sudo pkill -u $AI_USER 2>/dev/null || true
    sudo userdel -r $AI_USER 2>/dev/null
fi

# Create user
print_step "Creating user $AI_USER..."
sudo useradd -m -s /bin/bash -U $AI_USER
check_error "Failed to create user $AI_USER"

# Set password (optional)
prompt_yes_no "Set a login password for $AI_USER now? (y/n) " REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Setting password for $AI_USER..."
    if [ "$(id -u)" -eq 0 ]; then
        run_interactive_command passwd "$AI_USER"
    else
        run_interactive_command sudo passwd "$AI_USER"
    fi
    check_error "Failed to set password for $AI_USER"
else
    print_warning "Skipping password setup for $AI_USER"
    echo "  You can set it later with: sudo passwd $AI_USER"
fi

# Add user to docker group
print_step "Adding $AI_USER to docker group..."
sudo usermod -aG docker $AI_USER
check_error "Failed to add user to docker group"

# Create .bashrc for the user
print_step "Configuring bash environment..."
sudo tee -a "$AI_HOME/.bashrc" > /dev/null << EOF
# Alias for docker compose
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias aihome='cd "\$HOME/$INSTALL_DEST_DIR"'

# Custom prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Path for local runtime scripts
export AI_INSTALL_ROOT="\$HOME/$INSTALL_DEST_DIR"
export CONFIG_REPO_PATH="\$AI_INSTALL_ROOT/settings/repos"
export PATH="\$AI_INSTALL_ROOT/run:\$PATH"
EOF

sudo chown $AI_USER:$AI_USER "$AI_HOME/.bashrc"

# Set proper permissions
sudo chmod 755 "$AI_HOME"

echo ""
print_step "User $AI_USER created successfully"
echo "To switch to this user later: su - $AI_USER"
