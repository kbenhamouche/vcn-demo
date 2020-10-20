// Azure variables

variable "azure_application_id" {} //export TF_VAR_azure_application_id

variable "azure_auth_token" {} //export TF_VAR_azure_auth_token

variable "azure_tenant_id" {} //export TF_VAR_azure_tenant_id

variable "azure_subscription_id" {} //export TF_VAR_azure_subscription_id

variable "azure_region" {
  description = "Enter your region (example: canadacentral for Canada Central)"
  default = "canadacentral"
}

variable "azure_vnet_cidr_block" {
  description = "Enter the VNET subnet (example: 172.19.0.0/16)"
  default = "172.19.0.0/16"
}

variable "azure_public_sn_cidr_block" {
  description = "Enter the public subnet (example: 172.19.0.0/24)"
  default = "172.19.0.0/24"
}

variable "azure_private_sn_cidr_block" {
  description = "Enter the private subnet (example: 172.19.100.0/24)"
  default = "172.19.100.0/24"
}

variable "azure_private_ip" {
  description = "Enter the private IP for the LAN interface (example: 172.19.100.5)"
  default = "172.19.100.100"
}

variable "azure_public_ip" {
  description = "Enter the public IP for the WAN interface (example: 172.19.0.5)"
  default = "172.19.0.5"
}

variable "instance_type" {
  description = "Enter the instance type (example: Standard_D3_v2)"
  default = "Standard_D3_v2"
}

variable "vce_username" {
  description = "Enter the username for ssh access"
  default = "vce"
}

variable "vce_password" {
  description = "Enter the password for the ssh access"
  default = "VeloCloud123"
}

// AVI variables
variable "avi_controller" {
  default = "10.5.99.170"
}
variable "avi_username" {} 
variable "avi_password" {} 

variable "avi_tenant" {
  default = "admin"
}

variable "azure_cloud_name" {
  default = "Azure"
}

variable "azure_pool" {
  default = "azure-http-Pool"
}

variable "azure_vs_name" {
  default = "web-azure-cloud-vs"
}

variable "azure_private_sn_vip" {
  default = "172.19.100.0"
}

variable "azure_domain_name" {
  default = "web-azure-cloud-vs.ovn.ca"
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