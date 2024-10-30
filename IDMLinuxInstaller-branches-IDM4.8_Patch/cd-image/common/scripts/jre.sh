#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

install_java()
{
        if [ -L "/opt/netiq/common/jre" ]
        then
                str1=`gettext install "Java is already installed."`
                write_and_log "$str1"
        else
                install_rpm "JRE" "*.rpm" "${IDM_INSTALL_HOME}common/packages/java" "${MAIN_INSTALL_LOG}" "--nodeps"
        fi
}






