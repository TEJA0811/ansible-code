variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

variable "resource_group_location" {
  type        = string
  description = "resource group location"
}

variable "virtual_network_name" {
  type        = string
  description = "virtual network name"
}

variable "subnet0_name" {
  type        = string
  description = "subnet[0] name"
}

variable "subnet1_name" {
  type        = string
  description = "subnet[1] name"
}

variable "common_tags" {
  default     = {}
  description = "Common Tags to apply on Azure Resources"
  type        = map(string)
}