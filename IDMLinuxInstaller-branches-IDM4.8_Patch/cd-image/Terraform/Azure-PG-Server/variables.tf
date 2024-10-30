variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

variable "resource_group_location" {
  type        = string
  description = "resource group location"
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

variable "keyvault_dbadminloginpass_name" {
  type        = string
  description = "Azure PG DB Admin password within keyvault"
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

variable "storage_account_name_for_tfstate" {
  type = string
  description = "Storage account created for storing terraform state files"
}
