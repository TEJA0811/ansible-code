#!/bin/bash

CURRENT_IDM_VERSION="4.8.8"

cd "$(dirname "$0")"

[ -d final ] && rm -r final
mkdir final

[ -d IDM_Azure_Terraform_Configuration ] && rm -r IDM_Azure_Terraform_Configuration

cp -r terraform IDM_Azure_Terraform_Configuration


sed -i s/\"__AZURE_RESOURCE_GROUP_NAME__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/\"__AZURE_RESOURCE_GROUP_LOCATION__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/\"__AZURE_KEYVAULT__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/\"__AZURE_CONTAINER_REGISTRY_SERVER__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/\"__AZURE_ACR_USERNAME__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/\"__AZURE_ACR_PWD__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/\"__KUBERNETES_NAMESPACE__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/\"__AZURE_POSTGRESQL_SERVER_NAME_TERRAFORM__\"//g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/__AZURE_RESOURCE_GROUP_EXISTS__/false/g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/__AZURE_KEYVAULT_EXISTS__/false/g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i s/__AZURE_POSTGRESQL_SERVER_DEPLOY__/true/g IDM_Azure_Terraform_Configuration/terraform.tfvars
sed -i '/update_values_yaml/d' IDM_Azure_Terraform_Configuration/terraform.tfvars


# Ouput
cp terraform/terraform.tfvars final/terraform.tfvars
mv IDM_Azure_Terraform_Configuration/azure_pg_confgen.tf final/azure_pg.tf
zip -r final/IDM_${CURRENT_IDM_VERSION}_Azure_Terraform_Configuration.zip IDM_Azure_Terraform_Configuration


rm -r IDM_Azure_Terraform_Configuration


 
