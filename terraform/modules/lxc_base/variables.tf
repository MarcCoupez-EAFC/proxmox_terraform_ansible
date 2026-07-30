variable "node" {
    type = string
    description = "Node"
    default = "pve"
}
variable "OS" {
  type = string
  description = "Systeme d'exploitation du LXC"
}

variable "ip_lxc" {
    type = string
    description = "IP attribué à la machine, dhcp par défaut"
    default = "dhcp"
}

variable "template" {
    type = string
    description = "Chemin vers le template utilisé"
}

variable "name" {
    type = string
    description = "Nom du LXC"
}


variable "RAM" {
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
  default = "~/.ssh/id_rsa.pub"
}