variable "fw_rules" {
    type = list(object({
    iface = optional(string,"vmbr0")
    type = optional(string,"IN")
    action  = optional(string,"")
    proto   = optional(string, "tcp")
    dport   = optional(string, "")
    source  = string
    dest    = optional(string, "")
    comment = optional(string, "")
  }))
    description = "Liste des règles firewall (sous forme de dictionnaire)"

}

variable "node_name" {
    type = string
    default = "pve"
}