# This is a Terraform script for setting up a Virtual Machine with cloudinit.
# Cloudinit image is "debian-13-genericcloud-amd64-20260712-2537.qcow2"

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

# variables
variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API endpoint"
}

variable "proxmox_token_id" {
  type        = string
  description = "Proxmox API token ID"
  sensitive   = true
}

variable "proxmox_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "proxmox_ci_user" {
  type        = string
  description = "cloudinit user"
  sensitive   = true
}

variable "proxmox_ci_password" {
  type        = string
  description = "cloudinit password"
  sensitive   = true
}

variable "proxmox_ci_sshkeys" {
  type        = string
  description = "cloudinit sshkeys"
  sensitive   = true
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = true
}

# VM resources
resource "proxmox_vm_qemu" "cloudinit" {
  vmid            = 603
  name            = "web-vm"
  target_node     = "pve"
  agent           = 1
  cpu             {cores=2}
  memory          = 6092
  boot            = "order=scsi0"
  clone           = "debian13-cloudinit"
  scsihw          = "virtio-scsi-single"
  vm_state        = "running"
  tags            = "webserver"   # VM tag, optional
  automatic_reboot = true

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/webstartup.yml"   #custom script, optional
  ciupgrade  = true
  nameserver = "1.1.1.1 8.8.8.8"
  ipconfig0  = "ip=192.168.12.1/24,gw=192.168.12.1"
  skip_ipv6  = true
  ciuser     = var.proxmox_ci_user
  cipassword = var.proxmox_ci_password
  sshkeys    = var.proxmox_ci_sshkeys


  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "30G"  # disk size
        }
      }
    }
    ide {
      # attach cloudinit drive
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
    tag    = 47   # vlan tag, optional
  }
}
