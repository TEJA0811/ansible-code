#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

    prompt "INSTALL_UA"
    getValidLocalIP "$UA_SERVER_HOST"
    warningforDBoptions()
    {
     if [ $IS_UPGRADE -eq 0 ]
     then
     	return
     fi
     if [ ! -z "$UA_WFE_DB_CREATE_OPTION" ] && [ -z "$CalledonWarning" ]
     then
      export CalledonWarning=true
      if [ "$UA_WFE_DB_CREATE_OPTION" == "file" ] || [ "$UA_WFE_DB_CREATE_OPTION" == "startup" ]
      then
        warnstring=`gettext install "Refer documentation for more details with respect to file/startup option, post the upgrade."`
	echo_sameline "${txtred}"
	write_and_log $warnstring
	echo_sameline ""
	echo_sameline "${txtrst}"
      fi
     fi
    }

    vault_ip=$IP_ADDR
    if [ -f /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties ]
    then
    	ISM_FILE_LOCATION=/opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
	local rbpm_url_data=`grep -ir "com.netiq.rbpm.redirect.url =" ${ISM_FILE_LOCATION} | awk '{print $3}' | sed 's/^[ ]*//'`
	local RBPM_PROTO="`echo ${rbpm_url_data} | grep '://' | sed -e 's,^\(.*://\).*,\1,g'`"
	local RBPM_URL=`echo ${rbpm_url_data} | sed -e s,$RBPM_PROTO,,g`
	local RBPM_SERVER_HOSTNAME="$(echo $RBPM_URL | grep : | cut -d: -f1)"
	if [ -z ${RBPM_SERVER_HOSTNAME} ]
	then
	  local RBPM_SERVER_HOSTNAME="$(echo $RBPM_URL | grep / | cut -d/ -f1)"
	fi
    fi
    if [ ! -z "$RBPM_SERVER_HOSTNAME" ] && [ "$RBPM_SERVER_HOSTNAME" != "" ] && [ $IS_UPGRADE -eq 1 ]
    then
    	UA_SERVER_HOST=$RBPM_SERVER_HOSTNAME
	save_prompt "UA_SERVER_HOST"
    else
    	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "n" ]
	then
	  if [ ! -z "$SSO_SERVER_HOST" ] && [ -z "$UA_SERVER_HOST" ]
	  then
	    UA_SERVER_HOST=$SSO_SERVER_HOST
	    save_prompt "UA_SERVER_HOST"
	  fi
	fi
    	prompt "UA_SERVER_HOST" "$vault_ip"
	if [ ! -z "$SSO_SERVER_HOST" ] && [ "$SSO_SERVER_HOST" == "$UA_SERVER_HOST" ]
	then
	  UA_SERVER_SSL_PORT=$SSO_SERVER_SSL_PORT
	  save_prompt "UA_SERVER_SSL_PORT"
	else
	  prompt_port "UA_SERVER_SSL_PORT"
	fi
    fi
  
  if [ $IS_UPGRADE -ne 1 ]
  then
    if [ ! -z $AZURE_POSTGRESQL_REQUIRED ] && [ "$AZURE_POSTGRESQL_REQUIRED" == "y" ]
    then
      export AMPERSANDMARK=\&
      export AZUREPGSSL=ssl=true
      export QUESTIONMARK=?
    fi
    if [[  -z "$ID_VAULT_HOST"  ||  -z "$ID_VAULT_LDAPS_PORT" || -z "$ID_VAULT_ADMIN_LDAP"  || -z "$ID_VAULT_PASSWORD"  ]]       
    then
        PROMPT_SAVE="false"
    
        while true
        do
            prompt "ID_VAULT_HOST" "$vault_ip"
            prompt_port "ID_VAULT_LDAPS_PORT" '-' '-' "$ID_VAULT_HOST"
            prompt "ID_VAULT_ADMIN_LDAP"
            convert_dot_notation ${ID_VAULT_ADMIN_LDAP}

            prompt "ID_VAULT_ADMIN" $RET
            prompt_pwd "ID_VAULT_PASSWORD"
            RET=0
            if [ "$SKIP_LDAP_SERVER_VALIDATION" != "true" ]
            then
               verify_ldap_connection $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD
               RET=$?
            fi
        
            if (( $RET != 0 )); then
                echo_sameline ""
                echo_sameline "${txtred}"
                str1=`gettext install "ERROR: Could not connect to the Identity Vault."`
                write_and_log $str1
                echo_sameline "${txtrst}"
                echo_sameline "${txtylw}"
                read1=`gettext install "To re-enter the connection details, press Enter."`
                read -p "$read1"
                echo_sameline "${txtrst}"
                echo_sameline ""
            else
                echo ""
               break
           fi
       done
       save_prompt "ID_VAULT_HOST"
       save_prompt "ID_VAULT_LDAPS_PORT"
       save_prompt "ID_VAULT_ADMIN_LDAP"
       save_prompt "ID_VAULT_ADMIN"
       save_prompt "ID_VAULT_PASSWORD"
    fi

       
  #    prompt "EXTERNAL_SSO_SERVER"
    if [ "$IS_OSP_INSTALLED" == "true" ] && [ "$CREATE_SILENT_FILE" != true ] && [ ! -z $UA_SERVER_HOST ]
    then
	 if [ -z "$ENABLE_STANDALONE" ]
	 then
         SSO_SERVER_HOST=$UA_SERVER_HOST
         save_prompt "SSO_SERVER_HOST"
	 fi

    fi
    if [ -z $SSO_SERVER_HOST ]
	then 
		prompt "SSO_SERVER_HOST"
	fi
	
    if [ -z "$IS_COMMON_PASSWORD" ]
    then
    	common_pwd
	fi
    prompt_port "ID_VAULT_LDAP_PORT"
    # prompt "SSO_SERVER_HOST" $IP_ADDR 
    # prompt "SSO_SERVER_PORT"
	
	if [ ! -z $TOMCAT_HTTP_PORT ] && [ -z "$ENABLE_STANDALONE" ]
	then
		SSO_SERVER_PORT=$TOMCAT_HTTP_PORT
		save_prompt "SSO_SERVER_PORT"
	else
		prompt "SSO_SERVER_PORT"
	fi
    	
	if [ ! -z $UA_SERVER_SSL_PORT ] && [ -z "$ENABLE_STANDALONE" ]
	then
		SSO_SERVER_SSL_PORT=$UA_SERVER_SSL_PORT
		save_prompt "SSO_SERVER_SSL_PORT"
	else
		prompt_port "SSO_SERVER_SSL_PORT" '-' '-' "$SSO_SERVER_HOST"
	fi
    prompt_pwd "SSO_SERVICE_PWD" confirm
  
    if [ -z "$ID_VAULT_DEPLOY_CTX" ] || [ -z "$ID_VAULT_DRIVER_SET" ]
    then
	    PROMPT_SAVE="false"
	    while true
	    do    	
	    	prompt "ID_VAULT_DRIVER_SET"
	    	prompt "ID_VAULT_DEPLOY_CTX"
	    	RET=0
	    	if [ "$CREATE_SILENT_FILE" != true ]
	    	then
	    		verify_ldap_dn $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD "cn=$ID_VAULT_DRIVER_SET,$ID_VAULT_DEPLOY_CTX"
	    		RET=$?
	    	fi
	    	if (( $RET != 0 )); 
	    		then
	             	echo_sameline ""
	                echo_sameline "${txtred}"
	                str2=`gettext install "ERROR: Container does not exist."`
	                write_and_log "$str2"
	                echo_sameline "${txtrst}"
	                echo_sameline "${txtylw}"
	                read1=`gettext install "To re-enter the container details, press Enter."`
	                read -p "$read1"
	                echo_sameline "${txtrst}"
	                echo_sameline ""
	            else
	                echo ""
	                break
	       fi
		done
		save_prompt "ID_VAULT_DRIVER_SET"
		save_prompt "ID_VAULT_DEPLOY_CTX"
	fi
	
	if [ "$CONFIGURING_ENGINE" != "true" ]
	then
		prompt "UA_CREATE_DRIVERS"
		if [ "$UA_CREATE_DRIVERS" == "n" ]
		then
			prompt "UA_DRIVER_NAME"
		else
			UA_DRIVER_NAME="User Application Driver"
			save_prompt "UA_DRIVER_NAME"
		fi
	else
		UA_CREATE_DRIVERS="y"
		UA_DRIVER_NAME="User Application Driver"
		save_prompt "UA_CREATE_DRIVERS"
		save_prompt "UA_DRIVER_NAME"
	fi
    prompt "UA_ADMIN"
    prompt_pwd "UA_ADMIN_PWD" confirm
    if [ -f ${IDM_KEYSTORE_PATH} ] && [ "$CREATE_SILENT_FILE" != true ]
    then
	str2=`gettext install "Installer has detected that an Identity Manager keystore exists."`
        write_log "$str2"
    fi
   
    prompt_pwd "IDM_KEYSTORE_PWD" confirm
    if [ -z "$OSPPromptNotNeeded" ]
    then
      prompt_pwd "OSP_KEYSTORE_PWD" confirm
    fi
    prompt "UA_CLUSTER_ENABLED" - "y/n"
    if [ ! -z "$AZURE_CLOUD" ] && [ "$AZURE_CLOUD" == "y" ]
    then
    	echo "Masking the prompt for workflow engine id" &> /dev/null
    else
    	prompt "UA_WORKFLOW_ENGINE_ID"
    fi
    prompt "UA_WFE_DB_PLATFORM_OPTION" - "postgres/oracle/mssql"
    if [ "$UA_WFE_DB_PLATFORM_OPTION" == "postgres" ]
    then
    	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "n" ]
	then
        	prompt "INSTALL_PG_DB" - "y/n"
	else
		INSTALL_PG_DB="n"
		save_prompt "INSTALL_PG_DB"
	fi
        if [ "$INSTALL_PG_DB" == "n" ]
        then
            prompt "UA_WFE_DB_HOST" "$UA_SERVER_HOST"
        else
            UA_WFE_DB_HOST=$UA_SERVER_HOST
	       save_prompt "UA_WFE_DB_HOST"
        fi
    else
        prompt "UA_WFE_DB_HOST" "$UA_SERVER_HOST"
    fi
    if [ "$UA_WFE_DB_PLATFORM_OPTION" == "postgres" ] && [ "$INSTALL_PG_DB" == "y" ]
    then
	prompt_port "UA_WFE_DB_PORT" '-' '-' "$UA_WFE_DB_HOST"
    else
	prompt "UA_WFE_DB_PORT" 
    fi
	
	if [ "$UA_WFE_DB_PLATFORM_OPTION" == "oracle" ]
	then
	    prompt "UA_ORACLE_DATABASE_TYPE" - "sid/service"
	fi
	
    prompt "UA_DATABASE_NAME"
    prompt "WFE_DATABASE_NAME"
    prompt "UA_WFE_DATABASE_USER"
    if [ ! -z "$IS_ADVANCED_MODE" ] && [ "$IS_ADVANCED_MODE" == "true" ]
    then
    prompt_pwd "UA_WFE_DATABASE_PWD" confirm force
    else
    prompt_pwd "UA_WFE_DATABASE_PWD" confirm
    fi
    if [ ! -z "$INSTALL_PG_DB" ] && [ "$INSTALL_PG_DB" == "y" ] && [ "$CREATE_SILENT_FILE" != true ]
    then
    	install_postgres
    fi
    prompt_file "UA_WFE_DB_JDBC_DRIVER_JAR"
    if [ ! -z "$UA_WFE_DB_PLATFORM_OPTION" ] && [ "$UA_WFE_DB_PLATFORM_OPTION" == "postgres" ]
    then
        #prompt "UA_WFE_DATABASE_ADMIN_USER"
	if [ ! -z "$IS_ADVANCED_MODE" ] && [ "$IS_ADVANCED_MODE" == "true" ]
	then
        prompt_pwd "UA_WFE_DATABASE_ADMIN_PWD" confirm force
	else
        prompt_pwd "UA_WFE_DATABASE_ADMIN_PWD" confirm
	fi
    fi

    prompt "UA_WFE_DB_CREATE_OPTION" - "now/file/startup"
    warningforDBoptions
   
    if [ "$UA_WFE_DB_CREATE_OPTION" == "now" ]
    then
      prompt "UA_DB_NEW_OR_EXIST" - "new/exist"
      prompt "WFE_DB_NEW_OR_EXIST" - "new/exist"
    elif [ "$UA_WFE_DB_CREATE_OPTION" == "file" ]
    then
	  prompt "UA_DB_NEW_OR_EXIST" - "new/exist"
	  prompt "WFE_DB_NEW_OR_EXIST" - "new/exist"
      prompt "UA_DB_SCHEMA_FILE" 
      prompt "WFE_DB_SCHEMA_FILE" 
    fi
 
    prompt "ENABLE_CUSTOM_CONTAINER_CREATION" - "y/n"
    
    if [ "${ENABLE_CUSTOM_CONTAINER_CREATION}" == "y" ]
    then
      if [ "$CREATE_SILENT_FILE" == true ] && [ ! -z $KUBERNETES_ORCHESTRATION ] && [ "$KUBERNETES_ORCHESTRATION" == "y" ]
      then
        prompt_file_required_during_silentfile "CUSTOM_CONTAINER_LDIF_PATH"
      else
        prompt_file "CUSTOM_CONTAINER_LDIF_PATH" 
      fi
    fi

    prompt "USER_CONTAINER"
    prompt "ADMIN_CONTAINER"
    prompt "ROOT_CONTAINER" 
    prompt "GROUP_ROOT_CONTAINER" 
    prompt "UA_APP_CTX"
    prompt "WFE_APP_CTX"
    prompt "TOMCAT_HTTP_PORT"
	prompt_port "UA_SERVER_SSL_PORT"
	prompt "SSPR_SERVER_HOST"
	if [ "$UA_SERVER_HOST" != "$SSPR_SERVER_HOST" ]
	then
	  prompt_port "SSPR_SERVER_SSL_PORT" '-' '-' "$SSPR_SERVER_HOST"
	else
	  if [ -z "$SSPR_SERVER_SSL_PORT" ]
	  then
	    SSPR_SERVER_SSL_PORT=$UA_SERVER_SSL_PORT
	    save_prompt "SSPR_SERVER_SSL_PORT"
	  fi
	fi
	if [ ! -z "$CUSTOM_SSPR_CERTIFICATE" ] && [ "$CUSTOM_SSPR_CERTIFICATE" == "y" ]
	then
	  if [ "$UA_SERVER_HOST" == "$SSPR_SERVER_HOST" ]
	  then
	    export customuacertnotneeded=true
	  fi
	fi
	if [ ! -z "$CUSTOM_OSP_CERTIFICATE" ] && [ "$CUSTOM_OSP_CERTIFICATE" == "y" ]
	then
	  if [ "$UA_SERVER_HOST" == "$SSO_SERVER_HOST" ]
	  then
	    export customuacertnotneeded=true
	  fi
	fi

if [ ! -z "$IS_UPGRADE" ] && [ $IS_UPGRADE -eq 0 ]
then
  if [ -z "$customuacertnotneeded" ]
  then
	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	then
    if [ ! -z "$IDM_ACCESS_VIA_SINGLE_DOMAIN" ]
    then
      CUSTOM_UA_CERTIFICATE="n"
      save_prompt "CUSTOM_UA_CERTIFICATE"
    else
      CUSTOM_UA_CERTIFICATE="y"
      save_prompt "CUSTOM_UA_CERTIFICATE"
    fi
	fi
	if [ ! -z "$CUSTOM_RPT_CERTIFICATE" ] && [ "$CUSTOM_RPT_CERTIFICATE" == "y" ]
	then
	  if [ ! -z "$RPT_SERVER_HOSTNAME" ] && [ "$RPT_SERVER_HOSTNAME" == "$UA_SERVER_HOST" ]
	  then
	    CUSTOM_UA_CERTIFICATE=n
	    save_prompt "CUSTOM_UA_CERTIFICATE"
	    UA_COMM_TOMCAT_KEYSTORE_FILE=$RPT_COMM_TOMCAT_KEYSTORE_FILE
	    save_prompt "UA_COMM_TOMCAT_KEYSTORE_FILE"
	    UA_COMM_TOMCAT_KEYSTORE_PWD=$RPT_COMM_TOMCAT_KEYSTORE_PWD
	    save_prompt "UA_COMM_TOMCAT_KEYSTORE_PWD"
	  fi
	fi
	if [ ! -z "$CUSTOM_SSPR_CERTIFICATE" ] && [ "$CUSTOM_SSPR_CERTIFICATE" == "y" ]
	then
	  if [ ! -z "$SSPR_SERVER_HOST" ] && [ "$SSPR_SERVER_HOST" == "$UA_SERVER_HOST" ]
	  then
	    CUSTOM_UA_CERTIFICATE=n
	    save_prompt "CUSTOM_UA_CERTIFICATE"
	    UA_COMM_TOMCAT_KEYSTORE_FILE=$SSPR_COMM_TOMCAT_KEYSTORE_FILE
	    save_prompt "UA_COMM_TOMCAT_KEYSTORE_FILE"
	    UA_COMM_TOMCAT_KEYSTORE_PWD=$SSPR_COMM_TOMCAT_KEYSTORE_PWD
	    save_prompt "UA_COMM_TOMCAT_KEYSTORE_PWD"
	  fi
	fi
	prompt CUSTOM_UA_CERTIFICATE - "y/n"
        if [ "$CUSTOM_UA_CERTIFICATE" == "n" ] && [ -z "$UA_COMM_TOMCAT_KEYSTORE_FILE" ]
        then
                UA_COMM_TOMCAT_KEYSTORE_FILE=$IDM_TOMCAT_HOME/conf/tomcat.ks
                save_prompt "UA_COMM_TOMCAT_KEYSTORE_FILE"
                prompt_pwd "TOMCAT_SSL_KEYSTORE_PASS" confirm
                UA_COMM_TOMCAT_KEYSTORE_PWD=$TOMCAT_SSL_KEYSTORE_PASS
                save_prompt "UA_COMM_TOMCAT_KEYSTORE_PWD"
        else
                prompt_file "UA_COMM_TOMCAT_KEYSTORE_FILE"
                prompt_pwd "UA_COMM_TOMCAT_KEYSTORE_PWD" confirm
        fi
  else
    if [ ! -z "$CUSTOM_SSPR_CERTIFICATE" ] && [ "$CUSTOM_SSPR_CERTIFICATE" == "y" ]
    then
      if [ ! -z "$SSPR_SERVER_HOST" ] && [ "$SSPR_SERVER_HOST" == "$UA_SERVER_HOST" ] && [ -z "$CUSTOM_UA_CERTIFICATE" ]
      then
        CUSTOM_UA_CERTIFICATE=n
	save_prompt "CUSTOM_UA_CERTIFICATE"
	UA_COMM_TOMCAT_KEYSTORE_FILE=$SSPR_COMM_TOMCAT_KEYSTORE_FILE
	save_prompt "UA_COMM_TOMCAT_KEYSTORE_FILE"
	UA_COMM_TOMCAT_KEYSTORE_PWD=$SSPR_COMM_TOMCAT_KEYSTORE_PWD
	save_prompt "UA_COMM_TOMCAT_KEYSTORE_PWD"
      fi
    fi
	prompt_file "UA_COMM_TOMCAT_KEYSTORE_FILE"
	prompt_pwd "UA_COMM_TOMCAT_KEYSTORE_PWD" confirm
  fi
fi
    
    if [ "$UA_AUDIT_ENABLED" == "y" ]
    then
      #prompt "UA_NAUDIT_AUDIT_ENABLED" 
      prompt "UA_CEF_AUDIT_ENABLED"
    fi

    #prompt "SENTINEL_AUDIT_SERVER"


   elif [ $IS_UPGRADE -eq 1 ]
   then
    
    if [ "${IS_OSP_EXIST}" == "true" ]
    then
       prompt "OSP_INSTALL_FOLDER"
    fi

    if [ "${SSPR_INSTALLED_LOCAL}" == "true" ]
    then
       prompt "SSPR_INSTALL_FOLDER"
    else 
       prompt "UA_UPG_INSTALL_SSPR" - "y/n" 
    fi

   if [ "${UA_UPG_INSTALL_SSPR}" == "y" ]
   then
    if [ -z "$OSPPromptNotNeeded" ]
    then
      prompt_pwd "CONFIGURATION_PWD" confirm
    fi
    prompt "SSO_SERVER_HOST"
    prompt_port "SSO_SERVER_SSL_PORT"
    prompt "UA_ADMIN"
    prompt_pwd "UA_ADMIN_PWD" confirm
   fi

    prompt "UA_INSTALL_FOLDER"
  prompt_pwd "SSO_SERVICE_PWD" confirm
    prompt_file "UA_WFE_DB_JDBC_DRIVER_JAR"
    prompt "UA_WFE_DB_CREATE_OPTION" - "now/file/startup"
    warningforDBoptions
    
    if [ "$UA_WFE_DB_CREATE_OPTION" == "file" ]
    then
      prompt "UA_DB_SCHEMA_FILE"
      prompt "WFE_DB_SCHEMA_FILE"
    fi
   
    prompt "WFE_DATABASE_NAME"
    prompt_pwd "UA_WFE_DATABASE_PWD"
    if [ "$CREATE_SILENT_FILE" != true ]
    then
    	if [ -f /opt/uacon_upgrade.properties ]
    	then
    		rm /opt/uacon_upgrade.properties
		touch /opt/uacon_upgrade.properties
    	else
    		touch /opt/uacon_upgrade.properties
    	fi
    	readconfigpropertiesfordbconn
    	sed -i 's#\\##g' /opt/uacon_upgrade.properties
    	source /opt/uacon_upgrade.properties
    else
    	prompt "UA_WFE_DB_PLATFORM_OPTION" - "postgres/oracle/mssql"
    fi
    if [ "$UA_WFE_DB_PLATFORM_OPTION" == "postgres" ]
    then
        prompt_pwd "UA_WFE_DATABASE_ADMIN_PWD"
    fi
    prompt "WFE_APP_CTX"
      
   fi

	if [ ! -z "$INSTALL_REPORTING" ] && [ "$INSTALL_REPORTING" == "true" ]
	then
		prompt "RPT_SERVER_HOSTNAME" "$IP_ADDR"
		prompt "RPT_TOMCAT_HTTPS_PORT"
	fi

	if [ -z "$ACTIVEMQ_SERVER_HOST" ]
	then
		ACTIVEMQ_SERVER_HOST="localhost"
		save_prompt "ACTIVEMQ_SERVER_HOST"
		ACTIVEMQ_SERVER_TCP_PORT="61716"
		save_prompt "ACTIVEMQ_SERVER_TCP_PORT"
	fi
if [ ! -z "$IS_UPGRADE" ] && [ $IS_UPGRADE -eq 1 ]
then
#When ID_VAULT_HOST and UA_SERVER_HOST are different then giving an option to provide certificate file location with SAN
  idvaulthost=`grep -ir "com.netiq.idm.osp.ldap.host" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties | awk '{print $3}' | sed 's/^[ ]*//'`
  if [ -z ${idvaulthost} ]
  then
    idvaulthost=`grep -ir "DirectoryService/realms/jndi/params/AUTHORITY" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties | awk '{print $3}' | sed 's/^[ ]*//'`
  fi
  if [ "$idvaulthost" != "$UA_SERVER_HOST" ]
  then
    prompt "USE_EXISTING_CERT_WITH_SAN" - "y/n"
    if [ "$USE_EXISTING_CERT_WITH_SAN" == "n" ]
    then
      CUSTOM_UA_CERTIFICATE=y
      save_prompt "CUSTOM_UA_CERTIFICATE"
      prompt_file "UA_COMM_TOMCAT_KEYSTORE_FILE"
      prompt_pwd "UA_COMM_TOMCAT_KEYSTORE_PWD" confirm
    fi
  fi
fi
