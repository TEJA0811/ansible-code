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
LOG_FILE_NAME=/var/opt/netiq/idm/log/idmuninstall.log
IDM_INSTALL_HOME=`pwd`/../
initLocale
OSPVERSIONINST=

checkOSPExist()
{
  OSPVERSIONINST=`rpm -qi netiq-osp 2>>$log_file | grep "Version" | awk '{print $3}'`
}

main()
{
  parse_install_params $*
  
  checkOSPExist 
  if [ "$OSPVERSIONINST" != "" ]
  then
     
     str=`gettext install "OAuth uninstallation"`
     write_and_log "$INSTR $str"
 
     uninstallrpm osp osp.list
	 rm -rf /opt/netiq/idm/apps/osp
	 rm -rf /opt/netiq/idm/uninstall_data/osp
  fi 
}
set_log_file "${LOG_FILE_NAME}"
main $*
