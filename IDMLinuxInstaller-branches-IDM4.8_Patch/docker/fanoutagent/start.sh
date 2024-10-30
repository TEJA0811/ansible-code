#! /bin/bash

###########################################################
# This is a sample start up file for fanout agent that links
# default config location ("/opt/novell/dirxml/fanoutagent/config") 
# to /config/fanoutagent location.
#
# @author: Pankaj Yogi
# @created: 08 Oct, 2018
###########################################################

# variable pointing to fanout default location
DEFAULT_FANOUT="/opt/novell/dirxml/fanoutagent"

# variable pointing to custom location
CUSTOM_FANOUT="/config/fanoutagent"

# variable pointing to fanout config location
DEFAULT_FANOUT_CONFIG=$DEFAULT_FANOUT"/config"

# variable pointing to fanout config custom location
CUSTOM_FANOUT_CONFIG=$CUSTOM_FANOUT"/config"

# variable pointing to fanout logs location
DEFAULT_FANOUT_LOGS=$DEFAULT_FANOUT"/logs"

# variable pointing to fanout logs custom location
CUSTOM_FANOUT_LOGS=$CUSTOM_FANOUT"/logs"

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
		if [[ $VOLUME_CONFIGURED -eq 0 ]] ; then 
        		if [ "$(ls -A $SOURCE)" ] ; then
	       			# copy recursively so that subdirectories also get copied
					cp -r $SOURCE/* $DEST
				fi
		fi
	       	rm -r $SOURCE
        	ln -s $DEST $SOURCE
	fi
}


#function to detect if volume has configured state
setIfVolumeConfigured() {
	if [ -d "$CUSTOM_FANOUT/config" ] ; then
		VOLUME_CONFIGURED=1
	fi
}

# check for volumization 
setIfVolumeConfigured

if [ $VOLUME_CONFIGURED -eq 0 ]
then
  mkdir -p /config/fanoutagent/
  yes|cp /idm/version.properties /config/fanoutagent/
else
	#Need to do check existing version
	VERSIONFILE=/config/fanoutagent/version.properties
	if [ -f $VERSIONFILE ]
	then
		RUNNING_IDM_VERSION=$(grep novell-DXMLengnx $VERSIONFILE | cut -d"-" -f3)
		if [ -z $RUNNING_IDM_VERSION ] || [ "$RUNNING_IDM_VERSION" == "" ]
		then
			RUNNING_IDM_VERSION=4.8.0
		fi
	else
		RUNNING_IDM_VERSION=4.8.0
	fi
	if [ -f /idmpatch/common/scripts/common_install_vars.sh ]
	then
		source /idmpatch/common/scripts/common_install_vars.sh
	else
		source /idm/common/scripts/common_install_vars.sh
	fi
	IMAGE_IDM_VERSION=$(grep novell-DXMLengnx /idm/version.properties | cut -d"-" -f3)
	if [ "$RUNNING_IDM_VERSION" == "$IMAGE_IDM_VERSION" ]
	then
		echo "Proceeding" 
	else
		printf "$RUNNING_IDM_VERSION\n$SUPPORTED_DOCKER_IDM_VERSION" | sort -V | sed -n '1p' | grep -q $RUNNING_IDM_VERSION
		MIN_SUPPORTED_VERSION=$?
		if [ $MIN_SUPPORTED_VERSION -eq 0 ] && [ "$RUNNING_IDM_VERSION" != "$SUPPORTED_DOCKER_IDM_VERSION" ]
		then
			# Have to exit since lowest among running version and supported is running version
			echo ""
			echo "Minimum supported version is $SUPPORTED_DOCKER_IDM_VERSION"
			echo ""
			echo "Start the container version of $SUPPORTED_DOCKER_IDM_VERSION first and then start with this container version of $IMAGE_IDM_VERSION"
			echo "Exiting..."
			echo ""
			exit 1
		fi
		# If say we try to start the container with older version compared to the data layer; it should exit
		printf "$RUNNING_IDM_VERSION\n$IMAGE_IDM_VERSION" | sort -V | sed -n '1p' | grep -q $RUNNING_IDM_VERSION
		CORRECT_IDM_VERION_TOPROCEED=$?
		if [ $CORRECT_IDM_VERION_TOPROCEED -ne 0 ]
		then
			# As per ordering running version should be the first; if not exit
			echo ""
			echo "Configured data layer has been run with version later than $IMAGE_IDM_VERSION"
			echo "Exiting..."
			echo ""
			exit 1
		fi
		# At this stage running and supported could be same or running could be smaller; either way now it could be upgraded
	fi
	#At the end copy the image rpm version
	yes|cp /idm/version.properties /config/fanoutagent/
fi

# call for linking directories
createLinkIfRequired $DEFAULT_FANOUT_CONFIG $CUSTOM_FANOUT_CONFIG

createLinkIfRequired $DEFAULT_FANOUT_LOGS $CUSTOM_FANOUT_LOGS


echo "Press CTRL+P,Q to detach from this container, if not detached already"
sleep 10s
DefaultLogFile="/var/opt/netiq/idm/log/idmupgrade.log"
LOGTOFOLLOWistrue=1
if [ ! -z "$LOGTOFOLLOW" ] && [ "$LOGTOFOLLOW" != "" ]
then
	ls $LOGTOFOLLOW &> /dev/null
	LOGTOFOLLOWistrue=$?
fi
if [ $LOGTOFOLLOWistrue -eq 0 ]
then
	tail -f $LOGTOFOLLOW
else
	tail -f $DefaultLogFile
fi
tail -F /dev/null
