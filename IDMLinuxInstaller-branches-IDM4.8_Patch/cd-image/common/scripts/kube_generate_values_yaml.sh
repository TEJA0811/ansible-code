#!/bin/bash

values_yaml_file=/config/values.yaml
DEFAUT_DATA_CONTAINERS_LDIF_FILE="/azure/IDM_Azure_Terraform_Configuration/data_containers.ldif"

generate_helm_values_yaml()
{

  cp -rpf "/azure/IDM_Azure_Terraform_Configuration/values.yaml" "${values_yaml_file}" 

   # Identity Manager Edition
  search_and_replace "__IS_ADVANCED_EDITION__" "${IS_ADVANCED_EDITION}" "${values_yaml_file}"

   # Azure PostgreSQL
  search_and_replace "__AZURE_POSTGRESQL_REQUIRED__" "${AZURE_POSTGRESQL_REQUIRED}" "${values_yaml_file}"


  # Ingress
  search_and_replace "__KUBE_INGRESS_HOST_NAME__" "${IDM_ACCESS_VIA_SINGLE_DOMAIN}" "${values_yaml_file}"
  search_and_replace "__AZURE_KEY_VAULT_TLS_CERT_NAME__" "ingress-tls-crt" "${values_yaml_file}"


  # Persistence
  if [ ! -z "$AZURE_CLOUD" ] && [ "$AZURE_CLOUD" == "y" ] && [ ! -z "$TERRAFORM_GENERATE" ] && [ "$TERRAFORM_GENERATE" == "y" ]
  then
    search_and_replace "__CONTAINER_REGISTRY_SERVER__" "${AZURE_CONTAINER_REGISTRY_SERVER}" "${values_yaml_file}"

    search_and_replace "__KUBE_PERSISTENCE_ID_VAULT_STORAGE_CLASS__" "managed-premium" "${values_yaml_file}"
    search_and_replace "__KUBE_PERSISTENCE_ID_VAULT_STORAGE_SIZE__" "20Gi" "${values_yaml_file}"

    search_and_replace "__KUBE_PERSISTENCE_STORAGE_CLASS__" "azurefile" "${values_yaml_file}"
    search_and_replace "__KUBE_PERSISTENCE_STORAGE_SIZE__" "50Gi" "${values_yaml_file}"
    
  else
    search_and_replace "__CONTAINER_REGISTRY_SERVER__" "" "${values_yaml_file}"
   
    search_and_replace "__KUBE_PERSISTENCE_ID_VAULT_STORAGE_CLASS__" "" "${values_yaml_file}"
    search_and_replace "__KUBE_PERSISTENCE_ID_VAULT_STORAGE_SIZE__" "" "${values_yaml_file}"

    search_and_replace "__KUBE_PERSISTENCE_STORAGE_CLASS__" "" "${values_yaml_file}"
    search_and_replace "__KUBE_PERSISTENCE_STORAGE_SIZE__" "" "${values_yaml_file}"

  fi

   # Secret Manager
   search_and_replace "__AZURE_KEY_VAULT_NAME__" "${AZURE_KEYVAULT}" "${values_yaml_file}"

  # Identity Vault Configuration
  search_and_replace "__INSTALL_ENGINE__" "${INSTALL_ENGINE}" "${values_yaml_file}"
  search_and_replace "__ENGINE_REPLICA_COUNT__" "${ENGINE_REPLICA_COUNT}" "${values_yaml_file}"
  search_and_replace "__ID_VAULT_SERVER_CONTEXT__" "${ID_VAULT_SERVER_CONTEXT}" "${values_yaml_file}"
  search_and_replace "__ID_VAULT_ADMIN_LDAP__" "${ID_VAULT_ADMIN_LDAP}" "${values_yaml_file}"
  search_and_replace "__ID_VAULT_DRIVER_SET__" "${ID_VAULT_DRIVER_SET}" "${values_yaml_file}"
  search_and_replace "__ID_VAULT_DEPLOY_CTX__" "${ID_VAULT_DEPLOY_CTX}" "${values_yaml_file}"
  search_and_replace "__ID_VAULT_TREENAME__" "${ID_VAULT_TREENAME}" "${values_yaml_file}"

  search_and_replace "__ID_VAULT_RSA_KEYSIZE__" "${ID_VAULT_RSA_KEYSIZE}" "${values_yaml_file}"
  search_and_replace "__ID_VAULT_EC_CURVE__" "${ID_VAULT_EC_CURVE}" "${values_yaml_file}"
  search_and_replace "__ID_VAULT_CA_LIFE__" "${ID_VAULT_CA_LIFE}" "${values_yaml_file}"

  # OSP Configuration
  if [ -z "$INSTALL_OSP" ]
  then
    search_and_replace "__INSTALL_OSP__" "false" "${values_yaml_file}"
  else
    search_and_replace "__INSTALL_OSP__" "${INSTALL_OSP}" "${values_yaml_file}"
  fi
  search_and_replace "__OSP_REPLICA_COUNT__" "${OSP_REPLICA_COUNT}" "${values_yaml_file}"
  search_and_replace "__OSP_CUSTOM_NAME__" "${OSP_CUSTOM_NAME}" "${values_yaml_file}"

  # User Application Configuration
  if [ -z "$INSTALL_UA" ]
  then
    search_and_replace "__INSTALL_UA__" "false" "${values_yaml_file}"
    search_and_replace "__INSTALL_FR__" "false" "${values_yaml_file}"    
  else
    search_and_replace "__INSTALL_UA__" "${INSTALL_UA}" "${values_yaml_file}"
    search_and_replace "__INSTALL_FR__" "${INSTALL_UA}" "${values_yaml_file}"
  fi
  search_and_replace "__UA_ADMIN__" "${UA_ADMIN}" "${values_yaml_file}"
  search_and_replace "__UA_REPLICA_COUNT__" "${UA_REPLICA_COUNT}" "${values_yaml_file}"
  search_and_replace "__UA_DB_SCHEMA_FILE__" "${UA_DB_SCHEMA_FILE}" "${values_yaml_file}"
  search_and_replace "__WFE_DB_SCHEMA_FILE__" "${WFE_DB_SCHEMA_FILE}" "${values_yaml_file}"
  search_and_replace "__UA_CEF_AUDIT_ENABLED__" "${UA_CEF_AUDIT_ENABLED}" "${values_yaml_file}"
  search_and_replace "__USE_EXISTING_CERT_WITH_SAN__" "${USE_EXISTING_CERT_WITH_SAN}" "${values_yaml_file}"
  #search_and_replace "__GROUP_ROOT_CONTAINER__" "${GROUP_ROOT_CONTAINER}" "${values_yaml_file}"
  #search_and_replace "__ROOT_CONTAINER__" "${ROOT_CONTAINER}" "${values_yaml_file}"
  search_and_replace "__WFE_DB_NEW_OR_EXIST__" "${WFE_DB_NEW_OR_EXIST}" "${values_yaml_file}"
  search_and_replace "__UA_DB_NEW_OR_EXIST__" "${UA_DB_NEW_OR_EXIST}" "${values_yaml_file}"
  search_and_replace "__UA_WFE_DB_CREATE_OPTION__" "${UA_WFE_DB_CREATE_OPTION}" "${values_yaml_file}"
  search_and_replace "__UA_WFE_DB_JDBC_DRIVER_JAR__" "${UA_WFE_DB_JDBC_DRIVER_JAR}" "${values_yaml_file}"
  search_and_replace "__UA_WFE_DATABASE_USER__" "${UA_WFE_DATABASE_USER}" "${values_yaml_file}"
  search_and_replace "__WFE_DATABASE_NAME__" "${WFE_DATABASE_NAME}" "${values_yaml_file}"
  search_and_replace "__UA_DATABASE_NAME__" "${UA_DATABASE_NAME}" "${values_yaml_file}"
  search_and_replace "__UA_WFE_DB_PORT__" "${UA_WFE_DB_PORT}" "${values_yaml_file}"
  search_and_replace "__UA_WFE_DB_HOST__" "${UA_WFE_DB_HOST}" "${values_yaml_file}"
  search_and_replace "__UA_WFE_DB_PLATFORM_OPTION__" "${UA_WFE_DB_PLATFORM_OPTION}" "${values_yaml_file}"
  search_and_replace "__UA_ORACLE_DATABASE_TYPE__" "${UA_ORACLE_DATABASE_TYPE}" "${values_yaml_file}"
  search_and_replace "__UA_WORKFLOW_ENGINE_ID__" "${UA_WORKFLOW_ENGINE_ID}" "${values_yaml_file}"
  search_and_replace "__UA_CLUSTER_ENABLED__" "${UA_CLUSTER_ENABLED}" "${values_yaml_file}"
  search_and_replace "__ENGINE_REPLICA_COUNT__" "${ENGINE_REPLICA_COUNT}" "${values_yaml_file}"
  search_and_replace "__UA_REPLICA_COUNT__" "${UA_REPLICA_COUNT}" "${values_yaml_file}"
  search_and_replace "__OSP_REPLICA_COUNT__" "${OSP_REPLICA_COUNT}" "${values_yaml_file}"

  # ActiveMQ Configuration
  if [ -z "$INSTALL_ACTIVEMQ" ]
  then
    search_and_replace "__INSTALL_ACTIVEMQ__" "false" "${values_yaml_file}"
  else
    search_and_replace "__INSTALL_ACTIVEMQ__" "${INSTALL_ACTIVEMQ}" "${values_yaml_file}"
  fi

  # Reporting Configuration
  if [ -z "$INSTALL_REPORTING" ]
  then
    search_and_replace "__INSTALL_REPORTING__" "false" "${values_yaml_file}"
  else
    search_and_replace "__INSTALL_REPORTING__" "${INSTALL_REPORTING}" "${values_yaml_file}"
  fi
  search_and_replace "__FOR_SSPR_CONTAINER__" "${FOR_SSPR_CONTAINER}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_PLATFORM_OPTION__" "${RPT_DATABASE_PLATFORM_OPTION}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_HOST__" "${RPT_DATABASE_HOST}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_PORT__" "${RPT_DATABASE_PORT}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_NAME__" "${RPT_DATABASE_NAME}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_USER__" "${RPT_DATABASE_USER}" "${values_yaml_file}"
  search_and_replace "__RPT_ORACLE_DATABASE_TYPE__" "${RPT_ORACLE_DATABASE_TYPE}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_JDBC_DRIVER_JAR__" "${RPT_DATABASE_JDBC_DRIVER_JAR}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_CREATE_OPTION__" "${RPT_DATABASE_CREATE_OPTION}" "${values_yaml_file}"
  search_and_replace "__RPT_DATABASE_NEW_OR_EXIST__" "${RPT_DATABASE_NEW_OR_EXIST}" "${values_yaml_file}"
  search_and_replace "__RPT_ADMIN__" "${RPT_ADMIN}" "${values_yaml_file}"

  # SSPR Configuration
  if [ -z "$INSTALL_SSPR" ]
  then
    search_and_replace "__INSTALL_SSPR__" "false" "${values_yaml_file}"
  else
    search_and_replace "__INSTALL_SSPR__" "${INSTALL_SSPR}" "${values_yaml_file}"
  fi

  # Identity Console Configuration
  if [ -z "$INSTALL_IDENTITY_CONSOLE" ]
  then
    search_and_replace "__INSTALL_IDENTITY_CONSOLE__" "false" "${values_yaml_file}"
  else
    search_and_replace "__INSTALL_IDENTITY_CONSOLE__" "${INSTALL_IDENTITY_CONSOLE}" "${values_yaml_file}"
  fi
  search_and_replace "__ID_CONSOLE_USE_OSP__" "${ID_CONSOLE_USE_OSP}" "${values_yaml_file}"


  # Adavanced Configuration
  LDIF=$(cat "${DEFAUT_DATA_CONTAINERS_LDIF_FILE}" | sed 's/^/    /')
  if [ "$ENABLE_CUSTOM_CONTAINER_CREATION" == "y" ]
  then
    LDIF=$(cat "${CUSTOM_CONTAINER_LDIF_PATH}" | sed 's/^/    /')
  fi
  ESCAPED_LDIF="$(echo "${LDIF}" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\$/\\$/g')"
  sed -i "s/__DATA_CONTAINER_LDIF__/${ESCAPED_LDIF}/g" "${values_yaml_file}"

  search_and_replace "__ROOT_CONTAINER__" "${ROOT_CONTAINER}" "${values_yaml_file}"
  search_and_replace "__GROUP_ROOT_CONTAINER__" "${GROUP_ROOT_CONTAINER}" "${values_yaml_file}"
  search_and_replace "__USER_CONTAINER__" "${USER_CONTAINER}" "${values_yaml_file}"
  search_and_replace "__ADMIN_CONTAINER__" "${ADMIN_CONTAINER}" "${values_yaml_file}"
  search_and_replace "__KUBE_SUB_DOMAIN__" "cluster.local" "${values_yaml_file}"


  if [ "$IS_COMMON_PASSWORD" == "y" ] 
  then
    search_and_replace "__SECRET_ID_VAULT_PASSWORD__" "idm-common-password" "${values_yaml_file}"
    search_and_replace "__SECRET_SSO_SERVICE_PWD__" "idm-common-password" "${values_yaml_file}"
    search_and_replace "__SECRET_UA_ADMIN_PWD__" "idm-common-password" "${values_yaml_file}"
    search_and_replace "__SECRET_RPT_ADMIN_PWD__" "idm-common-password" "${values_yaml_file}"
    search_and_replace "__SECRET_CONFIGURATION_PWD__" "idm-common-password" "${values_yaml_file}"
  else

    if [ ! -z "$INSTALL_ENGINE" ] && [ "$INSTALL_ENGINE" == "true" ]
    then
        search_and_replace "__SECRET_ID_VAULT_PASSWORD__" "id-vault-password" "${values_yaml_file}"
    else
        search_and_replace "__SECRET_ID_VAULT_PASSWORD__" "" "${values_yaml_file}" 
    fi

    if [ ! -z "$INSTALL_OSP" ] && [ "$INSTALL_OSP" == "true" ]
    then
        search_and_replace "__SECRET_SSO_SERVICE_PWD__" "sso-service-password" "${values_yaml_file}"
    else
        search_and_replace "__SECRET_SSO_SERVICE_PWD__" "" "${values_yaml_file}" 
    fi

    if [ ! -z "$INSTALL_UA" ] && [ "$INSTALL_UA" == "true" ]
    then
        search_and_replace "__SECRET_UA_ADMIN_PWD__" "ua-admin-password" "${values_yaml_file}"
    else
        search_and_replace "__SECRET_UA_ADMIN_PWD__" "" "${values_yaml_file}" 
    fi

    if [ ! -z "$INSTALL_REPORTING" ] && [ "$INSTALL_REPORTING" == "true" ]
    then
        search_and_replace "__SECRET_RPT_ADMIN_PWD__" "rpt-admin-password" "${values_yaml_file}"
    else
        search_and_replace "__SECRET_RPT_ADMIN_PWD__" "" "${values_yaml_file}" 
    fi

    if [ ! -z "$INSTALL_SSPR" ] && [ "$INSTALL_SSPR" == "true" ]
    then
        search_and_replace "__SECRET_CONFIGURATION_PWD__" "sspr-configuration-passsword" "${values_yaml_file}"
    else
        search_and_replace "__SECRET_CONFIGURATION_PWD__" "" "${values_yaml_file}" 
    fi

  fi
  
  if [ ! -z "$AZURE_POSTGRESQL_REQUIRED" ] && [ "$AZURE_POSTGRESQL_REQUIRED" == "y" ]
  then
    search_and_replace "__SECRET_UA_WFE_DATABASE_PWD__" "uawfedbuserpwd" "${values_yaml_file}"
    search_and_replace "__SECRET_RPT_DATABASE_SHARE_PASSWORD__" "rptdbusersharepwd" "${values_yaml_file}"
  else

    if [ ! -z "$INSTALL_UA" ] && [ "$INSTALL_UA" == "true" ]
    then
        search_and_replace "__SECRET_UA_WFE_DATABASE_PWD__" "ua-wfe-db-pwd" "${values_yaml_file}"
    else
        search_and_replace "__SECRET_UA_WFE_DATABASE_PWD__" "" "${values_yaml_file}" 
    fi

    if [ ! -z "$INSTALL_REPORTING" ] && [ "$INSTALL_REPORTING" == "true" ]
    then
        search_and_replace "__SECRET_RPT_DATABASE_SHARE_PASSWORD__" "rpt-db-shared-pwd" "${values_yaml_file}"
    else
        search_and_replace "__SECRET_RPT_DATABASE_SHARE_PASSWORD__" "" "${values_yaml_file}" 
    fi

  fi

}
