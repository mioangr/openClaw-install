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

# Local variables to keep the template DRY
locals {
  # Set this to the path of your autoinstall.yaml file
  autoinstall_path = "autoinstall.yaml" 
}

# The vmware-iso source block
source "vmware-iso" "ubuntu-server" {
  # --- VM Hardware ---
  vm_name              = "ubuntu-server-golden"
  guest_os_type        = "ubuntu-64"
  disk_size            = 40960 # Disk size in MB (40 GB)
  memory               = 6144  # Memory in MB (6 GB)
  cpus                 = 2     # Number of CPUs
  network              = "nat" # Use NAT for internet access & isolation

  # --- ISO Source ---
  iso_urls             = ["https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"]
  iso_checksum         = "sha256:76d6e45bfe1c6d6cbc26c1e4501a5570312f10202b53c98c433c145ac54bf0d1"

  # --- Autoinstall Method ---
  # This is where the magic happens. Packer attaches the 'autoinstall.yaml' file
  # as a cloud-init 'cidata' disk. The boot command then tells the installer to
  # look for it there.
  cd_files     = [local.autoinstall_path]
  cd_label     = "cidata"

  boot_wait    = "5s"
  # This boot command sends the correct kernel parameters to launch the autoinstaller.
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud;s=/cdrom/",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  # --- SSH Connection for Provisioning ---
  # Packer connects to the VM via SSH after the OS is installed to run provisioners.
  # These settings must match what you defined in your autoinstall.yaml.
  ssh_username           = "iadmin"
  ssh_password           = "YOUR_PLAINTEXT_PASSWORD" # Replace this!
  ssh_timeout            = "30m"
  shutdown_command       = "echo 'iadmin' | sudo -S shutdown -P now" # Allows clean shutdown
}

# The build block runs the builder and any provisioners.
build {
  sources = ["source.vmware-iso.ubuntu-server"]

  # This provisioner runs after the OS is installed.
  # It can be used for any final customization steps.
  provisioner "shell" {
    inline = [
      "echo 'Packer build completed successfully.'",
      # Add any other post-install commands here, e.g.:
      # "sudo apt-get update",
      # "sudo apt-get install -y htop",
    ]
  }
}