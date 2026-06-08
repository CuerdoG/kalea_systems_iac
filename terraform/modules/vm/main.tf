resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore
    size         = var.disk_size
    interface    = "scsi0"
  }

  dynamic "network_device" {
    for_each = var.networks
    content {
      bridge  = network_device.value.bridge
      vlan_id = try(network_device.value.vlan_id, null)
    }
  }

  initialization {

    dynamic "ip_config" {
      for_each = var.ip_configs
      content {
        ipv4 {
          address = ip_config.value.address
          gateway = try(ip_config.value.gateway, null)
        }
      }
    }

    user_account {
      username = var.username
      keys     = [file(var.ssh_key)]
    }
  }
}
