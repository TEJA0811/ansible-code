#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../

. ../common/scripts/common_install_vars.sh
. ../common/scripts/common_install_error.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/license.sh 
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/install_common_libs.sh
. ../common/scripts/jre.sh
. ../common/scripts/tomcat.sh
. ../common/scripts/postgres.sh
. ../common/scripts/activemq.sh
. ../common/scripts/platform_agent.sh
. ../common/scripts/locale.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/dxcmd_util.sh
. ../common/scripts/install_info.sh
. ../common/scripts/prompts.sh

. scripts/sspr_config_util.sh
. scripts/pre_install.sh
. sspr_pre_upgrade.sh
. sspr_post_upgrade.sh
. scripts/sspr_config.sh

CONFIGURE_FILE=sspr
CONFIGURE_FILE_DISPLAY="Self Service Password Reset"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
initLocale

main()
{
    parse_install_params $*
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        local OLD_IFS=$IFS
        cleanup_tmp
    fi
    init
	create_IP_cfg_file_conditionally
    foldername_space_check
    system_validate
    display_copyrights

    if [ $IS_WRAPPER_CFG_INST -ne 1 ]
    then
    	rpm -qi netiq-tomcatconfig &> /dev/null
	rpmqueryRetValue=$?
        if [ -f "/etc/init.d/idmapps_tomcat_init" ] || [ $rpmqueryRetValue -eq 0 ]
        then
	    if [ $rpmqueryRetValue -eq 0 ]
	    then
	    	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
	    else
            	INSTALLED_FOLDER_PATH=`grep -i 'TOMCAT_PARENT_DIR=' /etc/init.d/idmapps_tomcat_init | cut -d '=' -f2`
	    fi
            if [ ! -z "${INSTALLED_FOLDER_PATH}" ]
            then
                EXISTING_SSPR_INSTALLED_PATH=`grep 'Dsspr' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh | grep -v [[:blank:]]# | grep -v ^# | awk -F "Dsspr" '{print $2}' | cut -d ' ' -f 1 | cut -d '=' -f 2 | cut -d '"' -f1 | xargs`
                #
                if [ ! -z $EXISTING_SSPR_INSTALLED_PATH ] && [ -f "${INSTALLED_FOLDER_PATH}/tomcat/webapps/sspr.war" ]
                then 
                SSPR_INSTALLED_FOLDER_PATH=`/usr/bin/dirname $EXISTING_SSPR_INSTALLED_PATH` 
                LOG_FILE_NAME=/var/opt/netiq/idm/log/sspr_upgrade.log
                write_log "$SCRIPT_VERSION"
                set_is_upgrade
                else 
                SSPR_INSTALLED_FOLDER_PATH=
                fi
            fi
        fi
        rpm -qi netiq-sspr &> /dev/null
        if [ $? -ne 0 ] && [ $IS_WRAPPER_CFG_INST -eq 0 ]
        then
    	    export IS_UPGRADE=0
        fi
       if [ ${IS_UPGRADE} -ne 1 ]
       then 
        echo_sameline ""
        str1=`gettext install "Refer log for more information at"`
        echo_sameline "${txtgrn}"
        write_and_log "$str1 ${log_file}"
        echo_sameline "${txtrst}"
        echo_sameline ""   
        disp_str=`gettext install "Installing :"`
        highlightMsg "$disp_str SSPR"
       fi
    fi

    check_upgrade_supported

    if [ ${IS_UPGRADE} -eq 1 ]
    then
       sspr_prompt_check_upgrade

        if [ $IS_WRAPPER_CFG_INST -ne 1 ]
    then
        if [ ${IS_UPGRADE} -eq 0 ]
        then
            log_file=/var/opt/netiq/idm/log/idminstall.log
        elif [ ${IS_UPGRADE} -eq 1 ]
        then
            log_file=/var/opt/netiq/idm/log/idmupgrade.log
        fi
        write_log "$SCRIPT_VERSION"
    fi
       #Exit
       if [ "${UPGRADE_IDM}" == "n" ]
       then  
        exit 0
       fi      
    
       echo_sameline ""
       str1=`gettext install "Refer log for more information at"`
       echo_sameline "${txtgrn}"
       write_and_log "$str1 ${log_file}"
       echo_sameline "${txtrst}"
       echo_sameline ""   
       disp_str=`gettext install "Upgrading :"`
       highlightMsg "$disp_str SSPR"
       
       init_prompts ../common/conf/prompts.conf
       source_prompt_file
       #
       #prompt_pwd "ID_VAULT_PASSWORD"
       prompt_pwd "IDM_KEYSTORE_PWD"
       
       source_prompt_file
       #stop existing tomcat
       if [ -f /etc/init.d/idmapps_tomcat_init ]
       then
         /etc/init.d/idmapps_tomcat_init stop
       fi
       #Create the backup folder
       create_backup
       if [ $IS_WRAPPER_CFG_INST -eq 0 ]
       then
        fcount=`ls -lrt ${IDM_TOMCAT_HOME}/webapps/*.war | grep -v sspr.war | wc -l`
        if [ ${fcount} -eq 0 ]
        then
          #Standalone sspr upgrade
          tomcatfilesbackup
        fi
      fi
        sspr_files_backup
    fi
    
    #install common libraries
    install_common_libs `pwd`/common.deps

    # Update SSPR

    installrpm "${IDM_INSTALL_HOME}sspr/packages" "${IDM_INSTALL_HOME}sspr/sspr.list"

    installrpm "${IDM_INSTALL_HOME}common/packages/tomcat" ../common/packages/tomcat/deps.list

    add_config_option $CONFIGURE_FILE
	mkdir -p ${UNINSTALL_FILE_DIR}/sspr &> /dev/null
	yes | cp -rpf ../common ${UNINSTALL_FILE_DIR}/ &> /dev/null
	yes | cp -rpf uninstall.sh ${UNINSTALL_FILE_DIR}/sspr/ &> /dev/null
    yes | cp -rpf sspr.list ${UNINSTALL_FILE_DIR}/sspr/ &> /dev/null

    if [ ${IS_UPGRADE} -eq 1 ]
    then
        upgrade_sspr_configuration
        #Upgrade
        init_standalone_setenv
        if [ $IS_WRAPPER_CFG_INST -ne 1 ]
        then
           sspr_restore_server_xml
        fi
        grantToauth
    fi

    if [ $IS_WRAPPER_CFG_INST -ne 1 ] && [ ${IS_UPGRADE} -ne 1 ]
    then
        disp_str=`gettext install "Completed installation of :"`
        highlightMsg "$disp_str SSPR"
    elif [ ${IS_UPGRADE} -eq 1 ]
    then
        disp_str=`gettext install "Completed upgrade of :"`
        highlightMsg "$disp_str SSPR"
	rm $CONFIGURE_FILE &> /dev/null
    fi

    if [ $IS_WRAPPER_CFG_INST -ne 1 ] && [ ${IS_UPGRADE} -eq 1 ]
    then
        cleanup_tmp
	RestrictAccess
    fi
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        IFS=$OLD_IFS
    fi
    copyThirdPartyLicense
    commonJREswitch
    remove32bitJRE
    removetruststoreentryfromsetenv
    RemoveAJPConnector
    addSSPRLogoutURLToWhitelist
    fixssprconfigurationxml
}

main $* 
