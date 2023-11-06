locals {
  prefix = basename(path.cwd)
}

provider "azurerm" {
  features {}
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "azurerm_resource_group" "default" {
  name     = "${local.prefix}-rg"
  location = "northeurope"
}

resource "azurerm_storage_account" "default" {
  name                     = "${lower(replace(local.prefix, "/[^A-Za-z0-9]/", ""))}st"
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "default" {
  name                 = "backup"
  storage_account_name = azurerm_storage_account.default.name
}

resource "time_rotating" "default" {
  rotation_years = 10
}

#https://learn.microsoft.com/en-us/rest/api/storageservices/create-service-sas
data "azurerm_storage_account_blob_container_sas" "default" {
  connection_string = azurerm_storage_account.default.primary_connection_string
  container_name    = azurerm_storage_container.default.name
  start             = time_rotating.default.id
  expiry            = timeadd(time_rotating.default.id, "${10 * 365 * 24}h") #10 years

  permissions {
    read   = true
    write  = true
    delete = true
    list   = true
    add    = false
    create = false
  }
}

module "vnet" {
  source              = "jsathler/network/azurerm"
  version             = "0.0.2"
  name                = local.prefix
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    default = {
      address_prefixes   = ["10.0.0.0/24"]
      nsg_create_default = false
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

locals {
  storage_account_backup_url = "https://${azurerm_storage_account.default.name}.blob.core.windows.net/${azurerm_storage_container.default.name}${data.azurerm_storage_account_blob_container_sas.default.sas}"
}

# output "SAS" {
#   value = nonsensitive(local.storage_account_backup_url)
# }

module "windows-function" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.default.name
  service_plan = {
    name    = local.prefix
    os_type = "Windows"
    #sku_name               = "P0v3"
    #zone_balancing_enabled = true
  }

  windows_functions = [
    {
      name                       = "${local.prefix}-dotnet"
      storage_account_name       = azurerm_storage_account.default.name
      storage_account_access_key = azurerm_storage_account.default.primary_access_key
      virtual_network_subnet_id  = module.vnet.subnet_ids["default-snet"]
      backup                     = { storage_account_url = local.storage_account_backup_url }
    },
    {
      name                       = "${local.prefix}-node"
      storage_account_name       = azurerm_storage_account.default.name
      storage_account_access_key = azurerm_storage_account.default.primary_access_key
      virtual_network_subnet_id  = module.vnet.subnet_ids["default-snet"]
      site_config = {
        application_stack = {
          stack_runtime = "Node.js"
        }
        cors = { allowed_origins = ["https://portal.azure.com", "https://example.com"] }
      }
    },
    {
      name                       = "${local.prefix}-java"
      storage_account_name       = azurerm_storage_account.default.name
      storage_account_access_key = azurerm_storage_account.default.primary_access_key
      #virtual_network_subnet_id  = module.vnet.subnet_ids["default-snet"]
      public_network_access_enabled = true
      site_config = {
        application_stack = {
          stack_runtime = "Java"
        }

        ip_restriction = [
          {
            name       = "my-ip"
            priority   = 100
            ip_address = "${chomp(data.http.myip.response_body)}/32"
          },
          {
            name                      = "my-subnet"
            priority                  = 200
            virtual_network_subnet_id = module.vnet.subnet_ids["default-snet"]
          },
          {
            name        = "azure-databricks"
            priority    = 300
            service_tag = "AzureDatabricks"
          }
        ]
      }
    },
    {
      name                       = "${local.prefix}-psh"
      storage_account_name       = azurerm_storage_account.default.name
      storage_account_access_key = azurerm_storage_account.default.primary_access_key
      virtual_network_subnet_id  = module.vnet.subnet_ids["default-snet"]
      site_config = {
        application_stack = {
          stack_runtime = "PowerShell"
        }
      }
    }
  ]
}
