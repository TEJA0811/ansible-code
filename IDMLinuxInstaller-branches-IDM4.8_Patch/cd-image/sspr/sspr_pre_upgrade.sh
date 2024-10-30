#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

upgrade_sspr_install()
{
    if [ ${IS_UPGRADE} -eq 1 ] && [ $IS_WRAPPER_CFG_INST -eq 1 ]
    then
    	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
    	EXISTING_SSPR_INSTALLED_PATH=`grep 'Dsspr' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh | grep -v [[:blank:]]# | grep -v ^# | awk -F "Dsspr" '{print $2}' | cut -d ' ' -f 1 | cut -d '=' -f 2 | cut -d '"' -f1 | xargs`
	if [ ! -z $EXISTING_SSPR_INSTALLED_PATH ]
	then
		SSPR_INSTALLED_FOLDER_PATH=`/usr/bin/dirname $EXISTING_SSPR_INSTALLED_PATH`
	fi
	rpm -qi netiq-sspr &> /dev/null
	ssprrpmpresence=$?
    	if [ -z $SSPR_INSTALLED_FOLDER_PATH ] || [ "$SSPR_INSTALLED_FOLDER_PATH" == "" ] || [ $ssprrpmpresence -ne 0 ]
	then
		write_log "Skipping upgrade of sspr"
		rpm -e netiq-sspr &> /dev/null
		rpm -e netiq-ssprconfig &> /dev/null
		return 0
	fi
    fi
    ## 
    RPMFORCE="--force" installrpm "${IDM_INSTALL_HOME}sspr/packages" "${IDM_INSTALL_HOME}sspr/sspr.list"
    CONFIGURE_FILE=sspr
    add_config_option $CONFIGURE_FILE
}

create_backup()
{
    IDM_BACKUP_FOLDER=/opt/netiq/idm_backup_$(date +%Y%m%d_%H%M%S)
    mkdir -p ${IDM_BACKUP_FOLDER}

    str1=`gettext install "SSPR configuration is backed up at"`
    write_and_log "$str1 ${IDM_BACKUP_FOLDER}"
    echo_sameline ""
}

sspr_files_backup()
{
  if [ -d ${EXISTING_SSPR_INSTALLED_PATH} ]
  then
   if [ -f ${EXISTING_SSPR_INSTALLED_PATH}/SSPRConfiguration.xml ]
   then
     cp -rpf ${EXISTING_SSPR_INSTALLED_PATH}/SSPRConfiguration.xml ${IDM_BACKUP_FOLDER}/
   fi

   if [ -d ${EXISTING_SSPR_INSTALLED_PATH}/LocalDB ]
   then
     cp -rpf ${EXISTING_SSPR_INSTALLED_PATH}/LocalDB ${IDM_BACKUP_FOLDER}/
   fi
  fi
 
  if [ -d ${SSPR_INSTALLED_FOLDER_PATH} ]
  then
    cp -rpf ${SSPR_INSTALLED_FOLDER_PATH}/ ${IDM_BACKUP_FOLDER}/
    #rm -rf ${SSPR_INSTALLED_FOLDER_PATH}
  fi
}

tomcatfilesbackup()
{
 #
 if [ -d ${INSTALLED_FOLDER_PATH}/tomcat/ ]
 then
    cp -rpf ${INSTALLED_FOLDER_PATH}/tomcat/ ${IDM_BACKUP_FOLDER}/
 fi
 if [ -d ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/ ]
 then
    cp -rpf ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/ ${IDM_BACKUP_FOLDER}/
 fi

 #rm -rf ${INSTALLED_FOLDER_PATH}/tomcat/
 rm -rf ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/
}

