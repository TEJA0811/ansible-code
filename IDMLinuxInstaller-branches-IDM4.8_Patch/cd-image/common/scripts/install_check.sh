#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

IS_INSTALL_CHECK_DONE=false

IS_OSP_INSTALLED=false
IS_UA_INSTALLED=false
IS_SSPR_INSTALLED=false
IS_REPORTINGINSTALLED=false

IS_IDVAULT_INSTALLED=false

IS_ENGINE_INSTALLED=false
IS_REPORTING_INSTALLED=false
IS_JRE_INSTALLED=false


check_installed_components()
{

if [ "$IS_INSTALL_CHECK_DONE" == false ]
then
    disp_str=`gettext install "Verifying installed components..."`
    write_and_log "$disp_str"
    if rpm -qa | grep -q netiq-osp ;  then
        IS_OSP_INSTALLED=true
    fi

    if rpm -qa | grep -q netiq-user ;  then
        IS_UA_INSTALLED=true
    fi

    if rpm -qa | grep -q netiq-sspr ;  then
        IS_SSPR_INSTALLED=true
    fi
    if rpm -qa | grep -q novell-DXMLengnx ;  then
        IS_ENGINE_INSTALLED=true
    fi
    if rpm -qa | grep -q novell-edirectory-expat ;  then
        IS_IDVAULT_INSTALLED=true
    fi

    if rpm -qa | grep -q netiq-IDMRPT ;  then
        IS_REPORTING_INSTALLED=true
    fi

    if rpm -qa | grep -q netiq-jrex- ;  then
        IS_JRE_INSTALLED=true
    fi


   
    IS_INSTALL_CHECK_DONE=true

fi

}
