variable "student_name" {
  type = string
}

resource "azurerm_resource_group" "lab" {
  name     = "rg-tf-day2-${var.student_name}"
  location = "centralindia"
  tags = {
    lab = "remote-state"
  }
}

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-day2-${var.student_name}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  address_space       = ["10.50.0.0/16"]
}

output "rg_id" {
  value = azurerm_resource_group.lab.id
}
