variable "name" {
  description = "Globally unique name: 3-24 chars, lowercase letters and numbers only"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase letters/numbers."
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "replication_type" {
  description = "LRS, ZRS, GRS or GZRS"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS"], var.replication_type)
    error_message = "replication_type must be one of LRS, ZRS, GRS, GZRS."
  }
}

variable "containers" {
  description = "List of private blob containers to create"
  type        = list(string)
  default     = []
}

variable "soft_delete_days" {
  description = "Days to keep deleted blobs"
  type        = number
  default     = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
