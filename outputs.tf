output "service_plan_id" {
  value = azurerm_service_plan.default.id
}

output "service_plan_kind" {
  value = azurerm_service_plan.default.kind
}

output "std_logic_app_ids" {
  value = try({ for key, value in azurerm_logic_app_standard.default : value.name => value.id }, null)
}

output "std_logic_app_identities" {
  value = try({ for key, value in azurerm_logic_app_standard.default : value.name => value.identity }, null)
}

output "std_logic_app_default_host_names" {
  value = try({ for key, value in azurerm_logic_app_standard.default : value.name => value.default_hostname }, null)
}

output "win_function_ids" {
  value = try({ for key, value in azurerm_windows_function_app.default : value.name => value.id }, null)
}

output "win_function_identities" {
  value = try({ for key, value in azurerm_windows_function_app.default : value.name => value.identity }, null)
}

output "win_function_default_host_names" {
  value = try({ for key, value in azurerm_windows_function_app.default : value.name => value.default_hostname }, null)
}
