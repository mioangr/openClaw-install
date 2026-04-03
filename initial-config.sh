#!/bin/bash

# =============================================================================
# Ubuntu 24.04 Server Optimization & Hardening Script
# Target: VMware Workstation (Win 11 Host with Hyper-V)
# =============================================================================

# Exit on any error
set -e

echo "--- Starting System Optimization ---"

# 1. Update and Upgrade System
echo "--- Updating Packages ---"
sudo apt update && sudo apt upgrade -y

# 2. Install Essential Utilities & VMware Integration
echo "--- Installing Essential Tools & Open-VM-Tools ---"
sudo apt install -y open-vm-tools open-vm-tools-desktop curl wget git build-essential vim htop net-tools

# 3. Security Hardening: Firewall (UFW)
echo "--- Configuring Firewall (Allowing SSH only) ---"
sudo ufw allow ssh
sudo ufw --force enable

# 4. Security Hardening: SSH Configuration
echo "--- Disabling Root SSH Login ---"
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 5. Boot Performance: Disable Splash Screen (Verbose Boot)
echo "--- Optimizing GRUB for Verbose Boot ---"
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub
sudo update-grub

# 6. Cleanup
echo "--- Cleaning up package cache ---"
sudo apt autoremove -y
sudo apt autoclean

echo "--- Setup Complete! ---"
echo "Recommended: Restart the VM to apply Kernel updates and GRUB changes."