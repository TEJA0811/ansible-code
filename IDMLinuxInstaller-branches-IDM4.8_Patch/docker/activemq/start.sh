#! /bin/bash

###########################################################
# This is a sample start up file for activemq that
# links default stateful location ("/opt/netiq/idm/activemq") 
# to /config/activemq location.
#
# @author: Pankaj Yogi
# @created: 12 Oct, 2018
#
# @modifier: Pankaj Yogi
# @version: 1.0
###########################################################

# variable pointing to activemq default location
DEFAULT_ACTIVEMQ="/opt/netiq/idm/activemq"

# variable pointing to activemq custom location
CUSTOM_ACTIVEMQ="/config/activemq"

# Activemq config file
CONF_FILE="conf/activemq.xml"

# variable indicating whether Activemq is already configured
CONFIGURED=0

# variable DATA
DATA="data"

# variable CONF
CONF="conf"

# This function create the necessary links of destination directory
# at source directory. This function also do necessary steps required
# while creating link.
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
		CREATE_DIR_FLAG=1
	fi
	
	# If source point to a directory we need to create the link
	if [ -d $SOURCE ] ; then
		#copy all data from default location to linked
		if [ ! -f $CUSTOM_ACTIVEMQ/$CONF_FILE ]; then
        		cp -r $SOURCE/* $DEST
		else 
			CONFIGURED=1
		fi
	       	rm -r $SOURCE &> /dev/null
        	ln -s $DEST $SOURCE
	fi
}

# Please note order is important here
# Link activemq/data directory
createLinkIfRequired $DEFAULT_ACTIVEMQ/$DATA $CUSTOM_ACTIVEMQ/$DATA

# Link activemq/conf directory
createLinkIfRequired $DEFAULT_ACTIVEMQ/$CONF $CUSTOM_ACTIVEMQ/$CONF

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
    su -l novlua -c "JAVA_HOME=/opt/netiq/common/jre/ /opt/netiq/idm/activemq/bin/activemq stop"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# run application
CONFIGURED=$CONFIGURED /startamq.sh &
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

