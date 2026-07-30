terraform {
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

module "lxc" {
  source = "./modules/lxc_base"
  for_each = local.lxc_config
  name = each.key
  RAM = each.value.RAM
  disk = {
    localisation = each.value.disk.localisation
    espace = each.value.disk.espace
  }
  OS = each.value.OS
  vlan_tag = each.value.vlan_tag
  template = each.value.template
  tags = each.value.tags
}

module "user" {
  source = "./modules/accounts/"
}

resource "proxmox_acl" "terraform_vm_access" {
  path= "/"
  role_id = "Terraform"
  token_id = "terraform-pve@pve!provider"
  propagate   = true
}

