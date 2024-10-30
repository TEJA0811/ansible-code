######  Do not edit - START ######
keyvault_secret_name              = "MultilineSecret"
keyvault_valuesyaml_name          = "valuesyaml"
keyvault_secretproperties_name    = "secretproperties"
keyvault_dbadminloginpass_name    = "dbadminloginpass"
keyvault_uawfedbuser_name         = "uawfedbuser"
keyvault_uawfedbuserpwd_name      = "uawfedbuserpwd"
keyvault_uadbname_name            = "uadbname"
keyvault_wfedbname_name           = "wfedbname"
keyvault_rptdbname_name           = "rptdbname"
keyvault_rptdbusersharepwd_name   = "rptdbusersharepwd"
keyvault_crtfile_name             = "tlscrt"
keyvault_keyfile_name             = "tlskey"
keyvault_slesvmpwd_name           = "slesvmpwd"
######  Do not edit - END   ######
######  Do not edit unless you know what you are doing - START ######
engine_image_name                 = "identityengine:idm-4.8.6"
custom_ldif_file_basename         = "__CUSTOM_CONTAINER_LDIF_PATH_BASENAME__"
######  Do not edit unless you know what you are doing - END ######

###### Network Names and ip ######
virtual_network_name              = "myVnet"
subnet0_name                      = "mySubnet"
subnet1_name                      = "mySubnet2"
terraform_local_ip                = "127.0.0.1"
###### Network Names and ip ######

###### Azure Storage account for storing terraform state #####
storage_account_name_for_tfstate  = "__AZURE_STORAGE_ACCOUNT_FOR_TFSTATE__"
###### Azure Storage account for storing terraform state #####

###### Azure Key Vault and Resource Group details #####
keyvault_name                     = "__AZURE_KEYVAULT__"
keyvault_resource_group_name      = "__AZURE_RESOURCE_GROUP_NAME__"
resource_group_name               = "__AZURE_RESOURCE_GROUP_NAME__"
resource_group_location           = "__AZURE_RESOURCE_GROUP_LOCATION__"
###### Azure Key Vault and Resource Group details #####

###### Azure Container Registry Details #####
image_registry_server             = "__AZURE_CONTAINER_REGISTRY_SERVER__"
image_registry_server_username    = "__AZURE_ACR_USERNAME__"
image_registry_server_password    = "__AZURE_ACR_PWD__"
###### Azure Container Registry Details #####


###### Azure Database options - modify when needed - START ######
azure_postgres_server_name        = "__AZURE_POSTGRESQL_SERVER_NAME_TERRAFORM__"
# db_sku_name determines the performance and pricing for your database instance.  Choose the same after due diligence.  Refer Azure doc for more values with sku_name.
db_sku_name                       = "GP_Standard_D4s_v3"
# db_version refers to the postgresql version.  Possible values are 11,12 and 13 as of this release.
db_version                        = "12"
# Accepted values for db_storage_mb during this release are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432.
db_storage_mb                     = 32768
# Accepted values for db_backup_retention_days are between 7 and 35
db_backup_retention_days          = 35
###### Azure Database options - modify when needed - END   ######



###### Azure SLES VM options - modify when needed - START  ######
# Virtual Machine Settings within Azure which would act as Docker Host for Identity Engine
engine_docker_host_name           = "__AZURE_DOCKER_VM_HOST_NAME__"
engine_data_disk_size             = "__AZURE_DOCKER_VM_ENGINE_DATADISK_SIZE__"
# Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid.
vm_osdisk_account_tier             = "Standard"
# Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2.
vm_osdisk_account_kind             = "StorageV2"
# Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. 
vm_osdisk_account_replication_type = "LRS"
# Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool for vm_osdisk_access_tier
vm_osdisk_access_tier              = "Hot"
# Virtual Machine Operating System disk name
vm_osdisk_name                     = "OsDisk"
# Possible values for vm_osdisk_storage_account_type are Standard_LRS, StandardSSD_LRS and Premium_LRS. 
vm_osdisk_storage_account_type     = "Premium_LRS"
# Possible values for vm_datadisk_storage_account_type are Standard_LRS, StandardSSD_ZRS, Premium_LRS, Premium_ZRS, StandardSSD_LRS or UltraSSD_LRS.
vm_datadisk_storage_account_type   = "Premium_LRS"
###### Azure SLES VM options - modify when needed - END    ######



###### Azure Kubernetes Service options - modify when needed - START #####
kubernetes_namespace              = "__KUBERNETES_NAMESPACE__"
service_principal_client_app_id   = "__SERVICE_PRINCIPAL_ID__"
service_principal_client_password = "__SERVICE_PRINCIPAL_PWD__"
# The Kubernetes version available in the region
aks_module_kubernetes_version = "1.21.9"
# The prefix for the resources created in the specified Azure Resource Group
aks_prefix                         = "idmaks"
# The name for the AKS resources created in the specified Azure Resource Group. This variable overwrites the 'prefix' var (The 'prefix' var will still be applied to the dns_prefix if it is set)
aks_cluster_name                   = "cluster-name"
# Disk size of nodes in GBs.
aks_os_disk_size_gb                = 50
# The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid
aks_sku_tier                       = "Paid"
# Minimum number of nodes in a pool
aks_agents_min_count               = 5
# Maximum number of nodes in a pool
aks_agents_max_count               = 10
# The maximum number of pods that can run on each agent.
aks_agents_max_pods                = 100
#  The default Azure AKS agentpool (nodepool) name.
aks_agents_pool_name               = "defnodepool"
# The type of Node Pool which should be created. Possible values are AvailabilitySet and VirtualMachineScaleSets. 
aks_agents_type                    = "VirtualMachineScaleSets"
# The default virtual machine size for the Kubernetes agents
aks_agents_size                    = "standard_b2ms"
###### Azure Kubernetes Service options - modify when needed - END   #####

