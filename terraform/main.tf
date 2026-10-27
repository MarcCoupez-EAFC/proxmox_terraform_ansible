terraform {
  required_version = ">=1.15.8"
  required_providers {
    proxmox = {
        source = "bpg/proxmox"
        version = "0.111.1"
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
}

module "lxc" {
  source   = "./modules/lxc_base"
  for_each = local.lxc_config

  // Identité
  name    = each.key

  tags    = each.value.tags


  // Ressources
  RAM      = each.value.RAM
  disk     = each.value.disk
  OS       = each.value.OS
  template = each.value.template
  cpu_cores = each.value.cpu_cores
  // Réseau
  vlan_tag    = each.value.vlan_tag
  ip_lxc      = "${local.lxc_ips[each.key]}/24"
  gateway     = cidrhost(local.vlans[each.value.vlan_tag], 1)
  dns_servers = [local.lxc_ips["debian-dns"]]

}