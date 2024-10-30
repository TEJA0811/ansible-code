#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

    getValidLocalIP
    prompt "INSTALL_OSP"

    if [ -f "${IDM_TEMP}/components.properties" ]
    then
        grep -q "reporting" "${IDM_TEMP}/components.properties"
        RET=$?
        if [ $RET -eq 0 ]
        then
            grep -q "user_application" "${IDM_TEMP}/components.properties"
            RET=$?
            if [ $RET -eq 1 ] && [ ! -f /opt/netiq/idm/apps/tomcat/webapps/idmdash.war ]
            then
	    	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "n" ]
		then
                	prompt "EXTERNAL_SSO_SERVER"
		else
			EXTERNAL_SSO_SERVER=y
			save_prompt "EXTERNAL_SSO_SERVER"
		fi
                if [ "$EXTERNAL_SSO_SERVER" == "y" ] && [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "n" ]
                then
			prompt "EXTERNAL_SSO_SERVER_HOST"
			SSO_SERVER_HOST=$EXTERNAL_SSO_SERVER_HOST
			save_prompt "SSO_SERVER_HOST"
			     write_log "OSP prompts are not asked since it is configured on external server"
	               return
                fi
            fi
        fi
    fi
if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ] && [ "$CREATE_SILENT_FILE" != true ]
then
 if [ -z "$OSPPromptNotNeeded" ]
 then
  prompt "EDIRAPI_PROMPT_NEEDED"
  prompt "UA_PROMPT_NEEDED"
  prompt "SSPR_PROMPT_NEEDED"
  prompt "RPT_PROMPT_NEEDED"
 fi
fi
if [ ! -z "$EDIRAPI_PROMPT_NEEDED" ] && [ "$EDIRAPI_PROMPT_NEEDED" == "y" ]
then
  prompt "IDCONSOLE_HOST"
  prompt "IDCONSOLE_PORT"
  prompt "EDIRAPI_TREENAME"
  prompt "ENABLE_CUSTOM_CONTAINER_CREATION"
  if [ "$ENABLE_CUSTOM_CONTAINER_CREATION" == "n" ]
  then
    CUSTOM_CONTAINER_LDIF_PATH=/tmp/emptyospspecific.ldif
    if [ "$CREATE_SILENT_FILE" != true ]
    then
      rm -rf $CUSTOM_CONTAINER_LDIF_PATH
      touch $CUSTOM_CONTAINER_LDIF_PATH
    fi
    save_prompt "CUSTOM_CONTAINER_LDIF_PATH"
  fi
fi
    if [ ! -z $ENABLE_STANDALONE ] && [ -z $EXTERNAL_SSO_SERVER ]
    then
	if [ ! -z $EXCLUSIVE_SSO ] && [ "$EXCLUSIVE_SSO" == "true" ]
	then
		EXTERNAL_SSO_SERVER=y
		save_prompt "EXTERNAL_SSO_SERVER"
	else
		if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "n" ]
		then
    		  prompt "EXTERNAL_SSO_SERVER"
		else
		  EXTERNAL_SSO_SERVER=y
		  save_prompt "EXTERNAL_SSO_SERVER"
		fi
	fi
	if [ "$EXTERNAL_SSO_SERVER" == "y" ]
	then
		prompt "SSO_SERVER_HOST" 
		prompt_port "SSO_SERVER_SSL_PORT" '-' '-' "$SSO_SERVER_HOST"
	fi
    fi

    if [ "$CREATE_SILENT_FILE" != true ] && [ -z $ID_VAULT_HOST ]
    then
        getValidLocalIP "$SSO_SERVER_HOST"
        vault_ip=$IP_ADDR
        ID_VAULT_HOST=$vault_ip
        save_prompt "ID_VAULT_HOST" 

    fi

    if [ "$CREATE_SILENT_FILE" == true ] && [ $IS_IDM_CFG_SELECTED -eq 1 ] && [ -z $ID_VAULT_HOST ]
    then
        ID_VAULT_HOST='127.0.0.1'
        save_prompt "ID_VAULT_HOST" 
    fi 

    if [[  -z "$ID_VAULT_HOST"  ||  -z "$ID_VAULT_LDAPS_PORT" || -z "$ID_VAULT_ADMIN_LDAP"  || -z "$ID_VAULT_PASSWORD"  ]]
    then
 
        PROMPT_SAVE="false"
        while true
        do	
            prompt "ID_VAULT_HOST" "$vault_ip"
            prompt "ID_VAULT_LDAPS_PORT"
            prompt "ID_VAULT_ADMIN_LDAP"

            convert_dot_notation ${ID_VAULT_ADMIN_LDAP}

            prompt "ID_VAULT_ADMIN" $RET

            prompt_pwd "ID_VAULT_PASSWORD"
        
            if [ "$SKIP_LDAP_SERVER_VALIDATION" != "true" ]
            then
               verify_ldap_connection $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD
            fi
        
           if (( $? != 0 )); then
               echo ""
			   disp_str=`gettext install "ERROR: Could not connect to the Identity Vault."`
               echo_sameline "${txtred}"
               echo "$disp_str"
               echo_sameline "${txtrst}"
			   disp_str=`gettext install "To re-enter the connection details, press Enter."`
               read -p "${txtylw}$disp_str ${txtrst}"
               echo ""
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
    
    if [ -z "$IS_COMMON_PASSWORD" ]
    then
    	common_pwd
	fi
    
    if [ "$CREATE_SILENT_FILE" == true ] && [ $IS_IDM_CFG_SELECTED -eq 1 ] && [ "$ID_VAULT_HOST" == "127.0.0.1" ]
    then
        ID_VAULT_HOST=$SSO_SERVER_HOST
        save_prompt "ID_VAULT_HOST"
    fi   
	if [ -z $EXCLUSIVE_RPT ]
	then
      prompt_pwd "SSO_SERVICE_PWD" confirm
	fi
    if [ -z "$OSPPromptNotNeeded" ]
    then
      if [ ! -z $COMMON_KEYSTORE_PWD ]
      then
        OSP_KEYSTORE_PWD=$COMMON_KEYSTORE_PWD
        save_prompt "OSP_KEYSTORE_PWD"
      fi
    	prompt_pwd "OSP_KEYSTORE_PWD" confirm
    fi
    #prompt "OSP_AUDIT_ENABLED"
    if [ -z "$OSPPromptNotNeeded" ]
    then
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
    fi
    if [ -z "$OSPPromptNotNeeded" ]
    then
	prompt "OSP_CUSTOM_NAME"
    	prompt "USER_CONTAINER"
    	prompt "ADMIN_CONTAINER"
    fi

    prompt "TOMCAT_HTTP_PORT"   
if [ ! -z $EXCLUSIVE_SSO ] && [ "$EXCLUSIVE_SSO" == "true" ]
then
	TOMCAT_HTTPS_PORT=$SSO_SERVER_SSL_PORT
	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "n" ]
	then
	  prompt "UA_ADMIN"
	  prompt_pwd "UA_ADMIN_PWD" confirm
	fi
else
	if [ -z "$OSPPromptNotNeeded" ] && [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	then
		prompt_port "TOMCAT_HTTPS_PORT"   
	fi
fi
  if [ ! -z $COMMON_KEYSTORE_PWD ]
  then
    IDM_KEYSTORE_PWD=$COMMON_KEYSTORE_PWD
    save_prompt "IDM_KEYSTORE_PWD"
    TOMCAT_SSL_KEYSTORE_PASS=$COMMON_KEYSTORE_PWD
    save_prompt "TOMCAT_SSL_KEYSTORE_PASS"
  fi
	prompt_pwd "IDM_KEYSTORE_PWD" confirm
	if [ -z "$OSPPromptNotNeeded" ]
	then
		if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
		then
      if [ ! -z "$IDM_ACCESS_VIA_SINGLE_DOMAIN" ]
      then
        CUSTOM_OSP_CERTIFICATE="n"
        save_prompt "CUSTOM_OSP_CERTIFICATE"
      else
        CUSTOM_OSP_CERTIFICATE="y"
        save_prompt "CUSTOM_OSP_CERTIFICATE"
      fi
		else
		  CUSTOM_OSP_CERTIFICATE="n"
		  save_prompt "CUSTOM_OSP_CERTIFICATE"
		fi
		prompt CUSTOM_OSP_CERTIFICATE - "y/n"
		if [ "$CUSTOM_OSP_CERTIFICATE" == "n" ]
		then
			OSP_COMM_TOMCAT_KEYSTORE_FILE=$IDM_TOMCAT_HOME/conf/tomcat.ks
			save_prompt "OSP_COMM_TOMCAT_KEYSTORE_FILE"
			prompt_pwd "TOMCAT_SSL_KEYSTORE_PASS" confirm
			OSP_COMM_TOMCAT_KEYSTORE_PWD=$TOMCAT_SSL_KEYSTORE_PASS
			save_prompt "OSP_COMM_TOMCAT_KEYSTORE_PWD"
		else
			prompt_file "OSP_COMM_TOMCAT_KEYSTORE_FILE"
			prompt_pwd "OSP_COMM_TOMCAT_KEYSTORE_PWD" confirm
		fi
	fi
if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ] && [ "$CREATE_SILENT_FILE" != true ]
then
  # Prompting all of host and port for redirects
  if [ "$UA_PROMPT_NEEDED" == "y" ]
  then
    prompt "UA_SERVER_HOST"
    prompt "UA_SERVER_SSL_PORT"
    prompt "FR_SERVER_HOST"
    prompt_port "NGINX_HTTPS_PORT"
  fi
  if [ "$SSPR_PROMPT_NEEDED" == "y" ]
  then
    prompt "SSPR_SERVER_HOST"
    prompt "SSPR_SERVER_SSL_PORT"
  fi
  if [ "$RPT_PROMPT_NEEDED" == "y" ]
  then
    prompt "RPT_SERVER_HOSTNAME"
    prompt "RPT_TOMCAT_HTTPS_PORT"
  fi
fi

