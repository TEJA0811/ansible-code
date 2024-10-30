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

CONFIGURE_FILE=reporting
CONFIGURE_FILE_DISPLAY="Identity Reporting"
IDMVERSIONINST=

main()
{
    uninstallrpm reporting reporting.list
    rm -rf /opt/netiq/idm/apps/tomcat/webapps/IDMRPT-CORE/build-info.json
	uaver=`UAAppVersion`
	[ "$uaver" == "" ] && [ -d ../osp ] && [ -f ../osp/osp.list ] && cd ../osp && ./uninstall.sh && cd - && uninstallrpm "common/packages/tomcat" deps.list
	rm -rf /opt/netiq/idm/apps/IDMReporting
	rm -rf /opt/netiq/idm/uninstall_data/reporting
	remove_config_file ${CONFIGURE_FILE} 
}

main $*
