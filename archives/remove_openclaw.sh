#!/bin/bash

#############################################################
# OPENCLAW FULL RESET SCRIPT
#
# PURPOSE:
# Completely removes everything created by setup script,
# allowing you to return to a "clean VM" state.
#
# WHAT THIS SCRIPT DOES:
# - Stops and removes Docker containers
# - Removes Docker (optional)
# - Deletes AI user and home directory
# - Deletes OpenClaw working directory
# - Removes Docker data
#
# WARNING:
# This script is DESTRUCTIVE.
#
# BOOTSTRAP TERM EXPLANATION:
# "Bootstrap" refers to setting up a system from scratch.
# This script does the opposite: it resets the system so
# bootstrap can be run again cleanly.
#
#############################################################

set -e

#############################
# CONFIGURATION
#############################

AI_USER="aiuser"
WORK_DIR="/home/${AI_USER}/openclaw"
REMOVE_DOCKER=true   # set to false if you want to keep Docker

#############################
# ROOT CHECK
#############################

if [[ $EUID -ne 0 ]]; then
   echo "Please run with sudo: sudo ./reset_openclaw.sh"
   exit 1
fi

#############################
# CONFIRMATION
#############################

echo "WARNING: This will DELETE OpenClaw environment and possibly Docker."
read -p "Type 'YES' to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
    echo "Aborted."
    exit 0
fi

#############################
# STOP DOCKER CONTAINERS
#############################

if command -v docker &> /dev/null; then
    echo "Stopping all Docker containers..."

    docker stop $(docker ps -aq) 2>/dev/null || true

    echo "Removing all Docker containers..."

    docker rm $(docker ps -aq) 2>/dev/null || true
else
    echo "Docker not installed - skipping container cleanup"
fi

#############################
# REMOVE DOCKER DATA
#############################

if command -v docker &> /dev/null; then
    echo "Removing Docker images, volumes, networks..."

    docker system prune -a -f --volumes || true
fi

#############################
# REMOVE WORK DIRECTORY
#############################

if [ -d "$WORK_DIR" ]; then
    echo "Removing OpenClaw working directory..."
    rm -rf "$WORK_DIR"
else
    echo "Work directory not found - skipping"
fi

#############################
# REMOVE AI USER
#############################

if id "$AI_USER" &>/dev/null; then
    echo "Removing user $AI_USER..."

    userdel -r "$AI_USER" || true
else
    echo "User not found - skipping"
fi

#############################
# REMOVE DOCKER (OPTIONAL)
#############################

if [ "$REMOVE_DOCKER" = true ]; then

    if command -v docker &> /dev/null; then
        echo "Removing Docker..."

        apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true

        apt autoremove -y

        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd

        echo "Docker removed."
    else
        echo "Docker already removed"
    fi

else
    echo "Skipping Docker removal"
fi

#############################
# CLEAN DOCKER REPO CONFIG
#############################

echo "Cleaning Docker repository configuration..."

rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.gpg

#############################
# FINAL MESSAGE
#############################

echo ""
echo "====================================="
echo "RESET COMPLETE"
echo "====================================="
echo ""
echo "System is now close to a fresh state."
echo "You can rerun your setup script."
echo ""
