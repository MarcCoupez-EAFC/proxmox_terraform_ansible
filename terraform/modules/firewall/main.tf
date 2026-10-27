terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111"
    }
  }
}

# =============================================================================
# Module firewall : SEULE source de vérité pour tout ce qui est "datacenter"
#   1. Objets nommés (alias, ipset)       -> ne filtrent rien, ce sont des noms
#   2. Security groups                     -> ne filtrent rien tant qu'un guest
#                                             ou le node ne les référence pas
#   3. Règles du node (l'hôte Proxmox)
#   4. Interrupteur général du datacenter  -> créé EN DERNIER
# Les règles propres à chaque LXC sont dans modules/lxc_base/firewall.tf
# =============================================================================

# --- 1. Objets nommés --------------------------------------------------------

resource "proxmox_virtual_environment_firewall_alias" "vlan" {
  for_each = var.vlans
  name     = "vlan_${each.value.name}"
  cidr     = each.value.cidr
  comment  = "VLAN ${each.key}"
}

# Le nom "management" n'est pas anodin : Proxmox le reconnaît et autorise
# AUTOMATIQUEMENT ces réseaux vers la GUI (8006) ET SSH (22) du node quand le
# firewall est actif. C'est le filet de sécurité anti-lockout.
# Conséquence : "SSH désactivé" ne peut pas être garanti par le firewall seul,
# il doit l'être côté hôte (sshd_config).
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

# --- 2. Security groups ------------------------------------------------------

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

  # Les règles référencent alias/ipset par leur NOM (simple string) :
  # Terraform ne voit pas la dépendance, il faut la déclarer.
  depends_on = [
    proxmox_virtual_environment_firewall_alias.vlan,
    proxmox_virtual_environment_firewall_ipset.management,
  ]
}

# --- 3. Node : options + règles ----------------------------------------------

# Étage "node" : s'il est à false, les règles du node ci-dessous sont ignorées.
resource "proxmox_virtual_environment_node_firewall" "this" {
  node_name = var.node_name
  enabled   = true

  log_level_in  = "nolog"
  log_level_out = "nolog"
}

resource "proxmox_virtual_environment_firewall_rules" "node" {
  count     = length(var.node_rules) > 0 ? 1 : 0
  node_name = var.node_name

  dynamic "rule" {
    for_each = var.node_rules
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

  depends_on = [proxmox_virtual_environment_firewall_ipset.management]
}

# --- 4. Interrupteur général (UN SEUL, en dernier) ---------------------------

resource "proxmox_virtual_environment_cluster_firewall" "this" {
  enabled       = var.enabled
  input_policy  = var.input_policy
  output_policy = var.output_policy

  depends_on = [
    proxmox_virtual_environment_firewall_ipset.management,
    proxmox_virtual_environment_cluster_firewall_security_group.this,
    proxmox_virtual_environment_node_firewall.this,
    proxmox_virtual_environment_firewall_rules.node,
  ]
}
