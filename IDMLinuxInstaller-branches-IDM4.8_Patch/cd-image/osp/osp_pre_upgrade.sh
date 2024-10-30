#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

upgrade_pre_install()
{
    disp_str=`gettext install "Installing One SSO Provider (OSP)"`
    write_and_log "$disp_str"

    strerr=`gettext install "One SSO Provider RPM installation failed"`
    RPMFORCE="--force" installrpm "${IDM_INSTALL_HOME}osp/packages" "${IDM_INSTALL_HOME}osp/osp.list"
    check_errs $? $strerr
    RET=$?
    check_return_value $RET



    cp ${IDM_INSTALL_HOME}osp/conf/configutil.sh ${OSP_INSTALL_PATH}/bin/
    cp ${IDM_INSTALL_HOME}osp/lib/netiq-configutil.jar ${OSP_INSTALL_PATH}/lib/
}

