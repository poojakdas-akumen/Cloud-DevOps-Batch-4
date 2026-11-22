variable "student_name" {
  description = "Your short name, lowercase letters only (used in resource names)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{3,10}$", var.student_name))
    error_message = "Use 3-10 lowercase letters, e.g. manoop."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "containers" {
  description = "Blob containers to create"
  type        = list(string)
  default     = ["images", "logs"]
}

variable "tags" {
  type = map(string)
  default = {
    course = "terraform-azure"
  }
}
