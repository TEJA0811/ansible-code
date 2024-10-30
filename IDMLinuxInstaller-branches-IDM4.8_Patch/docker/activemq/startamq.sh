
if [ $CONFIGURED == "0" ] ; then 
	if [ -d /idmpatch ]
	then
		cd /idmpatch/activemq
	else
		cd /idm/activemq
	fi
	if [ -z $INSTALL_ACTIVEMQ ]
	then
		echo "Interactive install not supported. Exiting..."
		kill -s SIGTERM 1
	  ENABLE_STANDALONE=true ./configure.sh
	else
	  ENABLE_STANDALONE=true ./configure.sh &> /dev/null
	fi
	chown -R novlua:novlua /opt/netiq/idm/activemq /config/activemq &> /dev/null
	if [ -z $INSTALL_ACTIVEMQ ]
	then
	  su -l novlua -c "JAVA_HOME=/opt/netiq/common/jre/ /opt/netiq/idm/activemq/bin/activemq start"
	else
	  su -l novlua -c "JAVA_HOME=/opt/netiq/common/jre/ /opt/netiq/idm/activemq/bin/activemq start &> /dev/null"
	fi
	su -l novlua -c "yes|cp /idm/version.properties /config/activemq/"
else
	#Need to do check existing version
	VERSIONFILE=/config/activemq/version.properties
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
			kill 1
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
			kill 1
			exit 1
		fi
		# At this stage running and supported could be same or running could be smaller; either way now it could be upgraded
	fi
	#At the end copy the image rpm version
	su -l novlua -c "yes|cp /idm/version.properties /config/activemq/"
	chown -R novlua:novlua /opt/netiq/idm/activemq /config/activemq &> /dev/null
	su -l novlua -c "JAVA_HOME=/opt/netiq/common/jre/ /opt/netiq/idm/activemq/bin/activemq start"
fi

echo "Press CTRL+P,Q to detach from this container, if not detached already"
sleep 10s
DefaultLogFile="/opt/netiq/idm/activemq/data/activemq.log"
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
