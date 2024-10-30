#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

#export INSTALL_HOME=`pwd`/../
export IDM_INSTALL_HOME=`pwd`/../

. ../common/scripts/common_install_vars.sh
. ../common/scripts/common_install_error.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh 
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/install_common_libs.sh
. ../common/scripts/locale.sh
. scripts/pre_install.sh
. scripts/merge_cust_loc.sh

initLocale

main()
{
    init    
    foldername_space_check
    parse_install_params $*
    if [ -z $ENABLE_STANDALONE ]
    then
    	exitIfnotRunfromWrapper
    fi

    system_validate
    display_copyrights

    install_common_libs `pwd`/common.deps

    disp_str=`gettext install "Installing One SSO Provider (OSP)"`
    write_and_log "$disp_str"
    
    strerr=`gettext install "One SSO Provider RPM installation failed"`
    	RPMFORCE="--force --nodeps" installrpm "${IDM_INSTALL_HOME}osp/packages" osp.list
    	check_errs $? $strerr
    	RET=$?
    	check_return_value $RET
	installrpm "${IDM_INSTALL_HOME}common/packages/tomcat" ../common/packages/tomcat/deps.list

    if [ -d /opt/netiq/idm/apps/osp ]
    then
            /usr/bin/chown -R novlua:novlua /opt/netiq/idm/apps/osp
    fi     
    cp ${IDM_INSTALL_HOME}osp/conf/configutil.sh ${OSP_INSTALL_PATH}/bin/
    cp ${IDM_INSTALL_HOME}osp/lib/netiq-configutil.jar ${OSP_INSTALL_PATH}/lib/
	mkdir -p ${UNINSTALL_FILE_DIR}/osp &> /dev/null
	yes | cp -rpf ../common ${UNINSTALL_FILE_DIR}/ &> /dev/null
	yes | cp -rpf uninstall.sh ${UNINSTALL_FILE_DIR}/osp/ &> /dev/null
    yes | cp -rpf osp.list ${UNINSTALL_FILE_DIR}/osp/ &> /dev/null
    copyThirdPartyLicense
    removetruststoreentryfromsetenv
    configupdatejre8unlink
    updatetomcatversion_for_osp
}

main $*
