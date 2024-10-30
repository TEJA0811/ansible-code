terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.84.0"
    }
    postgresql = {
      source  = "registry.terraform.io/cyrilgdn/postgresql"
      version = "=1.14.0"
    }
  }
}

data "terraform_remote_state" "tfstatestore" {
  backend = "azurerm"
  config = {
    resource_group_name = var.resource_group_name
    storage_account_name = var.storage_account_name_for_tfstate
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
  }
}

data "azurerm_resource_group" "commonrg" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "terrakv_local" {
  name                = var.keyvault_name                // KeyVault name
  resource_group_name = var.keyvault_resource_group_name // resourceGroup
}

data "azurerm_key_vault_secret" "dbadminloginpass" {
  name         = var.keyvault_dbadminloginpass_name // Name of Azure db admin pass in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
}

data "azurerm_key_vault_secret" "uawfedbuser" {
  name         = var.keyvault_uawfedbuser_name // Name of Azure db admin pass in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
}

data "azurerm_key_vault_secret" "uawfedbuserpwd" {
  name         = var.keyvault_uawfedbuserpwd_name // Name of Azure db admin pass in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
}

data "azurerm_key_vault_secret" "rptdbusersharepwd" {
  name         = var.keyvault_rptdbusersharepwd_name // Name of Azure db admin pass in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
}

data "azurerm_key_vault_secret" "uadbname" {
  name         = var.keyvault_uadbname_name // Name of Azure db admin pass in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
}

data "azurerm_key_vault_secret" "wfedbname" {
  name         = var.keyvault_wfedbname_name // Name of Azure db admin pass in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
}

data "azurerm_key_vault_secret" "rptdbname" {
  name         = var.keyvault_rptdbname_name // Name of Azure db admin pass in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
}

resource "azurerm_postgresql_flexible_server" "azure-pg" {
  name                = var.azure_postgres_server_name
  location            = data.azurerm_resource_group.commonrg.location
  resource_group_name = data.azurerm_resource_group.commonrg.name

  administrator_login    = "postgres"
  administrator_password = data.azurerm_key_vault_secret.dbadminloginpass.value

  sku_name = var.db_sku_name
  #sku_name = "GP_Gen5_4"
  version    = var.db_version
  storage_mb = var.db_storage_mb

  backup_retention_days = var.db_backup_retention_days

  #public_network_access_enabled    = true
  #ssl_enforcement_enabled          = false
  #ssl_minimal_tls_version_enforced = "TLS1_2"
}

data "azurerm_postgresql_flexible_server" "azure-pg" {
  name                = azurerm_postgresql_flexible_server.azure-pg.name
  resource_group_name = data.azurerm_resource_group.commonrg.name
  depends_on = [
    azurerm_postgresql_flexible_server.azure-pg
  ]
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "example" {
  name             = "Allow_access_to_Azure_services"
  server_id        = azurerm_postgresql_flexible_server.azure-pg.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "example2" {
  name             = "Add_your_local_ip"
  server_id        = azurerm_postgresql_flexible_server.azure-pg.id
  start_ip_address = var.terraform_local_ip
  end_ip_address   = var.terraform_local_ip
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "example3" {
  name             = "Allow_access_to_all_ips"
  server_id        = azurerm_postgresql_flexible_server.azure-pg.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

provider "postgresql" {
  host            = "${azurerm_postgresql_flexible_server.azure-pg.name}.postgres.database.azure.com"
  port            = 5432
  username        = "postgres"
  password        = data.azurerm_key_vault_secret.dbadminloginpass.value
  superuser       = false
  max_connections = 0
  connect_timeout = 7200
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 300"
  }
  triggers = {
    "before" = postgresql_role.idmadmin.id
  }
}

resource "postgresql_role" "idmadmin" {
  name     = data.azurerm_key_vault_secret.uawfedbuser.value // actual value from UA_WFE_DATABASE_USER
  login    = true
  password = data.azurerm_key_vault_secret.uawfedbuserpwd.value // actual value from UA_WFE_DATABASE_PWD
  depends_on = [
    azurerm_postgresql_flexible_server_firewall_rule.example
  ]
}

resource "postgresql_role" "idm_rpt_data" {
  name            = "idm_rpt_data" // Hard-coded name within RPT
  create_database = true
  create_role     = true
  inherit         = true
  login           = true
  password        = data.azurerm_key_vault_secret.rptdbusersharepwd.value // actual value from RPT_DATABASE_SHARE_PASSWORD
  depends_on = [
    azurerm_postgresql_flexible_server_firewall_rule.example
  ]
}

resource "postgresql_role" "idm_rpt_cfg" {
  name = "idm_rpt_cfg" // Hard-coded name within RPT
  #superuser = true
  create_database = true
  create_role     = true
  inherit         = true
  login           = true
  password        = data.azurerm_key_vault_secret.rptdbusersharepwd.value // actual value from RPT_DATABASE_SHARE_PASSWORD
  depends_on = [
    azurerm_postgresql_flexible_server_firewall_rule.example
  ]
}

resource "postgresql_role" "idmrptuser" {
  name            = "idmrptuser" // Hard-coded name within RPT
  create_database = true
  create_role     = true
  inherit         = true
  login           = true
  password        = data.azurerm_key_vault_secret.rptdbusersharepwd.value // actual value from RPT_DATABASE_SHARE_PASSWORD
  depends_on = [
    azurerm_postgresql_flexible_server_firewall_rule.example
  ]
}

resource "postgresql_role" "esec_user" {
  name = "esec_user" // Hard-coded name within RPT
  #login    = true
  #password = data.azurerm_key_vault_secret.rptdbusersharepwd.value // actual value from RPT_DATABASE_SHARE_PASSWORD
  depends_on = [
    azurerm_postgresql_flexible_server_firewall_rule.example
  ]
}

resource "postgresql_grant_role" "grantrptcfgroleTopostgres" {
  role       = "postgres"
  grant_role = "idm_rpt_cfg"
  depends_on = [
    postgresql_role.idm_rpt_cfg
  ]
}

resource "postgresql_grant_role" "grantrptdataroleTopostgres" {
  role       = "postgres"
  grant_role = "idm_rpt_data"
  depends_on = [
    postgresql_role.idm_rpt_data
  ]
}

resource "postgresql_grant_role" "grantidmrptuserroleTopostgres" {
  role       = "postgres"
  grant_role = "idmrptuser"
  depends_on = [
    postgresql_role.idmrptuser
  ]
}

resource "postgresql_grant_role" "grantpostgresroleToesecuser" {
  role       = "esec_user"
  grant_role = "postgres"
  depends_on = [
    postgresql_role.idm_rpt_data
  ]
}

resource "postgresql_database" "idmuserappdb" {
  name = data.azurerm_key_vault_secret.uadbname.value
}

resource "postgresql_database" "igaworkflowdb" {
  name = data.azurerm_key_vault_secret.wfedbname.value
}

resource "postgresql_database" "idmrptdb" {
  name = data.azurerm_key_vault_secret.rptdbname.value
}

resource "postgresql_grant" "grantallforidmuserappdb" {
  database    = postgresql_database.idmuserappdb.name
  role        = data.azurerm_key_vault_secret.uawfedbuser.value
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    postgresql_database.idmuserappdb,
    postgresql_role.idmadmin
  ]
}

resource "postgresql_grant" "grantallforigaworkflowdb" {
  database    = postgresql_database.igaworkflowdb.name
  role        = data.azurerm_key_vault_secret.uawfedbuser.value
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    postgresql_database.igaworkflowdb,
    postgresql_role.idmadmin
  ]
}

resource "postgresql_grant" "grantallforidmrptdb" {
  database    = postgresql_database.idmrptdb.name
  role        = data.azurerm_key_vault_secret.uawfedbuser.value
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    postgresql_database.idmrptdb,
    postgresql_role.idmadmin
  ]
}

resource "postgresql_grant" "grantallforidmrptdb-rptcfg" {
  database    = postgresql_database.idmrptdb.name
  role        = "idm_rpt_cfg"
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    postgresql_database.idmrptdb,
    postgresql_role.idm_rpt_cfg,
    postgresql_grant.grantallforidmrptdb
  ]
}

resource "postgresql_grant" "grantallforidmrptdb-rptdata" {
  database    = postgresql_database.idmrptdb.name
  role        = "idm_rpt_data"
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    postgresql_database.idmrptdb,
    postgresql_role.idm_rpt_data,
    postgresql_grant.grantallforidmrptdb-rptcfg
  ]
}

resource "postgresql_grant" "grantallforidmrptdb-postgres" {
  database    = postgresql_database.idmrptdb.name
  role        = "postgres"
  object_type = "database"
  privileges  = ["ALL"]
 #with_grant_option = true
  depends_on = [
    postgresql_database.idmrptdb,
    postgresql_grant.grantallforidmrptdb-rptdata
  ]
}

resource "postgresql_grant" "grantallforidmrptdb-esec_user" {
  database          = postgresql_database.idmrptdb.name
  role              = "esec_user"
  object_type       = "database"
  privileges        = ["ALL"]
  with_grant_option = true
  depends_on = [
    postgresql_database.idmrptdb,
    postgresql_role.esec_user,
    postgresql_grant.grantallforidmrptdb-rptdata,
    postgresql_grant.grantallforidmrptdb-postgres
  ]
}
