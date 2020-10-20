// Configure the AVI provider
provider "avi" {
    avi_username   = var.avi_username
    avi_password   = var.avi_password
    avi_controller = var.avi_controller
    avi_tenant     = var.avi_tenant // admin
    avi_version = "20.1.1"
}