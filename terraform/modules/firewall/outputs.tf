output "security_groups" {
  description = "Noms des security groups, à passer aux machines"
  value       = { for k, sg in proxmox_virtual_environment_cluster_firewall_security_group.this : k => sg.name }
}

output "vlan_aliases" {
  description = "Noms des alias VLAN (clé = tag), utilisables comme source/dest dans les règles"
  value       = { for k, a in proxmox_virtual_environment_firewall_alias.vlan : k => a.name }
}