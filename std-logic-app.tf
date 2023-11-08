#######
# Standard Logic Apps
#######

resource "azurerm_logic_app_standard" "default" {
  for_each                   = var.standard_logic_apps == null ? {} : { for key, value in var.standard_logic_apps : value.name => value }
  name                       = var.name_sufix_append ? "${each.key}-logic" : each.key
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_service_plan.default.id
  app_settings               = each.value.app_settings
  bundle_version             = each.value.bundle_version
  client_affinity_enabled    = each.value.client_affinity_enabled
  client_certificate_mode    = each.value.client_certificate_mode
  enabled                    = each.value.enabled
  https_only                 = each.value.https_only
  storage_account_name       = each.value.storage_account_name
  storage_account_access_key = each.value.storage_account_access_key
  storage_account_share_name = each.value.storage_account_share_name
  use_extension_bundle       = each.value.use_extension_bundle
  version                    = each.value.version
  virtual_network_subnet_id  = try(azurerm_subnet.default[0].id, null)
  tags                       = local.tags

  # dynamic "connection_string" {
  #   for_each = []
  #   content {
  #     name  = null
  #     type  = null
  #     value = null
  #   }
  # }  

  dynamic "identity" {
    for_each = each.value.identity == null ? [] : [each.value.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  site_config {
    always_on                        = each.value.site_config.always_on
    app_scale_limit                  = each.value.site_config.app_scale_limit
    dotnet_framework_version         = each.value.site_config.dotnet_framework_version
    elastic_instance_minimum         = each.value.site_config.elastic_instance_minimum
    ftps_state                       = each.value.site_config.ftps_state
    health_check_path                = each.value.site_config.health_check_path
    http2_enabled                    = each.value.site_config.http2_enabled
    scm_use_main_ip_restriction      = each.value.site_config.scm_use_main_ip_restriction
    scm_min_tls_version              = each.value.site_config.scm_min_tls_version
    scm_type                         = each.value.site_config.scm_type
    linux_fx_version                 = each.value.site_config.linux_fx_version
    min_tls_version                  = each.value.site_config.min_tls_version
    pre_warmed_instance_count        = each.value.site_config.pre_warmed_instance_count
    runtime_scale_monitoring_enabled = each.value.site_config.runtime_scale_monitoring_enabled
    use_32_bit_worker_process        = each.value.site_config.use_32_bit_worker_process
    vnet_route_all_enabled           = each.value.site_config.vnet_route_all_enabled
    websockets_enabled               = each.value.site_config.websockets_enabled

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

  }
}

resource "azapi_update_resource" "logic_app_standard" {
  depends_on = [azurerm_logic_app_standard.default]
  for_each   = var.standard_logic_apps == null ? {} : { for key, value in var.standard_logic_apps : value.name => value }
  type       = "Microsoft.Web/sites@2022-09-01"
  name       = var.name_sufix_append ? "${each.key}-logic" : each.key
  parent_id  = split("/providers/", azurerm_service_plan.default.id)[0]
  body = jsonencode({
    properties = {
      vnetContentShareEnabled = each.value.site_config.vnet_content_share_enabled
      vnetImagePullEnabled    = each.value.site_config.vnet_image_pull_enabled
      publicNetworkAccess     = each.value.public_network_access_enabled ? "Enabled" : "Disabled"
    }
  })
}

#######
# Create private endpoint for sites
#######

module "private-endpoint-std-logicapp" {
  for_each            = var.standard_logic_apps == null ? {} : { for key, value in var.standard_logic_apps : value.name => value if value.private_endpoint != null }
  source              = "jsathler/private-endpoint/azurerm"
  version             = "0.0.2"
  location            = var.location
  resource_group_name = var.resource_group_name
  name_sufix_append   = var.name_sufix_append
  tags                = local.tags

  private_endpoint = {
    name                           = each.value.private_endpoint.name
    subnet_id                      = each.value.private_endpoint.subnet_id
    private_connection_resource_id = azurerm_logic_app_standard.default[each.key].id
    subresource_name               = "sites"
    application_security_group_ids = each.value.private_endpoint.application_security_group_ids
    private_dns_zone_id            = each.value.private_endpoint.private_dns_zone_id
  }
}
