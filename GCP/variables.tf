// GCP variables

variable "gcp_credentials" {
  default = "~/gcp-auth.json"
}
variable "gcp_project" {
  default = "direct-electron-288211"
}
variable "gcp_region" {
  description = "Enter your region (example: northamerica-northeast1 for Canada)"
  default = "northamerica-northeast1"
}

variable "gcp_zone" {
  description = "Enter your AWS availability zone (example: northamerica-northeast1a for Canada)"
  default = "northamerica-northeast1-a"
}

variable "gcp_public_sn_cidr_block" {
  description = "Enter the public subnet (example: 172.18.0.0/24)"
  default = "172.18.0.0/24"
}

variable "gcp_private_sn_cidr_block" {
  description = "Enter the private subnet (example: 172.18.100.0/24)"
  default = "172.18.100.0/24"
}

variable "gcp_mngt_sn_cidr_block" {
  description = "Enter the private subnet (example: 172.18.1.0/24)"
  default = "172.18.1.0/24"
}

variable "gcp_private_ip" {
  description = "Enter the private IP for the LAN interface (example: 172.18.100.100) - this IP has to be configured in VCO/Edge/Device as Corporate IP"
  default = "172.18.100.100"
}

variable "gcp_instance_type" {
  description = "Enter the instance type (example: n1-standard-4)"
  default = "n1-standard-4"
}

// AVI Variables

variable "avi_controller" {
  default = "10.5.99.170"
}
variable "avi_username" {} 
variable "avi_password" {} 

variable "avi_tenant" {
  default = "admin"
}

variable "gcp_cloud_name" {
  default = "GCP"
}

variable "gcp_pool" {
  default = "gcp-http-Pool"
}

variable "gcp_vs_name" {
  default = "web-gcp-cloud-vs"
}

variable "gcp_vs_vip" {
  default = "172.58.2.120"
}

variable "gcp_domain_name" {
  default = "web-gcp-cloud-vs.ovn.ca"
}

variable "gslb_default_name" {
  default = "Default"
}
variable "gslb_service_name" {
  default = "GSLB-Web"
}

variable "gslb_domain_name" {
  default = "web-cloud.ovn.ca"
}

variable "gslb_site_name" {
  default = "GSLB-Private-Cloud"
}
