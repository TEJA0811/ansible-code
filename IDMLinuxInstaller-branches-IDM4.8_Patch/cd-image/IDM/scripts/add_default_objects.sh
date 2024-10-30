#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

add_default_objects()
{
	local templates_directory=$1
	
	write_log "Adding Default IDM Objects to ID Vault"
	
	getValidLocalIP "$ID_VAULT_HOST"
	ID_VAULT_HOST=$IP_ADDR
	
    if [ "$TREE_CONFIG" == "existingtreeremote" ]
    then
        ID_VAULT_HOST=${ID_VAULT_EXISTING_SERVER}
        ID_VAULT_LDAPS_PORT=${ID_VAULT_EXISTING_LDAPS_PORT}
    fi

    new_import_ldif "${templates_directory}/default-notification-collection.ldif"
    new_import_ldif "${templates_directory}/default-password-policies.ldif"
    new_import_ldif "${templates_directory}/email-templates.ldif"
}

create_driverset_container_ldif()
{
	container_ctx=$1
	CONTAINER_LDIF=$IDM_TEMP/container.ldif
	write_log "Creating ldif file for driverset and container"
	
	if [ -f $CONTAINER_LDIF ]
    then
       rm $CONTAINER_LDIF
    fi
    touch $CONTAINER_LDIF

    IFS=',' read -ra CONT_DNs <<< "$container_ctx"
    COUNTER=${#CONT_DNs[@]}
    ITEM_MARKER=`expr $COUNTER - 1`    
    for ((i=$ITEM_MARKER ; i >= 0; i--))
    do
    		dn_item=${CONT_DNs[$i]}    		
            IFS='=' read -ra LDAP_ITEMS <<< "$dn_item"
            LDAP_QUAL="${LDAP_ITEMS[0]}"
            LDAP_NAME="${LDAP_ITEMS[1]}"
            objectClass=${!LDAP_QUAL}
            ENTRY_DN=""
            ITEM_COUNTER=$ITEM_MARKER
            while [ $ITEM_COUNTER -le $COUNTER ] && [ $ITEM_MARKER -ge 0 ] 
            do
                    ENTRY_DN="$ENTRY_DN,${CONT_DNs[$ITEM_COUNTER]}"
                    ITEM_COUNTER=`expr $ITEM_COUNTER + 1`
            done
            ITEM_MARKER=`expr $ITEM_MARKER - 1`            
            ENTRY_DN="${ENTRY_DN:1:${#ENTRY_DN}-2}"

            echo "dn: $ENTRY_DN" >> $CONTAINER_LDIF
            echo "objectClass: $objectClass" >> $CONTAINER_LDIF
            echo "" >> $CONTAINER_LDIF
    done	
    
	#setup driver set ldif file for import    
}