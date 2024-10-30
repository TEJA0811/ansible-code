#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

install_ua_drivers() {

disp_str=`gettext install "Configuring user application drivers"`
echo  "$disp_str"

local logFilePath=get_log_file
local IDV_IP_ADDRESS=$1
local IDV_ADMIN_DN=$2
local IDV_ADMIN_PASS=$3
local IDV_DRIVERSET_DN=$4

cd ${IDM_TEMP}/

local ADMIN_DN="`echo ${IDV_ADMIN_DN} | sed 's/,/./g'|sed 's/ou=//g'|sed 's/cn=//g'|sed 's/o=//g'`"

export LD_LIBRARY_PATH=${DESIGNER_HOME}/plugins/com.novell.core.iconeditor_4.0.0.201702032115/os/linux/x86_64:${DESIGNER_HOME}/plugins/com.novell.core.jars_4.0.0.201702032115/os/linux/x86_64:$LD_LIBRARY_PATH


  ${DESIGNER_HOME}/Designer -nosplash -nl en -application com.novell.idm.rcp.DesignerHeadless -command deployDriver -p ${DESIGNER_HOME}/packages/eclipse/plugins -a ${ADMIN_DN} -w ${IDV_ADMIN_PASS} -s ${IDV_IP_ADDRESS} -c ${IDV_DRIVERSET_DN} -b "NOVLUABASE:NOVLIDMDUPPC;NOVLRSERVB:NOVLPSYNNOTF" -l ${logFilePath} -OL

cd -
}

