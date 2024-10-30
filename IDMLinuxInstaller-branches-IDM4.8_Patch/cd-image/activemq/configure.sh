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

#CONFIGURE_FILE=sspr
#CONFIGURE_FILE_DISPLAY="Self Service Password Reset"
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
    #init
    create_IP_cfg_file_conditionally
    check_installed_components
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        #config_mode
        IS_ADVANCED_MODE="true"
    fi

       init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf $IS_ADVANCED_MODE
	if rpm -qa | grep -q netiq-activemq ; then
		IS_ACTIVEMQ_INSTALLED=true
	fi
       process_prompts "Activemq Server" $IS_ACTIVEMQ_INSTALLED 
	tcpvar=tcp://0.0.0.0:$ACTIVEMQ_SERVER_TCP_PORT
	search_and_replace "tcp://0.0.0.0:61616" $tcpvar /opt/netiq/idm/activemq/conf/activemq.xml
    
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        IFS=$OLD_IFS
    fi
}


main $*
