
// AWS
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_role_arn" {}

module "AWS" {
    source = "./AWS"
    aws_access_key = var.aws_access_key
    aws_secret_key = var.aws_secret_key
    aws_role_arn = var.aws_role_arn
    avi_username = var.avi_username
    avi_password = var.avi_password
}

//Azure
variable "azure_application_id" {}
variable "azure_auth_token" {}
variable "azure_tenant_id" {}
variable "azure_subscription_id" {}

module "Azure" {
    source = "./Azure"
    azure_application_id = var.azure_application_id
    azure_auth_token = var.azure_auth_token
    azure_tenant_id = var.azure_tenant_id
    azure_subscription_id = var.azure_subscription_id
    avi_username = var.avi_username
    avi_password = var.avi_password
}

//GCP
module "GCP" {
    source = "./GCP"
    avi_username = var.avi_username
    avi_password = var.avi_password
}


//AVI
variable "avi_username" {} 
variable "avi_password" {} 

module "vSphere" {
    source = "./vSphere"
    avi_username = var.avi_username
    avi_password = var.avi_password
}