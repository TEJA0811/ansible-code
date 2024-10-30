#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export INSTALL_HOME=`pwd`/../
EDIRVERSIONINST=

. ../common/scripts/common_install_vars.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh 
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. scripts/pre_install.sh
. ../common/scripts/locale.sh

LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log

main()
{
	parse_install_params $*
	set_log_file "${LOG_FILE_NAME}"
	
	init
	if [ "${IDM_INSTALL_HOME}" == "" ]
	then
		# this script might have been invoked in a standalone manner
		IDM_INSTALL_HOME=${DIR}/../
	fi
	initLocale
	foldername_space_check
	exitIfnotRunfromWrapper
	system_validate
	display_copyrights
	checkeDirExist

	if [ "$EDIRVERSIONINST" == "" ]
	then
		## eDirectory is not installed, proceed with eDirectory install bundled in ISO
                str1=`gettext install "Installing Identity Store"` 
	        write_and_log  "$str1"
		$IDM_INSTALL_HOME/IDVault/setup/nds-install -u >> ${LOG_FILE_NAME}
		## After installation update the EDIRVERSIONINST variable with the updated eDirectory install
		checkeDirExist
	else
		str1=`gettext install "Install has detected Identity Vault"`
		write_and_log " $str1 $EDIRVERSIONINST."
		## Compare with eDirectory installed, supported eDirectory version. If it is same then proceed with IDM install
		EDIRVERSIONINST=`echo $EDIRVERSIONINST | cut -d"." -f1-2`
		SUPPORTED_EDIR_VERSION=`echo $SUPPORTED_EDIR_VERSION | cut -d"." -f1-2`
		if [ "$EDIRVERSIONINST" != "$SUPPORTED_EDIR_VERSION" ]
		then
			## if eDirectory installed is not the same as supported then request for upgrade the eDirectory
			echo "$EDIRVERSIONINST" | grep "$SUPPORTED_EDIR_VERSION" >/dev/null
			if [ $? -eq 1 ]
			then	
				str2=`gettext install "Identity Manager may not function properly. Upgrade to the supported version of Identity Vault."`
				write_and_log "$INSTR $str2"
				EDIRVERSIONINST=
				# Removing the exit 9 here since we are already checking with the user whether to proceed or not
				#exit 9
			fi
		fi
	fi
	mkdir -p ${UNINSTALL_FILE_DIR}/IDVault &> /dev/null
	yes | cp -rpf ../common ${UNINSTALL_FILE_DIR}/ &> /dev/null
	yes | cp -rpf ../IDVault/uninstall.sh ${UNINSTALL_FILE_DIR}/IDVault/ &> /dev/null
	copyThirdPartyLicense
}

(main $1)
