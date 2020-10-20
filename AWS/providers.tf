// AWS provider
provider "aws" {
  region = var.aws_region
  shared_credentials_file = var.aws_credentials
  profile = "default"
}

// AVI provider
provider "avi" {
    avi_username   = var.avi_username
    avi_password   = var.avi_password
    avi_controller = var.avi_controller
    avi_tenant     = var.avi_tenant // admin
    avi_version = "20.1.1"
}