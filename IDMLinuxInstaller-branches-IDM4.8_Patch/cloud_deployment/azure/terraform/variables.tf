###########################################################################
#                        Resource Group Variables                         #
###########################################################################
variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "resource_group_location" {
  type        = string
  description = "Resource group location"
}

variable "resource_group_exists" {
  type        = bool
  default     = false
  description = "Resource group already exists?"
}

##############################################################################
#                          Key Vault Variables                               #
##############################################################################
variable "keyvault_name" {
  type        = string
  description = "Name of the Key Vault"
}

variable "keyvault_exists" {
  type        = bool
  default     = false
  description = "Key Vault already exists?"
}


###################################################################################
#                    Docker Registry credentials                                  #
###################################################################################
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

###################################################################################
#                          Virtual Network and Subnets                            #
###################################################################################


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

###################################################################################
#                             Azure Kubernetes Service                            #
###################################################################################

variable "aks_cluster_name" {
  type        = string
  description = "Name of the Azure Kubernetes Cluster"
}

variable "aks_kubernetes_namespace" {
  type        = string
  description = ""
}

variable "aks_kubernetes_version" {
  type        = string
  description = "Version of Kubernetes to be used when creating the AKS cluster"
}

variable "aks_sku_tier" {
  type        = string
  description = "SKU Tier to be used for the AKS cluster"
}

variable "aks_agents_pool_name" {
  type        = string
  description = "Name to be used for the default Kubernetes Node Pool"
}

variable "aks_agents_size" {
  type        = string
  description = "Size of the Virtual Machines to be used in the default Kubernetes Node Pool"
}

variable "aks_agents_type" {
  type        = string
  description = "Type of the default Kubernetes Node Pool"
}

variable "aks_agents_max_pods" {
  type        = number
  description = "Maximum number of pods that can run on each agent of the default Kubernetes Node Pool"
}

variable "aks_os_disk_size_gb" {
  type        = number
  description = "Disk size of nodes in GBs"
}

variable "aks_agents_min_count" {
  type        = number
  description = "Minimum number of nodes in the pool"
}

variable "aks_agents_max_count" {
  type        = number
  description = "Maximum number of nodes in a pool"
}

###################################################################################
#                     Azure Database for PostgreSQL Flexible Server               #
###################################################################################
variable "deploy_azure_postgres_server" {
  type        = bool
  description = "Do you want to deploy Azure Database for PostgreSQL Flexible Server instance"
}

variable "azure_postgres_server_name" {
  type        = string
  description = "Name of PostgreSQL Flexible Server. The name must be unique across the entire Azure service, not just within the resource group."
}

variable "azure_postgres_sku_name" {
  type        = string
  description = "This option decides the performance and pricing for your database instance.  Choose the same after due diligence.  Refer Azure doc for more values with sku_name"
}

variable "azure_postgres_version" {
  type        = string
  description = "Indicates the postgresql version.  Possible values are 11,12 and 13 as of this release."
}

variable "azure_postgres_storage_mb" {
  type        = number
  description = "Indicates the storage size of Azure Postgres database in mb.  Accepted values for db_storage_mb during this release are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432."
}

variable "azure_postgres_backup_retention_days" {
  type        = number
  description = "Indicates the number of days the database backup should be retained.  Accepted values for db_backup_retention_days are between 7 and 35"
}

variable "terraform_local_ip" {
  type        = string
  description = "IP of the machine from where you are running your terraform"
}


###################################################################################
#                                Tags                                             #
###################################################################################

variable "common_tags" {
  default     = {}
  description = "Common Tags to apply on Azure Resources"
  type        = map(string)
}

###################################################################################
#                                values.yaml                                      #
###################################################################################
variable "update_values_yaml" {
  type        = bool
  default     = false
  description = "Do you want Terraform to update values.yaml with infrastructure related settings?"
}
