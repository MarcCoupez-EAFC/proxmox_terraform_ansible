output "id" {
    value = proxmox_virtual_environment_container.this.vm_id
    description = "ID du LXC créé"
}

output "tag" {
    value = proxmox_virtual_environment_container.this.tags
}

output "ipv4_adress" {
    value = proxmox_virtual_environment_container.this.ipv4
}