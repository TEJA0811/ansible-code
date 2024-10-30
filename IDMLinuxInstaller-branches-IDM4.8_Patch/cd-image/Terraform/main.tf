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

data "terraform_remote_state" "tfstatestore" {
  backend = "azurerm"
  config = {
    resource_group_name = var.resource_group_name
    storage_account_name = var.storage_account_name_for_tfstate
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "server" {

  source                  = "./sles15sp2-server"
  engine_docker_host_name = var.engine_docker_host_name
  keyvault_slesvmpwd_name = var.keyvault_slesvmpwd_name
  resource_group_name     = var.resource_group_name
  #resource_group_id = var.resource_group_id
  resource_group_location        = var.resource_group_location
  virtual_network_name           = var.virtual_network_name
  subnet0_name                   = var.subnet0_name
  keyvault_name                  = var.keyvault_name
  keyvault_resource_group_name   = var.keyvault_resource_group_name
  keyvault_secret_name           = var.keyvault_secret_name
  image_registry_server          = var.image_registry_server
  image_registry_server_username = var.image_registry_server_username
  image_registry_server_password = var.image_registry_server_password
  engine_image_name              = var.engine_image_name
  keyvault_crtfile_name          = var.keyvault_crtfile_name
  engine_data_disk_size          = var.engine_data_disk_size
  vm_osdisk_account_tier             = var.vm_osdisk_account_tier
  vm_osdisk_account_kind             = var.vm_osdisk_account_kind
  vm_osdisk_account_replication_type = var.vm_osdisk_account_replication_type
  vm_osdisk_access_tier              = var.vm_osdisk_access_tier
  vm_osdisk_name                     = var.vm_osdisk_name
  vm_osdisk_storage_account_type     = var.vm_osdisk_storage_account_type
  vm_datadisk_storage_account_type   = var.vm_datadisk_storage_account_type

}

resource "azurerm_subnet" "akssubnet" {
  name                 = var.subnet1_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.0.0/23"]
  depends_on           = [module.server]
}

module "aks" {
  source               = "Azure/aks/azurerm"
  resource_group_name  = var.resource_group_name
  client_id            = var.service_principal_client_app_id
  client_secret        = var.service_principal_client_password
  kubernetes_version   = var.aks_module_kubernetes_version
  orchestrator_version = var.aks_module_kubernetes_version
  prefix               = var.aks_prefix
  cluster_name         = var.aks_cluster_name
  network_plugin       = "azure"
  vnet_subnet_id       = azurerm_subnet.akssubnet.id
  os_disk_size_gb      = var.aks_os_disk_size_gb
  sku_tier             = var.aks_sku_tier
  #enable_role_based_access_control = true
  #rbac_aad_admin_group_object_ids  = [data.azuread_client_config.current.owners]
  #rbac_aad_managed                 = true
  private_cluster_enabled         = false # default value
  enable_http_application_routing = true
  enable_azure_policy             = true
  enable_auto_scaling             = true
  enable_host_encryption          = false
  agents_min_count                = var.aks_agents_min_count
  agents_max_count                = var.aks_agents_max_count
  agents_count                    = null # Please set `agents_count` `null` while `enable_auto_scaling` is `true` to avoid possible `agents_count` changes.
  agents_max_pods                 = var.aks_agents_max_pods
  agents_pool_name                = var.aks_agents_pool_name
  agents_availability_zones       = ["1", "2"]
  agents_type                     = var.aks_agents_type
  agents_size                     = var.aks_agents_size

  agents_labels = {
    "nodepool" : "defaultnodepool"
  }

  agents_tags = {
    "Agent" : "defaultnodepoolagent"
  }

  network_policy             = "calico"
  net_profile_dns_service_ip = "10.1.0.10"
  #net_profile_dns_service_ip     = "10.0.2.4"
  net_profile_docker_bridge_cidr = "170.10.0.1/16"
  net_profile_service_cidr       = "10.1.0.0/16"
  depends_on                     = [module.server]

}

provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

data "azurerm_key_vault" "terrakv_local" {
  name                = var.keyvault_name                // KeyVault name
  resource_group_name = var.keyvault_resource_group_name // resourceGroup
}

data "azurerm_key_vault_secret" "valuesyamlfile" {
  name         = var.keyvault_valuesyaml_name // Name of values yaml in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
  depends_on   = [module.server]
}

data "azurerm_key_vault_secret" "secretpropertiesfile" {
  name         = var.keyvault_secretproperties_name // Name of secret properties in keyvault
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
  depends_on   = [module.server]
}

resource "local_file" "valuesyamlfilelink" {
  content  = data.azurerm_key_vault_secret.valuesyamlfile.value
  filename = "${path.module}/values.yaml"
}

#resource "local_file" "secretpropertiesfilelink" {
#  content  = data.azurerm_key_vault_secret.secretpropertiesfile.value
#  filename = "${path.module}/secret.properties"
#}

data "azurerm_key_vault_secret" "crtfile" {
  name         = var.keyvault_crtfile_name 
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
  depends_on   = [module.server]
}

data "azurerm_key_vault_secret" "keyfile" {
  name         = var.keyvault_keyfile_name 
  key_vault_id = data.azurerm_key_vault.terrakv_local.id
  depends_on   = [module.server]
}

resource "kubernetes_namespace" "example" {
  metadata {
    annotations = {
      name = "example-annotation"
    }

    labels = {
      mylabel = "label-value"
    }

    name = var.kubernetes_namespace
  }
  depends_on = [
    module.aks
  ]
}

// kubectl create secret docker-registry regcred --docker-server=${registry_server} --docker-username=${registry_username} --docker-password=${registry_password}
resource "kubernetes_secret" "example2" {
  metadata {
    name      = "regcred"
    namespace = var.kubernetes_namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.image_registry_server}" = {
          auth = "${base64encode("${var.image_registry_server_username}:${var.image_registry_server_password}")}"
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"
  #data = {
  #  username = "${var.image_registry_server_username}"
  #  password = "${var.image_registry_server_password}"
  #}

  #type = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.example]
}

resource "kubernetes_secret" "example3" {
  metadata {
    name      = "ingress-tls"
    namespace = var.kubernetes_namespace
  }

  data = {
    //"tls.crt" = file("${path.module}/certs/tls.crt")
    //"tls.key" = file("${path.module}/certs/tls.key")
    "tls.crt" = data.azurerm_key_vault_secret.crtfile.value
    "tls.key" = data.azurerm_key_vault_secret.keyfile.value
  }

  type       = "kubernetes.io/tls"
  depends_on = [kubernetes_namespace.example, data.azurerm_key_vault_secret.crtfile, data.azurerm_key_vault_secret.keyfile]
}

resource "kubernetes_secret" "example4" {

  metadata {
    name = "init-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    "data_payload" = data.azurerm_key_vault_secret.secretpropertiesfile.value
  }
  depends_on = [kubernetes_namespace.example]
}

resource "kubernetes_config_map" "customldif" {
  metadata {
    name = "custom-ldif"
    namespace = var.kubernetes_namespace
  }
  data = {
    "custom.ldif" = "${file("${path.module}/custom-ldif/${var.custom_ldif_file_basename}")}"
  }
  count = fileexists("${path.module}/custom-ldif/${var.custom_ldif_file_basename}") ? 1 : 0
  depends_on = [kubernetes_namespace.example]
}

#resource "null_resource" "editvaluesyaml" {
#  provisioner "local-exec" {
#    command = "sed -i 's#PGDBHOSTVALUEFROMAZURE#${module.dbserver.dynamicazurepgname}.postgres.database.azure.com#g' ${path.module}/values.yaml"
#  }
#  depends_on = [
#    module.dbserver,
#    local_file.valuesyamlfilelink
#  ]
#}

