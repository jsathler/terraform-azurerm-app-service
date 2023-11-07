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

resource "azurerm_windows_function_app" "default" {
  for_each            = { for key, value in var.windows_functions : value.name => value }
  name                = var.name_sufix_append ? "${each.key}-func" : each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.default.id

  storage_account_name          = each.value.storage_account_name
  storage_account_access_key    = each.value.storage_account_access_key
  storage_key_vault_secret_id   = each.value.storage_key_vault_secret_id
  storage_uses_managed_identity = each.value.storage_uses_managed_identity

  builtin_logging_enabled       = each.value.builtin_logging_enabled
  enabled                       = each.value.enabled
  https_only                    = each.value.https_only
  public_network_access_enabled = each.value.public_network_access_enabled
  virtual_network_subnet_id     = each.value.virtual_network_subnet_id
  zip_deploy_file               = each.value.zip_deploy_file
  functions_extension_version   = each.value.functions_extension_version
  tags                          = local.tags

  #https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings
  app_settings = each.value.app_settings

  site_config {
    always_on                              = each.value.site_config.always_on
    api_definition_url                     = each.value.site_config.api_definition_url
    api_management_api_id                  = each.value.site_config.api_management_api_id
    app_command_line                       = each.value.site_config.app_command_line
    app_scale_limit                        = each.value.site_config.app_scale_limit
    application_insights_connection_string = each.value.site_config.application_insights_connection_string
    application_insights_key               = each.value.site_config.application_insights_key
    default_documents                      = each.value.site_config.default_documents
    elastic_instance_minimum               = each.value.site_config.elastic_instance_minimum
    ftps_state                             = each.value.site_config.ftps_state
    health_check_path                      = each.value.site_config.health_check_path
    health_check_eviction_time_in_min      = each.value.site_config.health_check_path == null ? null : each.value.site_config.health_check_eviction_time_in_min
    http2_enabled                          = each.value.site_config.http2_enabled
    load_balancing_mode                    = each.value.site_config.load_balancing_mode
    managed_pipeline_mode                  = each.value.site_config.managed_pipeline_mode
    minimum_tls_version                    = each.value.site_config.minimum_tls_version
    pre_warmed_instance_count              = each.value.site_config.pre_warmed_instance_count
    remote_debugging_enabled               = each.value.site_config.remote_debugging_enabled
    remote_debugging_version               = each.value.site_config.remote_debugging_version
    runtime_scale_monitoring_enabled       = each.value.site_config.runtime_scale_monitoring_enabled
    scm_minimum_tls_version                = each.value.site_config.scm_minimum_tls_version
    scm_use_main_ip_restriction            = each.value.site_config.scm_use_main_ip_restriction
    use_32_bit_worker                      = each.value.site_config.use_32_bit_worker
    vnet_route_all_enabled                 = each.value.site_config.vnet_route_all_enabled
    websockets_enabled                     = each.value.site_config.websockets_enabled
    worker_count                           = each.value.site_config.worker_count

    application_stack {
      dotnet_version              = each.value.site_config.application_stack.stack_runtime == ".NET" ? each.value.site_config.application_stack.dotnet_version : null
      use_dotnet_isolated_runtime = each.value.site_config.application_stack.stack_runtime == ".NET" ? each.value.site_config.application_stack.use_dotnet_isolated_runtime : null
      java_version                = each.value.site_config.application_stack.stack_runtime == "Java" ? each.value.site_config.application_stack.java_version : null
      node_version                = each.value.site_config.application_stack.stack_runtime == "Node.js" ? each.value.site_config.application_stack.node_version : null
      powershell_core_version     = each.value.site_config.application_stack.stack_runtime == "PowerShell" ? each.value.site_config.application_stack.powershell_core_version : null
      use_custom_runtime          = each.value.site_config.application_stack.stack_runtime == "Custom" ? each.value.site_config.application_stack.use_custom_runtime : null
    }

    dynamic "cors" {
      for_each = each.value.site_config.cors == null ? [] : [each.value.site_config.cors]
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = each.value.site_config.ip_restriction == null ? {} : { for key, value in each.value.site_config.ip_restriction : value.name => value }
      content {
        name                      = ip_restriction.key
        priority                  = ip_restriction.value.priority
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = try(each.value.site_config.ip_restriction.headers, null) == null ? {} : { for key, value in each.value.site_config.ip_restriction.headers : value.name => value }
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = each.value.site_config.scm_ip_restriction != null && each.value.site_config.scm_use_main_ip_restriction != false ? { for key, value in each.value.site_config.scm_ip_restriction : value.name => value } : {}
      content {
        name                      = scm_ip_restriction.key
        priority                  = scm_ip_restriction.value.priority
        action                    = scm_ip_restriction.value.action
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = try(each.value.site_config.scm_ip_restriction.headers, null) == null ? {} : { for key, value in each.value.site_config.scm_ip_restriction.headers : value.name => value }
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }

    # Feature not available for Function apps
    # dynamic "app_service_logs" {
    #   for_each = []
    #   content {
    #     disk_quota_mb         = app_service_logs.value.disk_quota_mb
    #     retention_period_days = app_service_logs.value.retention_period_days
    #   }
    # }    
  }

  dynamic "backup" {
    for_each = each.value.backup == null ? [] : [each.value.backup]
    content {
      name                = var.name_sufix_append ? "${each.key}-func" : each.key
      enabled             = true
      storage_account_url = backup.value.storage_account_url

      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = backup.value.schedule.keep_at_least_one_backup
        retention_period_days    = backup.value.schedule.retention_period_days
        start_time               = backup.value.schedule.start_time
      }
    }
  }

  #   connection_string {
  #     name  = null
  #     type  = null
  #     value = null
  #   }

  #You will may need the following roles: Storage Account Contributor, Storage Blob Data Owner, Storage Queue Data Contributor, Storage Table Data Contributor
  #https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob&pivots=programming-language-csharp#connecting-to-host-storage-with-an-identity
  dynamic "identity" {
    for_each = each.value.identity == null ? [] : [each.value.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  #   sticky_settings {
  #     app_setting_names       = each.value.sticky_settings.app_setting_names
  #     connection_string_names = each.value.sticky_settings.connection_string_names
  #   }


  # This functionality is current only available when running on Linux.
  # https://learn.microsoft.com/en-us/azure/azure-functions/storage-considerations?tabs=azure-cli#mount-file-shares
  #   storage_account {
  #     access_key   = each.value.storage_account.access_key
  #     account_name = each.value.storage_account.account_name
  #     name         = each.value.storage_account.name
  #     share_name   = each.value.storage_account.share_name
  #     type         = each.value.storage_account.type
  #     mount_path   = each.value.storage_account.mount_path
  #   }

}

resource "azapi_update_resource" "windows_function_app_vnet" {
  depends_on = [azurerm_windows_function_app.default]
  for_each   = { for key, value in var.windows_functions : value.name => value }
  type       = "Microsoft.Web/sites@2022-09-01"
  name       = var.name_sufix_append ? "${each.key}-func" : each.key
  parent_id  = split("/providers/", azurerm_service_plan.default.id)[0]
  body = jsonencode({
    properties = {
      vnetContentShareEnabled = each.value.site_config.vnet_content_share_enabled
      vnetImagePullEnabled    = each.value.site_config.vnet_image_pull_enabled
    }
  })
}

#######
# Create private endpoint for sites
#######

module "private-endpoint" {
  for_each            = { for key, value in var.windows_functions : value.name => value if value.private_endpoint != null }
  source              = "jsathler/private-endpoint/azurerm"
  version             = "0.0.1"
  location            = var.location
  resource_group_name = var.resource_group_name
  name_sufix_append   = var.name_sufix_append
  tags                = local.tags

  private_endpoint = {
    name                           = each.value.private_endpoint.name
    subnet_id                      = each.value.private_endpoint.subnet_id
    private_connection_resource_id = azurerm_windows_function_app.default[each.key].id
    subresource_name               = "sites"
    application_security_group_ids = each.value.private_endpoint.application_security_group_ids
    private_dns_zone_id            = each.value.private_endpoint.private_dns_zone_id
  }
}
