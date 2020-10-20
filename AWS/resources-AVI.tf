// ----- AVI Section ----- //

/* STEPS
0- Create the AWS Cloud Connector
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

// Create AWS Cloud Connector
resource "avi_cloud" "aws_cloud" {
   depends_on = [aws_vpc.aws_vcn-vpc, aws_subnet.aws_vcn-private-sn]
   name = var.aws_cloud_name
   vtype = "CLOUD_AWS"
   dns_provider_ref = data.avi_ipamdnsproviderprofile.dns_profile.id
   dhcp_enabled = true
   license_tier = "ENTERPRISE"
   license_type = "LIC_CORES"
   
   aws_configuration {
      region = var.aws_region
      secret_access_key = var.aws_secret_key
      access_key_id = var.aws_access_key
      iam_assume_role = var.aws_role_arn
      route53_integration = false
      s3_encryption {}
      zones {
         availability_zone = var.aws_availability_zone
         mgmt_network_name = aws_subnet.aws_vcn-private-sn.tags.Name
         mgmt_network_uuid = aws_subnet.aws_vcn-private-sn.id
      }
      vpc = aws_vpc.aws_vcn-vpc.tags.Name
      vpc_id = aws_vpc.aws_vcn-vpc.id
   }
}

// 1- Define the HTTP Pool Servers

resource "avi_pool" "aws_http_pool" {
    depends_on = [aws_instance.aws_web-vm]
    name = var.aws_pool
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
    cloud_ref = avi_cloud.aws_cloud.id
    default_server_port = 80
    servers {
        ip {
            type = "V4"
            addr = aws_instance.aws_web-vm.private_ip
        }
    }
    analytics_policy {
     enable_realtime_metrics = true
   }
}

// 2- Define the VIP@

resource "avi_vsvip" "aws_vsvip" {
    depends_on = [aws_vpc.aws_vcn-vpc, aws_subnet.aws_vcn-private-sn, aws_instance.aws_velo-instance]
    name = var.aws_vs_name
    cloud_ref = avi_cloud.aws_cloud.id
    vip {
        auto_allocate_floating_ip = true
        auto_allocate_ip  = true
        subnet_uuid = aws_subnet.aws_vcn-private-sn.id
        subnet {
            ip_addr {
                addr = var.aws_private_sn
                type = "V4"
            }
            mask = "24"
        }
    }
    dns_info {
      fqdn = var.aws_domain_name
    }
}

// 3- Define the Virtual Services with WAF

resource "avi_virtualservice" "http_aws_vs" {
   depends_on = [avi_vsvip.aws_vsvip, aws_subnet.aws_vcn-private-sn, aws_instance.aws_velo-instance]
   name = var.aws_vs_name
   cloud_ref = avi_cloud.aws_cloud.id
   vsvip_ref = avi_vsvip.aws_vsvip.id
   pool_ref = avi_pool.aws_http_pool.id
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