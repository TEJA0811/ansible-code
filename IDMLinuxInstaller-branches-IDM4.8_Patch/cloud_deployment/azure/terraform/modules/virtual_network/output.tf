output "virtual_network_name" {
  value = azurerm_virtual_network.virtual_network.name
}
output "virtual_network_id" {
  value = azurerm_virtual_network.virtual_network.id
}
output "virtual_network_address_space" {
  value = azurerm_virtual_network.virtual_network.address_space
}

output "vm_subnet_name" {
  value = azurerm_subnet.vm_subnet.name
}
output "vm_subnet_id" {
  value = azurerm_subnet.vm_subnet.id
}
output "vm_subnet_address_prefixes" {
  value = azurerm_subnet.vm_subnet.address_prefixes
}

output "aks_subnet_name" {
  value = azurerm_subnet.aks_subnet.name
}
output "aks_subnet_id" {
  value = azurerm_subnet.aks_subnet.id
}
output "aks_subnet_address_prefixes" {
  value = azurerm_subnet.aks_subnet.address_prefixes
}