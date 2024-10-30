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
. ../common/scripts/components_version.sh
. ../common/scripts/locale.sh
IDM_INSTALL_HOME=`pwd`/../
initLocale
log_file="/var/opt/netiq/idm/log/idmuninstall.log"

CONFIGURE_FILE=user_application
CONFIGURE_FILE_DISPLAY="Identity Applications"
IDMVERSIONINST=

main()
{
    uninstallrpm user_application ua.list
    uninstallrpm user_application wf.list
    uninstallrpm user_application forms.list
    uninstallrpm user_application nginx.list
	uninstallrpm "common/packages/config_update/" deps.list
	rm -rf /opt/netiq/idm/apps/tomcat/webapps/idmdash/build-info.json
	[ -d ../sspr ] && [ -f ../sspr/sspr.list ] && cd ../sspr && ./uninstall.sh && cd -
	rptver=`ReportingAppVersion`
	if [ "$rptver" == "" ]
	then
		[ -d ../osp ] && [ -f ../osp/osp.list ] && cd ../osp && ./uninstall.sh && cd - && uninstallrpm "common/packages/tomcat" deps.list
	fi
	rm -rf /opt/netiq/idm/apps/configupdate
	rm -rf /opt/netiq/idm/apps/UserApplication
	rm -rf /opt/netiq/idm/uninstall_data/user_application
	remove_config_file ${CONFIGURE_FILE} 
}

main $*

