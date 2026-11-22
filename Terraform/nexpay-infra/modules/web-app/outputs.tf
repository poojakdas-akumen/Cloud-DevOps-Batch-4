output "id" {
  value = azurerm_linux_web_app.this.id
}

output "name" {
  value = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  value = azurerm_linux_web_app.this.default_hostname
}

output "url" {
  value = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "principal_id" {
  description = "Managed identity principal ID (use it for role assignments)"
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}
