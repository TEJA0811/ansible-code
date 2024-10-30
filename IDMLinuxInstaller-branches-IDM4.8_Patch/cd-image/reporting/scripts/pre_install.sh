#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

init()
{  
    if [ "$LOG_FILE_NAME" = "" ]
    then
        LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
    fi
    if [ $IS_UPGRADE -eq 1 ]
    then
        LOG_FILE_NAME=/var/opt/netiq/idm/log/idmupgrade.log
    fi
    set_log_file "$LOG_FILE_NAME"
}

system_validate()
{
    echo_sameline ""
}


