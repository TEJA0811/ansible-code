#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################


export IDM_INSTALL_HOME=`pwd`/../

. ../common/scripts/configureInput.sh
. ../common/scripts/common_install_vars.sh
. ../common/scripts/install_common_libs.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. conf/global_paths.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/multi_select.sh
. ../common/scripts/common_install_error.sh
. ../common/scripts/jre.sh
. ../common/scripts/tomcat.sh
. ../common/scripts/postgres.sh
. ../common/scripts/activemq.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/prompts.sh
. ../common/scripts/ldap_utils.sh
. ../common/scripts/audit.sh
. ../common/scripts/install_check.sh
. ../common/scripts/locale.sh
. ../common/scripts/dxcmd_util.sh
. ../common/scripts/database_utils.sh
. ../common/scripts/install_info.sh
. ../sspr/scripts/sspr_config.sh

. scripts/pre_install.sh
. scripts/ua_configure.sh
. scripts/drivers.sh

CONFIGURE_FILE=user_application
CONFIGURE_FILE_DISPLAY="Identity Applications"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idmconfigure.log
SKIP_LDAP_SERVER_VALIDATION="false"
DB_LOG_OUT=/var/opt/netiq/idm/log/uadb.out

initLocale

main()
{
    init
    create_IP_cfg_file_conditionally
    parse_install_params $*
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        cleanup_tmp
    fi
    check_installed_components
    config_mode
    init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf

    isAdvEdition=`is_advanced_edition "${ID_VAULT_HOST}" "${ID_VAULT_LDAPS_PORT}" "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}"`
    if [ ${isAdvEdition} -ne 1 ]
    then
        strerr=`gettext install "Identity Applications is not supported with Identity Manager standard edition."`
        check_errs 1 $strerr
    fi
   
    mkdir -p "${INITIALIZED_FILE_DIR}"
    
    if [ ! -f "${INITIALIZED_FILE_DIR}osp" ] && [ ${IS_WRAPPER_CFG_INST} -eq 0 ]
    then    	
    	#osp needs to be prompted and configured
		CFG_OSP="true"
	fi
	if [ ! -f "${INITIALIZED_FILE_DIR}sspr" ] && [ ${IS_WRAPPER_CFG_INST} -eq 0 ]
    then    	
    	#sspr needs to be prompted and configured
		CFG_SSPR="true"
	fi	
	
	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	then
		CUR=`pwd`
		source $DIR/../activemq/scripts/prompts.sh
		cd $CUR
	fi

	if [ "${CFG_OSP}" == "true" ]
	then
		CUR=`pwd`
		source $DIR/../osp/scripts/prompts.sh
		cd $CUR
	fi
	
	if [ "${CFG_SSPR}" == "true" ]
	then
		CUR=`pwd`
		source $DIR/../sspr/scripts/prompts.sh
		cd $CUR
	fi
	
    CUR=`pwd`
    [ -z "$FR_STANDALONE" ] && source $DIR/../user_application/scripts/prompts_fr.sh
    cd $CUR
    process_prompts "Identity Applications" $IS_UA_INSTALLED
   
    # source ${IDM_INSTALL_HOME}osp/scripts/prompts.sh
    # source scripts/prompts.sh
  
    write_and_log ""	
	
	if [ "${CFG_OSP}" == "true" ]
	then
		str1=`gettext install "Initializing Single Sign-on configuration... "`
        write_and_log "$str1"
		CUR=`pwd`
		if [ $UNATTENDED_INSTALL -eq 1 ]
		then
			OSP_PARAM_STR="-s -slc -ssc -log ${LOG_FILE_NAME} -sup"
		else
			OSP_PARAM_STR="-slc -ssc -log ${LOG_FILE_NAME} -sup"
		fi	
		cd $DIR/../osp
		./configure.sh ${OSP_PARAM_STR} -prod "user_application"
		mkdir -p "${INITIALIZED_FILE_DIR}"
        touch "${INITIALIZED_FILE_DIR}osp"
        cd $CUR
    fi
    if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
    then
    	if [ -z "$DOCKER_CONTAINER" ] || [ "$DOCKER_CONTAINER" != "y" ]
	then
	  install_postgres
	fi
    fi
       
    
	strinfo=`gettext install "Initializing Identity Applications configurations"`
    write_and_log "$strinfo"      
    
    strerr=`gettext install "Importing LDIF's Failed: Check Configure Logs for More Details"`
#    create_install_temp_keystore
    NCP_SERVERS=`query_server_dn`
    
    import_vault_certificates
    import_ldifs
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    strerr=`gettext install "Tomcat: Configuration failed. Check configure logs for more details."`
    configure_tomcat
    check_errs $? $strerr
    RET=$?
    check_return_value $RET
    if [ ! -z "$DOCKER_CONTAINER" ] || [ "$DOCKER_CONTAINER" == "y" ]
    then
      import_sspr_ldifs
    fi

    if [ -z "$FR_STANDALONE" ]
    then
    	strerr=`gettext install "NGINX: Configuration failed. Check configure logs for more details."`
    	configure_nginx
    	check_errs $? $strerr
    	RET=$?
    	check_return_value $RET
    fi

    generate_master_key_file

	# Grant rights to home novlua directory
	chown -R novlua:novlua "/home/users/novlua" >> "${log_file}" 2>&1
	
    strerr=`gettext install "ActiveMQ: Configuration failed: Check logs for more details."`
    configure_activemq
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    strerr=`gettext install "Auditing: Configuration failed. Check configure logs for more details."`
    
    if [ "$UA_AUDIT_ENABLED" == "y" ]
    then
      configure_auditing
      check_errs $? $strerr
      RET=$?
      check_return_value $RET
    fi


#    import_vault_certificates
# TODO: Right now driverset is hardcoded, util has to be writter to parse driverset the way needed"
    
    if [ "$UA_CREATE_DRIVERS" == "y" ]
    then
    create_driver_property_file

    strerr=`gettext install "Installing Service Drivers Failed: Check Logs for More Details"` 
	install_service_drivers "UA" "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}" "${ID_VAULT_HOST}" ${ID_VAULT_LDAPS_PORT} "cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}"
    check_errs $? $strerr
    RET=$?
    check_return_value $RET
    fi

    ##
    # Creating ssl certificate
    ##
    if [ ! -f ${IDM_TOMCAT_HOME}/conf/tomcat.ks ]
    then
     if [ ! -z "$CUSTOM_UA_CERTIFICATE" ] && [ "$CUSTOM_UA_CERTIFICATE" == "n" ]
     then
      create_ks_from_kmo ${ID_VAULT_HOST} ${ID_VAULT_LDAPS_PORT} ${ID_VAULT_ADMIN_LDAP} ${ID_VAULT_PASSWORD} dirxml $TOMCAT_SSL_KEYSTORE_PASS >> $LOG_FILE_NAME
      cp -rpf ${IDM_TEMP}/tomcat.ks ${IDM_TOMCAT_HOME}/conf/
      chmod 755 ${IDM_TOMCAT_HOME}/conf/tomcat.ks
     else
      if [ ! -z "$UA_COMM_TOMCAT_KEYSTORE_FILE" ]
      then
      	cp $UA_COMM_TOMCAT_KEYSTORE_FILE ${IDM_TOMCAT_HOME}/conf/tomcat.ks
      fi
     fi
    fi

    import_recaptcha_certs

    create_silent_property_file

    update_config_properties
    configupdate_idm
    
    strerr=`gettext install "Configupdate: Updating Configupdate failed. Check logs for more details"`
    update_config_update
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    if [ "${UA_WFE_DB_CREATE_OPTION}" == "file" ] || [ "${UA_WFE_DB_CREATE_OPTION}" == "now" ]
    then
      sed -i "s#com.netiq.idm.create-db-on-startup = true#com.netiq.idm.create-db-on-startup = false#g" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
    fi

    #May need to remove later
    callencryptclientpass

    strerr=`gettext install "Configuring database failed. Check logs for more details."`
    configure_database
    check_errs $? $strerr
    RET=$?
    check_return_value $RET


	if [ "${CFG_SSPR}" == "true" ]
	then
		str1=`gettext install "Initializing SSPR configurations. "`
        write_and_log "$str1"
		CUR=`pwd`
		if [ $UNATTENDED_INSTALL -eq 1 ]
		then
			OSP_PARAM_STR="-s -slc -ssc -wci -log ${LOG_FILE_NAME} -sup"
		else
			OSP_PARAM_STR="-slc -ssc -wci -log ${LOG_FILE_NAME} -sup"
		fi
		cd $DIR/../sspr
		./configure.sh ${OSP_PARAM_STR} -prod "user_application"
		mkdir -p "${INITIALIZED_FILE_DIR}"
        touch "${INITIALIZED_FILE_DIR}sspr"
        cd $CUR
    fi
    
    if [ ${IS_WRAPPER_CFG_INST} -ne 1 ]
    then
        if [ -f "${PASSCONF}" ]
        then
            rm "${PASSCONF}"
        fi
    fi

    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        clean_pass_conf
        backup_prompt_conf
    fi
    
    remove_config_file ${CONFIGURE_FILE}

    if [ "${UA_APP_CTX}" !=  "IDMProv" ]
    then
      if [ -f ${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war ]
      then 
        #mv ${IDM_TOMCAT_HOME}/webapps/IDMProv.war ${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war
        update_ua_context
        /usr/bin/chown novlua:novlua ${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war
      fi
    fi
    addauditcachefiledir
    
    if [ -e /etc/init.d/netiq-activemq ] && [ -e /etc/systemd/system/netiq-activemq.service ]
    then
	    systemctl restart netiq-activemq
		if [ $? -ne 0 ]
		then
			/etc/init.d/netiq-activemq stop
			/etc/init.d/netiq-activemq start
		fi
        write_log "Restarted ActiveMQ."
    fi
    if [ -z "$INSTALL_REPORTING" -o "$INSTALL_REPORTING" != "true" ]
    then
        if [ -e /etc/init.d/netiq-tomcat ] && [ -e /etc/systemd/system/netiq-tomcat.service ]
        then
		changeownershipofAppsAndACMQ
	        systemctl restart netiq-tomcat >> "${LOG_FILE_NAME}" 2>&1
		if [ $? -ne 0 ]
		then
			su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh" >> "${LOG_FILE_NAME}" 2>&1
			su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh" >> "${LOG_FILE_NAME}" 2>&1
		fi
		systemctl status netiq-tomcat &> /dev/null
		if [ true ]
		then
			systemctl stop netiq-tomcat &> /dev/null
			sleep 10s
			if [ $(systemctl is-active netiq-tomcat) == "active" ]
			then
				systemctl stop netiq-tomcat &> /dev/null
			fi
			systemctl start netiq-tomcat &> /dev/null
		fi
            write_log "Restarted Tomcat."
        fi
    fi
	
	[ $IS_UPGRADE -ne 1 ] && Replace80and443PortWithNULL
	[ $IS_UPGRADE -ne 1 ] && removeemptyConnectorPort
	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	then
	  callremoveclientpass userapp
	  sed -i '/com.netiq.idm.osp.ssl-keystore.file/d' ${ISM_CONFIG}
	  sed -i "/force_no_osp/d" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
          echo "force_no_osp=\"true\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	fi
	if [ ! -z "$CONFIGURE_FILE_DIR" ] && [ ! -f $CONFIGURE_FILE_DIR/reporting ]
	then
	  #Cleanup old lightweight designer install
	  rm -rf "$DESIGNER_HOME"
	fi
	grep -q ///IDMRPT ${ISM_CONFIG} &> /dev/null
	if [ $? -eq 0 ] && [ ! -z "$CONFIGURE_FILE_DIR" ] && [ ! -f $CONFIGURE_FILE_DIR/reporting ]
	then
	  ## Reporting values in ism can be removed here since they are not configured
	  sed -i "/com.netiq.rpt/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idmdcs/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.dcsdrv/d" ${ISM_CONFIG}
	else
	  echo "Reporting is configured" &> /dev/null
	fi
	ismPropertiesChangeUAandRPT
}


main $*
