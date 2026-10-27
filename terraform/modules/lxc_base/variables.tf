variable "node" {
    type = string
    description = "Node"
    default = "pve"
}
variable "os" {
  type = string
  description = "Systeme d'exploitation du LXC"
}

variable "ip_lxc" {
  type        = string
  description = "IP du LXC en notation CIDR (ex : 192.168.30.10/24), ou \"dhcp\""

  validation {
    condition     = var.ip_lxc == "dhcp" || can(cidrhost(var.ip_lxc, 0))
    error_message = "ip_lxc doit valoir \"dhcp\" ou une IP CIDR (ex : 192.168.30.10/24)."
  }
}

variable "gateway" {
  type        = string
  description = "Passerelle par défaut du LXC (interface du firewall dans le VLAN). Obligatoire si l'IP est statique."
  default     = null

  validation {
    condition     = var.ip_lxc == "dhcp" || var.gateway != null
    error_message = "Une IP statique nécessite une passerelle."
  }
}
variable "template" {
    type = string
    description = "Chemin vers le template utilisé"
}

variable "name" {
    type = string
    description = "Nom du LXC"
}


variable "ram" {
    type = number
    description = "Nombre de RAM en Mb"
}

variable "disk" {
    type = object({
         localisation = string
         espace = number})
    description = "Dict : localisation->localisation du disque, espace->espace libre en Go"
    default = {
        localisation = "local-lvm"
        espace = 8
    }
}

variable "vlan_tag" {
    type = number
    description = "Tag VLAN attribué"
    default = null
}

variable "bridge" {
    type = object({bridge = string
                    name = string})
    description = "Dict : bridge->bridge utilisé, nom->nom du reseaux"
    default = {
        bridge = "vmbr0"
        name = "eth0"
    }
}

variable tags {
    type = list(string)
    description = "tag associé au lxc"
}
variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "cpu_cores" {

    type = number
    default = 2
}

variable "dns_servers" {
  type        = list(string)
  description = "Serveurs DNS du LXC"
  default     = []
}


# --- Firewall ----------------------------------------------------------------

variable "security_groups" {
  type        = list(string)
  description = "Security groups (définis au niveau datacenter) appliqués à ce conteneur"

  validation {
    condition     = length(var.security_groups) > 0
    error_message = "Un LXC sans security group est injoignable (input DROP), Ansible compris. Ajoute au moins ssh-admin."
  }

  validation {
    condition     = length(var.security_groups) == length(distinct(var.security_groups))
    error_message = "Un même security group est listé plusieurs fois."
  }
}

variable "firewall_input_policy" {
  type        = string
  description = "Politique par défaut du trafic entrant du conteneur"
  default     = "DROP"

  validation {
    condition     = contains(["ACCEPT", "DROP", "REJECT"], var.firewall_input_policy)
    error_message = "firewall_input_policy doit valoir ACCEPT, DROP ou REJECT."
  }
}

variable "firewall_output_policy" {
  type        = string
  description = "Politique par défaut du trafic sortant du conteneur"
  default     = "ACCEPT"

  validation {
    condition     = contains(["ACCEPT", "DROP", "REJECT"], var.firewall_output_policy)
    error_message = "firewall_output_policy doit valoir ACCEPT, DROP ou REJECT."
  }
}

variable "firewall_log_level_in" {
  type        = string
  description = "Niveau de log du trafic entrant ('info' pour déboguer un flux bloqué)"
  default     = "nolog"

  validation {
    condition     = contains(["nolog", "emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"], var.firewall_log_level_in)
    error_message = "Niveau de log invalide."
  }
}
