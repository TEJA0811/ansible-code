#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################
. ../common/scripts/common_install_vars.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh 
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/locale.sh
. ../common/scripts/prompts.sh
. ../common/conf/global_paths.sh
log_file="/var/opt/netiq/idm/log/idmuninstall.log"

IDM_INSTALL_HOME=`pwd`/../
initLocale
CONFIGURE_FILE=IDM
CONFIGURE_FILE_DISPLAY="Identity Manager Engine"
IDMVERSIONINST=
source_prompt_file
checkIDMExist()
{
        IDMVERSIONINST=`rpm -qi novell-DXMLengnx 2>>$log_file | grep "Version" | awk '{print $3}'`
}

main()
{
	strerr=`gettext install "Please try running the uninstall.sh @ "`
    log_file=$log_file parse_install_params $* &> /dev/null
	if [ $IS_ENGINE_INSTALL -eq 0 ] && [ $IS_RL_INSTALL -eq 0 ] && [ $IS_FOA_INSTALL -eq 0 ]
	then
		write_and_log "$strerr $IDM_INSTALL_HOME"
		exit 1
	fi
    if [ $IS_ENGINE_INSTALL -eq 1 ]
    then
	    uninstallrpm IDM IDMdriver.list
	    uninstallrpm IDM IDMengine.list
	if [ ! -f $UNINSTALL_FILE_DIR/IDM/remoteLoader64.list ]
	then
		uninstallrpm IDM IDMcommon.list
		uninstallrpm IDM IDMcommon64.list
	fi
	# $UNINSTALL_IDVAULT posses the answer to whether eDirectory should be uninstalled with IDM or not?
    if [[ "$UNINSTALL_IDVAULT" == "Y" || "$UNINSTALL_IDVAULT" == "y" ]]
    then
    	if [ ! -f ${OES_file_tocheck} ]
	then
        cd ../IDVault
        ./uninstall.sh
	    cd ../IDM
	fi
    fi
    elif [ $IS_RL_INSTALL -eq 1 ]
    then
	checkIDMExist
	rpm -e novell-DXMLrdxml
	rpm -e netiq-jre
    	if [ "$IDMVERSIONINST" != "" ]
	then
		uninstallrpm IDM openssl32.list
		uninstallrpm IDM remoteLoader64.list
	else
		uninstallrpm IDM rlwithEdir.list
		uninstallrpm IDM IDMdriver.list
		uninstallrpm IDM remoteLoader64.list
	    uninstallrpm IDM IDMcommon64.list
		uninstallrpm IDM IDMcommon.list
		uninstallrpm IDM IDMcommon32.list
		uninstallrpm IDM openssl32.list
		uninstallrpm IDM openssl64.list
	fi
    elif [ $IS_FOA_INSTALL -eq 1 ]
    then
	uninstallrpm IDM IDMFanout.list
    else
        IS_ENGINE_INSTALL=1
    fi
remove_config_file ${CONFIGURE_FILE}     
}

main $*
