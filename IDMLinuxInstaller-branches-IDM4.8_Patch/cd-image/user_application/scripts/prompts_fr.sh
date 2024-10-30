#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

    if [ ! -z "$ENABLE_STANDALONE" ] && [ "$ENABLE_STANDALONE" == "true" ]
    then
    	getValidLocalIP "$FR_SERVER_HOST"

    	vault_ip=$IP_ADDR
	prompt "FR_SERVER_HOST" "$vault_ip"
	prompt "SSO_SERVER_HOST"
	prompt_port "SSO_SERVER_SSL_PORT"
	prompt_pwd "SSO_SERVICE_PWD" confirm
	prompt "UA_SERVER_HOST" "$vault_ip"
	prompt_port "UA_SERVER_SSL_PORT"
    else
    	FR_SERVER_HOST=$UA_SERVER_HOST
	save_prompt "FR_SERVER_HOST"
    fi
  
	prompt_port "NGINX_HTTPS_PORT"

