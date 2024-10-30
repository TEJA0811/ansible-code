#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

install_tomcat_tar()
{
    disp_str=`gettext install "Installing Tomcat "`
    write_and_log "$disp_str"
    mkdir /opt/netiq/common/idm
    tar -zxvf ${IDM_INSTALL_HOME}common/packages/tomcat/apache-tomcat-8.5.16.tar.gz -C /opt/netiq/common/idm >/dev/null
    mv /opt/netiq/common/idm/apache-tomcat-8.5.16/ /opt/netiq/common/idm/tomcat
}

install_tomcat()
{
    if [ -f "/etc/init.d/netiq-userapp" ]
    then
        echo_sameline "Tomcat already installed, hence skipping." >> ${MAIN_INSTALL_LOG}
    else
        install_rpm "Tomcat base" "netiq-tomcat-base*.rpm" "${IDM_INSTALL_HOME}common/packages/tomcat" "${MAIN_INSTALL_LOG}" 
		install_rpm "Tomcat configuration" "netiq-tomcat-config*.rpm" "${IDM_INSTALL_HOME}common/packages/tomcat" "${MAIN_INSTALL_LOG}"
	fi
}






