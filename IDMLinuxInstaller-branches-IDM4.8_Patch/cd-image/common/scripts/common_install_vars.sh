#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

DIR=`dirname $0`
export INSTALL_HOME=$DIR/../../

SCRIPT_VERSION=`gettext install "IDM 4.8.8"`

INSTR="%%%"
# For silent mode, set the value of this variable to 1
UNATTENDED_INSTALL=0
# Set the IDM version for license display
CURRENT_IDM_VERSION=4.8.8
# Specify if this is an upgrade installation
IS_UPGRADE=1
# Set this variable to 1 to denote that license check has already been done by a parent script.
# In such case, any child script should not perform the check again
IS_LICENSE_CHECK_DONE=1
# Set this variable to 1 to denote that system requirement check has been done by a parent script
# In such case, any child script should not perform the check again
IS_SYSTEM_CHECK_DONE=1
# UPdate the below variable with the supported version of eDirectory for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_EDIR_VERSION=9.2.8
# UPdate the below variable with the supported version of IDM Engine for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_IDM_VERSION=4.8.0
# Same as SUPPORTED_IDM_VERSION but careful decision needed as we may support 480 to 491 with docker
# In that case this variable may never need any changes
SUPPORTED_DOCKER_IDM_VERSION=4.8.0
# UPdate the below variable with the supported version of IDM Engine for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_IDM_RL_VERSION=4.8.0
# UPdate the below variable with the supported version of IDM Engine for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_IDM_FO_VERSION=1.2.0
# UPdate the below variable with the supported version of IDM UA App for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_APP_UA_VERSION=4.8.0
# UPdate the below variable with the supported version of IDM Form Renderer for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_FR_VERSION=1.0.0
# UPdate the below variable with the supported version of IDM Reporting App for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_APP_REPORT_VERSION=6.5.0
# UPdate the below variable with the supported version of IDM iManger for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_IMANAGER_VERSION=3.2.0
# UPdate the below variable with the supported version of OSP for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_OSP_VERSION=6.3.6
# UPdate the below variable with the supported version of ActiveMQ for IDM
# Version specified in the below variable should be the minimum version
# ANy version above this should be allowd for IDM install to proceed
SUPPORTED_AMQ_VERSION=5.15.9
# Set it to 1 when called from the wrapper configure configuration for cleanups
IS_WRAPPER_CFG_INST=0
# Indicates if advanced mode of installation
#IS_ADVANCED_EDITION="false"
# For later Use
VERBOSE_MODE=false
# This is only used by the Framework installer. Set this to 1 for engine install
IS_ENGINE_INSTALL=0
# This is only used by the Framework installer. Set this to 1 for remote loader install
IS_RL_INSTALL=0
# This is only used by the Framework installer. Set this to 1 for fanout agent install
IS_FOA_INSTALL=0
# This is a temporary log file
TEMP_LOG_FILE_NAME=/tmp/temporary.log
#Specify the log file
LOG_FILE_NAME=
# Set it to 1 if you want to skip port ckeck
SKIP_PORT_CHECK=0
# Set it to 1 if you want to skip file system ckeck
SKIP_BTRFS_CHECK=0
#Skip user prompts as it may already have been answered
SKIP_PROMPTS=0
INSTALL_ONLY=0
#Indicates whether IDM is selected for configuration
IS_IDM_CFG_SELECTED=0
#Silent install filename
FILE_SILENT_INSTALL=
INSTALL_PARAMS=
CONFIGURE_FILE_DIR=/etc/opt/netiq/idm/configure/
NOT_CONFIGURED_FOR_CLOUD=/etc/opt/netiq/idm/configure/notconfiguredforcloud
INITIALIZED_FILE_DIR=/etc/opt/netiq/idm/initialized/
UNINSTALL_FILE_DIR=/opt/netiq/idm/uninstall_data/
MASTERCONFFILE=/etc/opt/netiq/idm/conf/idmprompt.properties
IDMCONF=/etc/opt/netiq/idm/conf/idmconf.properties
PASSCONF=/etc/opt/netiq/idm/conf/.pass
IDM_TEMP=/tmp/idm_install
SKIP_DB_CHECK=0
JRE8CODE_BLOCK=true

##############################################################
# Backing up prompt file of previous run
##############################################################
backup_prompt_conf()
{
    #if [ -f "${MASTERCONFFILE}" ]
    #then
    #    mv "${MASTERCONFFILE}" "${MASTERCONFFILE}_`date +'%y%m%d%H%M'`"
    #fi
    write_and_log ""
}

##############################################################
# Function to remove password configuration file 
##############################################################
clean_pass_conf()
{
    #if [ -f "${PASSCONF}" ]
    #then
    #    rm "${PASSCONF}"
    #fi
    if [ -d $IDM_TEMP ]
    then
      cd $IDM_TEMP
      cd ..
      rm -rf idm_install 
    fi  
    write_and_log ""
}

##############################################################
# Upgrade = true
##############################################################
set_is_upgrade()
{
    IS_UPGRADE=1
}

##############################################################
# Upgrade = true
##############################################################
clear_is_upgrade()
{
    IS_UPGRADE=0
}

##############################################################
# License checked = true
##############################################################
set_lic_check_done()
{
    IS_LICENSE_CHECK_DONE=1
}

##############################################################
# System checked = true
##############################################################
set_sys_check_done()
{
    IS_SYSTEM_CHECK_DONE=1
}

##############################################################
# Parse common install variables
##############################################################
parse_install_params()
{
    INSTALL_PARAMS="$*"
    while [[ $# > 0 ]]
    do
      case "$1" in
        -slc)
          set_lic_check_done
          ;;
        -ssc)
          set_sys_check_done
          ;;
        -u)
          set_is_upgrade
          ;;
        -s)
          UNATTENDED_INSTALL=1
          ;;
        -f)
          FILE_SILENT_INSTALL=${2}
	  if [ -f $FILE_SILENT_INSTALL ] && [ -z $SILENT_FILE_SET ]
	  then
	  	FILE_SILENT_INSTALL=$(readlink -m $FILE_SILENT_INSTALL)
		SILENT_FILE_SET=true
	  fi
          shift
          ;;
        -comp)
          CVAL=${2}
          #echo "Received install parameter : $CVAL"
          if [ "${CVAL}" = "ENGINE" ]
          then
            IS_ENGINE_INSTALL=1
          elif [ "${CVAL}" = "RL" ]
          then
            IS_RL_INSTALL=1
          elif [ "${CVAL}" = "FOA" ]
          then
            IS_FOA_INSTALL=1
          fi
          shift
          ;;
        -log)
          LOG_FILE_NAME=${2}
          shift
          ;;
        -sup)
          SKIP_PROMPTS=1
          ;;
        -wci)
          IS_WRAPPER_CFG_INST=1
          ;;
        -ad)
          IS_ADVANCED_EDITION="true"
          ;;
        -sd)
          IS_ADVANCED_EDITION="false"
          ;;
        -typical)
          IS_ADVANCED_MODE="false"
          ;;
        -custom)
          IS_ADVANCED_MODE="true"
          ;;
        -prod)
          PROD_NAME=${2}
          if [ "${PROD_NAME}" = "IDMRL" ]
          then
            PROD_NAME="IDM"
          elif [ "${PROD_NAME}" = "IDMFO" ]
          then
            PROD_NAME="IDM"
          fi
          shift
          ;;
        -verbose)
          VERBOSE_MODE=${2}
          shift
          ;;
      esac
      shift
    done
    
    set_log_file "$LOG_FILE_NAME"
    str1="Received command line parameters :"
    write_log "$INSTR $str1 $INSTALL_PARAMS" 
}

add_config_option()
{
    CFG_FILE=$1
    if [ -f "${CONFIGURE_FILE_DIR}${CFG_FILE}" ]
    then
        write_log "Config option for ${CONFIGURE_FILE_DIR}${CFG_FILE} already exists ... skipping."
        return
    fi
    
    if [ ! -d "${CONFIGURE_FILE_DIR}" ]
    then
        mkdir -p "${CONFIGURE_FILE_DIR}"
    fi
    write_log "Adding configure option : ${CFG_FILE}"
    touch "${CONFIGURE_FILE_DIR}${CFG_FILE}"
}

should_config()
{
    CFG_FILE=$1
    if [ -f "${CONFIGURE_FILE_DIR}${CFG_FILE}" ]
    then
        write_log "Configuration option is available for ${CFG_FILE}"
        echo "1"
    else
        write_log "No configuration required for ${CFG_FILE}"
        echo "0"
    fi
}

remove_config_file()
{
    CFG_FILE=$1
    if [ -f "${CONFIGURE_FILE_DIR}${CFG_FILE}" ]
    then
    	if [ $IS_UPGRADE -eq 0 ]
	then
        	add_install_info "${CFG_FILE}"
	fi
        write_log "Removing configuration file ${CFG_FILE}"
        rm "${CONFIGURE_FILE_DIR}${CFG_FILE}"
#        echo "1"
    else
        write_log "No Configuration file ${CFG_FILE} to remove"
#        echo "0"
    fi
}

foldername_space_check()
{
	dir=`pwd`
	if [ `echo $dir | cut -d" " -f1` != `echo $dir | cut -d" " -f2` ]
	then
		SPACE_NOT_ALLOWED=`gettext install "Installer has detected that the mounted directory path has space. To continue further mount/extract the ISO into a directory structure that does not contain space."`
		write_and_log "${SPACE_NOT_ALLOWED}"
		exit 1
	fi
}

cleanup_tmp()
{
  rm -rf ${IDM_TEMP} >> /dev/null
}
