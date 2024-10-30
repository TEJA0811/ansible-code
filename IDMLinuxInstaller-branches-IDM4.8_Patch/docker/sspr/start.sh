#! /bin/bash -x

###########################################################
# This is a sample start up file for sspr that
# links default stateful location ("/opt/netiq/idm/apps/sspr" 
# and "/opt/netiq/idm/apps/tomcat") 
# to /config/sspr location.
#
# @author: Pankaj Yogi
# @created: 24 Oct, 2018
# 
# @modified: 19 Nov, 2018
# @modifier: Pankaj Yogi
###########################################################

# sspr host location
CONF_HOME="/config/sspr"

# variable pointing to sspr default location
DEFAULT_SSPR="/opt/netiq/idm/apps/sspr"

#variable pointing to sspr custom location
CUSTOM_SSPR=$CONF_HOME/sspr

# variable pointing to tomcat default location
DEFAULT_TOMCAT="/opt/netiq/idm/apps/tomcat"

# variable pointing to tomcat custom location
CUSTOM_TOMCAT=$CONF_HOME/tomcat

# variable SSPR_DATA
SSPR_DATA="sspr_data"

# variable CONF
CONF="conf"

# variable to detect if configuration happened
VOLUME_CONFIGURED=0

# This function create the necessary links of destination directory
# at source directory. This function also do necessary steps required
# while creating link for tomcat.
createLinkIfRequired() {
	SOURCE=$1 # first parameter is source directory
	DEST=$2	# second parameter is destination directory
	
	if [ ! -d $DEST ] ; then
		mkdir -p $DEST
		chmod 775 $DEST
		#DEST_NOT_EXISTS=1
	#else 
		#DEST_NOT_EXISTS=0
	fi

	# In activemq case SOURCE directory may not exist some time
	# so create directory first.
	if [ ! -e $SOURCE ] ; then
		mkdir -p $SOURCE
		CREATE_DIR_FLAG=1
	else
		CREATE_DIR_FLAG=0
	fi
	
	# If source point to a directory we need to create the link
	if [ -d $SOURCE ] ; then
		# incase of sspr do not copy files from default location
		# to linked when linked location already exists.
		if [ $VOLUME_CONFIGURED -eq 0 ] && [ $CREATE_DIR_FLAG -eq 1 ] ; then 
        		cp -r $SOURCE/* $DEST
		fi
	       	rm -r $SOURCE
        	ln -s $DEST $SOURCE
	fi
}

#function to detect if volume has configured state
setIfVolumeConfigured() {
	if [ -f "$CUSTOM_SSPR/sspr_data/SSPRConfiguration.xml" ] ; then
		VOLUME_CONFIGURED=1
	fi
}

#
setIfVolumeConfigured

# Link sspr/sspr_data directory
createLinkIfRequired $DEFAULT_SSPR/$SSPR_DATA $CUSTOM_SSPR/$SSPR_DATA

# Link tomcat/conf directory
createLinkIfRequired $DEFAULT_TOMCAT/$CONF $CUSTOM_TOMCAT/$CONF

#call startsspr.sh
./startsspr.sh
