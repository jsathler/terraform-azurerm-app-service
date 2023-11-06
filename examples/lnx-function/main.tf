locals {
  prefix = basename(path.cwd)
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${local.prefix}-rg"
  location = "northeurope"
}

module "linux-function" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.default.name
  service_plan = {
    name = local.prefix
    #sku_name               = "P0v3"
    #zone_balancing_enabled = true
  }
}
