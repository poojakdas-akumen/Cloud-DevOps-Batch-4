data "azurerm_resource_group" "rg" {
  name = "pooja_devops"
}

resource "azurerm_storage_account" "storage" {

  name                     = "pooja${terraform.workspace}stg01"

  resource_group_name      = data.azurerm_resource_group.rg.name

  location                 = var.location

  account_tier             = var.storage_tier

  account_replication_type = var.replication_type

}