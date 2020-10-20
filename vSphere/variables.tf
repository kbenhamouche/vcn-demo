// variables required for AVI connection.

variable "avi_controller" {
  default = "10.5.99.170"
}
variable "avi_username" {} 
variable "avi_password" {} 

variable "avi_tenant" {
  default = "admin"
}

#variables required for configuration of Avi for gcp deployment in a shared VIP with L7 and L4 Virtual Services.
variable "private_cloud_name" {
  default = "Default-Cloud"
}

variable "ipaddr_placement" {
  default = "172.58.2.0"
}

variable "private_pool" {
  default = "private-http-Pool"
}

variable "pool_private_server1" {
  default = "172.51.0.115"
}

variable "private_vs_name" {
  default = "web-private-cloud-vs"
}

variable "private_vs_vip" {
  default = "172.58.2.121"
}

variable "private_domain_name" {
  default = "web-private-cloud-vs.ovn.ca"
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