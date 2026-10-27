terraform {
  required_version = ">=1.15.8"
  required_providers {
    proxmox = {
        source = "bpg/proxmox"
        version = ">=0.111.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.server_adress
  api_token = var.api_token
  insecure  = true
  
}

locals {
  // IP de chaque machine, calculée une fois et réutilisable partout
  lxc_ips = {
    for name, cfg in local.lxc_config :
    name => cidrhost(local.vlans[cfg.vlan_tag], cfg.host)
  }

  vlan_names = { 1 = "admin",20 = "monitoring", 30 = "api", 40 = "vault", 50 = "dev"
  55 = "git", 60 = "prod", 70 = "users", 80 = "dmz", 90 = "backup"
  }
}

module "firewall" {
  source = "./modules/firewall"

  enabled          = var.firewall_enabled
  management_cidrs = var.management_cidrs

  vlans = {
    for tag, cidr in local.vlans : tag => { name = local.vlan_names[tag], cidr = cidr }
  }

  security_groups = {
    ssh-admin = {
      comment = "SSH depuis le VLAN admin"
      rules   = [{ dport = "22", source = local.vlans[1], comment = "SSH admin" }]
    }
  }
  fw_rules = [
  { action = "ACCEPT", dport = "8006", source = "+management_cidrs", comment = "GUI Proxmox" },
  { action = "ACCEPT", dport = "22",   source = "+management_cidrs", comment = "SSH admin" },
  { action = "ACCEPT", proto = "icmp", source = "+management_cidrs", comment = "Ping" },
]
}

module "lxc" {
  source   = "./modules/lxc_base"
  for_each = local.lxc_config

  // Identité
  name    = each.key

  tags    = each.value.tags


  // Ressources
  ram      = each.value.ram
  disk     = each.value.disk
  os      = each.value.os
  template = each.value.template
  cpu_cores = each.value.cpu_cores
  // Réseau
  vlan_tag    = each.value.vlan_tag
  ip_lxc      = "${local.lxc_ips[each.key]}/24"
  gateway     = cidrhost(local.vlans[each.value.vlan_tag], 1)
  dns_servers = [local.lxc_ips["debian-dns"]]

}

