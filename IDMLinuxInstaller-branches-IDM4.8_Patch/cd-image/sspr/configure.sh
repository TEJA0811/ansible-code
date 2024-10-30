#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../
. ../common/scripts/common_install_vars.sh
. ../common/conf/global_variables.sh
. ../common/scripts/commonlog.sh
. ../common/conf/global_paths.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/multi_select.sh
. ../common/scripts/prompts.sh
. ../common/scripts/ldap_utils.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/install_common_libs.sh
. ../common/scripts/install_check.sh
. ../common/scripts/locale.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/dxcmd_util.sh
. ../common/scripts/install_info.sh
. scripts/sspr_config_util.sh
. scripts/pre_install.sh
. scripts/sspr_config.sh

CONFIGURE_FILE=sspr
CONFIGURE_FILE_DISPLAY="Self Service Password Reset"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idmconfigure.log

initLocale

main()
{
    parse_install_params $*    
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        local OLD_IFS=$IFS
        cleanup_tmp
    fi
    set_log_file $LOG_FILE_NAME
    init
    create_IP_cfg_file_conditionally
    check_installed_components
    if [ ! -f "$CONFIGURE_FILE_DIR/sspr" ]
    then
	echo_sameline "${txtcyn}"
        str1=`gettext install "No Identity Manager components available for configuration... exiting."`
        echo_sameline "${txtrst}"
        write_and_log "${str1}"
	exit 1
    fi
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        #config_mode
        IS_ADVANCED_MODE="true"
	export enablessprconfiguration=true
    fi
    if [ ! -z "$customssprcertnotneeded" ] && [ "$customssprcertnotneeded" == "true" ]
    then
      if [ ! -z "$enablessprconfiguration" ] && [ "$enablessprconfiguration" == "true" ]
      then
        ## sspr configuration needed
	echo "SSPR configuration" &> /dev/null
      else
        # sspr configuration not needed
        return 0
      fi
    fi

    if [ $IS_WRAPPER_CFG_INST -eq 1 ] && [ -f "/opt/ua_upgrade.properties" ]
    then
      sed -i 's#\\##g' /opt/ua_upgrade.properties
      source /opt/ua_upgrade.properties
  
      source_prompt_file
    else
       init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf $IS_ADVANCED_MODE
       process_prompts "Identity Applications" $IS_SSPR_INSTALLED 
    fi

    if [ $IS_WRAPPER_CFG_INST -ne 1 ]
    then
        echo_sameline ""
        str1=`gettext install "Refer log for more information at"`
        echo_sameline "${txtgrn}"
        write_and_log "$str1 ${LOG_FILE_NAME}"
        echo_sameline "${txtrst}"
        echo_sameline ""	
        disp_str=`gettext install "Configuring :"`
        highlightMsg "$disp_str SSPR"
        #create the keystore
		if [ ! -z "$CUSTOM_SSPR_CERTIFICATE" ] && [ "$CUSTOM_SSPR_CERTIFICATE" == "n" ]
		then
			create_ks_from_kmo ${ID_VAULT_HOST} ${ID_VAULT_LDAPS_PORT} ${ID_VAULT_ADMIN_LDAP} ${ID_VAULT_PASSWORD} dirxml $TOMCAT_SSL_KEYSTORE_PASS >> $LOG_FILE_NAME
			cp -rpf ${IDM_TEMP}/tomcat.ks ${IDM_TOMCAT_HOME}/conf/
		else
			if [ ! -z "$SSPR_COMM_TOMCAT_KEYSTORE_FILE" ]
			then
			  # copying the given keystore file as tomcat.ks
			  cp $SSPR_COMM_TOMCAT_KEYSTORE_FILE ${IDM_TOMCAT_HOME}/conf/tomcat.ks
			fi
		fi
    fi
    
    import_vault_certificates
    
    tomcatServerXmlCfg_SSPR
    rpm -qi netiq-sspr &> /dev/null
    ssprrpm=$?
    [ $ssprrpm -eq 0 ] && keystorePassToCustom_SSPR
    setTLSv12_SSPR
    #modify_server_xml
    
    [ $ssprrpm -eq 0 ] && create_SSPRConfiguration
    
    import_sspr_ldifs
    status=$?
    
    chown -R novlua:novlua ${IDM_TOMCAT_HOME}
    [ $ssprrpm -eq 0 ] && chown -R novlua:novlua ${SSPR_CONFIG_FILE_HOME}
    #
    [ $ssprrpm -eq 0 ] && chmod 644 ${SSPR_CONFIG_FILE_HOME}/SSPRConfiguration.xml 
    #disable the osp auditing
    sed -i 's/-Dcom.netiq.idm.osp.audit.enabled=true/-Dcom.netiq.idm.osp.audit.enabled=false/g' ${IDM_TOMCAT_HOME}/bin/setenv.sh

    if [ -z "${UA_UPG_INSTALL_SSPR}" ] 
    then
        TMP_LOG="${LOG_FILE_NAME}.ssprlog"
        ${IDM_JRE_HOME}/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.AddIDVCertsToSSPRCfg ${ID_VAULT_HOST} ${ID_VAULT_LDAPS_PORT} "${SSPR_CONFIG_FILE_HOME}/SSPRConfiguration.xml" "${ID_VAULT_ADMIN_LDAP}" "${TMP_LOG}" >> $TMP_LOG 2>&1
        cat "${TMP_LOG}" >> "${LOG_FILE_NAME}"
        rm "${TMP_LOG}"
    fi
    #This method call will execute only for standalone sspr installer
    init_standalone_setenv

    if [ $IS_WRAPPER_CFG_INST -ne 1 ]
    then
        if [ $status -eq 0 ]
        then
            #Update white list if the osp is on different
            update_sspr_whitelist

            disp_str=`gettext install "Completed configuration of :"`
        else
            disp_str=`gettext install "Aborted configuration of : "`
        fi
        highlightMsg "$disp_str SSPR"
        remove_config_file sspr
    fi
    
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        block_clear_port
        cleanup_tmp
	RestrictAccess
    fi
    
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        IFS=$OLD_IFS
    fi
    if [ ! -z $EXCLUSIVE_SSPR ] && [ "$EXCLUSIVE_SSPR" == "true" ]
    then
    	/opt/netiq/idm/apps/tomcat/bin/startUA.sh &> /dev/null
	RestrictAccess
	changeownershipofAppsAndACMQ
    fi
    [ $IS_UPGRADE -ne 1 ] && removeemptyConnectorPort
}


main $*
