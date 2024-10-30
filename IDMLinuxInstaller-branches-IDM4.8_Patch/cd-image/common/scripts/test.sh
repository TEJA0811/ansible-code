#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

DIR=`dirname $0`
export INSTALL_HOME=`pwd`/../../
. "$DIR/commonlog.sh"
. "$DIR/system_utils.sh"
. "$DIR/installupgrpm.sh"
. "$DIR/license.sh"
. "$DIR/os_check.sh"
. "$DIR/databaseutil.sh"

set_log_file "/tmp/abcd.txt"
getTotalMemory
getTotalCPUCore
display_copyrights

#Minimum disk space required in various directories for installing
DIRS_TO_CHECK=( "/opt/netiq"  "/var/opt/novell" "/var" "/usr" "/etc" "/tmp"  "/")
#               1GB             5MB         1GB                 512MB  25MB 1MB     10MB                        10MB   512MB
SPACE_NEEDED=( "107374182400000000"  "1073741824" "536870912" "26214400" "1048576" "10485760"  "536870912" )


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

verify_db_connection postgres novell "jdbc:postgresql://164.989.1678.47888:5432/idmuserappdb" "PostgreSQL" /home/postgresql-9.4.1212.jdbc42.jar
if [ $? -eq 0 ]
then
   write_log "Database connection success..."
else
   write_log "Database connection failed..."
fi

verify_db_connection postgres novell "jdbc:postgresql://164.989.1778.47999:5432/idmuserappdb" "PostgreSQL" /home/postgresql-9.4.1212.jdbc42.jar
if [ $? -eq 0 ]
then
   write_log "Database connection success..."
else
   write_log "Database connection failed..."
fi

verify_OSs

installrpm $DIR testrpm.list
