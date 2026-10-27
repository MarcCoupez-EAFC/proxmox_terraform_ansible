locals {
  // Plan d'adressage : un sous-réseau par VLAN
  vlans = {
    1 = "192.168.1.0/24" # Admin
    20 = "192.168.20.0/24" # Monitoring
    30 = "192.168.30.0/24" # API
    40 = "192.168.40.0/24" # Vault
    50 = "192.168.50.0/24" # Dev
    55 = "192.168.55.0/24" # Git
    60 = "192.168.60.0/24" # Prod
    70 = "192.168.70.0/24" # Users
    80 = "192.168.80.0/24" # DMZ
    90 = "192.168.90.0/24" # Backup
  }

  // Valeurs communes à tous les LXC d'infra
  lxc_defaults = {
    ram      = 2048
    os      = "debian"
    template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    disk = {
      localisation = "local-lvm"
      espace       = 8
    }
    cpu_cores = 2
  }

  // Uniquement ce qui est propre à chaque machine + les règles firewall qui vont s'appliquer
  lxc_specific = {
    debian-api-backend  = { vlan_tag = 30, host = 10, tags = ["api"]}
    debian-api-frontend = { vlan_tag = 30, host = 11, tags = ["api"] }
    debian-grafana      = { vlan_tag = 20, host = 10, tags = ["monitoring"] }
    debian-prometheus   = { vlan_tag = 20, host = 11, tags = ["monitoring"] }
    debian-postgresql   = { vlan_tag = 40, host = 10, tags = ["vault"] }
    debian-secrets      = { vlan_tag = 40, host = 11, tags = ["vault"] }
    debian-dns          = { vlan_tag = 80, host = 10, tags = ["dmz"] }
    debian-pbs          = { vlan_tag = 90, host = 10, tags = ["backup"], RAM = 4096 }
  }

  // Fusion : les valeurs spécifiques écrasent les valeurs par défaut
  lxc_config = {
    for name, cfg in local.lxc_specific :
    name => merge(local.lxc_defaults, cfg)
  }
}