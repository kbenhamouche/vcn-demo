terraform {
  required_providers {
    avi = {
      source = "terraform-providers/avi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
  required_version = ">= 0.13"
}
