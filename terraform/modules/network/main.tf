terraform {
  required_version = ">=1.15.8"
  required_providers {
    
    proxmox = {
        source = "bpg/proxmox"
        version = "0.111.1"
    }
  }
}



resource "proxmox_virtual_environment_firewall_rules" "inbound" {
 
  node_name = var.node_name
  dynamic "rule" {
    for_each = var.fw_rules
    content {
      iface   = rule.value.iface
      type    = rule.value.type
      action  = rule.value.action
      proto   = rule.value.proto
      dport   = rule.value.dport
      source  = rule.value.source
      dest    = rule.value.dest
      comment = rule.value.comment
      
    }
  }

}