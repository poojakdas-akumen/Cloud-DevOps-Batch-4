output "resource_group_name" {
  value = azurerm_resource_group.state.name
}

output "storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}

# Copy-paste this into terraform/backend.hcl
output "backend_hcl" {
  value = <<-EOT
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "nexpay/app.tfstate"
  EOT
}
