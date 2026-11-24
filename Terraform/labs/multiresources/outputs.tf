output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_name" {
  value = azurerm_subnet.subnet.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}