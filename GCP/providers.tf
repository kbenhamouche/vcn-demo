// GCP provider
provider "google" {
  credentials = file(var.gcp_credentials)
  project = var.gcp_project // to change
  region  = var.gcp_region
  zone = var.gcp_zone
}

// AVI provider
provider "avi" {
    avi_username   = var.avi_username
    avi_password   = var.avi_password
    avi_controller = var.avi_controller
    avi_tenant     = var.avi_tenant // admin
    avi_version = "20.1.1"
}