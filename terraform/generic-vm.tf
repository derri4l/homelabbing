# This is a terraform script to setup a VM. A base template is required for this to work.

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

variable "proxmox_ci_sshkeys" {
  type        = string
  description = "Proxmox ci sshkeys"
  sensitive   = true
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "generic-vm" {
  cores            = 2
  vmid             = 500
  name             = "generic-vm"
  target_node      = "pve"
  memory           = 6092
  balloon          = 2048
  clone            = "tmp-vm"
  scsihw           = "virtio-scsi-single"
  vm_state         = "stopped"
  tags             = "generic"
  automatic_reboot = true
  boot             = "order=scsi0;ide1"
  nameserver       = "1.1.1.1 8.8.8.8"
  ipconfig0        = "ip=192.168.12.1/24,gw=192.168.12.1"
  agent            = 1

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
    tag = 2
  }

  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "30G"
        }
      }
    }
    ide {
      ide1{
        cdrom {
          iso = "local:iso/cachyos-desktop-linux-260628.iso"    # overwrites ISO from template VM, optional
        }
      }
    }
  }
}
