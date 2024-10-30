#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################  
    
    prompt "INSTALL_ACTIVEMQ"

    getValidLocalIP "$ACTIVEMQ_SERVER_HOST"
    vault_ip=$IP_ADDR
    if [ ! -z $ENABLE_STANDALONE ] && [ "$ENABLE_STANDALONE" == "true" ]
    then
    	prompt "ACTIVEMQ_SERVER_HOST" "$vault_ip"
	prompt_port "ACTIVEMQ_SERVER_TCP_PORT" '-' '-' "$ACTIVEMQ_SERVER_HOST"
    fi
    
