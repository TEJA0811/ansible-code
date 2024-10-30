#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

#    init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf
#    source_prompt_file

#    UNIQUE_NAME=`uname -n |cut -d '.' -f 1 | sed -e "s/[^[:alnum:]]/_/g"`

    if [ ! -z "$DOCKER_CONTAINER" ] && [ "$DOCKER_CONTAINER" == "y" ] && [ -z "$standadvanPrompted" ] && [ "$CREATE_SILENT_FILE" != true ]
    then
        if [ ! -z "$UNATTENDED_INSTALL" ] && [ $UNATTENDED_INSTALL -eq 0 ]  
        then
                VAL="false"
                prompt_stand_advan "configure"
                if [ $VAL == "false" ]
                then
                        IS_ADVANCED_EDITION="false"
                else
                        IS_ADVANCED_EDITION="true"
                fi
        fi
        overwriteidme
	export standadvanPrompted="yes"
    fi

    if [ ! -z "$DOCKER_CONTAINER" ] && [ "$DOCKER_CONTAINER" == "y" ]
    then
	ID_VAULT_VARDIR="/var/opt/novell/eDirectory"
	save_prompt "ID_VAULT_VARDIR"
	ID_VAULT_DIB="/var/opt/novell/eDirectory/data/dib"
	save_prompt "ID_VAULT_DIB"
	ID_VAULT_CONF="/etc/opt/novell/eDirectory/conf/nds.conf"
	save_prompt "ID_VAULT_CONF"
    fi	
    if [ -z "$IS_COMMON_PASSWORD" ] && [ $IS_UPGRADE -eq 0 ]
    then
    	common_pwd
	fi
	
    UNIQUE_NAME=`uname -n |cut -d '.' -f 1 | sed -e "s/[^[:alnum:]]/_/g"`
	checkeDirExist()
	{
		EDIRVERSIONINST=`rpm -qi novell-NDSserv | grep "Version" | awk '{print $3}'`
		if [ "$EDIRVERSIONINST" == "" ]
		then
			EDIRVERSIONINST=`rpm -qi edirectory-oes-server 2>>$log_file | grep "Version" | awk '{print $3}'`
		fi
	}
	setidvtreename_and_hoststring()
	{
		if [ "$CREATE_SILENT_FILE" != true ] && [ "$ndsmanagepresent" == "0" ]
		then
			echo "q" > /tmp/ndsmanage-input
			conf_file=`LC_ALL=en_US ndsmanage < /tmp/ndsmanage-input | grep " ACTIVE" | awk '{print $2}'`
			rm -f /tmp/ndsmanage-input
			LC_ALL=en_US ndsconfig get n4u.base.tree-name --config-file ${conf_file} &> /dev/null
			if [ $? -eq 0 ] 
			then
				ID_VAULT_TREENAME=`LC_ALL=en_US ndsconfig get n4u.base.tree-name --config-file ${conf_file} | grep n4u.base.tree-name | cut -d"=" -f2`
				hoststring=`LC_ALL=en_US ndsconfig get n4u.server.interfaces --config-file ${conf_file} | awk -F '=|,' '{sub("@",":",$2);print $2}' | sed '/^$/d'`
			else
				str1=`gettext install "IDVault Tree Name couldn't be fetched"`
				[ $IS_UPGRADE -eq 1 ] && write_log "${str1}"
			fi
		fi
	}
	if [ $IS_UPGRADE -eq 1 ] || [ "$UPGRADE_IDM" == "y" ]
	then
		#Just setting this variable so that TREE_CONFIG related prompt is not asked
		TREE_CONFIG="upgradetree"
		save_prompt "TREE_CONFIG"
	fi
	if [ $IS_UPGRADE -eq 0 ]
	then
	  prompt "ID_VAULT_HOST" "$vault_ip"
	fi
	OPT=true
	# Take backup of product selection and their names
	SELECTIONBACK=("${SELECTION[@]}")
	SELECTION_DISPLAYBACK=("${SELECTION_DISPLAY[@]}")
	MENU_USER_CHOICESBACK=("${MENU_USER_CHOICES[@]}")
	iBACK=${i}
	COUNTBACK=${COUNT}
	if [ -z "$TREE_CONFIG" ]
	then
		PROMPT_SAVE="false"
		SELECTION=()
		SELECTION_DISPLAY=()
		MENU_USER_CHOICES=()
		if [ "$IS_ADVANCED_MODE" == "false" ] || ([ ! -z "$TERRAFORM_GENERATE" ] && [ "$TERRAFORM_GENERATE" == "y" ])
		then
			# Typical
			TREE_CONFIG="newtree"
			checkeDirExist
			userid=`id -u`
			if [ "$CREATE_SILENT_FILE" != true ]
			then
				if [ "$EDIRVERSIONINST" == "" -o -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
				then
					str1=`gettext install "The installer has detected an Identity Vault on the system. If you proceed with the Identity Manager setup, select Custom configuration and choose an existing tree."`
					write_and_log "${str1}"
					exit 1
				fi
			fi
		else
			# Custom configuration
			while ${OPT}
			do
				SELECTION=()
				SELECTION_DISPLAY=()
				MENU_USER_CHOICES=()
				checkeDirExist
				userid=`id -u`				
				MENU_OPTIONS=("newtree" "existingtreeremote" "existingtreelocal")
				str_op1=`gettext install "Create a new Identity Vault"`
				str_op2=`gettext install "Add to an Identity Vault existing on remote machine"`
				str_op3=`gettext install "Add to an Identity Vault existing on local machine"`				
				MENU_OPTIONS_DISPLAY=("$str_op1" "$str_op2" "$str_op3")
				MESSAGE=`gettext install "Select the configuration mode :"`
				get_user_input
				local COUNT=${#SELECTION[@]}
				if ((${COUNT} != 1 ))
				then
					str1=`gettext install "Invalid configuration mode. Choose only one option.."`
					write_and_log "${str1}"
					continue
				else
					OPT=false
				fi
				CFG_MODE=${SELECTION[0]}
				if [ "$CFG_MODE" == "newtree"  ]
				then
					TREE_CONFIG="newtree"
				elif [ "$CFG_MODE" == "existingtreeremote"  ]
				then
					TREE_CONFIG="existingtreeremote"
				elif [ "$CFG_MODE" == "existingtreelocal"  ]
				then
					TREE_CONFIG="existingtreelocal"
				fi
				if [ "$TREE_CONFIG" == "newtree" ] && [ "$EDIRVERSIONINST" == "" -o -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ] && [ "$CREATE_SILENT_FILE" != true ]
				then
					if [ "$EDIRVERSIONINST" == "" ]
					then
						str1=`gettext install "The installer has detected that the Identity Vault is not installed on the system.."`
						write_and_log "${str1}"
					fi
					if [ -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
					then
						str1=`gettext install "The installer has detected that the Identity Vault is installed and configured on the system."`
						write_and_log "${str1}"
					fi
					#str1=`gettext install "The installer has detected an Identity Vault on the system. If you proceed with the Identity Manager setup, select Custom configuration and choose an existing tree."`
					#write_and_log "${str1}"
					continue
				# create new tree locally positive case and break
				elif [ "$TREE_CONFIG" == "newtree" ] && [ "$EDIRVERSIONINST" != "" -a ! -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
				then
					break
				# add to existing tree remote negative cases
				elif [ "$TREE_CONFIG" == "existingtreeremote" ] && [ "$EDIRVERSIONINST" == "" -o -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ] && [ "$CREATE_SILENT_FILE" != true ]
				then
					if [ "$EDIRVERSIONINST" == "" ]
					then
						str1=`gettext install "The installer has detected that the Identity Vault is not installed on the system.."`
						write_and_log "${str1}"
					fi
					if [ -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
					then
						str1=`gettext install "The installer has detected that the Identity Vault is installed and configured on the system."`
						write_and_log "${str1}"
					fi
					#str1=`gettext install "The installer has detected that the Identity Vault is not installed on the system..  If you wish to use it for Identity Manager setup, retry after Identity Vault install"`
					#write_and_log "${str1}"
					continue
				# add to existing tree remote positive case and break
				elif [ "$TREE_CONFIG" == "existingtreeremote" ] && [ "$EDIRVERSIONINST" != "" ]
				then
					break
				# use existing tree already configured locally negative cases
				elif [ "$TREE_CONFIG" == "existingtreelocal" ] && [ "$EDIRVERSIONINST" == "" -o ! -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ] && [ "$CREATE_SILENT_FILE" != true ]
				then
					if [ "$EDIRVERSIONINST" == "" ]
					then
						str1=`gettext install "The installer has detected that the Identity Vault is not installed on the system.."`
						write_and_log "${str1}"
					fi
					if [ ! -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
					then
						str1=`gettext install "The installer has detected that the Identity Vault is installed and not configured on the system.."`
						write_and_log "${str1}"
					fi
					continue
				# use existing tree already configured locally positive cases and break
				elif [ "$TREE_CONFIG" == "existingtreelocal" ] && [ "$EDIRVERSIONINST" != "" -a -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
				then
					break
				fi
				if [ "$CREATE_SILENT_FILE" == true ]
				then
					break
				fi
			done
		fi
		save_prompt "TREE_CONFIG"
		if [ "$set_TERRAFORM_GENERATE" == "n" ]
		then 
			TERRAFORM_GENERATE="n"
			save_prompt "TERRAFORM_GENERATE"
		fi
	fi
	SELECTION=("${SELECTIONBACK[@]}")
	SELECTION_DISPLAY=("${SELECTION_DISPLAYBACK[@]}")
	MENU_USER_CHOICES=("${MENU_USER_CHOICESBACK[@]}")
	i=${iBACK}
	COUNT=${COUNTBACK}
	CHECK_ndslogin=true
	ndsmanage --help &> /dev/null
	ndsmanagepresent=$?
	setidvtreename_and_hoststring
	if [ \( "$TREE_CONFIG" == "existingtreeremote" -a \( -z "$ID_VAULT_EXISTING_SERVER" -o -z "$ID_VAULT_EXISTING_NCP_PORT" -o -z "$ID_VAULT_EXISTING_LDAPS_PORT" -o -z "$ID_VAULT_EXISTING_CONTEXTDN" \) \) -o \( "$TREE_CONFIG" != "existingtreeremote" -a \( -z "$ID_VAULT_TREENAME" -o -z "$ID_VAULT_ADMIN_LDAP" -o -z "$ID_VAULT_PASSWORD" \) \) ]
	then
		PROMPT_SAVE="false"
		while ${CHECK_ndslogin}
		do
			setidvtreename_and_hoststring
			if [ "$TREE_CONFIG" == "existingtreeremote" ]
			then
				prompt "ID_VAULT_EXISTING_SERVER"
				prompt "ID_VAULT_EXISTING_NCP_PORT"
				prompt "ID_VAULT_EXISTING_LDAPS_PORT"
				prompt "ID_VAULT_EXISTING_CONTEXTDN"
			fi
			if [ "$CREATE_SILENT_FILE" == true ] || [ $IS_UPGRADE -ne 1 ] 
			then
				prompt "ID_VAULT_TREENAME" ${UNIQUE_NAME}_tree
				if [ ! -z $AZURE_CLOUD ] && [ "$AZURE_CLOUD" == "y" ]
				then
					echo &> /dev/null
				else
				prompt "ID_VAULT_SERVERNAME"
				fi
			fi
			if [ "$TREE_CONFIG" == "newtree" ] && [ $IS_UPGRADE -ne 1 ] && [ -z "$ID_VAULT_SERVER_CONTEXT" ]
			then
			    prompt "ID_VAULT_SERVER_CONTEXT"
			fi
			prompt "ID_VAULT_ADMIN_LDAP"

			convert_dot_notation ${ID_VAULT_ADMIN_LDAP}

			prompt "ID_VAULT_ADMIN" $RET
			if [ "$TREE_CONFIG" != "newtree" ]
			then
				prompt_pwd "ID_VAULT_PASSWORD"
			else
				prompt_pwd "ID_VAULT_PASSWORD" confirm
			fi
			RC=0
			if [ "$TREE_CONFIG" == "newtree" ]
			then
				CHECK_ndslogin=false
			elif [ "$TREE_CONFIG" == "existingtreelocal" ] || [ "$TREE_CONFIG" == "upgradetree" ]
			then
				if [ ! -z ${hoststring} ]
				then
					source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} -h ${hoststring} &> /dev/null
					RC=$?
				else
					source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} &> /dev/null
					RC=$?
				fi
			elif [ "$TREE_CONFIG" == "existingtreeremote" ]
			then
				source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -h ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} &> /dev/null
				RC=$?
			fi
			
			if [ $RC -ne 0 ] && [ "$CREATE_SILENT_FILE" != true ]
			then
				str1=`gettext install "Entered credentials are incorrect.  Enter the credentials again."`
				write_and_log "${str1}"
			else
				CHECK_ndslogin=false
			fi
			
			if [ "$CREATE_SILENT_FILE" == true ]
			then
				CHECK_ndslogin=false
			fi
		done
		if [ "$TREE_CONFIG" == "existingtreeremote" ]
		then
		  save_prompt "ID_VAULT_EXISTING_SERVER"
		  save_prompt "ID_VAULT_EXISTING_NCP_PORT"
		  save_prompt "ID_VAULT_EXISTING_LDAPS_PORT"
		  save_prompt "ID_VAULT_EXISTING_CONTEXTDN"
		fi
		save_prompt "ID_VAULT_SERVER_CONTEXT"
		save_prompt "ID_VAULT_TREENAME"
		save_prompt "ID_VAULT_SERVERNAME"
		save_prompt "ID_VAULT_ADMIN_LDAP"
		save_prompt "ID_VAULT_ADMIN"
		save_prompt "ID_VAULT_PASSWORD"
	fi
	if [ "$TREE_CONFIG" == "newtree" ]
	then
	  prompt "ID_VAULT_RSA_KEYSIZE"
	  prompt "ID_VAULT_EC_CURVE"
	  prompt "ID_VAULT_CA_LIFE"
	fi
	RC=0
	if [ "$TREE_CONFIG" == "existingtreelocal" ]
	then
		if [ ! -z ${hoststring} ]
		then
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} -h ${hoststring} &> /dev/null
			RC=$?
		else
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} &> /dev/null
			RC=$?
		fi
	elif [ "$TREE_CONFIG" == "existingtreeremote" ]
	then
		source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -h ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} &> /dev/null
		RC=$?
	fi
	
	if [ $RC -ne 0 ] && [ $UNATTENDED_INSTALL -eq 1 ] && [ "$CREATE_SILENT_FILE" != true ]
	then
		str1=`gettext install "Entered credentials are incorrect.  Enter the credentials again."`
		write_and_log "${str1}"
		exit 1
	fi
	if [ "$TREE_CONFIG" == "newtree" ] || [ "$TREE_CONFIG" == "existingtreeremote" ]
	then
		prompt "ID_VAULT_VARDIR"
	fi
		if [ $IS_UPGRADE -eq 1 ]
		then
			check_if_btrfs
			if [ $? -eq 1 ]
			then
				exit 1
			fi
		else
		[ "$TREE_CONFIG" != "existingtreelocal" ] && [ "$TREE_CONFIG" != "upgradetree" ] && prompt_ndsData "ID_VAULT_DIB"
		fi
		
	if [ "$TREE_CONFIG" == "newtree" ] || [ "$TREE_CONFIG" == "existingtreeremote" ]
	then
		prompt_port "ID_VAULT_NCP_PORT"
		prompt_port "ID_VAULT_LDAP_PORT"
	fi
		prompt_port "ID_VAULT_LDAPS_PORT"
	if [ "$TREE_CONFIG" == "newtree" ] || [ "$TREE_CONFIG" == "existingtreeremote" ]
	then
		prompt_port "ID_VAULT_HTTP_PORT"
		prompt_port "ID_VAULT_HTTPS_PORT"
		prompt "ID_VAULT_CONF"
	fi
	if [ "$TREE_CONFIG" == "existingtreeremote" ] || [ "$TREE_CONFIG" == "existingtreelocal" ]
	then
		prompt "IS_DRIVERSET_REQ" - "y/n"
	fi

	if [ "$IS_DRIVERSET_REQ" == "y" ] || [ "$TREE_CONFIG" == "newtree" ]
	then
		prompt "ID_VAULT_DRIVER_SET"
		if [ -z "$ID_VAULT_DRIVER_SET" ]
  		then
    		prompt "ID_VAULT_DRIVER_SET"
    	fi
	    if [ -z "$ID_VAULT_DEPLOY_CTX" ] 
	    then
			prompt "ID_VAULT_DEPLOY_CTX"
		fi
		if [ -z "$CUSTOM_DRIVERSET_CONTAINER_LDIF_PATH" ]
		then
			if [ "$ID_VAULT_DEPLOY_CTX" != "o=system" ]
			then
				prompt_file "CUSTOM_DRIVERSET_CONTAINER_LDIF_PATH"
			fi
		fi
	fi	
	if [ ! -z "$IS_DRIVERSET_REQ" ] && [ "$IS_DRIVERSET_REQ" == "n" ]
	then
		if [ -z "$ID_VAULT_DEPLOY_CTX" ] || [ -z "$ID_VAULT_DRIVER_SET" ]
            	then
                    PROMPT_SAVE="false"
                    while true
                    do
                        prompt "ID_VAULT_DRIVER_SET"
                        prompt "ID_VAULT_DEPLOY_CTX"
                        RET=0
                        if [ "$CREATE_SILENT_FILE" != true ] && [ "$TREE_CONFIG" != "existingtreeremote" ]
                        then
                                verify_ldap_dn $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD "cn=$ID_VAULT_DRIVER_SET,$ID_VAULT_DEPLOY_CTX"
                                RET=$?
                        elif [ "$CREATE_SILENT_FILE" != true ] && [ "$TREE_CONFIG" == "existingtreeremote" ]
                        then
                                verify_ldap_dn $ID_VAULT_EXISTING_SERVER $ID_VAULT_EXISTING_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD "cn=$ID_VAULT_DRIVER_SET,$ID_VAULT_DEPLOY_CTX"
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
		PROMPT_SAVE="true"
	fi

