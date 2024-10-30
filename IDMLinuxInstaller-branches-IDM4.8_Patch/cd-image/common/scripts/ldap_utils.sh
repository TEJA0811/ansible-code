#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

import_ldif()
{
local ldif_file=$1

write_log "Importing ldif file: $ldif_file"

$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${IDM_INSTALL_HOME}common/lib/ldap.jar com.netiq.installer.utils.LDAPModify $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT "$ID_VAULT_ADMIN_LDAP" "${ID_VAULT_PASSWORD}" "$IDM_KEYSTORE_PATH" "${IDM_KEYSTORE_PWD}" "$ldif_file" /dev/null >>${LOG_FILE_NAME}  2>&1

if [ $? == 0 ]; then
     str1=`gettext install "Successful. "`
     write_log "$str1"
      return 0
  else
      str1=`gettext install "Failed. "`
      write_and_log "$str1"
       return 1
  fi  
}

new_import_ldif()
{
local ldif_file=$1

write_log "Importing ldif file: $ldif_file"

$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${IDM_INSTALL_HOME}common/lib/ldap.jar com.netiq.installer.utils.LdiffImport $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT "$ID_VAULT_ADMIN_LDAP" "${ID_VAULT_PASSWORD}" "$IDM_KEYSTORE_PATH" "${IDM_KEYSTORE_PWD}" "$ldif_file" /dev/null >>${LOG_FILE_NAME}  2>&1

if [ $? == 0 ]; then
     str1=`gettext install "Successful. "`
     write_log "$str1"
     return 0
  else
    str1=`gettext install "Failed. "`
    write_and_log "$str1"
    return 1
  fi  
}

query_server_dn()
{
    write_log "Querying the server dn..."
    TMP_LOG="${LOG_FILE_NAME}.querylog"
    $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${IDM_INSTALL_HOME}common/lib/ldap.jar com.netiq.installer.utils.LDAPQuery $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT "$ID_VAULT_ADMIN_LDAP" "${ID_VAULT_PASSWORD}" "$IDM_KEYSTORE_PATH" "${IDM_KEYSTORE_PWD}" "" "objectclass=NCP Server" dn 2 ${TMP_LOG}
    cat ${TMP_LOG} >> ${LOG_FILE_NAME}
    rm ${TMP_LOG}
    write_log "Completed querying server dn"
}

verify_ldap_connection()
{
  str1=`gettext install "Verifying Identity Vault connection parameters.."`
  write_and_log "$str1"
  $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${IDM_INSTALL_HOME}common/lib/ldap.jar com.netiq.installer.utils.VerifyLDAPConnection $1 $2 "$3" "$4" ${TEMP_LOG_FILE_NAME} >>${LOG_FILE_NAME}
  if [ $? == 0 ]; then
     str1=`gettext install "Connection successful "`
     write_and_log "$str1"
      return 0
  else
      str1=`gettext install "Connection failed "`
      write_and_log "$str1"
      return 1
  fi
  
}

verify_ldap_dn()
{
	str1=`gettext install "Verifying if the container exists.."`
	write_and_log "$str1"
	$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${IDM_INSTALL_HOME}common/lib/ldap.jar com.netiq.installer.utils.VerifyDN $1 $2 "$3" "$4" "$5" ${TEMP_LOG_FILE_NAME} >>${LOG_FILE_NAME}
  
  if [ $? == 0 ]; then
     str1=`gettext install "Container exists "`
     write_and_log "$str1"
      return 0
  else      
      return 1
  fi
}

