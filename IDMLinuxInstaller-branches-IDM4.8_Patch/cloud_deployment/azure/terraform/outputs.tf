output "keyvault" {
  value = {
        "Name" = var.keyvault_name
        "TenantId" = data.azurerm_key_vault.idmkv.tenant_id    
  }
}

output "vnet" {
  value = {
        "Name" = module.virtual_network.virtual_network_name
        "Address Space" = module.virtual_network.virtual_network_address_space
        "Subnets" = [
            {
               "Name" = "${module.virtual_network.vm_subnet_name}"
               "Address Prefixes" =  module.virtual_network.vm_subnet_address_prefixes
            },
            {
               "Name" = "${module.virtual_network.aks_subnet_name}"
               "Address Prefixes" =  module.virtual_network.aks_subnet_address_prefixes
            }
        ]
  }
}


output "aks" {
  value = {
        "Name" = module.azure_kubernetes_service.name
        "Kubernetes Version" = module.azure_kubernetes_service.kubernetes_version
        "Azure Key Vault Secrets Provider ClientId" = module.azure_kubernetes_service.azureKeyvaultSecretsProvider_clientId
  }
}


output "database" {
  value = !var.deploy_azure_postgres_server ? null : {
        
        "Host" = module.azure_pg_server[0].host
        "Port" = "5432"
        "Database Administrator" = module.azure_pg_server[0].administrator
        "Database Administrator Password Key Vault Secret" = "dbadminloginpass"
        "Identity Applications Database" = module.azure_pg_server[0].idm_userapp_db
        "Workflow Engine Database" = module.azure_pg_server[0].iga_workflow_db
        "Identity Applications Database User" = module.azure_pg_server[0].ua_wfe_dbuser
        "Identity Applications Database User Password Key Vault Secret" = "uawfedbuserpwd"
        "Identity Reporting Database" = module.azure_pg_server[0].rpt_db
        "Identity Reporting Database User" = module.azure_pg_server[0].administrator
        "Identity Reporting Database User Password Key Vault Secret" = "dbadminloginpass"
        "Identity Reporting Database Shared Password Key Vault Secret" = "rptdbusersharepwd"

  }
}