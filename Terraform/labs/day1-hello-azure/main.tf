# DATA SOURCE: read information that already exists (who am I logged in as?)
data "azurerm_client_config" "current" {}

# LOCALS: computed values we reuse (like variables inside the code)
locals {
  rg_name = "rg-tf-day1-${var.student_name}"
  tags = merge(var.tags, {
    owner = var.student_name
  })
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# RESOURCE 1: resource group
resource "azurerm_resource_group" "lab" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

# RESOURCE 2: storage account - notice the REFERENCES to resource 1
resource "azurerm_storage_account" "lab" {
  name                     = "st${var.student_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.lab.name     # reference
  location                 = azurerm_resource_group.lab.location # reference
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

# RESOURCE 3: one container per list item (for_each)
resource "azurerm_storage_container" "lab" {
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.lab.id
  container_access_type = "private"
}
