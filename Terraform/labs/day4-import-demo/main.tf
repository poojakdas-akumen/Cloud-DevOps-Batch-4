# Step 1 (option A): write the resource blocks yourself so they MATCH the real resources.
# Step 1 (option B): delete this file and let Terraform write it:
#   terraform plan -generate-config-out=generated.tf

resource "azurerm_resource_group" "legacy" {
  name     = "rg-legacy-${var.student_name}"
  location = "centralindia"
  tags = {
    created_by = "portal"
  }
}

resource "azurerm_virtual_network" "legacy" {
  name                = "vnet-legacy-${var.student_name}"
  location            = azurerm_resource_group.legacy.location
  resource_group_name = azurerm_resource_group.legacy.name
  address_space       = ["10.60.0.0/16"]
}
