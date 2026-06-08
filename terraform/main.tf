terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0"
    }
  }
}


provider "proxmox" {
  endpoint = "https://192.168.1.220:8006/"
  username = "root@pam"
  password = var.pm_password
  insecure = true
}


# WordPress
resource "proxmox_virtual_environment_container" "Wordpress" {
  node_name    = "pve"
  vm_id        = 202
  unprivileged = true
  pool_id      = "Zitadel"

  cpu {
    cores = 1
  }

  memory {
    dedicated = 768
  }

  disk {
    datastore_id = "local-lvm"
    size         = 10
  }

  network_interface {
    name    = "eth0"
    bridge  = "vmbr1"
    vlan_id = 30
  }

  operating_system {
    template_file_id = "HDD-4TB:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type             = "debian"
  }

  initialization {
    hostname = "WordPress-Zitadel"
    ip_config {
      ipv4 {
        address = "10.0.30.203/24"
        gateway = "10.0.30.1"
      }
    }
    user_account {
      password = var.ad_password
      keys     = [file("~/.ssh/id_rsa.pub")]
    }
  }

  features {
    nesting = true
  }

  start_on_boot = true
}


# MariaDB
resource "proxmox_virtual_environment_container" "MariaDB" {
  node_name    = "pve"
  vm_id        = 203
  unprivileged = true
  pool_id      = "Zitadel"

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 10
  }

  network_interface {
    name    = "eth0"
    bridge  = "vmbr1"
    vlan_id = 40
  }

  operating_system {
    template_file_id = "HDD-4TB:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type             = "debian"
  }

  initialization {
    hostname = "MariaDB-Zitadel"
    ip_config {
      ipv4 {
        address = "10.0.40.203/24"
        gateway = "10.0.40.1"
      }
    }
    user_account {
      password = var.ad_password
      keys     = [file("~/.ssh/id_rsa.pub")]
    }
  }

  features {
    nesting = true
  }

  start_on_boot = true
}


# Bastion (Apache Guacamole)
resource "proxmox_virtual_environment_vm" "bastion" {
  name      = "Bastion-Zitadel"
  node_name = "pve"
  vm_id     = 205
  pool_id   = "Zitadel"

  clone {
    vm_id = 9201
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  # NIC 1: VLAN 10 Gestion
  network_device {
    bridge  = "vmbr1"
    vlan_id = 10
  }

  # NIC 2: Red Kalea Systems
  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.0.10.207/24"
        gateway = "10.0.10.1"
      }
    }
    ip_config {
      ipv4 {
        address = "192.168.1.207/24"
      }
    }
    user_account {
      username = "admin"
      password = var.ad_password
      keys     = [file("~/.ssh/id_rsa.pub")]
    }
  }
}
