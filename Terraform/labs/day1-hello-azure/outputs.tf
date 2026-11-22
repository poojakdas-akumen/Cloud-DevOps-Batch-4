output "resource_group_name" {
  value = azurerm_resource_group.lab.name
}

output "storage_account_name" {
  value = azurerm_storage_account.lab.name
}

output "container_names" {
  value = [for c in azurerm_storage_container.lab : c.name]
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "storage_primary_key" {
  value     = azurerm_storage_account.lab.primary_access_key
  sensitive = true # hidden in CLI output (but still stored in state!)
}
