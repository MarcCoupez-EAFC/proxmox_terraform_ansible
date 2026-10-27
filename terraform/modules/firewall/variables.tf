variable "enabled" {
  type        = bool
  description = "Active le firewall du datacenter. Laisser à false tant que l'accès admin n'est pas vérifié."
  default     = false
}

variable "input_policy" {
  type        = string
  description = "Politique par défaut du trafic entrant"
  default     = "DROP"

  validation {
    condition     = contains(["ACCEPT", "DROP", "REJECT"], var.input_policy)
    error_message = "input_policy doit valoir ACCEPT, DROP ou REJECT."
  }
}

variable "output_policy" {
  type        = string
  description = "Politique par défaut du trafic sortant"
  default     = "ACCEPT"

  validation {
    condition     = contains(["ACCEPT", "DROP", "REJECT"], var.output_policy)
    error_message = "output_policy doit valoir ACCEPT, DROP ou REJECT."
  }
}

variable "management_cidrs" {
  type        = list(string)
  description = "Réseaux autorisés à administrer Proxmox"

  validation {
    condition     = length(var.management_cidrs) > 0
    error_message = "Au moins un réseau d'administration est requis, sinon le firewall coupera tout accès."
  }

  validation {
    condition     = alltrue([for c in var.management_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque entrée doit être une notation CIDR (ex : 192.168.1.0/24)."
  }
}

variable "vlans" {
  type = map(object({
    name = string
    cidr = string
  }))
  description = "VLAN à déclarer comme alias (clé = tag VLAN), utilisables ensuite dans les règles"
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.vlans) : can(cidrhost(v.cidr, 0))])
    error_message = "Chaque VLAN doit avoir un cidr valide."
  }

  validation {
    condition     = alltrue([for v in values(var.vlans) : can(regex("^[a-z][a-z0-9_-]*$", v.name))])
    error_message = "Les noms de VLAN doivent commencer par une lettre et ne contenir que a-z, 0-9, _ ou -."
  }
}

variable "security_groups" {
  type = map(object({
    comment = optional(string, "")
    rules = list(object({
      type    = optional(string, "in")
      action  = optional(string, "ACCEPT")
      proto   = optional(string, "tcp")
      dport   = optional(string)
      source  = optional(string)
      dest    = optional(string)
      comment = optional(string, "")
    }))
  }))
  description = "Groupes de règles réutilisables (clé = nom du groupe)"
  default     = {}

  validation {
    condition = alltrue(flatten([
      for sg in values(var.security_groups) : [
        for r in sg.rules : contains(["in", "out"], r.type) && contains(["ACCEPT", "DROP", "REJECT"], r.action)
      ]
    ]))
    error_message = "type doit valoir in/out et action ACCEPT/DROP/REJECT."
  }

  validation {
    condition = alltrue(flatten([
      for sg in values(var.security_groups) : [for r in sg.rules : r.source != "0.0.0.0/0"]
    ]))
    error_message = "Une règle ouverte à tout Internet (0.0.0.0/0) est interdite."
  }
}

variable "fw_rules" {

  type = list(object({
    action  = string                       # obligatoire : ACCEPT / DROP / REJECT
    type    = optional(string, "in")
    iface   = optional(string)             # null = toutes les interfaces
    proto   = optional(string, "tcp")
    dport   = optional(string)
    source  = optional(string)
    dest    = optional(string)
    comment = optional(string, "")
  }))
}

variable "node_name" {

  type = string
  default = "pve"
}

