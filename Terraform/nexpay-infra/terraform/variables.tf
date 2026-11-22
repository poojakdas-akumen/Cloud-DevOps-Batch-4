variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "centralindia"
}

variable "owner" {
  description = "Team or person responsible (goes into tags)"
  type        = string
  default     = "devops-team"
}

variable "assign_storage_role" {
  description = "Create the RBAC role assignment for the web app identity"
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "Additional tags merged into the common tags"
  type        = map(string)
  default     = {}
}
