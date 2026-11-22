# Module: web-app

Creates a Linux App Service Plan + Linux Web App (Node.js) with HTTPS only, TLS 1.2,
FTPS disabled, a system-assigned managed identity and optional VNet integration.

```hcl
module "web_app" {
  source              = "../modules/web-app"
  name                = "app-nexpay-dev-ab12cd"
  resource_group_name = module.rg.name
  location            = module.rg.location
  sku_name            = "B1"
  subnet_id           = module.network.app_subnet_id
  app_settings = {
    NODE_ENV = "development"
  }
}
```

Outputs: `id`, `name`, `default_hostname`, `url`, `principal_id`.
