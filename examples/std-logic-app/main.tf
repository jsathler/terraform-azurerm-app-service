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

    }
    appservice = {
      address_prefixes   = ["10.0.1.0/24"]
      nsg_create_default = false
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

module "private-zone" {
  source              = "jsathler/dns-zone/azurerm"
  version             = "0.0.1"
  resource_group_name = azurerm_resource_group.default.name
  zones = {
    "privatelink.azurewebsites.net" = {
      private = true
      vnets = {
        "${local.prefix}-vnet" = { id = module.vnet.vnet_id }
      }
    }
  }
}

module "standard-logic-app" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.default.name
  service_plan = {
    name     = local.prefix
    os_type  = "Windows"
    sku_name = "WS1"
    #zone_balancing_enabled = true
  }

  standard_logic_apps = [
    {
      name                          = "${local.prefix}-public"
      storage_account_name          = azurerm_storage_account.default.name
      storage_account_access_key    = azurerm_storage_account.default.primary_access_key
      public_network_access_enabled = true
      identity                      = {}
      #app_settings               = { WEBSITE_RUN_FROM_PACKAGE = 1 }

      site_config = {
        scm_use_main_ip_restriction = true

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
      name                       = "${local.prefix}-private"
      storage_account_name       = azurerm_storage_account.default.name
      storage_account_access_key = azurerm_storage_account.default.primary_access_key
      virtual_network_subnet_id  = module.vnet.subnet_ids["appservice-snet"]

      site_config = {
        cors = { allowed_origins = ["https://portal.azure.com", "https://example.com"] }
      }

      private_endpoint = {
        name      = "${local.prefix}-private-logic-site"
        subnet_id = module.vnet.subnet_ids.default-snet
        #application_security_group_ids = [azurerm_application_security_group.default["kv"].id]
        private_dns_zone_id = module.private-zone.private_zone_ids["privatelink.azurewebsites.net"]
      }
    }
  ]
}

output "standard-logic-app" {
  value = module.standard-logic-app
}
