#!/bin/bash

###########################################################
# This is a sample start up file for userapp that
# links default stateful location ("/opt/netiq/idm/apps/UserApplication" 
# and "/opt/netiq/idm/apps/tomcat") 
# to /config/userapp location.
#
# @author: Pankaj Yogi
# @created: 04 Dec, 2018
###########################################################

source /commonfunctions.sh

# variable pointing to userapp log location
DEFAULT_LOG="/opt/netiq/idm/apps/tomcat/logs"

# variable pointing to userapp custom log location
CUSTOM_LOG=$CUSTOM_TOMCAT/"logs"

# variable pointing to userapp cache location
DEFAULT_CACHE="/opt/netiq/idm/apps/tomcat/cache"

# variable pointing to userapp custom cache location
CUSTOM_CACHE=$CUSTOM_TOMCAT/"cache"

# variable pointing to userapp customizations
DEFAULT_CUST="/opt/netiq/idm/apps/UserApplication/"

# variable pointing to userapp custom customization
CUSTOM_CUST=$CUSTOM_USERAPP/""

# variable pointing to configure log location
DEFAULT_CONFIGURE_LOG="/var/opt/netiq/idm/log"

# variable pointing to custom configure log location
CUSTOM_CONFIGURE_LOG=$CONF_HOME/log


# variable CONF
CONF="conf"

#variable to detect if volume has configured data
VOLUME_CONFIGURED=0

# This function create the necessary links of destination directory
# at source directory. This function also do necessary steps required
# while creating link for tomcat.
createLinkIfRequired() {
	SOURCE=$1 # first parameter is source directory
	DEST=$2	# second parameter is destination directory
	
	if [ ! -d $DEST ] ; then
		mkdir -p $DEST
	fi

	# In activemq case SOURCE directory may not exist some time
	# so create directory first.
	if [ ! -e $SOURCE ] ; then
		mkdir -p $SOURCE
	fi

	# If source point to a directory we need to create the link
	if [ -d $SOURCE ] ; then
		# incase of userapp do not copy files from default location
		# to linked when linked location already exists.
		if [ $VOLUME_CONFIGURED -eq 0 ] ; then 
			if [ "$(ls -A $SOURCE)" ] ; then                
        			cp -r $SOURCE/* $DEST &> /dev/null
			fi
		fi
	       	rm -r $SOURCE &> /dev/null
        	ln -s $DEST $SOURCE
	fi
}

#function to detect if volume has configured state
setIfVolumeConfigured() {
	if [ -f "$CUSTOM_TOMCAT/conf/ism-configuration.properties" ] ; then
		VOLUME_CONFIGURED=1
	fi
	# For second instance this file would not be present as it is a link.  Although above condition is still required for it to be configured during the fresh case
	if [ -f ${CONF_HOME}/copiedfromfirstinstance ]
	then
		VOLUME_CONFIGURED=1
	fi
}

setIfVolumeConfigured

mkdir -p $CUSTOM_USERAPP
mkdir -p /config/userapp/configupdate
mkdir -p $CUSTOM_TOMCAT/bin

# try to create backlinks if already configured
if [[ $VOLUME_CONFIGURED -eq 1 ]] ; then
	createBackLinkFiles
fi

#else part is available in startUA.sh file 

# Link tomcat/conf directory
# Linking the same conf directory across multi-instances
createLinkIfRequired $DEFAULT_TOMCAT/$CONF /config/userapp/tomcat/$CONF

# Link tomcat/logs directory
createLinkIfRequired $DEFAULT_LOG $CUSTOM_LOG

# Link tomcat/cache directory
createLinkIfRequired $DEFAULT_CACHE $CUSTOM_CACHE

# Link configure log directory
createLinkIfRequired $DEFAULT_CONFIGURE_LOG $CUSTOM_CONFIGURE_LOG

#call startUA.sh
#DEFAULT_USERAPP=$DEFAULT_USERAPP CUSTOM_USERAPP=$CUSTOM_USERAPP CONF_HOME=$CONF_HOME CUSTOM_TOMCAT=$CUSTOM_TOMCAT DEFAULT_TOMCAT=$DEFAULT_TOMCAT ./startUA.sh
if [ -f /opt/netiq/idm/apps/tomcat/logs/catalina.out ]
then
	cat /opt/netiq/idm/apps/tomcat/logs/catalina.out >> /opt/netiq/idm/apps/tomcat/logs/catalina-back.out
	>/opt/netiq/idm/apps/tomcat/logs/catalina.out
fi
pid=0

# SIGUSR1-handler
my_handler() {
  echo "my_handler"
}

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]
  then
    #kill -SIGTERM "$pid"
    #wait "$pid"
    source /commonfunctions-sub.sh
    controllingnumber=$(cat $CONF_HOME/controlling)
    sed -i '/${controllingnumber}/d' /config/userapp/transaction-lock-file
    rm -f $CONF_HOME/controlling
    rm -f $CONF_HOME/transaction-lock-file
    su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# run application
/startUA.sh &
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

