
// ----- AVI Section ----- //

/* STEPS
0- Create the Azure Cloud Connector
1- Define Pool Servers for public clouds
2- Define the VIP@ for public clouds
3- Define the Virtual Services with WAF for public clouds
*/

data "avi_ipamdnsproviderprofile" "dns_profile" {
   name = "AVI-DNS-Profile"
}

data "avi_ipamdnsproviderprofile" "ipam_profile" {
   name = "VIP-AVI-IPAM"
}

data "avi_applicationprofile" "system_http" {
   name = "System-HTTP"
}

data "avi_networkprofile" "system_tcp_proxy" {
   name = "System-TCP-Proxy"
}

data "avi_wafpolicy" "default_waf_policy" {
   name = "System-WAF-Policy"
}

data "avi_healthmonitor" "default_gslb_health_monitor" {
   name = "System-GSLB-HTTP"
}

data "avi_gslb" "gslb_name" {
   name = var.gslb_default_name
}

// Create Azure Credentials
resource "avi_cloudconnectoruser" "azure_user" {
  name       = "AZURE_CREDENTIALS"
  azure_serviceprincipal {
    application_id = var.azure_application_id
    authentication_token = var.azure_auth_token
    tenant_id = var.azure_tenant_id
  }
}

// Create AWS Cloud Connector
resource "avi_cloud" "azure_cloud" {
   depends_on = [azurerm_resource_group.vcn-demo-rg, azurerm_virtual_network.vcn-vnet, azurerm_subnet.vcn-private-sn]
   name = var.azure_cloud_name
   vtype = "CLOUD_AZURE"
   dns_provider_ref = data.avi_ipamdnsproviderprofile.dns_profile.id
   //ipam_provider_ref = data.avi_ipamdnsproviderprofile.ipam_profile.id
   dhcp_enabled = true
   license_tier = "ENTERPRISE"
   license_type = "LIC_CORES"
   
   azure_configuration {
      subscription_id = var.azure_subscription_id
      resource_group = azurerm_resource_group.vcn-demo-rg.name
      location = var.azure_region
      cloud_credentials_ref = avi_cloudconnectoruser.azure_user.id
      network_info {
        virtual_network_id = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${azurerm_resource_group.vcn-demo-rg.name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.vcn-vnet.name}"
        se_network_id = azurerm_subnet.vcn-private-sn.name
        management_network_id = azurerm_subnet.vcn-private-sn.name
      }
   }
}

// 1- Define the HTTP Pool Servers

resource "avi_pool" "azure_http_pool" {
    depends_on = [azurerm_virtual_machine.azure_web-vm]
    name = var.azure_pool
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
    cloud_ref = avi_cloud.azure_cloud.id
    default_server_port = 80
    servers {
        ip {
            type = "V4"
            addr = azurerm_network_interface.web-vm-if.private_ip_address
        }
    }
    analytics_policy {
     enable_realtime_metrics = true
   }
}

// 2- Define the VIP@

resource "avi_vsvip" "azure_vsvip" {
    depends_on = [azurerm_resource_group.vcn-demo-rg, azurerm_virtual_network.vcn-vnet, azurerm_subnet.vcn-private-sn, azurerm_virtual_machine.velo-vedge]
    name = var.azure_vs_name
    cloud_ref = avi_cloud.azure_cloud.id
    vip {
        auto_allocate_floating_ip = true
        auto_allocate_ip  = true
        subnet_uuid = azurerm_subnet.vcn-private-sn.name
        subnet {
            ip_addr {
                addr = var.azure_private_sn_vip
                type = "V4"
            }
            mask = "24"
        }
    }
    dns_info {
      fqdn = var.azure_domain_name
    }
}

// 3- Define the Virtual Services with WAF

resource "avi_virtualservice" "http_azure_vs" {
   depends_on = [avi_vsvip.azure_vsvip, azurerm_virtual_network.vcn-vnet, azurerm_subnet.vcn-private-sn, azurerm_virtual_machine.velo-vedge]
   name = var.azure_vs_name
   cloud_ref = avi_cloud.azure_cloud.id
   vsvip_ref = avi_vsvip.azure_vsvip.id
   pool_ref = avi_pool.azure_http_pool.id
   application_profile_ref = data.avi_applicationprofile.system_http.id
   network_profile_ref = data.avi_networkprofile.system_tcp_proxy.id
   waf_policy_ref = data.avi_wafpolicy.default_waf_policy.id
   services {
      port = 80
      enable_ssl = false
   }
   analytics_policy {
    metrics_realtime_update {
      enabled  = true
      duration = 0
    }
  }
}