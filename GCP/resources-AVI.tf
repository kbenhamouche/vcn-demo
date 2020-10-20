
// ----- AVI Section ----- //

/* STEPS
0- Create GCP User and GCP Cloud Connector
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

// CloudConnector user
resource "avi_cloudconnectoruser" "gcp_user" {
  name       = "GCP-CREDENTIALS"
  gcp_credentials {
    service_account_keyfile_data = file(var.gcp_credentials)
  }
}

// Create GCP Cloud Connector
resource "avi_cloud" "gcp_cloud" {
   depends_on = [google_compute_network.gcp_vcn_demo_private_vpc, google_compute_subnetwork.gcp_vcn_private_sn]
   name  = var.gcp_cloud_name
   vtype = "CLOUD_GCP"
   ipam_provider_ref = data.avi_ipamdnsproviderprofile.ipam_profile.id
   dns_provider_ref = data.avi_ipamdnsproviderprofile.dns_profile.id
   dhcp_enabled = true
   license_tier = "ENTERPRISE"
   license_type = "LIC_CORES"
   
   gcp_configuration {
      region_name = var.gcp_region
      zones = [var.gcp_zone]
      se_project_id = var.gcp_project
      cloud_credentials_ref = avi_cloudconnectoruser.gcp_user.id
      vip_allocation_strategy {
         routes {
            match_se_group_subnet = false
         }
      }
      network_config {
         config = "INBAND_MANAGEMENT"
         inband {
            vpc_project_id   = var.gcp_project
            vpc_subnet_name  = google_compute_subnetwork.gcp_vcn_private_sn.name
            vpc_network_name = google_compute_network.gcp_vcn_demo_private_vpc.name
         }
      }
   }
}

// 1- Define the HTTP Pool Servers

resource "avi_pool" "gcp_http_pool" {
    depends_on = [google_compute_instance.gcp_web-vm]
    name = var.gcp_pool
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
    cloud_ref = avi_cloud.gcp_cloud.id
    default_server_port = 80
    servers {
        ip {
            type = "V4"
            addr = google_compute_instance.gcp_web-vm.network_interface.0.network_ip
        }
    }
    analytics_policy {
     enable_realtime_metrics = true
   }
}

// 2- Define the VIP@
resource "avi_vsvip" "gcp_vsvip" {
    depends_on = [google_compute_instance.gcp_vce_instance]
    name = var.gcp_vs_name
    cloud_ref = avi_cloud.gcp_cloud.id
    vip {
        auto_allocate_floating_ip = true
        ip_address {
            addr = var.gcp_vs_vip
            type = "V4"
        }
    }
    dns_info {
        fqdn = var.gcp_domain_name
    }
}

// 3- Define the Virtual Services with WAF
resource "avi_virtualservice" "http_gcp_vs" {
   depends_on = [avi_vsvip.gcp_vsvip]
   name = var.gcp_vs_name
   cloud_ref = avi_cloud.gcp_cloud.id
   vsvip_ref = avi_vsvip.gcp_vsvip.id
   pool_ref = avi_pool.gcp_http_pool.id
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