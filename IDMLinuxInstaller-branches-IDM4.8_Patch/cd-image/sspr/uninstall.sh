#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. ../common/scripts/common_install_vars.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/locale.sh
IDM_INSTALL_HOME=`pwd`/../
initLocale

LOG_FILE_NAME=/var/opt/netiq/idm/log/idmuninstall.log
SSPRVERSIONINST=

checkSSPRExist()
{
  SSPRVERSIONINST=`rpm -qi netiq-sspr 2>>$log_file | grep "Version" | awk '{print $3}'`
}

main()
{
    if [ $IS_WRAPPER_CFG_INST -ne 1 ]
    then
        if [ ${IS_UPGRADE} -eq 0 ]
        then
            log_file=/var/opt/netiq/idm/log/idmuninstall.log
        fi
        write_log "$SCRIPT_VERSION"
    fi
  parse_install_params $*
  checkSSPRExist 
  if [ "$SSPRVERSIONINST" != "" ]
  then
     
     str=`gettext install "sspr uninstallation"`
     write_and_log "$INSTR $str"
 
     uninstallrpm sspr sspr.list
	 rm -rf /opt/netiq/idm/apps/sspr
	 rm -rf /opt/netiq/idm/uninstall_data/sspr
  fi 
}
set_log_file "${LOG_FILE_NAME}"
main $*
