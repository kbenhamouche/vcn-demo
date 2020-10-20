// ----- AVI Section ----- //

/* STEPS
1- Define Pool Servers for private clouds
2- Define the VIP@ for private clouds
3- Define the Virtual Services with WAF for private clouds
4- Create the GSLB Service
*/

data "avi_cloud" "private_cloud" {
   name = var.private_cloud_name
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

data "avi_ipamdnsproviderprofile" "dns_profile" {
   name = "AVI-DNS-Profile"
}

data "avi_ipamdnsproviderprofile" "ipam_profile" {
   name = "VIP-AVI-IPAM"
}

data "avi_healthmonitor" "default_gslb_health_monitor" {
   name = "System-GSLB-HTTP"
}

data "avi_gslb" "gslb_name" {
   name = var.gslb_default_name
}

// 1- Define the HTTP Pool Servers

resource "avi_pool" "private_http_pool" {
   name = var.private_pool
   lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
   cloud_ref = data.avi_cloud.private_cloud.id
   default_server_port = 80
   servers {
      ip {
         type = "V4"
         addr = var.pool_private_server1
      }
   }
   analytics_policy {
    enable_realtime_metrics = true
   }
}

// 2- Define the VIP@

resource "avi_vsvip" "private_vsvip" {
   name = var.private_vs_name
   cloud_ref = data.avi_cloud.private_cloud.id
   vip {
      ip_address {
         addr = var.private_vs_vip
         type = "V4"
      }
   }
   dns_info {
      fqdn = var.private_domain_name
   }
}

// 3- Define the Virtual Services with WAF

resource "avi_virtualservice" "http_private_vs" {
   name = var.private_vs_name
   cloud_ref = data.avi_cloud.private_cloud.id
   vsvip_ref = avi_vsvip.private_vsvip.id
   pool_ref = avi_pool.private_http_pool.id
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


//4 - Create the GSLB service

// Define the GSLB service
resource "avi_gslbservice" "gslb_service_web" {
  // remove dependency that you are not going to use
  depends_on = [avi_virtualservice.http_private_vs]
  name = var.gslb_service_name
  domain_names = [var.gslb_domain_name]
  wildcard_match = false
  health_monitor_refs = [data.avi_healthmonitor.default_gslb_health_monitor.id]
  controller_health_status_enabled = false
  site_persistence_enabled = false
  is_federated = false
  use_edns_client_subnet = false
  enabled = true
  ttl = 1
  groups { 
      name = "${var.gslb_service_name}-pool"
      priority = 10
      algorithm = "GSLB_ALGORITHM_ROUND_ROBIN"
      consistent_hash_mask=31
      consistent_hash_mask6=31
      // private cloud
      members {
        cluster_uuid = element(data.avi_gslb.gslb_name.sites.*.cluster_uuid, index(data.avi_gslb.gslb_name.sites.*.name,var.gslb_site_name))
        vs_uuid = avi_virtualservice.http_private_vs.uuid
        fqdn = var.private_domain_name
        ratio = 1
        enabled = true
      }
    }
}
