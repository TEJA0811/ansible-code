#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

##
# JRE INSTALLED LOCATION
##
IDM_JRE_HOME=/opt/netiq/common/jre

###
# Temp location
##
IDM_TEMP=/tmp/idm_install


###
# Edirectory Install location
###
EDIR_INSTALL_DIR=/opt/novell/eDirectory/


#IDM_KEYSTORE_PATH=$IDM_JRE_HOME/lib/security/cacerts

##
# Postgres db server home
##
POSTGRES_HOME=/opt/netiq/idm/postgres

##
# Designer installed home
##
DESIGNER_HOME=/opt/netiq/idm/lightWeightDesigner


##
#  prompt temp file
##
PROMPT_FILE=${IDM_TEMP}/input.properties


##
# Current directory
##
CURRENT_DIR=`pwd`

##
# ISM configuration file
##
ISM_CONFIG_HOME=/opt/netiq/idm/apps/tomcat/conf
ISM_CONFIG_FILE_NAME=ism-configuration.properties
ISM_CONFIG=${ISM_CONFIG_HOME}/${ISM_CONFIG_FILE_NAME}


SSPR_CONFIG_FILE_HOME=/opt/netiq/idm/apps/sspr/sspr_data

##
# OSP home
##
IDM_OSP_HOME=/opt/netiq/idm/apps/osp

##
# TOMCAT INSTALLED LOCATION
##
IDM_TOMCAT_HOME=/opt/netiq/idm/apps/tomcat

###
# IDM keystore file with path
###

IDM_KEYSTORE_PATH=$IDM_TOMCAT_HOME/conf/idm.jks


##
# TOMCAT BASE INSTALLED LOCATION
##
IDM_TOMCAT_HOME_BASE=/opt/netiq/idm/tomcat


###
# User Application Configupdate file path.
###
CONFIG_UPDATE_PATH=/opt/netiq/configupdate
CONFIG_UPDATE_FILE=/tmp/configupdate.properties

###
# XML utility
###
XML_MOD=${IDM_INSTALL_HOME}common/bin/xmlmod

###
# Config update home
###
CONFIG_UPDATE_HOME=/opt/netiq/idm/apps/configupdate




###
# OSP Installation Path
###
OSP_INSTALL_PATH=/opt/netiq/idm/apps/osp

###
# iManager paths
###
NETIQ_TOMCAT_HOME=/opt/netiq/idm/tomcat
NETIQ_COMMON_TOMCAT_HOME=/opt/netiq/common/tomcat
IMAN_TOMCAT_HOME=/var/opt/novell/tomcat9
IMAN_JAVA_HOME=/opt/netiq/common/jre
IMAN_USER_HOME_PATH=/var/opt/novell/novlwww
IMAN_NPS_HOME=/var/opt/novell/iManager/nps
#SERVLET_HOSTNAME=164.99.178.47
#CONFIG_OSP_JAR=osp-config-edir.jar


###
# RPT Variables
###
RPT_APP_CTX=IDMRPT

## Location of install log
INSTALL_LOG_DIR=/var/opt/netiq/idm/log/

# Install info filename
INFO_FILENAME=/etc/opt/netiq/idm/configure/install-info.txt
