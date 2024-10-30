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
    set_log_file "$LOG_FILE_NAME"
}

system_validate()
{

#Minimum disk space required in various directories for installing
DIRS_TO_CHECK=( "/opt/netiq"  "/var/opt/netiq" "/var" "/usr" "/etc" "/tmp"  "/")
#               1GB             5MB         1GB                 512MB  25MB 1MB     10MB                        10MB   512MB
SPACE_NEEDED=( "107374182400000000"  "1073741824" "536870912" "26214400" "1048576" "10485760"  "536870912" )

checkAndExitDiskspace

verify_hostname
if [ $? -eq 0 ]
then
    write_log "Valid Hostname..."
fi
verify_network_address
if [ $? -eq 0 ]
then
    write_log "Valid Network Configuration..."
fi
check_port_in_use 524
if [ $? -eq 0 ]
then
    write_log "Port is in Use..."
else
    write_log "Port is available..."
fi
# validate_port 524
# if [ $? -eq 0 ]
# then
    # write_log "Valid Port..."
# else
    # write_log "Invalid Port..."
# fi

validate_port 1524
if [ $? -eq 0 ]
then
    write_log "Valid Port..."
else
    write_log "Invalid Port..."
fi

verify_OSs
if [ $? -eq 0 ]
then
    write_log "Valid OS..."
else
    write_log "Invalid OS..."
fi


}


