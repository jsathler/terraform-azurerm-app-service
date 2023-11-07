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
