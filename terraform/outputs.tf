output "inventory" {
  value = {
    for a,b in module.lxc :
    a => {
      id = b.id
      tags = b.tag
      ansible_host = try(values(b.ipv4_adress)[0],null)
      }
  }
    
  }
