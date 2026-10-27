# =============================================================================
# Firewall propre à CE conteneur.
# Pour qu'une règle s'applique réellement à un LXC, il faut les 4 étages :
#   1. firewall datacenter enabled = true          (module firewall)
#   2. firewall_options.enabled = true             (ci-dessous)
#   3. firewall = true sur la network_interface    (main.tf)
#   4. au moins un security group attaché          (ci-dessous)
# Sans 4 et avec input_policy = DROP, le conteneur est injoignable (Ansible compris).
# =============================================================================

# Étage 4 : les règles. Créées AVANT l'activation du firewall du conteneur.
resource "proxmox_virtual_environment_firewall_rules" "this" {
  node_name    = var.node
  container_id = proxmox_virtual_environment_container.this.vm_id

  dynamic "rule" {
    for_each = var.security_groups
    content {
      security_group = rule.value
      comment        = "SG ${rule.value}"
    }
  }
}

# Étage 2 : activation. N'arrive qu'une fois les règles en place,
# pour ne jamais avoir un conteneur en DROP sans aucune règle.
resource "proxmox_virtual_environment_firewall_options" "this" {
  node_name    = var.node
  container_id = proxmox_virtual_environment_container.this.vm_id

  enabled       = true
  input_policy  = var.firewall_input_policy
  output_policy = var.firewall_output_policy

  # Empêche le conteneur d'usurper une autre IP que celle configurée
  # (Proxmox ajoute automatiquement l'IP du LXC à l'ipset ipfilter-net0).
  # C'est ce qui rend fiables les règles basées sur l'IP source.
  ipfilter = true

  # Passer à "info" sur une machine pour voir les paquets refusés
  # (GUI : conteneur > Firewall > Log).
  log_level_in  = var.firewall_log_level_in
  log_level_out = "nolog"

  depends_on = [proxmox_virtual_environment_firewall_rules.this]
}
