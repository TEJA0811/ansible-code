#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

install_ua_utils()
{
        install_rpm "User application utils" "netiq-userapputils-*.rpm" "${IDM_INSTALL_HOME}user_application/packages/ua" "${log_file}" "--nodeps"

}

install_ua_wars()
{
        install_rpm "User application wars" "netiq-userapp-*.rpm" "${IDM_INSTALL_HOME}user_application/packages/ua" "${log_file}" "--nodeps --force "

}


install_sspr()
{
    local CURR_DIR=`pwd`
    cd ${IDM_INSTALL_HOME}sspr
    ./install.sh $*
    cd $CURR_DIR


}


copy_tomcat_configs()
{

disp_str=`gettext install "Creating tomcat configuration"`
echo "$disp_str"

mkdir ${IDM_TOMCAT_HOME}/conf
cp ${IDM_TOMCAT_HOME_BASE}/conf/* ${IDM_TOMCAT_HOME}/conf/

}
