# BOOTSTRAP: creates the storage that will hold Terraform state for everything else.
# This folder itself uses LOCAL state (chicken-and-egg: the backend doesn't exist yet).
# Run once per subscription:  terraform init && terraform apply

terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  # subscription_id is read from the ARM_SUBSCRIPTION_ID environment variable
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "state" {
  name     = "rg-nexpay-tfstate"
  location = var.location
  tags = {
    project    = "nexpay"
    purpose    = "terraform-state"
    managed_by = "terraform"
  }
}

resource "azurerm_storage_account" "state" {
  name                            = "sttfnexpay${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS" # state is precious: keep a copy in another region
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true # recover an older state file if something goes wrong
    delete_retention_policy {
      days = 30
    }
  }

  # Protect against an accidental 'terraform destroy'.
  # Remove this block ONLY when you really want to delete the state storage.
  lifecycle {
    prevent_destroy = true
  }

  tags = azurerm_resource_group.state.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
