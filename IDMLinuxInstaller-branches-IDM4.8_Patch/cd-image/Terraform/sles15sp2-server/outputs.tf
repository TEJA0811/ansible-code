output "idm_virtual_network_id" {
  value = azurerm_virtual_network.terraformvirtualnetwork.id
}

output "idm_subnet_id" {
  value = azurerm_subnet.terraformvmsubnet.id
}
