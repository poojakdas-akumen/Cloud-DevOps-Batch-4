include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules//network"
}

# Read outputs from the resource-group unit (and deploy it first)
dependency "rg" {
  config_path = "../resource-group"

  # Fake values so 'plan' works before the RG really exists
  mock_outputs = {
    name     = "rg-mock"
    location = "centralindia"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name_prefix         = "nexpay-tg-${include.root.locals.env}"
  resource_group_name = dependency.rg.outputs.name
  address_space       = ["10.130.0.0/16"]
  app_subnet_prefix   = "10.130.1.0/24"
  data_subnet_prefix  = "10.130.2.0/24"
}
