variable "name" {
  description = "Globally unique web app name (becomes <name>.azurewebsites.net)"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"

  validation {
    condition     = contains(["B1", "B2", "S1", "P0v3", "P1v3", "P2v3"], var.sku_name)
    error_message = "Allowed SKUs: B1, B2, S1, P0v3, P1v3, P2v3 (Basic or higher is needed for VNet integration)."
  }
}

variable "always_on" {
  description = "Keep the app loaded (recommended for prod)"
  type        = bool
  default     = true
}

variable "node_version" {
  type    = string
  default = "20-lts"
}

variable "health_check_path" {
  type    = string
  default = null
}

variable "subnet_id" {
  description = "Delegated subnet ID for VNet integration (null to skip)"
  type        = string
  default     = null
}

variable "app_settings" {
  description = "Environment variables for the app"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
