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

. scripts/pre_install.sh
. scripts/ua_configure.sh
. scripts/drivers.sh

CONFIGURE_FILE=user_application
CONFIGURE_FILE_DISPLAY="Identity Applications Forms Renderer"
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

    CUR=`pwd`
    [ -z "$FR_STANDALONE" ] && source $DIR/../user_application/scripts/prompts_fr.sh
    cd $CUR
    
    	strerr=`gettext install "NGINX: Configuration failed. Check configure logs for more details."`
    	configure_nginx
    	check_errs $? $strerr
    	RET=$?
    	check_return_value $RET

    # Grant rights to home novlua directory
	chown -R novlua:novlua "/home/users/novlua" >> "${log_file}" 2>&1
	
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

    [ $IS_UPGRADE -ne 1 ] && Replace80and443PortWithNULL
}


main $*
