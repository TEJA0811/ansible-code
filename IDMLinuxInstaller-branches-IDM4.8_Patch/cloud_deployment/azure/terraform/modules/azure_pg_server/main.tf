terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.10.0"
    }
    postgresql = {
      source  = "registry.terraform.io/cyrilgdn/postgresql"
      version = "=1.16.0"
    }
  }
}

resource "azurerm_postgresql_flexible_server" "azure-pg" {
  name                = var.azure_postgres_server_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  administrator_login    = "postgres"
  administrator_password = var.db_admin_password

  sku_name   = var.azure_postgres_sku_name
  version    = var.azure_postgres_version
  storage_mb = var.azure_postgres_storage_mb

  backup_retention_days = var.azure_postgres_backup_retention_days


  tags = var.common_tags

  lifecycle {
    ignore_changes = [
        zone,
        high_availability.0.standby_availability_zone,
        tags,
    ]
  }

}


resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_pg_firewall_rule1" {
  name             = "Allow_access_to_Azure_services"
  server_id        = azurerm_postgresql_flexible_server.azure-pg.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_pg_firewall_rule2" {
  name             = "Add_your_local_ip"
  server_id        = azurerm_postgresql_flexible_server.azure-pg.id
  start_ip_address = var.terraform_local_ip
  end_ip_address   = var.terraform_local_ip
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_pg_firewall_rule3" {
  name             = "Allow_access_to_all_ips"
  server_id        = azurerm_postgresql_flexible_server.azure-pg.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}


resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"

  depends_on = [
    azurerm_postgresql_flexible_server_firewall_rule.azure_pg_firewall_rule1,
    azurerm_postgresql_flexible_server_firewall_rule.azure_pg_firewall_rule2,
    azurerm_postgresql_flexible_server_firewall_rule.azure_pg_firewall_rule3,
  ]
}

resource "postgresql_database" "idmuserappdb" {
  name = "idmuserappdb" #var.uadbname_name

    depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "postgresql_database" "igaworkflowdb" {
  name = "igaworkflowdb" #var.wfedbname_name

    depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "postgresql_database" "idmrptdb" {
  name =  "idmrptdb" #var.rptdbname_name

    depends_on = [
    time_sleep.wait_60_seconds
  ]
}


resource "postgresql_role" "idmadmin" {
  name     = "idmadmin"  #var.uawfedbuser_name
  login    = true
  password = var.ua_wfe_db_user_pwd 

  depends_on = [
    time_sleep.wait_60_seconds
  ]

}

resource "postgresql_role" "idm_rpt_data" {
  name            = "idm_rpt_data" // Hard-coded name within RPT
  create_database = true
  create_role     = true
  inherit         = true
  login           = true
  password        = var.rpt_db_user_shared_pwd

 depends_on = [
    time_sleep.wait_60_seconds
  ]

}

resource "postgresql_role" "idm_rpt_cfg" {
  name = "idm_rpt_cfg" // Hard-coded name within RPT
  #superuser = true
  create_database = true
  create_role     = true
  inherit         = true
  login           = true
  password        = var.rpt_db_user_shared_pwd 

  depends_on = [
    time_sleep.wait_60_seconds
  ]

}

resource "postgresql_role" "idmrptuser" {
  name            = "idmrptuser" // Hard-coded name within RPT
  create_database = true
  create_role     = true
  inherit         = true
  login           = true
  password        = var.rpt_db_user_shared_pwd 

  depends_on = [
    time_sleep.wait_60_seconds
  ]

}


resource "postgresql_role" "esec_user" {
  name = "esec_user" // Hard-coded name within RPT
  depends_on = [
    time_sleep.wait_60_seconds
  ]
}


resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [
    postgresql_database.idmuserappdb,
    postgresql_database.igaworkflowdb,
    postgresql_database.idmrptdb,
    postgresql_role.idmadmin,
    postgresql_role.idm_rpt_data,
    postgresql_role.idm_rpt_cfg,
    postgresql_role.idmrptuser,
    postgresql_role.esec_user,
  ]
}

resource "postgresql_grant_role" "grantrptcfgroleTopostgres" {
  role       = "postgres" #var.dbadmin_name
  grant_role = "idm_rpt_cfg"
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_role.idm_rpt_cfg
  ]
}

resource "postgresql_grant_role" "grantrptdataroleTopostgres" {
  role       = "postgres" #var.dbadmin_name
  grant_role = "idm_rpt_data"
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_role.idm_rpt_data
  ]
}

resource "postgresql_grant_role" "grantidmrptuserroleTopostgres" {
  role       = "postgres" #var.dbadmin_name
  grant_role = "idmrptuser"
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_role.idmrptuser
  ]
}

resource "postgresql_grant_role" "grantpostgresroleToesecuser" {
  role       = "esec_user"
  grant_role = "postgres" #var.dbadmin_name
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_role.idm_rpt_data
  ]
}



resource "postgresql_grant" "grantallforidmuserappdb" {
  database    = postgresql_database.idmuserappdb.name
  role        = "idmadmin" #var.uawfedbuser_name
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_database.idmuserappdb,
    postgresql_role.idmadmin
  ]
}

resource "postgresql_grant" "grantallforigaworkflowdb" {
  database    = postgresql_database.igaworkflowdb.name
  role        = "idmadmin" #var.uawfedbuser_name
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_database.igaworkflowdb,
    postgresql_role.idmadmin
  ]
}

resource "postgresql_grant" "grantallforidmrptdb" {
  database    = postgresql_database.idmrptdb.name
  role        = "idmadmin" #var.uawfedbuser_name
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    time_sleep.wait_30_seconds,
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
    time_sleep.wait_30_seconds,
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
    time_sleep.wait_30_seconds,
    postgresql_database.idmrptdb,
    postgresql_role.idm_rpt_data,
    postgresql_grant.grantallforidmrptdb-rptcfg
  ]
}

resource "postgresql_grant" "grantallforidmrptdb-postgres" {
  database    = postgresql_database.idmrptdb.name
  role        = "postgres" #var.dbadmin_name
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_database.idmrptdb,
    postgresql_grant.grantallforidmrptdb-rptdata
  ]
}

resource "postgresql_grant" "grantallforidmrptdb-esec_user" {
  database          = postgresql_database.idmrptdb.name
  role              = "esec_user"
  object_type       = "database"
  privileges        = ["ALL"]
  depends_on = [
    time_sleep.wait_30_seconds,
    postgresql_database.idmrptdb,
    postgresql_role.esec_user,
    postgresql_grant.grantallforidmrptdb-rptdata,
    postgresql_grant.grantallforidmrptdb-postgres
  ]
}





