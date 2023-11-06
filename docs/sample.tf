module "eventhub" {
  source              = "jsathler/eventhub/azurerm"
  resource_group_name = azurerm_resource_group.default.name

  namespace = {
    name                     = local.prefix
    auto_inflate_enabled     = true
    maximum_throughput_units = 3

    sas_key_auth = [
      { name = "app1", send = true },
      { name = "app2", manage = true }
    ]

    rbac_auth = [{ object_id = data.azurerm_client_config.default.object_id, sender = true }]
  }

  network_rules = {
    public_network_access_enabled = true
  }

  eventhubs = [
    {
      name = "${local.prefix}-1"
      sas_key_auth = [
        { name = "app3", send = true, listen = true },
        { name = "app4", manage = true },
        { name = "app5", listen = true }
      ]
      rbac_auth = [{ object_id = data.azurerm_client_config.default.object_id, owner = true }]
    },
    {
      name            = "${local.prefix}-2"
      partition_count = 2
      consumer_groups = [{ name = "group1" }, { name = "group2" }]
      rbac_auth       = [{ object_id = data.azurerm_client_config.default.object_id, receiver = true }]
    }
  ]
}
