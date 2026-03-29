#!/bin/bash

#############################################################
# OPENCLAW FULL SETUP SCRIPT (MEGA SCRIPT)
#
# BOOTSTRAP SCRIPT EXPLANATION:
# A "bootstrap script" is a script that prepares a fresh system
# (like a new VM) by installing all required software and
# configurations so that your application can run.
#
# PREREQUISITE:
# Ubuntu Server is already installed (e.g. in VMware VM)
#
# FEATURES:
# - Idempotent (safe to run multiple times)
# - Installs Docker
# - Creates AI user
# - Configures environment
# - Prompts for secrets and stores them in .env
#
# HOW TO RUN THIS SCRIPT:
# To download and run the script in one command:
#   curl -O https://raw.githubusercontent.com/mioangr/openClaw-install/main/setup_openclaw.sh && sudo bash setup_openclaw.sh
#
# Or download first, then run:
#   curl -O https://raw.githubusercontent.com/mioangr/openClaw-install/main/setup_openclaw.sh
#   sudo bash setup_openclaw.sh
#
#############################################################

set -e

#############################
# CONFIGURATION VARIABLES
#############################

AI_USER="aiuser"
WORK_DIR="/home/","$AI_USER","/openclaw"
ENV_FILE="${WORK_DIR}/.env"

#############################
# HELPER FUNCTIONS
#############################

log() {
    echo -e "\n==== $1 ====
"}

#############################
# ROOT CHECK
#############################

if [[ $EUID -ne 0 ]]; then
   echo "Please run with sudo: sudo ./setup_openclaw.sh"
   exit 1
fi

#############################
# SYSTEM UPDATE
#############################

log "Updating system (if needed)"

apt update

#############################
# INSTALL BASE PACKAGES
#############################

log "Installing base packages"

apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git

#############################
# INSTALL DOCKER (CHECK FIRST)
#############################

if command -v docker &> /dev/null; then
    log "Docker already installed - skipping"
else
    log "Installing Docker"

    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update

    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

#############################
# CREATE AI USER
#############################

if id "$AI_USER" &>/dev/null; then
    log "User $AI_USER already exists"
else
    log "Creating AI user"

    adduser --disabled-password --gecos "" "$AI_USER"
fi

#############################
# ADD USER TO DOCKER GROUP
#############################

if groups "$AI_USER" | grep -q docker; then
    log "User already in docker group"
else
    log "Adding user to docker group"
    usermod -aG docker "$AI_USER"
fi

#############################
# CREATE WORK DIRECTORY
#############################

if [ -d "$WORK_DIR" ]; then
    log "Work directory exists"
else
    log "Creating work directory"
    mkdir -p "$WORK_DIR"
    chown -R "$AI_USER:$AI_USER" "$WORK_DIR"
fi

#############################
# CREATE .ENV FILE (SECRETS)
#############################

if [ -f "$ENV_FILE" ]; then
    log ".env file already exists - skipping"
else
    log "Creating .env file (you will be prompted for secrets)"

    read -p "Enter GitHub Token (or leave empty): " GITHUB_TOKEN
    read -s -p "Enter OpenAI API Key (or leave empty): " OPENAI_API_KEY
    echo

    cat <<EOF > "$ENV_FILE"
GITHUB_TOKEN=$GITHUB_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
EOF

    chown "$AI_USER:$AI_USER" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

#############################
# CREATE DOCKER COMPOSE FILE
#############################

COMPOSE_FILE="${WORK_DIR}/docker-compose.yml"

if [ -f "$COMPOSE_FILE" ]; then
    log "docker-compose.yml already exists"
else
    log "Creating docker-compose.yml"

cat <<EOF > "$COMPOSE_FILE"
version: "3.9"

services:
  openclaw:
    image: node:18
    container_name: openclaw-agent

    env_file:
      - .env

    volumes:
      - ./data:/data
      - ./logs:/logs

    stdin_open: true
    tty: true

    restart: unless-stopped

    cap_drop:
      - ALL

    security_opt:
      - no-new-privileges:true
EOF

    chown "$AI_USER:$AI_USER" "$COMPOSE_FILE"
fi

#############################
# FINAL MESSAGE
#############################

log "SETUP COMPLETE"

echo "Next steps:"
echo "-----------------------------------"
echo "1. Log in as AI user:"
echo "   su - $AI_USER"
echo ""
echo "2. Test Docker:"
echo "   docker run hello-world"
echo ""
echo "3. Go to working directory:"
echo "   cd $WORK_DIR"
echo ""
echo "4. Start services:"
echo "   docker compose up -d"
echo ""
echo "IMPORTANT:"
echo "- You must log out and back in for docker group to apply"
echo "- Your secrets are stored in: $ENV_FILE"
echo "-----------------------------------"
