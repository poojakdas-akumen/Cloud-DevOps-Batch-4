provider "azurerm" {
  features {
    resource_group {
      # Safety: refuse to delete a resource group that still contains resources
      # Terraform doesn't know about.
      prevent_deletion_if_contains_resources = true
    }
  }
  # subscription_id comes from ARM_SUBSCRIPTION_ID (see scripts/set-azure-env.sh)
}
