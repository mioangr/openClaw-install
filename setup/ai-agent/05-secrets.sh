#!/bin/bash
# =============================================================================
# Script 05: Configure Secrets
# =============================================================================
# Purpose: Prompts for GitHub token and stores it securely in .env file
# Dependencies: User 'aiuser' exists
# Output: /home/aiuser/.env with GITHUB_TOKEN and GITHUB_USERNAME
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Configuring Secrets"

AI_USER="aiuser"
AI_HOME="/home/$AI_USER"
ENV_FILE="$AI_HOME/.env"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    print_warning ".env file already exists"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file"
        exit 0
    fi
fi

echo ""
echo "To interact with GitHub, you need a Personal Access Token (PAT)."
echo ""
echo "Create a token here: https://github.com/settings/tokens"
echo ""
echo "Required permissions:"
echo "  - repo (full control of private repositories)"
echo "  - workflow (if using GitHub Actions)"
echo "  - write:discussion (optional, for comments)"
echo ""
read -p "Press Enter when you have your token ready..."

# Get GitHub token
echo ""
read -sp "Enter your GitHub token: " GITHUB_TOKEN
echo ""

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME

# Validate token (basic check)
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_USERNAME" ]; then
    die 1 "Token and username are required" "Run this script again and provide both values"
fi

# Create .env file
print_step "Creating .env file at $ENV_FILE..."

sudo tee "$ENV_FILE" > /dev/null << EOF
# GitHub Authentication
GITHUB_TOKEN=$GITHUB_TOKEN
GITHUB_USERNAME=$GITHUB_USERNAME

# LLM Configuration
OLLAMA_URL=http://ollama:11434
REDIS_URL=redis://redis:6379

# Workspace
WORKSPACE=/workspace
EOF

# Set secure permissions
sudo chmod 600 "$ENV_FILE"
sudo chown $AI_USER:$AI_USER "$ENV_FILE"

echo ""
print_step "Secrets configured successfully"
echo "✓ Token stored securely in $ENV_FILE"
echo "✓ Permissions set to 600 (readable only by $AI_USER)"