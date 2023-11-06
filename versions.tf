terraform {
  required_version = ">= 1.5.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.9.0"
    }
  }
}
