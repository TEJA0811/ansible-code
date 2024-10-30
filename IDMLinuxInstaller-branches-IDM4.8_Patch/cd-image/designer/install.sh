#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. ../common/scripts/common_install_vars.sh
. ../common/conf/global_paths.sh
. ../common/conf/global_variables.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh 
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/install_common_libs.sh
. ../common/conf/global_paths.sh
. ../common/scripts/common_install_error.sh
. ../common/scripts/locale.sh

IDM_INSTALL_HOME=`pwd`/../
CONFIGURE_FILE=designer
CONFIGURE_FILE_DISPLAY="Identity Manager designer"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log

initLocale

main()
{
    parse_install_params $*
    init
    # check if designer exists ... if not, then install
    if [ ! -d "$DESIGNER_HOME" ]
    then
        str1=`gettext install "Installing headless designer"`
        write_and_log "$str1"
        CWD=`pwd`
	if [ ! -d "/opt/netiq/idm" ]
        then
                mkdir -p /opt/netiq/idm >> /dev/null
        fi
        unzip ${IDM_INSTALL_HOME}/designer/packages/*.zip -d /opt/netiq/idm/ >>/dev/null 2>>$LOG_FILE_NAME
        disp_str=`gettext install "Headless designer installation failed. Check logs for more details."`
        check_errs $? $disp_str
        cd "${CWD}"
    else
        str1=`gettext install "Designer is already setup ... skipping..."`
        write_and_log "$str1"
    fi
    copyThirdPartyLicense
}

init()
{
    set_log_file "$LOG_FILE_NAME"
}

main $*
