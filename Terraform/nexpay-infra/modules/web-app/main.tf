resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  # Outbound traffic from the app goes through our VNet (null = no integration)
  virtual_network_subnet_id = var.subnet_id

  identity {
    type = "SystemAssigned" # lets the app access other Azure services without passwords
  }

  site_config {
    always_on           = var.always_on
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    health_check_path   = var.health_check_path

    application_stack {
      node_version = var.node_version
    }
  }

  app_settings = var.app_settings
  tags         = var.tags
}
