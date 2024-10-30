#! /bin/bash -x

###########################################################
# This is a sample start up file for reporting that
# links default stateful location ("/opt/netiq/idm/apps/reporting" 
# and "/opt/netiq/idm/apps/tomcat") 
# to /config/reporting location.
#
# @author: 
# @created: 
###########################################################

source /commonfunctions.sh

# variable pointing to reporting default location
DEFAULT_REPORTING="/opt/netiq/idm/apps/reporting"

#variable pointing to reporting custom location
CUSTOM_REPORTING=$CONF_HOME/reporting

# variable pointing to tomcat log location
DEFAULT_LOG="/opt/netiq/idm/apps/tomcat/logs"

# variable pointing to tomcat custom log location
CUSTOM_LOG=$CUSTOM_TOMCAT/"logs"

# variable pointing to configure log location
DEFAULT_CONFIGURE_LOG="/var/opt/netiq/idm/log"

# variable pointing to custom configure log location
CUSTOM_CONFIGURE_LOG=$CONF_HOME/log


# variable CONF
CONF="conf"


# This function create the necessary links of destination directory
# at source directory. This function also do necessary steps required
# while creating link for tomcat.
createLinkIfRequired() {
	SOURCE=$1 # first parameter is source directory
	DEST=$2	# second parameter is destination directory
	
	if [ ! -d $DEST ] ; then
		mkdir -p $DEST
		#DEST_NOT_EXISTS=1
	#else 
		#DEST_NOT_EXISTS=0
	fi

	# In activemq case SOURCE directory may not exist some time
	# so create directory first.
	if [ ! -e $SOURCE ] ; then
		mkdir -p $SOURCE
	fi
	
	# If source point to a directory we need to create the link
	if [ -d $SOURCE ] ; then
		# incase of reporting do not copy files from default location
		# to linked when linked location already exists.
		if [[ $VOLUME_CONFIGURED -eq 0 ]] ; then 
        		cp -r $SOURCE/* $DEST &> /dev/null
		fi
	       	rm -r $SOURCE &> /dev/null
        	ln -s $DEST $SOURCE
	fi
}


setIfVolumeConfigured

# try to create backlinks if already configured
if [[ $VOLUME_CONFIGURED -eq 1 ]] ; then
	createBackLinkFiles
fi

# Link reporting/conf directory
#createLinkIfRequired $DEFAULT_REPORTING/$CONF $CUSTOM_REPORTING/$CONF

# Link tomcat/conf directory
createLinkIfRequired $DEFAULT_TOMCAT/$CONF $CUSTOM_TOMCAT/$CONF

# Link tomcat/logs directory
createLinkIfRequired $DEFAULT_LOG $CUSTOM_LOG

# Link configure log directory
createLinkIfRequired $DEFAULT_CONFIGURE_LOG $CUSTOM_CONFIGURE_LOG

# Link cef cache directory
createLinkIfRequired $DEFAULT_TOMCAT/cache $CUSTOM_TOMCAT/cache

#call startreporting.sh
#CONF_HOME=$CONF_HOME CUSTOM_TOMCAT=$CUSTOM_TOMCAT DEFAULT_TOMCAT=$DEFAULT_TOMCAT ./startreporting.sh
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
    su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# run application
/startreporting.sh &
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

