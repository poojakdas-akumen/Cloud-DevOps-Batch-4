# Module: network

Creates a VNet, an **app subnet** (delegated to App Service) and a **data subnet** protected by an NSG.

```hcl
module "network" {
  source              = "../modules/network"
  name_prefix         = "nexpay-dev"
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.10.0.0/16"]
  app_subnet_prefix   = "10.10.1.0/24"
  data_subnet_prefix  = "10.10.2.0/24"
}
```

Outputs: `vnet_id`, `vnet_name`, `app_subnet_id`, `data_subnet_id`.
