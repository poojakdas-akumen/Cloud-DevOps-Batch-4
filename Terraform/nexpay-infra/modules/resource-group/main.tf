# The simplest possible module: one resource, a few inputs, a few outputs.
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
