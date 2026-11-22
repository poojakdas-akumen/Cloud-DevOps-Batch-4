variable "name_prefix" {
  description = "Prefix used in resource names (e.g. nexpay-dev)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "VNet address space, e.g. [\"10.10.0.0/16\"]"
  type        = list(string)
}

variable "app_subnet_prefix" {
  description = "CIDR for the app subnet, e.g. 10.10.1.0/24"
  type        = string
}

variable "data_subnet_prefix" {
  description = "CIDR for the data subnet, e.g. 10.10.2.0/24"
  type        = string
}

variable "tags" {
  description = "Tags for all network resources"
  type        = map(string)
  default     = {}
}
