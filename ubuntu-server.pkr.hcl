# Required Packer plugins
packer {
  required_version = ">= 1.7.0"
  required_plugins {
    vmware = {
      version = ">= 2.1.1"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

# Local variables
locals {
  autoinstall_path = "autoinstall.yaml"
}

# VMware ISO builder source
source "vmware-iso" "ubuntu-server" {
  # --- VM Hardware ---
  vm_name              = "ubuntu-server-golden"
  guest_os_type        = "ubuntu-64"
  disk_size            = 40960           # 40 GB in MB
  memory               = 4096            # 4 GB
  cpus                 = 2
  network              = "nat"
  
  # *** REQUIRED: Network adapter type ***
  network_adapter_type = "vmxnet3"       # Use vmxnet3 for best performance

  # --- ISO Source (Ubuntu Server 24.04 LTS) ---
  iso_urls = [
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"
  ]
  iso_checksum = "sha256:76d6e45bfe1c6d6cbc26c1e4501a5570312f10202b53c98c433c145ac54bf0d1"

  # --- Autoinstall via cloud-init (cidata) ---
  cd_files = [local.autoinstall_path]
  cd_label = "cidata"

  # --- Boot Command for Unattended Install ---
  # This waits for the ISO to boot, then sends the correct kernel parameters.
  boot_wait    = "10s"
  boot_command = [
    "<enter><wait>",                         # Select first boot option (default)
    "<esc><wait>",                           # Enter boot prompt (for some ISO versions)
    "linux /casper/vmlinuz --- autoinstall ds=nocloud;s=/cdrom/ <enter><wait>",
    "initrd /casper/initrd <enter><wait>",
    "boot <enter>"
  ]

  # --- SSH Connection Settings (must match your autoinstall.yaml) ---
  ssh_username     = "iadmin"
  ssh_password     = "YOUR_PLAINTEXT_PASSWORD"   # !!! Replace with actual plaintext password
  ssh_timeout      = "30m"
  shutdown_command = "echo 'iadmin' | sudo -S shutdown -P now"

  # Optional: keep the VM registered in VMware after build
  # skip_export = true   # Uncomment if you want to keep the VM in the inventory
}

# Build block
build {
  sources = ["source.vmware-iso.ubuntu-server"]

  # Optional: run additional provisioning after OS is installed
  provisioner "shell" {
    inline = [
      "echo 'Packer build completed successfully.'",
      # Add any post-install commands here, e.g.:
      # "sudo apt-get update && sudo apt-get install -y htop"
    ]
  }
}
