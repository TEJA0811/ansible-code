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
  backend "azurerm" {
    resource_group_name  = "__AZURE_RESOURCE_GROUP_NAME__"
    storage_account_name = "__AZURE_TFSTATE_STORAGE_ACCOUNT_NAME__"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  count    = var.resource_group_exists?0:1
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }

}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_key_vault" "akv" {
  count                       = var.keyvault_exists?0:1
  name                        = var.keyvault_name
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]

    certificate_permissions = [
      "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
    ]
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }

}


data "azurerm_key_vault" "idmkv" {
  name                = var.keyvault_name
  resource_group_name = data.azurerm_resource_group.rg.name

  depends_on = [
    azurerm_key_vault.akv

  ]
}

module "virtual_network" {

  source                  = "./modules/virtual_network"
  virtual_network_name    = var.virtual_network_name
  resource_group_name     = data.azurerm_resource_group.rg.name
  resource_group_location = data.azurerm_resource_group.rg.location
  subnet0_name            = var.subnet0_name
  subnet1_name            = var.subnet1_name
  common_tags             = var.common_tags

}

module "azure_kubernetes_service" {

  source = "./modules/azure_kubernetes_service"

  cluster_name = var.aks_cluster_name

  kubernetes_namespace = var.aks_kubernetes_namespace
  create_azure_pg_root_cert_secret = var.deploy_azure_postgres_server

  resource_group_name     = data.azurerm_resource_group.rg.name
  resource_group_location = data.azurerm_resource_group.rg.location

  image_registry_server          = var.image_registry_server
  image_registry_server_username = var.image_registry_server_username
  image_registry_server_password = var.image_registry_server_password

  kubernetes_version = var.aks_kubernetes_version

  sku_tier = var.aks_sku_tier

  agents_pool_name = var.aks_agents_pool_name
  agents_size      = var.aks_agents_size
  agents_type      = var.aks_agents_type
  os_disk_size_gb  = var.aks_os_disk_size_gb
  agents_max_pods  = var.aks_agents_max_pods
  agents_min_count = var.aks_agents_min_count
  agents_max_count = var.aks_agents_max_count
  subnet_id        = module.virtual_network.aks_subnet_id

  keyvault_id        = data.azurerm_key_vault.idmkv.id
  keyvault_tenent_id = data.azurerm_key_vault.idmkv.tenant_id

  common_tags        = var.common_tags

}

module "values_yaml" {

  source = "./modules/values_yaml"
  count  = var.update_values_yaml ? 1 : 0

  path = "./values.yaml"

  settings = {
    registry                    = var.image_registry_server
    azureKeyVaultName           = var.keyvault_name
    azureKeyVaultTenantId       = data.azurerm_key_vault.idmkv.tenant_id
    azureUserAssignedIdentityID = module.azure_kubernetes_service.azureKeyvaultSecretsProvider_clientId
  }

  depends_on = [
    module.virtual_network,
    module.azure_kubernetes_service

  ]

}

















