data "azurerm_key_vault_secret" "dbadminloginpass" {
  count        = var.deploy_azure_postgres_server ? 1 : 0
  name         = "dbadminloginpass"
  key_vault_id = data.azurerm_key_vault.idmkv.id
}

data "azurerm_key_vault_secret" "rptdbusersharepwd" {
  count        = var.deploy_azure_postgres_server ? 1 : 0
  name         = "rptdbusersharepwd"
  key_vault_id = data.azurerm_key_vault.idmkv.id
}

data "azurerm_key_vault_secret" "uawfedbuserpwd" {
  count        = var.deploy_azure_postgres_server ? 1 : 0
  name         = "uawfedbuserpwd"
  key_vault_id = data.azurerm_key_vault.idmkv.id
}


provider "postgresql" {
  host            = var.deploy_azure_postgres_server ? "${var.azure_postgres_server_name}.postgres.database.azure.com" : ""
  port            = 5432
  username        = var.deploy_azure_postgres_server ? "postgres" : ""
  password        = var.deploy_azure_postgres_server ? data.azurerm_key_vault_secret.dbadminloginpass[0].value : ""
  superuser       = false
  max_connections = 0
  connect_timeout = 7200
}


module "azure_pg_server" {
  source                  = "./modules/azure_pg_server"
  count                   = var.deploy_azure_postgres_server ? 1 : 0
  resource_group_name     = data.azurerm_resource_group.rg.name
  resource_group_location = data.azurerm_resource_group.rg.location
  keyvault_id = data.azurerm_key_vault.idmkv.id

  azure_postgres_server_name = var.azure_postgres_server_name

  db_admin_password = data.azurerm_key_vault_secret.dbadminloginpass[0].value
  rpt_db_user_shared_pwd = data.azurerm_key_vault_secret.rptdbusersharepwd[0].value
  ua_wfe_db_user_pwd = data.azurerm_key_vault_secret.uawfedbuserpwd[0].value

  terraform_local_ip = var.terraform_local_ip

  azure_postgres_sku_name              = var.azure_postgres_sku_name
  azure_postgres_version               = var.azure_postgres_version
  azure_postgres_storage_mb            = var.azure_postgres_storage_mb
  azure_postgres_backup_retention_days = var.azure_postgres_backup_retention_days

  common_tags = var.common_tags

}