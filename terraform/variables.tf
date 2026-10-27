variable "server_adress" {

    type = string
    description = "Adresse  du serveur cible"
}

variable "api_token" {
    type = string
    sensitive = true
    description = "Token de l'API proxmox"
}
variable "management_cidrs" {
    type = list(string)
    description = "IPs du management"
    default = []
   
}

variable "firewall_enabled" {

    type = bool
    default = false
    description = "Activation ou non des firewalls"
}

