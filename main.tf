/*
Service Plan
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan

Function
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_function_app
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app

WebApp
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app

Storage account requirements
https://learn.microsoft.com/en-us/azure/azure-functions/storage-considerations

vnet integration
https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration#routes
*/
locals {
  tags = merge(var.tags, { ManagedByTerraform = "True" })
}

###########
# Resource Plan
###########

resource "azurerm_service_plan" "default" {
  name                         = var.name_sufix_append ? "${var.service_plan.name}-asp" : var.service_plan.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  os_type                      = var.service_plan.os_type
  sku_name                     = var.service_plan.sku_name
  worker_count                 = var.service_plan.worker_count
  maximum_elastic_worker_count = var.service_plan.maximum_elastic_worker_count
  app_service_environment_id   = var.service_plan.app_service_environment_id
  per_site_scaling_enabled     = var.service_plan.per_site_scaling_enabled
  zone_balancing_enabled       = var.service_plan.zone_balancing_enabled
  tags                         = local.tags
}

###########
# Networking
# Since each Service Plan instance requires dedicated a subnet, we decided to include subnet and nsg resources on this module
###########

data "azurerm_virtual_network" "default" {
  count               = var.vnet_integration == null ? 0 : 1
  name                = split("/", var.vnet_integration.vnet_id)[8]
  resource_group_name = split("/", var.vnet_integration.vnet_id)[4]
}

resource "azurerm_subnet" "default" {
  count                = var.vnet_integration == null ? 0 : 1
  name                 = var.name_sufix_append ? "${var.vnet_integration.asp_snet_name}-snet" : var.vnet_integration.asp_snet_name
  resource_group_name  = data.azurerm_virtual_network.default[0].resource_group_name
  virtual_network_name = data.azurerm_virtual_network.default[0].name
  address_prefixes     = [var.vnet_integration.asp_snet_prefix]

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_network_security_group" "default" {
  count               = try(var.vnet_integration.nsg_name, null) == null ? 0 : 1
  name                = var.name_sufix_append ? "${var.vnet_integration.nsg_name}-nsg" : var.vnet_integration.nsg_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "default" {
  count                     = try(var.vnet_integration.nsg_name, null) == null ? 0 : 1
  network_security_group_id = azurerm_network_security_group.default[0].id
  subnet_id                 = azurerm_subnet.default[0].id
}

resource "azurerm_subnet_route_table_association" "default" {
  count          = try(var.vnet_integration.route_table_id, null) == null ? 0 : 1
  subnet_id      = azurerm_subnet.default[0].id
  route_table_id = var.vnet_integration.route_table_id
}
