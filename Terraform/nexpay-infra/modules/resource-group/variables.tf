variable "name" {
  description = "Name of the resource group (e.g. rg-nexpay-dev)"
  type        = string

  validation {
    condition     = startswith(var.name, "rg-")
    error_message = "Resource group names must start with 'rg-' (naming standard)."
  }
}

variable "location" {
  description = "Azure region (e.g. centralindia)"
  type        = string
}

variable "tags" {
  description = "Tags applied to the resource group"
  type        = map(string)
  default     = {}
}
