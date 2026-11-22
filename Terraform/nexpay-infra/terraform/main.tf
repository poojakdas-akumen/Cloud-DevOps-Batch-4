# ----------------------------------------------------------------------------
# NexPay - root configuration
# One codebase, many environments (workspaces: dev / staging / prod)
# ----------------------------------------------------------------------------

# Guard: stop anyone from deploying into the "default" workspace by mistake
resource "terraform_data" "workspace_guard" {
  lifecycle {
    precondition {
      condition     = contains(keys(local.env_config), terraform.workspace)
      error_message = "Select a workspace first: terraform workspace select dev|staging|prod (current: ${terraform.workspace})."
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

module "rg" {
  source   = "../modules/resource-group"
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source              = "../modules/network"
  name_prefix         = local.name_prefix
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = local.config.address_space
  app_subnet_prefix   = local.config.app_subnet_prefix
  data_subnet_prefix  = local.config.data_subnet_prefix
  tags                = local.common_tags
}

module "storage" {
  source              = "../modules/storage-account"
  name                = "stnexpay${local.env}${local.suffix}"
  resource_group_name = module.rg.name
  location            = module.rg.location
  replication_type    = local.config.storage_replication
  containers          = ["invoices", "receipts"]
  tags                = local.common_tags
}

module "web_app" {
  source              = "../modules/web-app"
  name                = "app-${local.name_prefix}-${local.suffix}"
  resource_group_name = module.rg.name
  location            = module.rg.location
  sku_name            = local.config.app_sku
  always_on           = local.config.always_on
  subnet_id           = module.network.app_subnet_id
  health_check_path   = "/"
  tags                = local.common_tags

  app_settings = {
    NODE_ENV             = local.env
    STORAGE_ACCOUNT_NAME = module.storage.name
    STORAGE_BLOB_URL     = module.storage.primary_blob_endpoint
  }
}

# The web app's managed identity may read/write blobs - no keys, no passwords.
# Needs Owner or "User Access Administrator" on the subscription/RG.
# Set assign_storage_role = false if your account only has Contributor.
resource "azurerm_role_assignment" "app_to_storage" {
  count = var.assign_storage_role ? 1 : 0

  scope                = module.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.web_app.principal_id
}
