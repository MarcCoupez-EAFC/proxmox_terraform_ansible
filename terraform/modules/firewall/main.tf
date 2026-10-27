terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.111"
    }
  }
}

resource "proxmox_virtual_environment_firewall_alias" "vlan" {
  for_each = var.vlans
  name     = "vlan_${each.value.name}"
  cidr     = each.value.cidr
  comment  = "VLAN ${each.key}"
}

resource "proxmox_virtual_environment_firewall_ipset" "management" {
  name    = "management"
  comment = "Réseaux autorisés à administrer Proxmox"

  dynamic "cidr" {
    for_each = var.management_cidrs
    content {
      name = cidr.value
    }
  }
}

resource "proxmox_virtual_environment_cluster_firewall_security_group" "this" {
  for_each = var.security_groups
  name     = each.key
  comment  = each.value.comment

  dynamic "rule" {
    for_each = each.value.rules
    content {
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

# Activé en dernier, une fois l'accès admin garanti
resource "proxmox_virtual_environment_cluster_firewall" "this" {
  enabled       = var.enabled
  input_policy  = var.input_policy
  output_policy = var.output_policy

  depends_on = [
    proxmox_virtual_environment_firewall_ipset.management,
    proxmox_virtual_environment_cluster_firewall_security_group.this,
  ]
}

resource "proxmox_virtual_environment_firewall_rules" "node" {
  node_name = var.node_name

  dynamic "rule" {
    for_each = var.fw_rules
    content {
      action  = rule.value.action
      type    = rule.value.type
      iface   = rule.value.iface
      proto   = rule.value.proto
      dport   = rule.value.dport
      source  = rule.value.source
      dest    = rule.value.dest
      comment = rule.value.comment
    }
  }
}

resource "proxmox_virtual_environment_cluster_firewall" "this" {
  count = var.enabled ? 1 : 0

  enabled       = true
  input_policy  = "DROP"
  output_policy = "ACCEPT"

  depends_on = [proxmox_virtual_environment_firewall_rules.node]
}