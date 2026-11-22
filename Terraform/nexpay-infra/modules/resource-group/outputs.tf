output "name" {
  description = "Resource group name"
  value       = azurerm_resource_group.this.name
}

output "id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.this.id
}

output "location" {
  description = "Resource group region"
  value       = azurerm_resource_group.this.location
}
