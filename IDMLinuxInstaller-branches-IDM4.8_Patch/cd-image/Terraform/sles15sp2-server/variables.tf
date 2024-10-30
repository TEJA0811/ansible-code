variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

#variable "resource_group_id" {
#	type = string
#	description = "resource group id"
#}

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

variable "engine_docker_host_name" {
  type        = string
  description = "Identity Manager Engine within docker host"
}

variable "keyvault_slesvmpwd_name" {
  type        = string
  description = "Azure Docker Host user(azureuser) password name within keyvault"
}

variable "keyvault_name" {
  type        = string
  description = "Keyvault created during silent file creation within conf gen image"
}

variable "keyvault_resource_group_name" {
  type        = string
  description = "Resource group created during silent file creation within conf gen image"
}

variable "keyvault_secret_name" {
  type        = string
  description = "Secret name within keyvault - directly proportional to silent.properties"
}

variable "image_registry_server" {
  type        = string
  description = "Registry server which holds Identity Manager docker images"
}

variable "image_registry_server_username" {
  type        = string
  description = "Registry server username"
}

variable "image_registry_server_password" {
  type        = string
  description = "Registry server password"
  sensitive   = true
}

variable "engine_image_name" {
  type        = string
  description = "Identity Manager Engine image name without server tag"
}

variable "keyvault_crtfile_name" {
  type        = string
  description = "Cert file with calling name FQDN which is Common across userapp, reporting and osp"
}

variable "engine_data_disk_size" {
  type = string
  description = "Engine data disk size in GB"
}

variable "vm_osdisk_account_tier" {
  type = string
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid."
}

variable "vm_osdisk_account_kind" {
  type = string
  description = "Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2."
}

variable "vm_osdisk_account_replication_type" {
  type = string
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS."
}

variable "vm_osdisk_access_tier" {
  type = string
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool for vm_osdisk_access_tier"
}

variable "vm_osdisk_name" {
  type = string
  description = "Virtual Machine Operating System disk name"
}

variable "vm_osdisk_storage_account_type" {
  type = string
  description = "Indicates Operating system storage disk type. Possible values for vm_osdisk_storage_account_type are Standard_LRS, StandardSSD_LRS and Premium_LRS."
}

variable "vm_datadisk_storage_account_type" {
  type = string
  description = "Indicates the persistence layer for Identity manager Engine within the docker host.  Possible values for vm_datadisk_storage_account_type are Standard_LRS, StandardSSD_ZRS, Premium_LRS, Premium_ZRS, StandardSSD_LRS or UltraSSD_LRS."
}
