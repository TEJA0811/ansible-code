#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

reporting_pre_upgrade()
{
    IDM_BACKUP_FOLDER=/opt/netiq/idm_backup_$(date +%Y%m%d_%H%M%S)
    #init
    #parse_install_params $*
    checksize
    mkdir -p "$IDM_BACKUP_FOLDER"
    
    rpm -qi netiq-tomcatconfig &> /dev/null
    if [ $? -eq 0 ]
    then
    	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
    else
    	INSTALLED_FOLDER_PATH=`grep -i 'TOMCAT_PARENT_DIR=' /etc/init.d/idmapps_tomcat_init | cut -d '=' -f2`
    fi
  
    RPT_JRE_HOME_PATH=`grep -i 'JAVA_HOME=' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh | cut -d '=' -f2`    

    cp ${IDM_INSTALL_HOME}reporting/rpt_upgrade.properties /opt/
 
    strerr=`gettext install "Stop all the services"`    
    stopallservices

    strerr=`gettext install "Backing up the Reporting configuration..."`
    reportingbackup

    str1=`gettext install "Reporting configuration is backed up at"`
    write_and_log "$str1 ${IDM_BACKUP_FOLDER}"
    echo_sameline ""

    #strerr=`gettext install "Read the configuration from Identity Reporting"`
    #readinstalledconfig
}
