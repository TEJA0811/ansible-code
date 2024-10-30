
locals {
  dns_prefix        = replace(var.cluster_name, "_", "")
}

resource "azurerm_kubernetes_cluster" "aks" { 

  name                = var.cluster_name

  location            = var.resource_group_location

  resource_group_name = var.resource_group_name

  kubernetes_version = var.kubernetes_version

  http_application_routing_enabled = true

  azure_policy_enabled = true

  private_cluster_enabled = false

  sku_tier = var.sku_tier

  dns_prefix          = "${local.dns_prefix}-dns"
  

  network_profile  {
  
    network_plugin =  "azure"

    network_policy = "calico"

    dns_service_ip = "10.1.0.10"

    docker_bridge_cidr = "170.10.0.1/16"

    service_cidr  = "10.1.0.0/18"

  }

  default_node_pool  {

    name                = var.agents_pool_name
    vm_size             = var.agents_size
    type                = var.agents_type
    zones  = ["1", "2"]

    enable_auto_scaling = true
    min_count           = var.agents_min_count
    max_count           = var.agents_max_count
    node_count          = var.agents_min_count

    max_pods = var.agents_max_pods

    enable_host_encryption = false

    orchestrator_version = var.kubernetes_version

    os_disk_size_gb = var.os_disk_size_gb

    vnet_subnet_id = var.subnet_id

    node_labels = {
      "nodepool" : "defaultnodepool"
    }


    tags = merge(
      var.common_tags,
      {
        "Agent" = "defaultnodepoolagent"
      },
    )

  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
    secret_rotation_interval  = "2m"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }

}

resource "azurerm_role_assignment" "aks" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = var.subnet_id # Subnet ID

}


provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}


resource "kubernetes_namespace" "idm_namespace" {
  metadata {
    name = var.kubernetes_namespace
  }

}


resource "kubernetes_secret" "regcred" {

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

  depends_on = [kubernetes_namespace.idm_namespace]

}

resource "kubernetes_secret" "azure_pg_root_cert" {
 
  count = var.create_azure_pg_root_cert_secret ? 1 : 0

  metadata {
    name      = "identity-manager-db-ssl-root-crt"
    namespace = var.kubernetes_namespace
  }

  data = {
    "root.pem" = file("${path.module}/azure_pg_db_root.pem")
  }

  depends_on = [kubernetes_namespace.idm_namespace]
}


resource "azurerm_key_vault_access_policy" "aks_keyvault_policy" {
  key_vault_id = var.keyvault_id
  tenant_id    = var.keyvault_tenent_id
  object_id    = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
}
