# =============================================================================
# Packer Template for Ubuntu Server Golden Image (VMware Workstation)
# =============================================================================
# This template builds a fully automated Ubuntu Server VM template.
#
# QUICK START:
#   packer init .
#   packer validate .
#   packer build .
#
# HOW TO UPDATE TO A NEWER UBUNTU VERSION:
#   1. Change the 'ubuntu_version' variable below (e.g., "24.04.5").
#   2. Find the new SHA256 checksum:
#      - Go to https://releases.ubuntu.com/<version>/
#      - Open the SHA256SUMS file
#      - Copy the hash for the "-live-server-amd64.iso" file
#   3. Update the 'iso_checksum' variable with the new hash.
#   4. Re-run packer build.
# =============================================================================

# ----------------------------
# USER VARIABLES - EDIT THESE ONLY
# ----------------------------

# Ubuntu version and ISO details
variable "ubuntu_version" {
  type    = string
  default = "24.04.4"                    # <<< Change this to update Ubuntu version
}

variable "ubuntu_iso_name" {
  type    = string
  default = "ubuntu-${var.ubuntu_version}-live-server-amd64.iso"
}

# Official SHA256 checksum for Ubuntu Server 24.04.4 LTS
# Source: https://releases.ubuntu.com/24.04.4/SHA256SUMS
variable "iso_checksum" {
  type    = string
  default = "e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"
}

# VM Hardware Settings
variable "vm_name" {
  type    = string
  default = "ubuntu-server-golden"
}

variable "disk_size_mb" {
  type    = number
  default = 40960      # 40 GB
}

variable "memory_mb" {
  type    = number
  default = 4096       # 4 GB
}

variable "cpus" {
  type    = number
  default = 2
}

variable "network_type" {
  type    = string
  default = "nat"
}

variable "network_adapter" {
  type    = string
  default = "vmxnet3"
}

# SSH Connection Settings (must match autoinstall.yaml)
variable "ssh_username" {
  type    = string
  default = "iadmin"
}

variable "ssh_password" {
  type      = string
  default   = "YOUR_PLAINTEXT_PASSWORD_HERE"   # ⚠️ REPLACE THIS!
  sensitive = true
}

variable "ssh_timeout" {
  type    = string
  default = "30m"
}

# Path to your autoinstall.yaml file (relative to this template)
variable "autoinstall_file" {
  type    = string
  default = "autoinstall.yaml"
}

# ----------------------------
# PACKER CONFIGURATION
# ----------------------------
packer {
  required_version = ">= 1.7.0"
  required_plugins {
    vmware = {
      source  = "github.com/hashicorp/vmware"
      version = ">= 2.1.1"
    }
  }
}

# ----------------------------
# SOURCE: VMware ISO Builder
# ----------------------------
source "vmware-iso" "ubuntu-server" {
  # VM Hardware (using variables)
  vm_name              = "${var.vm_name}-${var.ubuntu_version}"
  guest_os_type        = "ubuntu-64"
  disk_size            = var.disk_size_mb
  memory               = var.memory_mb
  cpus                 = var.cpus
  network              = var.network_type
  network_adapter_type = var.network_adapter

  # ISO Source
  iso_urls      = ["https://releases.ubuntu.com/${var.ubuntu_version}/${var.ubuntu_iso_name}"]
  iso_checksum  = "sha256:${var.iso_checksum}"

  # Autoinstall Configuration (cidata)
  cd_files = [var.autoinstall_file]
  cd_label = "cidata"

  # Boot Command (Unattended)
  boot_wait    = "10s"
  boot_command = [
    "<enter><wait>",
    "<esc><wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud;s=/cdrom/ <enter><wait>",
    "initrd /casper/initrd <enter><wait>",
    "boot <enter>"
  ]

  # SSH Connection Settings (using variables)
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = var.ssh_timeout
  shutdown_command = "echo '${var.ssh_username}' | sudo -S shutdown -P now"
}

# ----------------------------
# BUILD: Run the builder and optional provisioners
# ----------------------------
build {
  sources = ["source.vmware-iso.ubuntu-server"]

  provisioner "shell" {
    inline = [
      "echo '✅ Packer build completed successfully!'",
      # Add any post-install commands here, for example:
      # "sudo apt-get update && sudo apt-get install -y htop"
    ]
  }
}
