variable "keyvault_id" {
  type        = string
  description = "subnet[0] name"
}

variable "db_admin_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "rpt_db_user_shared_pwd" {
  description = "Identity Reporting Database Shared Password"
  type        = string
  sensitive   = true
}

variable "ua_wfe_db_user_pwd" {
  description = "Identity Applications Database User Password"
  type        = string
  sensitive   = true
}

variable "azure_postgres_server_name" {
  type        = string
  description = "Full name of the Azure Postgres Server like idmpsqlserver.postgres.database.azure.com"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

variable "resource_group_location" {
  type        = string
  description = "resource group location"
}

variable "azure_postgres_sku_name" {
  type = string
  description = "This option decides the performance and pricing for your database instance.  Choose the same after due diligence.  Refer Azure doc for more values with sku_name"
}

variable "azure_postgres_version" {
  type = string
  description = "Indicates the postgresql version.  Possible values are 11,12 and 13 as of this release."
}

variable "azure_postgres_storage_mb" {
  type = number
  description = "Indicates the storage size of Azure Postgres database in mb.  Accepted values for db_storage_mb during this release are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432."
}

variable "azure_postgres_backup_retention_days" {
  type = number
  description = "Indicates the number of days the database backup should be retained.  Accepted values for db_backup_retention_days are between 7 and 35"
}


variable "common_tags" {
  default     = {}
  description = "Common Tags to apply on Azure Resources"
  type        = map(string)
}



variable "terraform_local_ip" {
  type        = string
  description = "IP of the machine from where you are running your terraform"
}