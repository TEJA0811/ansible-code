#!/bin/bash

cd "$(dirname "$0")"

VALUES_YAML="../final/templates/values.yaml"

# Identity Manager Edition
sed -i s/__IS_ADVANCED_EDITION__/true/g $VALUES_YAML

# Resgistry
sed -i s/__CONTAINER_REGISTRY_SERVER__//g $VALUES_YAML

# Persistence
sed -i s/__KUBE_PERSISTENCE_ID_VAULT_STORAGE_CLASS__/"managed-premium"/g $VALUES_YAML
sed -i s/__KUBE_PERSISTENCE_ID_VAULT_STORAGE_SIZE__/"20Gi"/g $VALUES_YAML
sed -i s/__KUBE_PERSISTENCE_STORAGE_CLASS__/"azurefile"/g $VALUES_YAML
sed -i s/__KUBE_PERSISTENCE_STORAGE_SIZE__/"50Gi"/g $VALUES_YAML

# Azure Key Vault
sed -i s/__AZURE_KEY_VAULT_NAME__//g $VALUES_YAML

# Ingress
sed -i s/__KUBE_INGRESS_HOST_NAME__//g $VALUES_YAML
sed -i s/__AZURE_KEY_VAULT_TLS_CERT_NAME__//g $VALUES_YAML

# Azure PosgreSQL Server
sed -i s/__AZURE_POSTGRESQL_REQUIRED__/"n"/g $VALUES_YAML

# Identity Engine
sed -i s/__INSTALL_ENGINE__/true/g $VALUES_YAML
sed -i s/__ENGINE_REPLICA_COUNT__/1/g $VALUES_YAML
sed -i s/__ID_VAULT_TREENAME__/"IDENTITY_MANAGER_TREE"/g $VALUES_YAML
sed -i s/__ID_VAULT_SERVER_CONTEXT__/"servers.system"/g $VALUES_YAML
sed -i s/__ID_VAULT_DRIVER_SET__/"driverset1"/g $VALUES_YAML
sed -i s/__ID_VAULT_DEPLOY_CTX__/"o=system"/g $VALUES_YAML
sed -i s/__ID_VAULT_ADMIN_LDAP__/"cn=admin,ou=sa,o=system"/g $VALUES_YAML
sed -i s/__SECRET_ID_VAULT_PASSWORD__//g $VALUES_YAML
sed -i s/__ID_VAULT_RSA_KEYSIZE__/"4096"/g $VALUES_YAML
sed -i s/__ID_VAULT_EC_CURVE__/"P384"/g $VALUES_YAML
sed -i s/__ID_VAULT_CA_LIFE__/"10"/g $VALUES_YAML

# OSP
sed -i s/__INSTALL_OSP__/true/g $VALUES_YAML
sed -i s/__OSP_REPLICA_COUNT__/1/g $VALUES_YAML
sed -i s/__OSP_CUSTOM_NAME__/"Identity Access"/g $VALUES_YAML
sed -i s/__SECRET_SSO_SERVICE_PWD__//g $VALUES_YAML

# Identity Applications
sed -i s/__INSTALL_UA__/true/g $VALUES_YAML
sed -i s/__UA_REPLICA_COUNT__/1/g $VALUES_YAML
sed -i s/__UA_ADMIN__/"cn=uaadmin,ou=sa,o=data"/g $VALUES_YAML
sed -i s/__SECRET_UA_ADMIN_PWD__//g $VALUES_YAML
sed -i s/__UA_WFE_DB_PLATFORM_OPTION__/"postgres"/g $VALUES_YAML
sed -i s/__UA_ORACLE_DATABASE_TYPE__/"sid"/g $VALUES_YAML
sed -i s/__UA_WFE_DB_HOST__//g $VALUES_YAML
sed -i s/__UA_WFE_DB_PORT__/"5432"/g $VALUES_YAML
sed -i s/__UA_DATABASE_NAME__/"idmuserappdb"/g $VALUES_YAML
sed -i s/__WFE_DATABASE_NAME__/"igaworkflowdb"/g $VALUES_YAML
sed -i s#__UA_WFE_DB_JDBC_DRIVER_JAR__#"/opt/netiq/idm/apps/tomcat/lib/postgresql-9.4.1212.jar"#g $VALUES_YAML
sed -i s/__UA_WFE_DATABASE_USER__/"idmadmin"/g $VALUES_YAML
sed -i s/__SECRET_UA_WFE_DATABASE_PWD__//g $VALUES_YAML
sed -i s/__UA_CREATE_DRIVERS__/"y"/g $VALUES_YAML
sed -i s/__UA_DRIVER_NAME__/"User Application Driver"/g $VALUES_YAML

# Form Renderer
sed -i s/__INSTALL_FR__/true/g $VALUES_YAML

# ActiveMQ
sed -i s/__INSTALL_ACTIVEMQ__/true/g $VALUES_YAML

# Identity Reporting
sed -i s/__INSTALL_REPORTING__/true/g $VALUES_YAML
sed -i s/__RPT_ADMIN__/"cn=uaadmin,ou=sa,o=data"/g $VALUES_YAML
sed -i s/__SECRET_RPT_ADMIN_PWD__//g $VALUES_YAML
sed -i s/__RPT_DATABASE_PLATFORM_OPTION__/"postgres"/g $VALUES_YAML
sed -i s/__RPT_ORACLE_DATABASE_TYPE__/"service"/g $VALUES_YAML 
sed -i s/__RPT_DATABASE_HOST__//g $VALUES_YAML
sed -i s/__RPT_DATABASE_PORT__/"5432"/g $VALUES_YAML
sed -i s/__RPT_DATABASE_NAME__/"idmrptdb"/g $VALUES_YAML
sed -i s#__RPT_DATABASE_JDBC_DRIVER_JAR__#"/opt/netiq/idm/apps/tomcat/lib/postgresql-9.4.1212.jar"#g $VALUES_YAML
sed -i s/__RPT_DATABASE_USER__/"postgres"/g $VALUES_YAML
sed -i s/__SECRET_RPT_DATABASE_SHARE_PASSWORD__//g $VALUES_YAML

sed -i s/__RPT_SMTP_CONFIGURE__/"y"/g $VALUES_YAML
sed -i s/__RPT_SMTP_SERVER__/"172.17.0.3"/g $VALUES_YAML
sed -i s/__RPT_SMTP_SERVER_PORT__/"465"/g $VALUES_YAML
sed -i s/__RPT_DEFAULT_EMAIL_ADDRESS__/"admin@mycompany.com"/g $VALUES_YAML
sed -i s/__RPT_CREATE_DRIVERS__/"y"/g $VALUES_YAML

# SSPR
sed -i s/__INSTALL_SSPR__/true/g $VALUES_YAML
sed -i s/__SECRET_CONFIGURATION_PWD__//g $VALUES_YAML


# Identity Console
sed -i s/__INSTALL_IDENTITY_CONSOLE__/true/g $VALUES_YAML
sed -i s/__ID_CONSOLE_USE_OSP__/"n"/g $VALUES_YAML

# Data Containers
LDIF=$(cat data_containers.ldif | sed 's/^/    /')
ESCAPED_LDIF="$(echo "${LDIF}" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\$/\\$/g')"
sed -i "s/__DATA_CONTAINER_LDIF__/${ESCAPED_LDIF}/g" $VALUES_YAML
sed -i s/__ROOT_CONTAINER__/"o=data"/g $VALUES_YAML
sed -i s/__GROUP_ROOT_CONTAINER__/"o=data"/g $VALUES_YAML
sed -i s/__USER_CONTAINER__/"o=data"/g $VALUES_YAML
sed -i s/__ADMIN_CONTAINER__/"o=data"/g $VALUES_YAML

# Kubernetes Cluster Domain
sed -i s/__KUBE_SUB_DOMAIN__/"cluster.local"/g $VALUES_YAML


