variable "location" {
  description = "The region where the Data Factory will be created. This parameter is required"
  type        = string
  default     = "northeurope"
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created. This parameter is required"
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to be applied to resources."
  type        = map(string)
  default     = null
}

variable "name_sufix_append" {
  description = "Define if all resources names should be appended with sufixes according to https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations."
  type        = bool
  default     = true
  nullable    = false
}

variable "service_plan" {
  type = object({
    name                         = string
    os_type                      = optional(string, "Linux")
    sku_name                     = optional(string, "B1")
    worker_count                 = optional(number, null)
    maximum_elastic_worker_count = optional(number, null)
    app_service_environment_id   = optional(string, null)
    per_site_scaling_enabled     = optional(bool, false)
    zone_balancing_enabled       = optional(bool, false)
  })
}

variable "windows_functions" {
  type = list(object({
    name                          = string #limit to 32 chars to avoid name colision in storage account
    storage_account_name          = string
    storage_account_access_key    = optional(string, null)
    storage_key_vault_secret_id   = optional(string, null)
    storage_uses_managed_identity = optional(string, null)
    builtin_logging_enabled       = optional(bool, true)
    enabled                       = optional(bool, true)
    https_only                    = optional(bool, true)
    public_network_access_enabled = optional(bool, false)
    virtual_network_subnet_id     = optional(string, null)
    zip_deploy_file               = optional(string, null)

    site_config = optional(object({
      always_on                              = optional(bool, true)
      api_definition_url                     = optional(string, null)
      api_management_api_id                  = optional(string, null)
      app_command_line                       = optional(string, null)
      app_scale_limit                        = optional(number, null)
      application_insights_connection_string = optional(string, null)
      application_insights_key               = optional(string, null)
      default_documents                      = optional(list(string), null)
      elastic_instance_minimum               = optional(number, null)
      ftps_state                             = optional(string, "FtpsOnly")
      health_check_path                      = optional(string, null)
      health_check_eviction_time_in_min      = optional(number, 2)
      http2_enabled                          = optional(bool, false)
      load_balancing_mode                    = optional(string, "LeastRequests")
      managed_pipeline_mode                  = optional(string, "Integrated")
      minimum_tls_version                    = optional(string, "1.2")
      pre_warmed_instance_count              = optional(number, null)
      remote_debugging_enabled               = optional(bool, false)
      remote_debugging_version               = optional(string, "VS2022")
      runtime_scale_monitoring_enabled       = optional(bool, false)
      scm_minimum_tls_version                = optional(string, "1.2")
      scm_use_main_ip_restriction            = optional(bool, false)
      use_32_bit_worker                      = optional(bool, false)
      vnet_route_all_enabled                 = optional(bool, true)
      vnet_content_share_enabled             = optional(bool, false)
      vnet_image_pull_enabled                = optional(bool, false)
      websockets_enabled                     = optional(bool, false)
      worker_count                           = optional(number, null)

      application_stack = optional(object({
        stack_runtime               = optional(string, ".NET")
        dotnet_version              = optional(string, "v7.0")
        use_dotnet_isolated_runtime = optional(bool, true)
        java_version                = optional(string, "17")
        node_version                = optional(string, "~18")
        powershell_core_version     = optional(string, "7.2")
        use_custom_runtime          = optional(bool, false)
      }), {}) #application_stack

      cors = optional(object({
        allowed_origins     = list(string)
        support_credentials = optional(bool, false)
      }), null) #cors

      ip_restriction = optional(list(object({
        name                      = string
        priority                  = number
        action                    = optional(string, "Allow")
        ip_address                = optional(string, null)
        service_tag               = optional(string, null)
        virtual_network_subnet_id = optional(string, null)
        headers = optional(object({
          x_azure_fdid      = optional(string, null)
          x_fd_health_probe = optional(string, null)
          x_forwarded_for   = optional(string, null)
          x_forwarded_host  = optional(string, null)
        }), null)
      })), null) #ip_restriction

      scm_ip_restriction = optional(list(object({
        name                      = string
        priority                  = number
        action                    = optional(string, "Allow")
        ip_address                = optional(string, null)
        service_tag               = optional(string, null)
        virtual_network_subnet_id = optional(string, null)
        headers = optional(object({
          x_azure_fdid      = optional(string, null)
          x_fd_health_probe = optional(string, null)
          x_forwarded_for   = optional(string, null)
          x_forwarded_host  = optional(string, null)
        }), null)
      })), null) #scm_ip_restriction 

    }), {}) ##site_config

    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), null)
    }), null) #identity

    backup = optional(object({
      storage_account_url = string
      schedule = optional(object({
        frequency_interval       = optional(number, 1)
        frequency_unit           = optional(string, "Day")
        keep_at_least_one_backup = optional(bool, true)
        retention_period_days    = optional(number, 31)
        start_time               = optional(string, "2023-01-01T23:00:00Z")
      }), {})
    }), null) #backup

    # storage_account = optional(list(object({
    #   name         = string
    #   access_key   = string
    #   account_name = string
    #   share_name   = string
    #   type         = optional(string, "AzureFiles")
    #   mount_path   = string
    # })), null)

  }))

  default = null
}
