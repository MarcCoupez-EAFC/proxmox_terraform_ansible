locals {
    lxc_config = {
        debian-api-backend = {
    
            RAM = 2048
            disk = {
                localisation = "local-lvm"
                espace = 8
            }
            OS = "debian"
            vlan_tag = 30
            template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
            tags = ["api"]
        }

        debian-api-frontend = {
              RAM = 2048
                disk = {
                    localisation = "local-lvm"
                    espace = 8
                }
                OS = "debian"
                vlan_tag = 30
                template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
                tags = ["api"]
        }
        debian-grafana = {
              RAM = 2048
                disk = {
                    localisation = "local-lvm"
                    espace = 8
                }
                OS = "debian"
                vlan_tag = 20
                template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
                tags = ["monitoring"]
        }
        debian-prometheus = {
              RAM = 2048
                disk = {
                    localisation = "local-lvm"
                    espace = 8
                }
                OS = "debian"
                vlan_tag = 20
                template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
                tags = ["monitoring"]
        }
        debian-postresql = {
              RAM = 2048
                disk = {
                    localisation = "local-lvm"
                    espace = 8
                }
                OS = "debian"
                vlan_tag = 40
                template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
                tags = ["vault"]
        }
    
        debian-secrets = {
              RAM = 2048
                disk = {
                    localisation = "local-lvm"
                    espace = 8
                }
                OS = "debian"
                vlan_tag = 40
                template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
                tags = ["vault"]
        }
        debian-dns = {
              RAM = 2048
                disk = {
                    localisation = "local-lvm"
                    espace = 8
                }
                OS = "debian"
                vlan_tag = null
                template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
                tags = ["dmz"]
        }
        debian-pbs = {
              RAM = 2048
                disk = {
                    localisation = "local-lvm"
                    espace = 8
                }
                OS = "debian"
                vlan_tag = null
                template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
                tags = ["backup"]
        }
        

    }
    vlans = {
        monitoring = "192.168.20.0/24"
        api = "192.168.30.0/24"
    }
    vlan_names = keys(local.vlans)
    

   
}
