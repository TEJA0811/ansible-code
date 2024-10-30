#!/bin/bash
if [ ! -z "$debug" ] && [ "$debug" = 'y' ]
then
	set -x
fi
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

PRODUCTSIDM=("IDM")
PRODUCTS_DISP_NAMEIDM=("Identity Manager Engine")


export IDM_INSTALL_HOME=`pwd`/../

. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/prompts.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/common_install_vars.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/install_common_libs.sh
. ../common/scripts/install_check.sh
. ../common/scripts/multi_select.sh
. ../common/scripts/common_install_error.sh
. ../common/scripts/ldap_utils.sh
. ../common/scripts/locale.sh
. ../common/scripts/dxcmd_util.sh
. ../common/scripts/install_info.sh
. scripts/add_default_objects.sh

create_IP_cfg_file_conditionally

EDIRVERSIONINST=
CONFIGURE_FILE=IDM
CONFIGURE_FILE_DISPLAY="Identity Manager Engine"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idmconfigure.log
set_log_file "${LOG_FILE_NAME}"
## eDirectory version installed obtained from novell-NDSserv rpm

initLocale

idmfailed(){
  EXITCODE=$1
  str2=`gettext install "Identity Manager Engine configuration failed with the exit code %s"`
  str2=`printf "$str2" "$EXITCODE"`
  write_and_log "$str2"
  exit $EXITCODE
}

restarteDir()
{
                str1=`gettext install "Restarting Identity Vault service"`
                write_and_log "$str1"
                str1=`gettext install "Stopping Identity Vault."`
                write_log "$str1"
                source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; ndsmanage stopall > /dev/null 2>&1
                str1=`gettext install "Starting Identity Vault"`
                write_log "$str1"
                source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; ndsmanage startall > /dev/null 2>&1
                str1=`gettext install "Identity Vault started"`
                write_log "$str1"
		sleep 15s
}

errorout_ifndsdnotfound()
{
	if [ $? -ne 0 ]
	then
		str1=$(gettext install "ndsd process is not running - exiting")
		write_and_log "$str1"
		exit 1
	fi
}

main()
{
    check_installed_components
    config_mode
    init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf
    process_prompts "Identity Engine" $IS_ENGINE_INSTALLED 
	
	cd ../IDVault
	retCode=0
	if [ ! -f ${OES_file_tocheck} ]
	then
	    ./configure.sh $*
	    retCode=$?
	fi
	RETURNED=$retCode
	if [ $RETURNED -ne 0 ]
	then
	str2=`gettext install "Identity Vault configuration failed with the exit code %s"`
	str2=`printf "$str2" "$RETURNED"`
	write_and_log "$str2"
	exit $RETURNED
	fi
	cd ../IDM
	checkeDirExist
	# ndsd process running?
	ps -p 1 | grep -q systemd
	if [ $? -eq 0 ]
	then
		# systemd process
		systemctl status ndsdtmpl* &> /dev/null
		errorout_ifndsdnotfound
	else
		# init process
		/opt/novell/eDirectory/bin/ndsstat &> /dev/null
		errorout_ifndsdnotfound
	fi
        str1=`gettext install "Configuring Identity Manager Engine"`
	write_and_log "$str1"
	userid=`id -u`
	if [ "$EDIRVERSIONINST" != "" -a -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
	then
                init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf
                source_prompt_file

				write_and_log " "
                source scripts/prompts.sh

                write_and_log " "
                restarteDir
                
                SCHEMADIR=/opt/novell/eDirectory/lib/nds-schema
		#EDIR_SCHEMA_FILES=$(ls $SCHEMADIR/*.sch)
		# Add the new schema files only in proper order otherwise schema will not be extended.
		#
		# Order of execution in schema file is crucial
		#
                EDIR_SCHEMA_FILES="vrschema.sch dvr_ext.sch sap.sch sapuser.sch nsimAux.sch WkOdrDvr.sch nxdrv.sch i5os.sch racf.sch tss.sch fanout.sch srvprv.sch nrf-extensions.sch osp.sch authsaml.sch edirectory-schema.sch blackboard.sch Banner.sch pum.sch acf2.sch Novell_Google_Schema.sch"
			 if [ -f "${PASSCONF}" ]
			 then
					
                    source "${PASSCONF}"
			 fi
				if [ "$TREE_CONFIG" == "existingtreeremote" ]
				then
					ldapconfig set "Require TLS for Simple Binds with Password=no" -a $ID_VAULT_ADMIN -w "${ID_VAULT_PASSWORD}" -t $ID_VAULT_TREENAME -p ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} > /dev/null 2>&1
				else
					ldapconfig set "Require TLS for Simple Binds with Password=no" -a $ID_VAULT_ADMIN -w "${ID_VAULT_PASSWORD}" > /dev/null 2>&1
				fi
                for SCH in $EDIR_SCHEMA_FILES
                do
		  if [ ! -f $SCHEMADIR/$SCH ]
		  then
		    continue
		  fi
						str=`gettext install "Extending Identity Manager schema"`
				    write_log "$str $SCHEMADIR/$SCH." > /dev/null 2>&1
		RC=0
		if [ "$TREE_CONFIG" == "existingtreeremote" ]
		then
               		source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndssch -h ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} -t $ID_VAULT_TREENAME $ID_VAULT_ADMIN $SCHEMADIR/$SCH -p "${ID_VAULT_PASSWORD}" > /dev/null 2>&1
	       		RC=$?
		else
               		source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndssch $ID_VAULT_ADMIN $SCHEMADIR/$SCH -p "${ID_VAULT_PASSWORD}" > /dev/null 2>&1
	       		RC=$?
		fi
	       if [ $RC -ne 0 ]
	       then
	        check_conf $RC "Error while configuring schema $SCHEMADIR/$SCH"
			idmfailed $RC
		exit 1
	       fi	
                done
				if [ "$TREE_CONFIG" == "existingtreeremote" ]
				then
					ldapconfig set "Require TLS for Simple Binds with Password=yes" -a $ID_VAULT_ADMIN -w "${ID_VAULT_PASSWORD}" -t $ID_VAULT_TREENAME -p ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} > /dev/null 2>&1
				else
					ldapconfig set "Require TLS for Simple Binds with Password=yes" -a $ID_VAULT_ADMIN -w "${ID_VAULT_PASSWORD}" > /dev/null 2>&1
				fi
                

#		prompt "ID_VAULT_TREENAME"
#               ID_VAULT_TREENAME="$return_value"

               str=`gettext install "Adding NMAS method "`
			write_log "$str ChallengeResponse."
		
		#Obtaining IDVault NCP interface
		echo "q" > /tmp/ndsmanage-input
		conf_file=`LC_ALL=en_US ndsmanage < /tmp/ndsmanage-input | grep " ACTIVE" | awk '{print $2}'`
		conf_file_dir=`dirname ${conf_file}`
		if [ ! -f /etc/opt/novell/eDirectory/conf/env_idm ]
		then
			ln -sf "${conf_file_dir}/env_idm" /etc/opt/novell/eDirectory/conf/env_idm
		fi
		rm -f /tmp/ndsmanage-input
		IDVAULT_SERVER_TCP_PORT=`LC_ALL=en_US.utf8 ndsconfig get "n4u.server.tcp-port" --config-file ${conf_file} | grep n4u.server.tcp-port | cut -d"=" -f2`
		IDVAULT_DIB_DIR=`LC_ALL=en_US.utf8 ndsconfig get "n4u.nds.dibdir" --config-file ${conf_file} | grep n4u.nds.dibdir | cut -d"=" -f2`
#		    IDVAULT_SERVER_INTERFACE=`LC_ALL=en_US.utf8 netstat -an | grep LISTEN | grep -v ":::" | grep -m1 ${IDVAULT_SERVER_TCP_PORT} | awk '{print($4)}' | cut -d":" -f1`
		    IDVAULT_SERVER_INTERFACE=`LC_ALL=en_US.utf8 ss -4tan state established dport = :${IDVAULT_SERVER_TCP_PORT} | grep -m1 -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:${IDVAULT_SERVER_TCP_PORT}" | sed -n 1p | cut -d":" -f1`
		ID_VAULT_NCP_PORT=`LC_ALL=en_US ndsconfig get n4u.server.interfaces | grep n4u.server.interfaces | awk -F'@' '{print $2}'`

		#Following code may need to be reverted once we have the IDVault fix for checkversion of methods
		#LD_LIBRARY_PATH="" /opt/novell/eDirectory/bin/nmasinst -addmethod "$ID_VAULT_ADMIN" "$ID_VAULT_TREENAME" "../IDVault/nmas/NmasMethods/Novell/ChallengeResponse/config.txt" -h ${IDVAULT_SERVER_TCP_PORT} -w "${ID_VAULT_PASSWORD}" -checkversion >> $log_file 2>&1
		if [ "$TREE_CONFIG" == "existingtreeremote" ]
		then
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/nmasinst -addmethod "$ID_VAULT_ADMIN" "$ID_VAULT_TREENAME" "../IDVault/nmas/NmasMethods/Novell/ChallengeResponse/config.txt" -h ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} -w "${ID_VAULT_PASSWORD}" >> $log_file 2>&1
			RC=$?
		else
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/nmasinst -addmethod "$ID_VAULT_ADMIN" "$ID_VAULT_TREENAME" "../IDVault/nmas/NmasMethods/Novell/ChallengeResponse/config.txt" -h ${IDVAULT_SERVER_INTERFACE}:${IDVAULT_SERVER_TCP_PORT} -w "${ID_VAULT_PASSWORD}" >> $log_file 2>&1
			RC=$?
		fi
		 if [ $RC -ne 0 ]
		 then
		    check_conf $RC "Error while Adding NMAS ChallengeResponse"
			idmfailed $RC
		     exit 1
		  fi
               str=`gettext install "Adding NMAS method "`
			write_log "$str SAML." > /dev/null 2>&1
		#Following code may need to be reverted once we have the IDVault fix for checkversion of methods
		#LD_LIBRARY_PATH="" /opt/novell/eDirectory/bin/nmasinst -addmethod "$ID_VAULT_ADMIN" "$ID_VAULT_TREENAME" "../IDVault/nmas/NmasMethods/Novell/SAML/config.txt" -h ${IDVAULT_SERVER_INTERFACE} -w "${ID_VAULT_PASSWORD}" -checkversion >> $log_file 2>&1
		if [ "$TREE_CONFIG" == "existingtreeremote" ]
		then
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/nmasinst -addmethod "$ID_VAULT_ADMIN" "$ID_VAULT_TREENAME" "../IDVault/nmas/NmasMethods/Novell/SAML/config.txt" -h ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} -w "${ID_VAULT_PASSWORD}" >> $log_file 2>&1
			RC=$?
		else
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/nmasinst -addmethod "$ID_VAULT_ADMIN" "$ID_VAULT_TREENAME" "../IDVault/nmas/NmasMethods/Novell/SAML/config.txt" -h ${IDVAULT_SERVER_INTERFACE}:${IDVAULT_SERVER_TCP_PORT} -w "${ID_VAULT_PASSWORD}" >> $log_file 2>&1
			RC=$?
		fi
		 if [ $RC -ne 0 ]
		 then
		    check_conf $RC "Error while Adding NMAS SAML"
			idmfailed $RC
		     exit 1
		  fi
					 
		if [ "$TREE_CONFIG" == "newtree" ] || [ -f ${OES_file_tocheck} ]
		then
			add_default_objects ${IDM_INSTALL_HOME}IDM/ldif
		fi
    	            
		if [ -z "${ID_VAULT_HOST}" ]
		then
			ID_VAULT_HOST=${IDVAULT_SERVER_INTERFACE}
		fi
		if [ -z "${ID_VAULT_NCP_PORT}" ]
		then
			ID_VAULT_NCP_PORT=${ID_VAULT_EXISTING_NCP_PORT}
		fi
#		if [ "$IS_ADVANCED_MODE" == "true" ]
#		then
#			if [ "$IS_DRIVERSET_REQ" == "y" ] || [ "$TREE_CONFIG" == "newtree" ]
#			then
#        		str1=`gettext install "Creating driverset and Deploy container(s)"`
#				write_and_log "$str1"
#				verify_ldap_dn $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD $ID_VAULT_DEPLOY_CTX
#				#if [ ${ID_VAULT_DEPLOY_CTX,,} != "o=system" ]
#				if [ $? -eq 1 ] && [ "$TREE_CONFIG" != "existingtreelocal" ]
#				then
#				    #if [ $ID_VAULT_DEPLOY_CTX == "o=system" ] #|| [ -z "$CUSTOM_DRIVERSET_CONTAINER_LDIF_PATH" ]
#				    #then
#					create_driverset_container_ldif $ID_VAULT_DEPLOY_CTX
#					import_ldif $IDM_TEMP/container.ldif
#					RET=$?
#					#CUSTOM_DRIVERSET_CONTAINER_LDIF_PATH
#					#else
##                        ldif_file=${CUSTOM_DRIVERSET_CONTAINER_LDIF_PATH}
##                        new_import_ldif "$ldif_file"
##                        RET=$?
##					fi
#
#					if [ $RET -ne 0 ]
#					then
#						str1=`gettext install "Failed to create deploy container(s). Aborting the configuration process..."`
#						write_and_log "$str1"
#						#exit 1
#						read -e -p "hello"
#					fi
#				fi
#			fi
#		fi
		cp  ${IDM_INSTALL_HOME}IDM/ldif/driverset.ldif $IDM_TEMP/. >>$LOG_FILE_NAME
		local ldif_file=$IDM_TEMP/driverset.ldif
		search_and_replace "___DRIVERSET_NAME___"  "cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}" "$ldif_file"
		if [ "$TREE_CONFIG" == "newtree" -o  "$TREE_CONFIG" == "existingtreelocal" -o "$TREE_CONFIG" == "existingtreeremote" ] && [ ! -z "$CUSTOM_DRIVERSET_CONTAINER_LDIF_PATH" ]
		then
			ldif_file=${CUSTOM_DRIVERSET_CONTAINER_LDIF_PATH}
		fi
		if [ "$TREE_CONFIG" == "newtree" ] || [ "$TREE_CONFIG" == "existingtreelocal" ] || [ "$TREE_CONFIG" == "existingtreeremote" ]
		then
			new_import_ldif "$ldif_file"
			RET=$?
			if [ $RET -ne 0 ]
			then
				str1=`gettext install "Failed to create driverset. Aborting the configuration process..."`
				write_and_log "$str1"
				exit 1
			fi
			str1=`gettext install "Associating server to driverset..."`
			write_and_log "$str1"
			convert_dot_notation "cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}"
			#associate_server "${ID_VAULT_HOST}" ${ID_VAULT_NCP_PORT} "${ID_VAULT_ADMIN}" "${ID_VAULT_PASSWORD}" "${RET}"
			associate_server "${ID_VAULT_HOST}" ${ID_VAULT_LDAPS_PORT} "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}" "cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}"
		fi
	fi
 
  # Copy .idme to DIB
  idmefile=$EDIR_INSTALL_DIR/.idme
  if [ -f $idmefile ]
  then
  	mv "$EDIR_INSTALL_DIR/.idme" "${IDVAULT_DIB_DIR}"
  fi


	if [ $IS_WRAPPER_CFG_INST -eq 0 ]
	then
		clean_pass_conf
		backup_prompt_conf
	fi
    restarteDir
    [ "$TREE_CONFIG" == "upgradetree" ] && [ ${IDVAULT_DIB_DIR} != "" ] && rm -f ${IDVAULT_DIB_DIR}/dx[0-9]* &> /dev/null
	#Workaround for IDM 4.7. Add the cert to cacert for the application drivers.
	add_cert_to_cacert "${ID_VAULT_HOST}" ${ID_VAULT_LDAPS_PORT} "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}" "dirxml"
	if [ ! -z "$SSLCert_notcreated" ] && [ "$SSLCert_notcreated" == "true" ]
	then
    	  restarteDir
	  add_cert_to_cacert "${ID_VAULT_HOST}" ${ID_VAULT_LDAPS_PORT} "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}" "dirxml"
	fi
    remove_config_file ${CONFIGURE_FILE}
}

configure_productIDM()
{
    PROD_NAME=$1
    COMPONENT=$2
    if [ "$PROD_NAME" = "IDMRL" ]
    then
        PROD_NAME=IDM
    fi
    if [ "$PROD_NAME" = "IDMFO" ]
    then
        PROD_NAME=IDM
    fi

    if [ "${COMPONENT}" != "" ]
    then
      ./configure.sh ${PARAM_STR} -comp ${COMPONENT} 
    else
      ./configure.sh ${PARAM_STR} 
    fi
}

update_config_listIDM()
{
    local COUNT=${#PRODUCTSIDM[@]}
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        if [ -f "${CONFIGURE_FILE_DIR}${PRODUCTSIDM[i]}" ]
        then
            MENU_OPTIONS+=("${PRODUCTSIDM[i]}")
            MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAMEIDM[i]}")
        fi
    done
}

configure_interactiveIDM()
{      

    # Get the user configuration mode...
	config_mode
	update_config_listIDM
	if [ "$IS_ADVANCED_MODE" == "true" ]
	then
		PARAM_STR="${PARAM_STR} -custom"
	else
		PARAM_STR="${PARAM_STR} -typical"
	fi
    local COUNT=${#MENU_OPTIONS[@]}
    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        PARAM_STR="${PARAM_STR} -sup" 
    fi    
    
    if [ ${COUNT} -eq 0 ]
    then
	echo_sameline "${txtcyn}"
        str1=`gettext install "No Identity Manager components available for configuration... exiting."`
        echo_sameline "${txtrst}"
        write_and_log "${str1}"
    fi
    
    # In case there are multiple products, then
    # ask for use input for the products to configure  
    COUNT=${#MENU_OPTIONS[@]}
    if [ $COUNT -gt 0 ]
    then
		if [ $IS_UPGRADE -ne 1 ]
		then
			echo_sameline "${txtylw}"
			MESSAGE=`gettext install "The following Identity Manager components are available for configuration : "`
			echo_sameline "${txtrst}"
			get_user_input "true"
        fi
        # Basing the count with menu options itself if it is upgrade.. ie., all that is available during configure would be considered.
        [ $IS_UPGRADE -ne 1 ] && COUNT=${#SELECTION[@]}
		if [ $IS_UPGRADE -eq 1 ]
		then
			SELECTION=("${MENU_OPTIONS[@]}")
			SELECTION_DISPLAY=("${MENU_OPTIONS_DISPLAY[@]}")
		fi
        init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf $IS_ADVANCED_MODE 
        # Get the user inputs..
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            #IDM
            if [ "${SELECTION[i]}" = "IDM" ] || [ "${SELECTION[i]}" = "IDMRL" ] || [ "${SELECTION[i]}" = "IDMFO" ]
            then
                if [ "${SELECTION[i]}" = "IDM" ]
                then
                    #readAndCreateUniqueVars "IDVault/IDVault.properties"
					source ../IDM/scripts/prompts.sh
                    # Validations such as edir and database to be skipped for ther components as both 
                    SKIP_LDAP_SERVER_VALIDATION="true"
                fi
            fi
        done
       # userInput ${CFG_MODE}
    
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            str1=`gettext install "Configuring :"`
            DT=`date`
			echo_sameline "${txtylw}"
            write_and_log "###############################################################"
			echo_sameline "${txtrst}"
            write_and_log " $str1 ${SELECTION_DISPLAY[i]}"
            write_and_log " $DT"
			echo_sameline "${txtylw}"
            write_and_log "###############################################################"
			echo_sameline "${txtrst}"
            write_and_log ""
            local COMPONENT=
            if [ "${SELECTION_DISPLAY[i]}" = "${PRODUCTS_DISP_NAMEIDM[0]}" ]
            then
                COMPONENT="ENGINE"
            elif [ "${SELECTION_DISPLAY[i]}" = "${PRODUCTS_DISP_NAMEIDM[1]}" ]
            then
                COMPONENT="RL"
            elif [ "${SELECTION_DISPLAY[i]}" = "${PRODUCTS_DISP_NAMEIDM[2]}" ]
            then
                COMPONENT="FOA"
            fi
			
            configure_productIDM ${SELECTION[i]} ${COMPONENT}
            str1=`gettext install "Completed configuration of :"`
			DT=`date`
	    echo_sameline "${txtylw}"
            write_and_log "###############################################################"
	    echo_sameline "${txtrst}"
            write_and_log " $str1 ${SELECTION_DISPLAY[i]}"
            write_and_log " $DT"
	    echo_sameline "${txtylw}"
            write_and_log "###############################################################"
	    echo_sameline "${txtrst}"
            write_and_log ""
            write_and_log ""
        done
    fi
}

configure_productsIDM()
{
    parse_install_params $*
    PARAM_STR="-slc -ssc -log ${LOG_FILE_NAME}"
    check_installed_components
    DT=`date`
    echo_sameline "${txtylw}"
    write_and_log "###############################################################"
    echo_sameline "${txtrst}"
	disp_str=`gettext install "Identity Manager Configuration"`
	disp_str="                  $disp_str "
    write_and_log "$disp_str"
    write_and_log "                   $DT"
    echo_sameline "${txtylw}"
    write_and_log "###############################################################"
    echo_sameline "${txtrst}"
    write_and_log ""
    PWD=`pwd`
    [ $IS_UPGRADE -ne 1 ] && remove_prompt_file

    configure_interactiveIDM
    
    #if [ ! -f "${IDMCONF}" ]
    #then
	#   write_log "${IDMCONF} is not available."
	#   return
    #fi

    clean_pass_conf
    
    backup_prompt_conf
	str1=`gettext install "Refer log for more information at"`
	[ $IS_UPGRADE -ne 1 ] && write_and_log "$str1 ${LOG_FILE_NAME}"
}

parse_install_params $*
if [ $IS_WRAPPER_CFG_INST -eq 0 ]
then
    cleanup_tmp
fi
if [ "$#" == "0" ]
then
	configure_productsIDM
else
	main $*
fi
