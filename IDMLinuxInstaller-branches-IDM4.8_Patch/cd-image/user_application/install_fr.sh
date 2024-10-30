#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../


. ../common/scripts/common_install_vars.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/commonlog.sh
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
. ../common/scripts/common_install_error.sh
. ../common/scripts/os_helper_utils.sh
. ../common/scripts/prompts.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/ldap_utils.sh
. ../common/scripts/database_utils.sh
. ../common/scripts/components_version.sh
. ../osp/scripts/osp_configure.sh
. ../osp/scripts/pre_install.sh
. ../osp/scripts/merge_cust_loc.sh
. ../osp/osp_pre_upgrade.sh
. ../osp/osp_post_upgrade.sh
. ../sspr/sspr_pre_upgrade.sh
. ../sspr/sspr_post_upgrade.sh
. ../sspr/scripts/sspr_config.sh
. ../sspr/scripts/sspr_config_util.sh
. ../common/scripts/ism_cfg_util.sh
. ../common/scripts/audit.sh
. ../common/scripts/locale.sh

. ./pre_upgrade.sh
. ./post_upgrade.sh


. scripts/pre_install.sh
. scripts/ua_install.sh
. scripts/ua_upgrade.sh
. scripts/ua_configure.sh


CONFIGURE_FILE=user_application
CONFIGURE_FILE_DISPLAY="Identity Applications Forms Renderer"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
#IS_UPGRADE=1

initLocale

main()
{
    parse_install_params $*
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        cleanup_tmp
    fi
    init
	create_IP_cfg_file_conditionally
    foldername_space_check
    system_validate
    display_copyrights
    write_and_log ""

    if [ $IS_UPGRADE -eq 1 ]
    then
        LOG_FILE_NAME=/var/opt/netiq/idm/log/idmupgrade.log
	fi
	IS_ADVANCED_MODE="true"
	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
	
	init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf
    
    formsinstall
	
	if [ $IS_UPGRADE -ne 1 ]
    then
      add_config_option $CONFIGURE_FILE
    fi
    copyThirdPartyLicense
}

main $*
