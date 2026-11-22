# ----------------------------------------------------------------------------
# ROOT Terragrunt config - written ONCE, inherited by every unit below it.
# Every child terragrunt.hcl does:  include "root" { path = find_in_parent_folders("root.hcl") }
# ----------------------------------------------------------------------------

locals {
  # Read dev/env.hcl or prod/env.hcl depending on where the child lives
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  env           = local.env_vars.locals.env
  location      = local.env_vars.locals.location
  unique_suffix = local.env_vars.locals.unique_suffix
}

# 1) Remote state: one state file per unit, automatically named by folder path
#    dev/network/terraform.tfstate, prod/web-app/terraform.tfstate, ...
remote_state {
  backend = "azurerm"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    resource_group_name  = "rg-nexpay-tfstate"
    storage_account_name = "sttfnexpayXXXXXX" # <-- replace with your bootstrap output
    container_name       = "tfstate"
    key                  = "terragrunt/${path_relative_to_include()}/terraform.tfstate"
  }
}

# 2) Provider block generated into every unit (modules stay provider-free)
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

# 3) Inputs every unit receives (merged with the child's own inputs)
inputs = {
  location = local.location
  tags = {
    project     = "nexpay"
    environment = local.env
    managed_by  = "terragrunt"
  }
}
