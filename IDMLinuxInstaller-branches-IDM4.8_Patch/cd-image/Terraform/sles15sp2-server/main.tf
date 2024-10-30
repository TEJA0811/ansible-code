# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.84.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you're using version 1.x, the "features" block is not allowed.
  features {}
}

#resource "null_resource" "importgroup" {
#  provisioner "local-exec" {
#    command = "terraform import data.azurerm_resource_group.terraformresourcegroup ${var.resource_group_id}"
#    interpreter = ["bash", "-c"]
#  }
#}

data "azurerm_key_vault" "terrakv" {
  name                = var.keyvault_name                // KeyVault name
  resource_group_name = var.keyvault_resource_group_name // resourceGroup
}

data "azurerm_key_vault_secret" "kvsecret" {
  name         = var.keyvault_secret_name // Name of secret
  key_vault_id = data.azurerm_key_vault.terrakv.id
}

data "azurerm_key_vault_secret" "crtfile" {
  name         = var.keyvault_crtfile_name 
  key_vault_id = data.azurerm_key_vault.terrakv.id
}
//data.azurerm_key_vault_secret.kvsecret.value

data "azurerm_key_vault_secret" "slesvmpwd" {
  name         = var.keyvault_slesvmpwd_name
  key_vault_id = data.azurerm_key_vault.terrakv.id
}

# Create a resource group if it doesn't exist
data "azurerm_resource_group" "terraformresourcegroup" {
  name = var.resource_group_name
}

# Create virtual network
resource "azurerm_virtual_network" "terraformvirtualnetwork" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = data.azurerm_resource_group.terraformresourcegroup.name

  tags = {
    environment = "Terraform Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "terraformvmsubnet" {
  name                 = var.subnet0_name
  resource_group_name  = data.azurerm_resource_group.terraformresourcegroup.name
  virtual_network_name = azurerm_virtual_network.terraformvirtualnetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
#resource "azurerm_public_ip" "myterraformpublicip" {
#    name                         = "myPublicIP"
#    location                     = var.resource_group_location
#    resource_group_name          = data.azurerm_resource_group.terraformresourcegroup.name
#    allocation_method            = "Dynamic"
#
#    tags = {
#        environment = "Terraform Demo"
#    }
#}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraformnsg" {
  name                = "NetworkSecurityGroup"
  location            = var.resource_group_location
  resource_group_name = data.azurerm_resource_group.terraformresourcegroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = data.azurerm_resource_group.terraformresourcegroup.name
  }

  byte_length = 8
}

# Create network interface
resource "azurerm_network_interface" "terraformnic" {
  name                = "NIC${random_id.randomId.hex}"
  location            = var.resource_group_location
  resource_group_name = data.azurerm_resource_group.terraformresourcegroup.name

  ip_configuration {
    name                          = "NicConfiguration"
    subnet_id                     = azurerm_subnet.terraformvmsubnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.4"
    #public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }

  tags = {
    environment = "Terraform Demo"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.terraformnic.id
  network_security_group_id = azurerm_network_security_group.terraformnsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = data.azurerm_resource_group.terraformresourcegroup.name
  location                 = var.resource_group_location
  account_tier             = var.vm_osdisk_account_tier
  account_kind             = var.vm_osdisk_account_kind
  account_replication_type = var.vm_osdisk_account_replication_type
  access_tier              = var.vm_osdisk_access_tier

  tags = {
    environment = "Terraform Demo"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraformvm" {
  name                  = var.engine_docker_host_name
  location              = var.resource_group_location
  resource_group_name   = data.azurerm_resource_group.terraformresourcegroup.name
  network_interface_ids = [azurerm_network_interface.terraformnic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = var.vm_osdisk_name
    caching              = "ReadWrite"
    storage_account_type = var.vm_osdisk_storage_account_type
  }

  source_image_reference {
    publisher = "suse"
    offer     = "sles-15-sp2-basic"
    sku       = "gen1"
    version   = "latest"
  }

  computer_name                   = var.engine_docker_host_name
  admin_username                  = "azureuser"
  admin_password                  = data.azurerm_key_vault_secret.slesvmpwd.value
  disable_password_authentication = false

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }

  #provisioner "local-exec" {
  #  command = "ping 127.0.0.1 -n 100 > nul" #or sleep 10
  #}
  depends_on = [
    data.azurerm_key_vault_secret.slesvmpwd
  ]

}

resource "azurerm_managed_disk" "example" {
  name                 = "${var.engine_docker_host_name}-disk1"
  location             = var.resource_group_location
  resource_group_name  = data.azurerm_resource_group.terraformresourcegroup.name
  storage_account_type = var.vm_datadisk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.engine_data_disk_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.example.id
  virtual_machine_id = azurerm_linux_virtual_machine.terraformvm.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "terraformvm" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_linux_virtual_machine.terraformvm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  #kvsecretvalue=data.azurerm_key_vault_secret.kvsecret.value
  settings = <<SETTINGS
    {
        "script": "${base64encode(templatefile("custom_script.sh", {
  kvsecretvalue               = "${data.azurerm_key_vault_secret.kvsecret.value}",
  imageregistryserver         = "${var.image_registry_server}",
  imageregistryserverusername = "${var.image_registry_server_username}",
  imageregistryserverpassword = "${var.image_registry_server_password}",
  engineimagename             = "${var.engine_image_name}",
  tlscrtvalue                 = "${data.azurerm_key_vault_secret.crtfile.value}",
  enginedatadisksize          = "${var.engine_data_disk_size}"
}))}"
    }
SETTINGS
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.example
  ]

}