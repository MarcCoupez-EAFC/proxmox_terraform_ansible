terraform {
  required_version = ">=1.15.8"
  required_providers {
    
    proxmox = {
        source = "bpg/proxmox"
        version = "0.111.1"
    }
  }
}

resource "proxmox_virtual_environment_container" "this" {
  node_name    = var.node
  unprivileged = true
  
  initialization {
    hostname = var.name
    
    ip_config {
      ipv4 {
        address = var.ip_lxc
      }
    }
    user_account {
      password = "password"
      keys = [file("${var.ssh_public_key_path}")]
    }
    
  
  }
  

  disk {
    datastore_id = var.disk.localisation
    size         = var.disk.espace
  }
  memory {
    dedicated = var.RAM
  }

  network_interface {
    name   = var.bridge.name
    bridge = var.bridge.bridge
    vlan_id = var.vlan_tag
  }

  operating_system {
    template_file_id = var.template
    type             = var.OS
  }
  tags = var.tags
  
}

