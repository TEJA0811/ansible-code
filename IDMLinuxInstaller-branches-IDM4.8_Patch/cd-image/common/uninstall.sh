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

main()
{
    parse_install_params $*
    if [ -f "$UNINSTALL_FILE_DIR/common.list" ]
    then
	uninstallrpm "COMMON" "common.list"
    fi
    
}

main $*
