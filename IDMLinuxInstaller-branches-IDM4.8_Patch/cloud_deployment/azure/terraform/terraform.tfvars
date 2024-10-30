###########################################################################################
# Common Tags for Azure Resources                                                         #
###########################################################################################

common_tags = {
   environment = "Production"
}

###########################################################################################
# Resource Group Name and Location                                                        #
###########################################################################################

# Name of Resource Group
resource_group_name = "__AZURE_RESOURCE_GROUP_NAME__"

# Location of Resource Group
resource_group_location = "__AZURE_RESOURCE_GROUP_LOCATION__"

# Is this an existing Resource Group?
resource_group_exists = __AZURE_RESOURCE_GROUP_EXISTS__

###########################################################################################
# Key Vault                                                                               #
###########################################################################################

# Name of Key Vault
# NOTE: The name must be globally unique 
keyvault_name = "__AZURE_KEYVAULT__"

# Is this an exiting Key Vault?
keyvault_exists = __AZURE_KEYVAULT_EXISTS__

###########################################################################################
# Image Registry Server                                                                   #
###########################################################################################

# Registry Server 
# Example: exampleregistry.azurecr.io
image_registry_server = "__AZURE_CONTAINER_REGISTRY_SERVER__"

# Registry Server Username
image_registry_server_username = "__AZURE_ACR_USERNAME__"

# Registry Server Password
image_registry_server_password = "__AZURE_ACR_PWD__"


###########################################################################################
# Virtual Network and Subnets                                                             #
###########################################################################################

# Name of Virtual Network
virtual_network_name = "idm_deployment_vnet"

# Name of Virtual Machine Subnet
subnet0_name = "idm_deployment_vm_subnet"

# Name of AKS Subnet
subnet1_name = "idm_deployment_aks_subnet"

###########################################################################################
# Azure Kubernetes Service                                                                #
###########################################################################################

# Name of the Azure Kubernetes Cluster
aks_cluster_name = "idm_deployment_cluster"

# Kubernetes version to be used when creating the AKS Cluster
aks_kubernetes_version = "1.23.8"

# The SKU Tier that should be used for the AKS Cluster.
aks_sku_tier = "Paid"

# Kubernetes namespace for deploying Identity Manager workloads in AKS
aks_kubernetes_namespace = "__KUBERNETES_NAMESPACE__"

#-----------------------------------------------------------------
# AKS Default Node Pool
#-----------------------------------------------------------------

# Name of the Default AKS Node Pool
aks_agents_pool_name = "defnodepool"

# The type of Node Pool
aks_agents_type = "VirtualMachineScaleSets"

# The size of the Virtual Machines that will form the nodes in this Node Pool 
aks_agents_size = "standard_b4ms"

# The size(in GB) of the OS Disk which should be used for each node in this Node Pool
aks_os_disk_size_gb = 50

# The maximum number of pods that can run on each node
aks_agents_max_pods = 100

# The minimum number of nodes which should exist in this Node Pool. 
aks_agents_min_count = 5

# The maximum number of nodes which should exist in this Node Pool
aks_agents_max_count = 10

###########################################################################################
# Azure Database for PostgreSQL Flexible Server                                           #
###########################################################################################

# Do you want to deploy a new Azure PostgreSQL Flexible Server instance
deploy_azure_postgres_server = __AZURE_POSTGRESQL_SERVER_DEPLOY__

 
# Name of the Azure PostgreSQL Server instance
# NOTE: Server name must be at least 3 characters and at most 63 characters. 
#       Server name must only contain lowercase letters, numbers, and hyphens. 
azure_postgres_server_name = "__AZURE_POSTGRESQL_SERVER_NAME_TERRAFORM__"

# The SKU Name for the PostgreSQL Flexible Server
azure_postgres_sku_name = "GP_Standard_D4s_v3"

# PostgreSQL engine major version.
azure_postgres_version = "12"

# Storage Size in MB
azure_postgres_storage_mb = 32768

# Backup retention period (in days)
azure_postgres_backup_retention_days = 35


update_values_yaml = true
terraform_local_ip = "127.0.0.1"
