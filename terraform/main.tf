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
   admin   = "vlan_admin" // alias créé par le module firewall
  users   = "vlan_users"
  interne = "192.168.0.0/16"
}

module "firewall" {
  source = "./modules/firewall"

  enabled          = var.firewall_enabled


  vlans = {
    for tag, cidr in local.vlans : tag => { name = local.vlan_names[tag], cidr = cidr }
  }
  management_cidrs = concat([local.vlans[1]], var.management_cidrs)

  # Une règle = "qui (source) peut joindre quel service (dport) sur la machine
  # qui porte ce groupe". La destination est implicite : c'est le LXC.
  security_groups = {
    ssh-admin = {
      comment = "SSH depuis le VLAN admin (Ansible compris)"
      rules   = [{ dport = "22", source = local.admin, comment = "SSH admin" }]
    }
    icmp-admin = {
      comment = "Ping depuis le VLAN admin"
      rules   = [{ proto = "icmp", source = local.admin, comment = "Ping admin" }]
    }
    node-exporter = {
      comment = "Scrape Prometheus"
      rules   = [{ dport = "9100", source = local.ip["debian-prometheus"], comment = "node_exporter" }]
    }
    web = {
      comment = "Frontend Vue.js"
      rules = [
        { dport = "80,443", source = local.users, comment = "Front - utilisateurs" },
        { dport = "80,443", source = local.admin, comment = "Front - admin" },
      ]
    }
    api-backend = {
      comment = "Backend FastAPI (appelé par le navigateur)"
      rules = [
        { dport = "8000", source = local.users, comment = "API - utilisateurs" },
        { dport = "8000", source = local.admin, comment = "API - admin" },
      ]
    }
    postgresql = {
      comment = "PostgreSQL : backend uniquement"
      rules   = [{ dport = "5432", source = local.ip["debian-api-backend"], comment = "DB depuis backend" }]
    }
    openbao = {
      comment = "OpenBao : backend + admin"
      rules = [
        { dport = "8200", source = local.ip["debian-api-backend"], comment = "Bao depuis backend" },
        { dport = "8200", source = local.admin, comment = "Bao depuis admin" },
      ]
    }
    grafana = {
      comment = "Grafana : admin"
      rules   = [{ dport = "3000", source = local.admin, comment = "Grafana" }]
    }
    prometheus = {
      comment = "Prometheus : Grafana + admin"
      rules = [
        { dport = "9090", source = local.ip["debian-grafana"], comment = "Datasource Grafana" },
        { dport = "9090", source = local.admin, comment = "Prometheus admin" },
      ]
    }
    dns = {
      comment = "DNS interne"
      rules = [
        { dport = "53", proto = "udp", source = local.interne, comment = "DNS udp" },
        { dport = "53", proto = "tcp", source = local.interne, comment = "DNS tcp" },
      ]
    }
    pbs = {
      comment = "Proxmox Backup Server : GUI admin + node"
      rules   = [{ dport = "8007", source = local.admin, comment = "PBS" }]
      # TODO : ajouter l'IP du node Proxmox (c'est lui qui pousse les sauvegardes)
    }
  }

  # Règles de l'HÔTE Proxmox. "+management" = l'ipset (préfixe + pour un ipset).
  # Pas de SSH : le cahier des charges le désactive. À rouvrir temporairement
  # si besoin, depuis le VLAN admin uniquement.
  node_rules = [
    { action = "ACCEPT", dport = "8006", source = "+management", comment = "GUI Proxmox" },
    { action = "ACCEPT", proto = "icmp", source = "+management", comment = "Ping" },
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
  security_groups = {
    ssh-admin = {
      comment = "SSH depuis le VLAN admin"
      rules   = [{ dport = "22", source = local.vlans[1], comment = "SSH admin" }]
    }
  }
}

