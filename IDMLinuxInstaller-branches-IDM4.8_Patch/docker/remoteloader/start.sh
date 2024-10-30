#! /bin/bash

###########################################################
# This is a sample start up file for remote loader that
# links default data location ("/var/opt/novell/dirxml/rdxml") 
# to /config/rdxml location.
#
# @author: Pankaj Yogi
# @created: 04 Oct, 2018
###########################################################

# variable pointing to rdxml default location
DEFAULT_RDXML_DATA="/var/opt/novell/dirxml/rdxml"

# variable pointing to custom location
CUSTOM_RDXML_DATA="/config/rdxml"

# variable pointing to directory containing jar/so/rpm files
CUSTOM_MOUNTFILES_DIR=$CUSTOM_RDXML_DATA/mountfiles

# variable pointing to rdxml configuration directory
RL_CONFIG_DIR="/etc/opt/novell/dirxml/rdxml"

# variable pointing to rdxml configuration directory
CUSTUM_RL_CONFIG_DIR=$CUSTOM_RDXML_DATA/driverconf

# check if CUSTOM_RDXML_DATA directory exists. If not,
# create one and link DEFAULT_RDXML_DATA to this dir.
if [ ! -d $CUSTOM_RDXML_DATA ] ; then
	mkdir -p $CUSTOM_RDXML_DATA
fi

if [ ! -d $CUSTUM_RL_CONFIG_DIR ] ; then
	mkdir -p $CUSTUM_RL_CONFIG_DIR
fi

# mountfiles handling
if [ -d $CUSTOM_MOUNTFILES_DIR ]
then
	# link the jar files
	for jarfiles in $(ls $CUSTOM_MOUNTFILES_DIR/*.jar)
	do
		ln -s $jarfiles /opt/novell/eDirectory/lib/dirxml/classes/
	done
	# link the so files
	for sofiles in $(ls $CUSTOM_MOUNTFILES_DIR/*.so)
	do
		ln -s $sofiles /opt/novell/eDirectory/lib64/nds-modules/
	done
	# install the rpms
	if [ -z $MOUNTRPMOPTIONS ]
	then
		MOUNTRPMOPTIONS="--force"
	fi
	ls $CUSTOM_MOUNTFILES_DIR/*.rpm &> /dev/null
	if [ $? -eq 0 ]
	then
		rpm $MOUNTRPMOPTIONS -Uvh $CUSTOM_MOUNTFILES_DIR/*rpm
	fi
fi

# check if link needs to be created
if [ -e "$CUSTOM_RDXML_DATA/*" ]
then
	VERSIONFILE=/config/rdxml/version.properties
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
	yes|cp /idm/version.properties /config/rdxml/
	rm -r $DEFAULT_RDXML_DATA
	ln -s $CUSTOM_RDXML_DATA $DEFAULT_RDXML_DATA
	
	rm -r $RL_CONFIG_DIR
	ln -s $CUSTUM_RL_CONFIG_DIR $RL_CONFIG_DIR
	
else
  if [ -d $DEFAULT_RDXML_DATA ] ; then
	#copy all data from default location to linked
	if [ -e "$DEFAULT_RDXML_DATA/*" ] ; then
        	#copy recursively so that subdirectories also copied
		cp -r $DEFAULT_RDXML_DATA/* $CUSTOM_RDXML_DATA
	fi
    rm -r $DEFAULT_RDXML_DATA
	ln -s $CUSTOM_RDXML_DATA $DEFAULT_RDXML_DATA
  fi
  
  if [ -d $RL_CONFIG_DIR ] ; then
	#copy all data from default location to linked
	if [ -e "$RL_CONFIG_DIR/*" ] ; then
        	#copy recursively so that subdirectories also copied
		cp -r $RL_CONFIG_DIR/* $CUSTUM_RL_CONFIG_DIR
	fi
    rm -r $RL_CONFIG_DIR
	ln -s $CUSTUM_RL_CONFIG_DIR $RL_CONFIG_DIR
  fi
  
  yes|cp /idm/version.properties /config/rdxml/
fi

#################################
#  Start Remote Loader Service  #
#################################
pid=0

# SIGUSR1-handler
my_handler() {
  echo "my_handler"
}

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]
  then
    /etc/init.d/rdxml stop
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# run application
/startRL.sh $RL_CONFIG_DIR &
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

