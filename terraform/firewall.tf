resource "proxmox_virtual_environment_firewall_ipset" "management" {
  name = "management"
  cidr {
    name    = local.vlans[1]
    comment = "VLAN admin"
  }
}

resource "proxmox_virtual_environment_cluster_firewall_security_group" "ssh_admin" {
  name    = "ssh-admin"
  comment = "SSH depuis le VLAN admin"
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "22"
    source  = local.vlans[1]
    comment = "SSH admin"
  }
}

resource "proxmox_virtual_environment_cluster_firewall" "this" {
  enabled       = true   # ← volontairement, pour l'instant
  input_policy  = "DROP"
  output_policy = "ACCEPT"

  depends_on = [proxmox_virtual_environment_firewall_ipset.management]
}

resource "proxmox_virtual_environment_node_firewall" "this" {
  node_name = "pve"   # nom de ton nœud
  enabled   = false

  # options facultatives
  log_level_in  = "nolog"
  log_level_out = "nolog"
  # ndp       = true
  # nosmurfs  = true
}