#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

install_activemq()
{
        if [ -d "/opt/netiq/common/activemq" ]
        then
                str1=`gettext install "ActiveMQ is already installed."`
                write_and_log "$str1"
        else
                install_rpm "ActiveMQ" "*.rpm" "${IDM_INSTALL_HOME}common/packages/activemq" "${MAIN_INSTALL_LOG}" "--nodeps"
        fi

}





