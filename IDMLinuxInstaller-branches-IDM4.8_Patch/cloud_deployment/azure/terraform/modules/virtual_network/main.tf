
# Create virtual network
resource "azurerm_virtual_network" "virtual_network" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# Create subnet for Virtual Machines
resource "azurerm_subnet" "vm_subnet" {
  name                 = var.subnet0_name
  resource_group_name  = azurerm_virtual_network.virtual_network.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.0.0/18"]
}

# Create subnet for Azure Kubernetes Service
resource "azurerm_subnet" "aks_subnet" {
  name                 = var.subnet1_name
  resource_group_name  = azurerm_virtual_network.virtual_network.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.128.0/17"]
}
