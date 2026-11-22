locals {
  # The workspace name IS the environment: dev, staging, prod
  env = terraform.workspace

  # Per-environment settings. Selecting a workspace automatically picks the right block.
  env_config = {
    dev = {
      address_space       = ["10.10.0.0/16"]
      app_subnet_prefix   = "10.10.1.0/24"
      data_subnet_prefix  = "10.10.2.0/24"
      app_sku             = "B1"
      always_on           = false
      storage_replication = "LRS"
    }
    staging = {
      address_space       = ["10.20.0.0/16"]
      app_subnet_prefix   = "10.20.1.0/24"
      data_subnet_prefix  = "10.20.2.0/24"
      app_sku             = "B1"
      always_on           = true
      storage_replication = "ZRS"
    }
    prod = {
      address_space       = ["10.30.0.0/16"]
      app_subnet_prefix   = "10.30.1.0/24"
      data_subnet_prefix  = "10.30.2.0/24"
      app_sku             = "P0v3"
      always_on           = true
      storage_replication = "GRS"
    }
  }

  config = lookup(local.env_config, local.env, local.env_config["dev"])

  name_prefix = "nexpay-${local.env}"
  suffix      = random_string.suffix.result

  common_tags = merge(var.extra_tags, {
    project     = "nexpay"
    environment = local.env
    managed_by  = "terraform"
    owner       = var.owner
  })
}
