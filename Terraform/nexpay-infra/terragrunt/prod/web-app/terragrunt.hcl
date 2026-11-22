include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules//web-app"
}

dependency "rg" {
  config_path = "../resource-group"
  mock_outputs = {
    name = "rg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    app_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-app"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name                = "app-nexpay-tg-${include.root.locals.env}-${include.root.locals.unique_suffix}"
  resource_group_name = dependency.rg.outputs.name
  subnet_id           = dependency.network.outputs.app_subnet_id
  sku_name            = "P0v3"
  always_on           = true
  health_check_path   = "/"
  app_settings = {
    NODE_ENV = "${include.root.locals.env}"
  }
}
