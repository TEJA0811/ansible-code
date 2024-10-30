#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. ../common/scripts/configureInput.sh
. ../common/scripts/common_install_vars.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/system_utils.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/prompts.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/locale.sh
source_prompt_file
IDM_INSTALL_HOME=`pwd`/../
initLocale
EDIRVERSIONINST=
LOG_FILE_NAME=/var/opt/netiq/idm/log/idmuninstall.log
UNIQUE_NAME=`uname -n |cut -d '.' -f 1 | sed -e "s/[^[:alnum:]]/_/g"`

main()
{
	set_log_file "${LOG_FILE_NAME}"
	checkeDirExist
	userid=`id -u`
	if [ -z "$ID_VAULT_TREENAME" -o -z "$ID_VAULT_ADMIN" -o -z "$ID_VAULT_PASSWORD" ] && [ -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
	then
		CHECK_ndslogin=true
		while ${CHECK_ndslogin}
		do
			prompt "ID_VAULT_TREENAME" ${UNIQUE_NAME}_tree
			prompt "ID_VAULT_ADMIN_LDAP"
			convert_dot_notation ${ID_VAULT_ADMIN_LDAP}
			prompt "ID_VAULT_ADMIN" $RET
			prompt_pwd "ID_VAULT_PASSWORD"
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} &> /dev/null
			RC=$?
			if [ $RC -ne 0 ]
			then
				str1=`gettext install "Entered credentials are incorrect.  Enter the credentials again."`
				write_and_log "${str1}"
			else
				CHECK_ndslogin=false
			fi
		done
		save_prompt "ID_VAULT_TREENAME"
		save_prompt "ID_VAULT_ADMIN"
		save_prompt "ID_VAULT_PASSWORD"
	fi
	if [ "$EDIRVERSIONINST" != "" ]
	then
		userid=`id -u`
		if [ -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
		then
			/opt/novell/eDirectory/bin/ndsconfig rm -a ${ID_VAULT_ADMIN} -w ${ID_VAULT_PASSWORD} -c
		fi
		/opt/novell/eDirectory/sbin/nds-uninstall  -u
	fi
}

main
