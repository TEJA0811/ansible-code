#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

    prompt "INSTALL_IDENTITY_CONSOLE"
    getValidLocalIP "$UA_SERVER_HOST"
   
    vault_ip=$IP_ADDR
    prompt "ID_CONSOLE_SERVER_HOST" "$vault_ip"
    prompt_port "ID_CONSOLE_SERVER_SSL_PORT"
  
  if [ $IS_UPGRADE -ne 1 ]
  then

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
    prompt "IDM_KEYSTORE_PWD"
  fi
  prompt "ID_CONSOLE_USE_OSP"
  if [ ! -z $ID_CONSOLE_USE_OSP ] && [ "$ID_CONSOLE_USE_OSP" == "y" ]
  then
    prompt "SSO_SERVER_HOST"
    prompt_port "SSO_SERVER_SSL_PORT"
    prompt_pwd "SSO_SERVICE_PWD"
  fi
  