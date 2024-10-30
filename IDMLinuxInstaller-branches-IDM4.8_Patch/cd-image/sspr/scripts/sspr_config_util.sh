#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

SSPR=sspr
SSPR_NAME="Self Service Password Reset"

merge_default_idm_settings()
{
    local ssprIDMSettingsXML=$1
    local ssprConfigurationXML=$2

    disp_str=`gettext install "Merging the default Identity Manager settings with the SSPR configuration"`
    write_and_log "$disp_str"

    $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.sspr.MergeDefaultIDMSettings $ssprIDMSettingsXML $ssprConfigurationXML >> ${LOG_FILE_NAME}

}

# Create a stanalone setenv file for SSPR
init_standalone_setenv()
{
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        fcount=`ls -lrt ${IDM_TOMCAT_HOME}/webapps/*.war | grep -v sspr.war | wc -l`
        if [ ${fcount} -eq 0 ]
        then
            sed -i 's~CATALINA_OPTS.*$~CATALINA_OPTS="-Dsspr.applicationPath=/opt/netiq/idm/apps/sspr/sspr_data"~g' ${IDM_TOMCAT_HOME}/bin/setenv.sh
        fi
	#addtruststorepasswordTosetenv
	removetruststoreentryfromsetenv
	addcheckrevocationTosetenv
	addcrldpTosetenv
	addlogbackTosetenv
        systemctl restart netiq-tomcat >> "${LOG_FILE_NAME}" 2>&1
	if [ $? -ne 0 ]
	then
		su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh" >> "${LOG_FILE_NAME}" 2>&1
		su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh" >> "${LOG_FILE_NAME}" 2>&1
	fi
    fi
}

#Check if we should continue with upgrade
check_upgrade_supported()
{
    if [ $IS_WRAPPER_CFG_INST -eq 0 ] && [ ${IS_UPGRADE} -eq 1 ]
    then
        fcount=`ls -lrt ${IDM_TOMCAT_HOME}/webapps/*.war | grep -v sspr.war | wc -l`
        if [ ${fcount} -gt 0 ]
        then
            disp_str=`gettext install "Installer has detected additional Identity Manager components. Installer is unable to perform upgrade while other application components are installed. Refer to the SSPR documentation for detailed upgrade steps."`
            write_and_log "$disp_str"
            exit 1
        fi
	rpm -Uvh --test ${IDM_INSTALL_HOME}sspr/packages/netiq-sspr-*rpm &> /dev/null
	retCode=$?
	if [ $retCode -eq 1 ]
	then
	  msg=`gettext install "SSPR version is already up-to-date. Exiting..."`
	  write_and_log "$msg"
	  exit 1
	elif [ $retCode -eq 2 ]
	then
	  msg=$(gettext install "Installed SSPR version is newer than the one in ISO/zip. Exiting...")
	  write_and_log "$msg"
	  exit 1
	fi
    fi    
}

update_config_list()
{
    MENU_OPTIONS+=("${SSPR}")
    MENU_OPTIONS_DISPLAY+=("${SSPR_NAME}")
}

upgrade_sspr_config_xml()
{
  disp_str=`gettext install "Upgrading SSPR configuration"`
  write_and_log "$disp_str"

  local ssprConfigurationXML=$1  

  $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.sspr.UpdateSSPRConfiguration "${ssprConfigurationXML}" "${LOG_FILE_NAME}"
}
