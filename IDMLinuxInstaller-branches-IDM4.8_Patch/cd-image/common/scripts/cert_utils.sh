#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

import_vault_certificates()
{
    create_idm_keystore
    import_certificates "${ID_VAULT_HOST}" "$ID_VAULT_LDAPS_PORT" "$IDM_KEYSTORE_PATH" "$IDM_KEYSTORE_PWD" "idm"
	if [ ! -z "$CUSTOM_RPT_CERTIFICATE" ] && [ "$CUSTOM_RPT_CERTIFICATE" == "y" ]
    then
      keystorerootcertAliasName=$(${IDM_JRE_HOME}/bin/keytool -list -keystore ${RPT_COMM_TOMCAT_KEYSTORE_FILE} -storepass ${RPT_COMM_TOMCAT_KEYSTORE_PWD} | grep trustedCertEntry | cut -d',' -f1)
      for trustedentryrootcert in $keystorerootcertAliasName
      do
       ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore ${RPT_COMM_TOMCAT_KEYSTORE_FILE} -srcstorepass ${RPT_COMM_TOMCAT_KEYSTORE_PWD} -destkeystore ${IDM_KEYSTORE_PATH} -deststorepass ${IDM_KEYSTORE_PWD} -srcalias $trustedentryrootcert -destalias $trustedentryrootcert -noprompt &> /dev/null
      done
    fi
    if [ ! -z "$CUSTOM_OSP_CERTIFICATE" ] && [ "$CUSTOM_OSP_CERTIFICATE" == "y" ]
    then
      keystorerootcertAliasName=$(${IDM_JRE_HOME}/bin/keytool -list -keystore ${OSP_COMM_TOMCAT_KEYSTORE_FILE} -storepass ${OSP_COMM_TOMCAT_KEYSTORE_PWD} | grep trustedCertEntry | cut -d',' -f1)
      for trustedentryrootcert in $keystorerootcertAliasName
      do
       ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore ${OSP_COMM_TOMCAT_KEYSTORE_FILE} -srcstorepass ${OSP_COMM_TOMCAT_KEYSTORE_PWD} -destkeystore ${IDM_KEYSTORE_PATH} -deststorepass ${IDM_KEYSTORE_PWD} -srcalias $trustedentryrootcert -destalias $trustedentryrootcert -noprompt &> /dev/null
      done
    fi
    if [ ! -z "$CUSTOM_UA_CERTIFICATE" ] && [ "$CUSTOM_UA_CERTIFICATE" == "y" ]
    then
      keystorerootcertAliasName=$(${IDM_JRE_HOME}/bin/keytool -list -keystore ${UA_COMM_TOMCAT_KEYSTORE_FILE} -storepass ${UA_COMM_TOMCAT_KEYSTORE_PWD} | grep trustedCertEntry | cut -d',' -f1)
      for trustedentryrootcert in $keystorerootcertAliasName
      do
       ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore ${UA_COMM_TOMCAT_KEYSTORE_FILE} -srcstorepass ${UA_COMM_TOMCAT_KEYSTORE_PWD} -destkeystore ${IDM_KEYSTORE_PATH} -deststorepass ${IDM_KEYSTORE_PWD} -srcalias $trustedentryrootcert -destalias $trustedentryrootcert -noprompt &> /dev/null
      done
    fi
}

create_install_temp_keystore()
{
    if [ ! -f "$IDM_TEMP_KEYSTORE" ]
    then
        str=`gettext install "Creating a temporary keystore for Identity Manager."`
        write_log "$str "
        local temp_key_pwd="changeit"
        # Create a keystore with certificate and delete it to make it empty keystore.
        ${IDM_JRE_HOME}/bin/keytool -genkey -keyalg RSA -keysize 2048 -keystore ${IDM_TEMP_KEYSTORE} -storetype pkcs12 -storepass ${temp_key_pwd} -keypass ${temp_key_pwd} -alias test -validity 7300 -dname "cn=delete" >> $LOG_FILE_NAME 2>&1

        ${IDM_JRE_HOME}/bin/keytool -delete -alias test -keysize 2048 -keystore ${IDM_TEMP_KEYSTORE} -storetype pkcs12 -storepass ${temp_key_pwd} -keypass ${temp_key_pwd} >> $LOG_FILE_NAME 2>&1
        import_certificates "${ID_VAULT_HOST}" "$ID_VAULT_LDAPS_PORT" "$IDM_TEMP_KEYSTORE" "$temp_key_pwd" "test"       
   fi
}

create_idm_keystore()
{
    if [ ! -f "$IDM_KEYSTORE_PATH" ]
    then
        str=`gettext install "Creating the Identity Manager keystore."`
        write_and_log "$str "

        # Create a keystore with certificate and delete it to make it empty keystore.
        ${IDM_JRE_HOME}/bin/keytool -genkey -keyalg RSA -keysize 2048 -keystore ${IDM_KEYSTORE_PATH} -storetype pkcs12 -storepass ${IDM_KEYSTORE_PWD} -keypass ${IDM_KEYSTORE_PWD} -alias idm -validity 7300 -dname "cn=delete" >> $LOG_FILE_NAME 2>&1

        ${IDM_JRE_HOME}/bin/keytool -delete -alias idm -keysize 2048 -keystore ${IDM_KEYSTORE_PATH} -storetype pkcs12 -storepass ${IDM_KEYSTORE_PWD} -keypass ${IDM_KEYSTORE_PWD} >> $LOG_FILE_NAME 2>&1
   fi
}


import_certificates()
{
    local host=$1
    local port=$2
    local keystore=$3
    local password=$4
    local alias=$5
    if [ ! -z "$skip_idv_cert_import" ] && [ "$skip_idv_cert_import" == "true" ]
    then
    	return
    fi

    str1=`gettext install "Importing Identity Vault certificates. "`
    write_and_log "$str1"
    $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ImportCertificate -src ${host}:${port} -ks $keystore -pwd $password -a $alias >> $LOG_FILE_NAME 2>&1
}

import_keystore()
{
    local srcKeystore=$1
    local destKeystore=$2
    local srcKSPass=$3
    local destKSPass=$4
    
    ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore "${srcKeystore}" -destkeystore "${destKeystore}" -srcstorepass "${srcKSPass}" -deststorepass "${destKSPass}" -deststoretype pkcs12 -noprompt >> $LOG_FILE_NAME 2>&1
}

import_from_cacert()
{
    local srcKeystore=${IDM_JRE_HOME}/lib/security/cacerts
    local srcKSPass=changeit
    local destKeystore=${IDM_KEYSTORE_PATH}
    local destKSPass=${IDM_KEYSTORE_PWD}
    local alias="$1"
    
    ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore "${srcKeystore}" -srcstoretype JKS -destkeystore "${destKeystore}" -srcstorepass "${srcKSPass}" -deststorepass "${destKSPass}" -alias "${alias}" -deststoretype pkcs12 -noprompt >> $LOG_FILE_NAME 2>&1
}
