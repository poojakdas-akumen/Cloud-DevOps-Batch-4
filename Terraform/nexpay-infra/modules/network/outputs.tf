output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "app_subnet_id" {
  description = "Subnet ID for App Service VNet integration"
  value       = azurerm_subnet.app.id
}

output "data_subnet_id" {
  value = azurerm_subnet.data.id
}
