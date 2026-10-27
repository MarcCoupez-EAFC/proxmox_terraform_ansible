variable "enabled" {
  type        = bool
  description = "Interrupteur général du firewall datacenter. false = AUCUNE règle n'est appliquée nulle part (node, LXC, VM)."
  default     = false
}

variable "input_policy" {
  type        = string
  description = "Politique par défaut du trafic entrant (niveau datacenter)"
  default     = "DROP"

  validation {
    condition     = contains(["ACCEPT", "DROP", "REJECT"], var.input_policy)
    error_message = "input_policy doit valoir ACCEPT, DROP ou REJECT."
  }
}

variable "output_policy" {
  type        = string
  description = "Politique par défaut du trafic sortant (niveau datacenter)"
  default     = "ACCEPT"

  validation {
    condition     = contains(["ACCEPT", "DROP", "REJECT"], var.output_policy)
    error_message = "output_policy doit valoir ACCEPT, DROP ou REJECT."
  }
}

variable "management_cidrs" {
  type        = list(string)
  description = "Réseaux autorisés à administrer Proxmox (alimente l'ipset spécial 'management')"
  default     = []

  # Bloquant UNIQUEMENT si on active le firewall : avant, une liste vide est acceptable.
  # (Validation croisée entre variables : Terraform >= 1.9)
  validation {
    condition     = !var.enabled || length(var.management_cidrs) > 0
    error_message = "Firewall activé sans réseau d'administration : tu vas te couper l'accès à Proxmox."
  }

  validation {
    condition     = alltrue([for c in var.management_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque entrée doit être une notation CIDR (ex : 192.168.10.0/24)."
  }
}

variable "vlans" {
  type = map(object({
    name = string
    cidr = string
  }))
  description = "VLAN déclarés comme alias 'vlan_<name>' (clé = tag VLAN), utilisables dans source/dest"
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
  description = "Groupes de règles réutilisables (clé = nom du groupe), à référencer depuis les LXC"
  default     = {}

  validation {
    condition = alltrue(flatten([
      for sg in values(var.security_groups) : [
        for r in sg.rules : contains(["in", "out"], r.type) && contains(["ACCEPT", "DROP", "REJECT"], r.action)
      ]
    ]))
    error_message = "type doit valoir in/out et action ACCEPT/DROP/REJECT."
  }

  # Une règle entrante SANS source = "depuis n'importe où" : même danger que 0.0.0.0/0
  validation {
    condition = alltrue(flatten([
      for sg in values(var.security_groups) : [
        for r in sg.rules : r.type != "in" || (r.source != null && r.source != "0.0.0.0/0")
      ]
    ]))
    error_message = "Toute règle entrante doit avoir une source explicite, différente de 0.0.0.0/0."
  }

  validation {
    condition = alltrue(flatten([
      for sg in values(var.security_groups) : [
        for r in sg.rules : r.dport == null || contains(["tcp", "udp"], r.proto)
      ]
    ]))
    error_message = "dport n'a de sens qu'avec proto = tcp ou udp (pas icmp)."
  }

  # Formats acceptés : "22", "80,443", "5900:5999", "80,8000:8010"
  validation {
    condition = alltrue(flatten([
      for sg in values(var.security_groups) : [
        for r in sg.rules : r.dport == null || can(regex("^[0-9]+(:[0-9]+)?(,[0-9]+(:[0-9]+)?)*$", r.dport))
      ]
    ]))
    error_message = "dport invalide. Formats : \"22\", \"80,443\" ou \"5900:5999\"."
  }
}

variable "node_rules" {
  type = list(object({
    action  = string
    type    = optional(string, "in")
    iface   = optional(string)
    proto   = optional(string, "tcp")
    dport   = optional(string)
    source  = optional(string)
    dest    = optional(string)
    comment = optional(string, "")
  }))
  description = "Règles appliquées à l'hôte Proxmox lui-même (GUI, ping...)"
  default     = []

  validation {
    condition     = alltrue([for r in var.node_rules : contains(["in", "out"], r.type) && contains(["ACCEPT", "DROP", "REJECT"], r.action)])
    error_message = "type doit valoir in/out et action ACCEPT/DROP/REJECT."
  }

  validation {
    condition     = alltrue([for r in var.node_rules : r.type != "in" || (r.source != null && r.source != "0.0.0.0/0")])
    error_message = "Toute règle entrante du node doit avoir une source explicite, différente de 0.0.0.0/0."
  }

  validation {
    condition     = alltrue([for r in var.node_rules : r.dport == null || contains(["tcp", "udp"], r.proto)])
    error_message = "dport n'a de sens qu'avec proto = tcp ou udp (pas icmp)."
  }

  validation {
    condition     = alltrue([for r in var.node_rules : r.dport == null || can(regex("^[0-9]+(:[0-9]+)?(,[0-9]+(:[0-9]+)?)*$", r.dport))])
    error_message = "dport invalide. Formats : \"22\", \"80,443\" ou \"5900:5999\"."
  }
}

variable "node_name" {
  type    = string
  default = "pve"
}
