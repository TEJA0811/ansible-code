#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

##
# This utility is for setting a value in a property file given a property name
#
##
set_config_value()
{
local NAME = $1
local VALUE = $2
local FILE = $3

sed "s/${NAME}=.*/${NAME}=${VALUE}/g" $FILE > temfile.txt

}


###
# This utility does search and replace of text in a file.
#
###

search_and_replace()
{

FIND="$1"
REPLACE="$2"
FILE="$3"

$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ReplaceStringUtil "${FIND}" "${REPLACE}" "${FILE}" >> ${LOG_FILE_NAME} 2>&1

}

###
# This utility converts cn notation to dot notation
# Example cn=admin,ou=sa,o=system to admin.sa.system
#
###

convert_dot_notation()
{
local str="$1"
RET="`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ConvertDotNotation "${str}"`"
}


##
# Checks if edirectory is installed
##
is_vault_installed()
{
    EDIRVERSIONINST=`rpm -qi novell-NDSserv 2>>$log_file | grep "Version" | awk '{print $3}'`
    if [ "$EDIRVERSIONINST" != ""  ]
    then
       RET=1
    else 
       RET=0

    fi

}

##############################################################
# For setting up the default local ip if not set in IP.cfg
# only if there are more than two ips configured
##############################################################
create_IP_cfg_file_conditionally()
{
	IDM_TEMP=/tmp/idm_install
	if [ ! -d "${IDM_TEMP}" ]
	then
		mkdir "${IDM_TEMP}" >> /dev/null
	fi
	IP_SAVE_FILE="${IDM_TEMP}/IP.cfg"
	SINGLE_IP_SAVE_FILE="${IDM_TEMP}/SINGLEIP.cfg"
	if [ ! -f ${IP_SAVE_FILE} ]
	then
		ip_address_list=`/sbin/ip -f inet addr list | grep -E '^[[:space:]]*inet' | sed -n '/127\.0\.0\./!p' | awk '{print $2}' | awk -F '/' '{print $1}'`
		NUMBER_OF_IP_CONFIGURED=`echo $ip_address_list | awk -F' ' '{print NF; exit}'`
		if [ ${NUMBER_OF_IP_CONFIGURED} -gt "1" ]
		then
			# More than one ip has been configured
			CHOSEN_IP=`echo $ip_address_list | awk '{print $1}'`
			echo "IP_ADDR=${CHOSEN_IP}" > ${IP_SAVE_FILE}
		fi
		if [ ${NUMBER_OF_IP_CONFIGURED} -eq "1" ]
		then
			# Only one ip has been configured
			CHOSEN_IP=`echo $ip_address_list`
			echo "IP_ADDR=${CHOSEN_IP}" > ${SINGLE_IP_SAVE_FILE}
			echo "IP_ADDR=${CHOSEN_IP}" > ${IP_SAVE_FILE}
		fi
	fi
}
