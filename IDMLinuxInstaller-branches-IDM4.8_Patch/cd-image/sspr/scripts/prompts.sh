#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################  
    
    prompt "INSTALL_SSPR"

    getValidLocalIP "$SSO_SERVER_HOST"
    vault_ip=$IP_ADDR
    if [ "$IS_WRAPPER_CFG_INST" -eq 1 ] && [ $IS_UPGRADE -eq 0 ]
    then
     if [ ! -z "$IS_ADVANCED_EDITION" ] && [ "$IS_ADVANCED_EDITION" == "false" ]
     then
      UA_SERVER_HOST=noUA
      save_prompt "UA_SERVER_HOST"
      UA_SERVER_SSL_PORT=8543
      save_prompt "UA_SERVER_SSL_PORT"
     else
      prompt "UA_SERVER_HOST" "$vault_ip"
      prompt_port "UA_SERVER_SSL_PORT"
     fi
    fi
    if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
    then
      prompt "FOR_SSPR_CONTAINER" - "y/n"
      if [ ! -z "$FOR_SSPR_CONTAINER" ] && [ "$FOR_SSPR_CONTAINER" == "y" ]
      then
        if [ -z "$SSPR_SERVER_SSL_PORT" ]
	then
          SSPR_SERVER_SSL_PORT=8443
	  save_prompt "SSPR_SERVER_SSL_PORT"
	fi
	if [ -z "$CUSTOM_SSPR_CERTIFICATE" ]
	then
	  CUSTOM_SSPR_CERTIFICATE=n
	  save_prompt "CUSTOM_SSPR_CERTIFICATE"
	fi
	if [ -z "$SSPR_COMM_TOMCAT_KEYSTORE_FILE" ]
	then
	  SSPR_COMM_TOMCAT_KEYSTORE_FILE=NA
	  save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_FILE"
	fi
	if [ -z "$SSPR_COMM_TOMCAT_KEYSTORE_PWD" ]
	then
	  SSPR_COMM_TOMCAT_KEYSTORE_PWD=notapplicable
	  save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_PWD"
	fi
      fi
    fi
    prompt "SSPR_SERVER_HOST" "$vault_ip"
    if [ "$IS_WRAPPER_CFG_INST" -eq 0 ]
    then
      prompt_port "SSPR_SERVER_SSL_PORT" '-' '-' "$SSPR_SERVER_HOST"
      TOMCAT_HTTPS_PORT=$SSPR_SERVER_SSL_PORT
      save_prompt "TOMCAT_HTTPS_PORT"
    fi
    if [ ! -z "$UA_SERVER_HOST" ] && [ ! -z "$SSPR_SERVER_HOST" ] && [ "$UA_SERVER_HOST" != "$SSPR_SERVER_HOST" ]
    then
      prompt_port "SSPR_SERVER_SSL_PORT" '-' '-' "$SSPR_SERVER_HOST"
    elif [ ! -z "$UA_SERVER_HOST" ] && [ ! -z "$SSPR_SERVER_HOST" ] && [ "$UA_SERVER_HOST" == "$SSPR_SERVER_HOST" ]
    then
      SSPR_SERVER_SSL_PORT=$UA_SERVER_SSL_PORT
      save_prompt "SSPR_SERVER_SSL_PORT"
      if [ ! -z "$UA_COMM_TOMCAT_KEYSTORE_PWD" ]
      then
        if [ -z "$SSPR_COMM_TOMCAT_KEYSTORE_PWD" ]
	then
          SSPR_COMM_TOMCAT_KEYSTORE_PWD=$UA_COMM_TOMCAT_KEYSTORE_PWD
	  save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_PWD"
	fi
      fi
    fi
    if [ ! -z "$SSPR_SERVER_SSL_PORT" ] && [ "$IS_WRAPPER_CFG_INST" -eq 0 ]
    then
      #sspr standalone
      TOMCAT_HTTPS_PORT=$SSPR_SERVER_SSL_PORT
      save_prompt "TOMCAT_HTTPS_PORT"
    fi
    if [ ! -z "$UA_SERVER_SSL_PORT" ] && [ "$IS_WRAPPER_CFG_INST" -eq 1 ]
    then
      #ua configure from wrapper
      TOMCAT_HTTPS_PORT=$UA_SERVER_SSL_PORT
      save_prompt "TOMCAT_HTTPS_PORT"
    fi
    if [ "$IS_WRAPPER_CFG_INST" -eq 1 ] && [ ! -z "$UA_SERVER_HOST" ] && [ ! -z "$SSPR_SERVER_HOST" ]
    then
      if [ "$UA_SERVER_HOST" == "$SSPR_SERVER_HOST" ]
      then
        export customssprcertnotneeded=true
	export enablessprconfiguration=true
	if [ -z "$TOMCAT_HTTPS_PORT" ]
	then
	  TOMCAT_HTTPS_PORT=$UA_SERVER_SSL_PORT
	  save_prompt "TOMCAT_HTTPS_PORT"
	fi
      else
        remove_config_file sspr
	export customssprcertnotneeded=true
      fi
    fi
    if [ "$CREATE_SILENT_FILE" == true ] && [ $IS_IDM_CFG_SELECTED -eq 1 ] && [ -z $ID_VAULT_HOST ]
    then
        ID_VAULT_HOST='127.0.0.1'
    fi 

    if [[  -z "$ID_VAULT_HOST"  ||  -z "$ID_VAULT_LDAPS_PORT" || -z "$ID_VAULT_ADMIN_LDAP"  || -z "$ID_VAULT_PASSWORD"  ]]
    then

        PROMPT_SAVE="false"
        while true
        do
            prompt "ID_VAULT_HOST" "$vault_ip"
            prompt_port "ID_VAULT_LDAPS_PORT" '-' '-' "$ID_VAULT_HOST"
            prompt "ID_VAULT_ADMIN_LDAP"
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
       save_prompt "ID_VAULT_PASSWORD"
    fi

    if [ -z "$IS_COMMON_PASSWORD" ]
    then
    	common_pwd
	fi
	
    if [ -z "$OSPPromptNotNeeded" ]
    then
    prompt "USER_CONTAINER"
    prompt "ADMIN_CONTAINER"
    fi

    if [ "$CREATE_SILENT_FILE" == true ] && [ $IS_IDM_CFG_SELECTED -eq 1 ] && [ "$ID_VAULT_HOST" == "127.0.0.1" ]
    then
        ID_VAULT_HOST=$SSPR_SERVER_HOST
        save_prompt "ID_VAULT_HOST"
    fi  
    
    if [ -z $ENABLE_STANDALONE ]
    then
	prompt "TOMCAT_HTTP_PORT"
	prompt_port "TOMCAT_HTTPS_PORT"
	SSPR_SERVER_SSL_PORT=$TOMCAT_HTTPS_PORT
    else
	TOMCAT_HTTPS_PORT=$SSPR_SERVER_SSL_PORT
    fi
    if [ ! -z "$CUSTOM_OSP_CERTIFICATE" ] && [ "$CUSTOM_OSP_CERTIFICATE" == "y" ]
    then
      if [ ! -z "$SSPR_SERVER_HOST" ] && [ ! -z "$SSO_SERVER_HOST" ]
      then
        if [ "$SSPR_SERVER_HOST" == "$SSO_SERVER_HOST" ]
        then
          export customssprcertnotneeded=true
        fi
      fi
    fi
    if [ -z "$OSPPromptNotNeeded" ] && [ -z "$customssprcertnotneeded" ]
    then
    	if [ ! -z "$CUSTOM_RPT_CERTIFICATE" ] && [ "$CUSTOM_RPT_CERTIFICATE" == "y" ]
	then
	  if [ ! -z "$RPT_SERVER_HOSTNAME" ] && [ "$RPT_SERVER_HOSTNAME" == "$SSPR_SERVER_HOST" ]
	  then
	    CUSTOM_SSPR_CERTIFICATE=n
	    save_prompt "CUSTOM_SSPR_CERTIFICATE"
	    SSPR_COMM_TOMCAT_KEYSTORE_FILE=$RPT_COMM_TOMCAT_KEYSTORE_FILE
	    save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_FILE"
	    SSPR_COMM_TOMCAT_KEYSTORE_PWD=$RPT_COMM_TOMCAT_KEYSTORE_PWD
	    save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_PWD"
	  fi
	fi
	prompt CUSTOM_SSPR_CERTIFICATE - "y/n"
	if [ "$CUSTOM_SSPR_CERTIFICATE" == "n" ] && [ -z "$SSPR_COMM_TOMCAT_KEYSTORE_FILE" ]
	then
		SSPR_COMM_TOMCAT_KEYSTORE_FILE=$IDM_TOMCAT_HOME/conf/tomcat.ks
		save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_FILE"
		prompt_pwd "TOMCAT_SSL_KEYSTORE_PASS" confirm
		SSPR_COMM_TOMCAT_KEYSTORE_PWD=$TOMCAT_SSL_KEYSTORE_PASS
		save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_PWD"
	else
		prompt_file "SSPR_COMM_TOMCAT_KEYSTORE_FILE"
		prompt_pwd "SSPR_COMM_TOMCAT_KEYSTORE_PWD" confirm
	fi
    fi
    if [ -z "$OSPPromptNotNeeded" ]
    then
	prompt_pwd "CONFIGURATION_PWD" confirm
    fi


#    prompt "EXTERNAL_SSO_SERVER"
	if [ -z $SSO_SERVER_HOST ]
	then 
	  if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	  then
		prompt "SSO_SERVER_HOST" "$vault_ip"
	  else
	    if [ $IS_WRAPPER_CFG_INST -eq 1 ]
	    then
	  	SSO_SERVER_HOST=$UA_SERVER_HOST
		save_prompt "SSO_SERVER_HOST"
	    else
		prompt "SSO_SERVER_HOST" "$vault_ip"
	    fi
	  fi
	fi
	
	if [ ! -z $TOMCAT_HTTP_PORT ] && [ $IS_WRAPPER_CFG_INST -eq 1 ] && [ -z $ENABLE_STANDALONE ]
	then
		SSO_SERVER_PORT=$TOMCAT_HTTP_PORT
		save_prompt "SSO_SERVER_PORT"
	else
		prompt "SSO_SERVER_PORT"
	fi
    	
	if [ ! -z $TOMCAT_HTTPS_PORT ] && [ $IS_WRAPPER_CFG_INST -eq 1 ] && [ -z $ENABLE_STANDALONE ]
	then
		SSO_SERVER_SSL_PORT=$TOMCAT_HTTPS_PORT
		save_prompt "SSO_SERVER_SSL_PORT"
	else
	  if [ ! -z "$SSPR_SERVER_HOST" ] && [ ! -z "$SSO_SERVER_HOST" ] && [ "$SSPR_SERVER_HOST" == "$SSO_SERVER_HOST" ] 
	  then
	    if [ ! -z "$SSPR_SERVER_SSL_PORT" ]
	    then
	  	SSO_SERVER_SSL_PORT=$SSPR_SERVER_SSL_PORT
		save_prompt "SSO_SERVER_SSL_PORT"
	    fi
	  else
		prompt_port "SSO_SERVER_SSL_PORT" '-' '-' "$SSO_SERVER_HOST"
	  fi
	fi

    prompt_pwd "SSO_SERVICE_PWD" confirm
    
	prompt_pwd "IDM_KEYSTORE_PWD" confirm
    
    prompt "UA_ADMIN"
	prompt_pwd "UA_ADMIN_PWD" confirm
