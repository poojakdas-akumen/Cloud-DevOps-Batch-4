# MODERN WAY (Terraform 1.5+): declare imports in code. They show up in 'terraform plan'.
data "azurerm_client_config" "current" {}

import {
  to = azurerm_resource_group.legacy
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-legacy-${var.student_name}"
}

import {
  to = azurerm_virtual_network.legacy
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-legacy-${var.student_name}/providers/Microsoft.Network/virtualNetworks/vnet-legacy-${var.student_name}"
}
