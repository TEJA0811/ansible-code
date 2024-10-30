#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

set_uid_permissions_to_lcache()
{
        file=/opt/novell/naudit/lcache
        if [ -e $file ]
        then
        chmod 4755 $file
        fi
}


installx64PA()
{
#	local LOG_FILE_NAME = get_log_file
        disp_str=`gettext install "Installing Platform Agent..."`
        write_and_log "$disp_str"
#        install_rpm "Audit Platform Agent" "novell-AUDTplatformagent-*_64*.rpm" "${IDM_INSTALL_HOME}common/platform_agent/" "${LOG_FILE_NAME}"
        rpm -ivh  ${IDM_INSTALL_HOME}common/packages/platform_agent/*_64*.rpm 
#>> ${LOG_FILE_NAME}  2>&1
        if [ $? -eq 0 ]
        then
                disp_str=`gettext install "Stopping the cache module..."`         
                write_and_log "$disp_str" >>  ${LOG_FILE_NAME}  2>&1
                killall -15 lcache >> ${LOG_FILE_NAME}  2>&1
        fi
        set_uid_permissions_to_lcache

}


