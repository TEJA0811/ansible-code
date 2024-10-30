output "dynamicazurepgname" {
  value = azurerm_postgresql_flexible_server.azure-pg.name
}

output "azurepgid" {
  value = azurerm_postgresql_flexible_server.azure-pg.id
}
