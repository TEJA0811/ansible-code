output "host" {
  value = "${azurerm_postgresql_flexible_server.azure-pg.name}.postgres.database.azure.com"
}

output "administrator" {
  value = azurerm_postgresql_flexible_server.azure-pg.administrator_login
}

output "ua_wfe_dbuser" {
  value = postgresql_role.idmadmin.name
}

output "idm_userapp_db" {
  value = postgresql_database.idmuserappdb.name
}

output "iga_workflow_db" {
  value = postgresql_database.igaworkflowdb.name
}

output "rpt_db" {
  value = postgresql_database.idmrptdb.name
}