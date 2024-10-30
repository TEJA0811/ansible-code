#!/bin/bash
if [ ! -z "$debug" ] && [ "$debug" == "y" ]
then
	set -x
fi

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

# variable pointing to nginx logs
DEFAULT_LOG="/opt/netiq/common/nginx/logs"

# variable pointingg to custom nginx logs
CUSTOM_LOG=$CUSTOM_FORMSRENDERER/"nginx/logs"

# variable pointing to form logs
DEFAULT_FORM_LOG="/opt/netiq/idm/apps/sites/logs"

# variable pointingg to custom form logs
CUSTOM_FORM_LOG=$CUSTOM_FORMSRENDERER/"form/logs"

# Cert directory for nginx
NGINX_CERT="/opt/netiq/common/nginx/cert"

# Variable pointing to custom nginx cert
CUSTOM_NGINX_CERT=$CUSTOM_FORMSRENDERER/"nginx/cert"

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
        			cp -r $SOURCE/* $DEST
			fi
		fi
	       	rm -r $SOURCE &> /dev/null
        	ln -s $DEST $SOURCE
	fi
}

#function to detect if volume has configured state
setIfVolumeConfigured() {
	if [ -f "$CUSTOM_FORMSRENDERER/netiq-golang.sh" ] ; then
		VOLUME_CONFIGURED=1
	fi
}


setIfVolumeConfigured

mkdir -p $CUSTOM_FORMSRENDERER

# try to create backlinks if already configured
if [[ $VOLUME_CONFIGURED -eq 1 ]] ; then
	createBackLinkFiles
fi

#else part is available in startFR.sh file 


#create link for log files
createLinkIfRequired $DEFAULT_LOG $CUSTOM_LOG
createLinkIfRequired $DEFAULT_FORM_LOG $CUSTOM_FORM_LOG
createLinkIfRequired $NGINX_CERT $CUSTOM_NGINX_CERT


#call startFR.sh
#CUSTOM_FORMSRENDERER=$CUSTOM_FORMSRENDERER ./startFR.sh
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
    su -l novlua -c "/etc/init.d/netiq-golang.sh stop"
    /opt/netiq/common/nginx/serv/netiq-nginx stop
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# run application
/startFR.sh &
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

