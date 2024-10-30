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

variable "subnet1_name" {
  type        = string
  description = "subnet[1] name"
}

variable "service_principal_client_app_id" {
  type        = string
  description = "Service Principal Client AppID"
}

variable "service_principal_client_password" {
  type        = string
  description = "Service Principal Client password"
  sensitive   = true
}

variable "engine_docker_host_name" {
  type        = string
  description = "Identity Manager Engine within docker host"
}

variable "keyvault_slesvmpwd_name" {
  type        = string
  description = "Azure Docker Host user(azureuser) password name within keyvault"
}

variable "azure_postgres_server_name" {
  type        = string
  description = "Actual name of the Azure Postgres Server like idmpsqlserver.postgres.database.azure.com"
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

variable "keyvault_valuesyaml_name" {
  type        = string
  description = "Values yaml content within keyvault - directly proportional to values.yaml"
}

variable "keyvault_secretproperties_name" {
  type        = string
  description = "Secret properties content within keyvault - directly proportional to secret.properties"
}

variable "keyvault_dbadminloginpass_name" {
  type        = string
  description = "Azure PG DB Admin password within keyvault"
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

variable "keyvault_uawfedbuser_name" {
  type        = string
  description = "Azure PG Userapp and WFE DB user name within keyvault"
}

variable "keyvault_uawfedbuserpwd_name" {
  type        = string
  description = "Azure PG Userapp and WFE DB user password name within keyvault"
}

variable "keyvault_rptdbusersharepwd_name" {
  type        = string
  description = "Azure PG RPT DB user share password name within keyvault"
}

variable "keyvault_uadbname_name" {
  type        = string
  description = "Userapp DB Name"
}

variable "keyvault_wfedbname_name" {
  type        = string
  description = "WFE DB Name"
}

variable "keyvault_rptdbname_name" {
  type        = string
  description = "Reporting DB Name"
}

variable "terraform_local_ip" {
  type        = string
  description = "IP of the machine from where you are running your terraform"
}

variable "keyvault_crtfile_name" {
  type        = string
  description = "Cert file with calling name FQDN which is Common across userapp, reporting and osp"
}

variable "keyvault_keyfile_name" {
  type        = string
  description = "Cert file's key with calling name FQDN which is Common across userapp, reporting and osp"
}

variable "engine_data_disk_size" {
  type = string
  description = "Engine data disk size in GB"
}

variable "kubernetes_namespace" {
  type = string
  description = "Indicates the namespace intended to use in Kubernetes environment"
}

variable "custom_ldif_file_basename" {
  type = string
  description = "Indicates the basename of the custom ldif file"
}

variable "db_sku_name" {
  type = string
  description = "This option decides the performance and pricing for your database instance.  Choose the same after due diligence.  Refer Azure doc for more values with sku_name"
}

variable "db_version" {
  type = string
  description = "Indicates the postgresql version.  Possible values are 11,12 and 13 as of this release."
}

variable "db_storage_mb" {
  type = number
  description = "Indicates the storage size of Azure Postgres database in mb.  Accepted values for db_storage_mb during this release are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432."
}

variable "db_backup_retention_days" {
  type = number
  description = "Indicates the number of days the database backup should be retained.  Accepted values for db_backup_retention_days are between 7 and 35"
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

variable "aks_prefix" {
  type = string
  description = "The prefix for the resources created in the specified Azure Resource Group"
}

variable "aks_cluster_name" {
  type = string
  description = "The name for the AKS resources created in the specified Azure Resource Group. This variable overwrites the 'prefix' var (The 'prefix' var will still be applied to the dns_prefix if it is set)"
}

variable "aks_os_disk_size_gb" {
  type = number
  description = "Disk size of nodes in GBs."
}

variable "aks_sku_tier" {
  type = string
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid"
}

variable "aks_agents_min_count" {
  type = number
  description = "Minimum number of nodes in a pool"
}

variable "aks_agents_max_count" {
  type = number
  description = "Maximum number of nodes in a pool"
}

variable "aks_agents_max_pods" {
  type = number
  description = "The maximum number of pods that can run on each agent."
}

variable "aks_agents_pool_name" {
  type = string
  description = "The default Azure AKS agentpool (nodepool) name."
}

variable "aks_agents_type" {
  type = string
  description = "The type of Node Pool which should be created. Possible values are AvailabilitySet and VirtualMachineScaleSets."
}

variable "aks_agents_size" {
  type = string
  description = "The default virtual machine size for the Kubernetes agents"
}

variable "storage_account_name_for_tfstate" {
  type = string
  description = "Storage account created for storing terraform state files"
}

variable "aks_module_kubernetes_version" {
  type = string
  description = "The Kubernetes version available in the region"
}
