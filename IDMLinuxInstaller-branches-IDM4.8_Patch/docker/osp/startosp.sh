#!/bin/bash
source /commonfunctions-sub.sh
source <( awk ' /'"#STARTINGPOINT"'/ {flag=1;next} /'"#ENDINGPOINT"'/{flag=0} flag { print }' /commonfunctions.sh )

configureosp() {
	cd /idm/osp 
	if [[ -z ${SECRET_PROPERTY_PATH} && ( -z ${INSTALL_REPORTING} || -z ${INSTALL_UA} ) && -z ${SILENT_INSTALL_FILE} ]]
	then         
		echo "Interactive install not supported. Exiting..."
		kill 1
		exit 1
		debug=$debug ENABLE_STANDALONE=true EXCLUSIVE_SSO=true IS_ADVANCED_MODE=true DOCKER_CONTAINER=y $DEBUGVAR ./configure.sh 
	else         
         if [ ! -z ${INSTALL_REPORTING} ] || [ ! -z ${INSTALL_UA} ]
         then
             timestamp=`date +"%Y%m%d%H%M%S"`
             SILENT_INSTALL_FILE=/tmp/silent-${timestamp}.properties
             env > ${SILENT_INSTALL_FILE}
         fi
		if [ ! -z ${SECRET_PROPERTY_PATH} ] && [ -f ${SECRET_PROPERTY_PATH} ]
		then
			cat ${SECRET_PROPERTY_PATH} >> ${SILENT_INSTALL_FILE}
		fi
         debug=$debug ENABLE_STANDALONE=true EXCLUSIVE_SSO=true IS_ADVANCED_MODE=true DOCKER_CONTAINER=y $DEBUGVAR ./configure.sh -s -ssc -slc -f ${SILENT_INSTALL_FILE} &> /dev/null
	fi 
}

if [ "$debug" = 'y' ]
then
	set -x
	DEBUGVAR="bash -x"
fi

if [ ! -e "/opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties" ] ; then	
	configureosp
	if [ -f /idmpatch/common/scripts/common_install_vars.sh ]
	then
		source /idmpatch/common/scripts/common_install_vars.sh
		source /idmpatch/common/conf/global_paths.sh
		source /idmpatch/common/scripts/system_utils.sh
		source /idmpatch/common/scripts/kube_utils.sh
		# Run upgrade functions
		setIDM_INSTALL_HOME
		ismPropertiesChangeUAandRPT
		RemoveAJPConnector
		configureKubeIngress osp
		if [ ! -z $OSP_REPLICA_COUNT ] && [ $OSP_REPLICA_COUNT -gt 1 ]
		then
			addSimpleTcpCluster
		fi
	fi
	# Before back linking copying the edited files
	updatetomcatversion_for_osp
	CopyBackEditedFiles &> /dev/null
	createBackLinkFiles
	chown -R novlua:novlua /opt/netiq/idm/apps/ $CONF_HOME &> /dev/null
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh" &> /dev/null
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh &> /dev/null"
	su -l novlua -c "yes|cp /idm/version.properties $CONF_HOME/"
else
	#Need to do check existing version
	VERSIONFILE=$CONF_HOME/version.properties
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
		source /idmpatch/common/conf/global_paths.sh
		source /idmpatch/common/scripts/system_utils.sh
		source /idmpatch/common/scripts/kube_utils.sh
	else
		source /idm/common/scripts/common_install_vars.sh
		source /idm/common/conf/global_paths.sh
		source /idm/common/scripts/system_utils.sh
	fi
	IMAGE_IDM_VERSION=$(grep novell-DXMLengnx /idm/version.properties | cut -d"-" -f3)
	if [ "$RUNNING_IDM_VERSION" == "$IMAGE_IDM_VERSION" ]
	then
		echo "Proceeding" 
		#Back link regardless
		createBackLinkFiles
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
		# Run upgrade functions
		setIDM_INSTALL_HOME
		ismPropertiesChangeUAandRPT
		RemoveAJPConnector
		configureKubeIngress osp
		if [ ! -z $OSP_REPLICA_COUNT ] && [ $OSP_REPLICA_COUNT -gt 1 ]
		then
			addSimpleTcpCluster
		fi
		updatetomcatversion_for_osp
		# Before back linking copying the edited files
		CopyBackEditedFiles &> /dev/null
		# Linking files to /config
		createBackLinkFiles
	fi
	#At the end copy the image rpm version
	su -l novlua -c "yes|cp /idm/version.properties $CONF_HOME/"
	chown -R novlua:novlua /opt/netiq/idm/apps/ $CONF_HOME &> /dev/null
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh"
fi
if [ "$debug" = 'y' ]
then
	set +x
fi
echo "Press ctrl+p ctrl+q to continue. This would detach you from the container."
sleep 10s
DefaultLogFile="/opt/netiq/idm/apps/tomcat/logs/catalina.out"
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
tail -f /dev/null
#while true; do :; done
