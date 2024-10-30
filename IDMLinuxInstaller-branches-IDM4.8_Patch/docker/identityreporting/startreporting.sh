#!/bin/sh
source /commonfunctions.sh

if [ ! -z $RPT_PG_DATABASE_ROOT_CRT ] && [ -f $RPT_PG_DATABASE_ROOT_CRT ]
then
	mkdir -p /home/users/novlua/.postgresql
	openssl x509 -outform der -in $RPT_PG_DATABASE_ROOT_CRT -out /home/users/novlua/.postgresql/root.crt
	chown -R novlua:novlua /home/users/novlua/
	mkdir -p /root/.postgresql
	openssl x509 -outform der -in $RPT_PG_DATABASE_ROOT_CRT -out /root/.postgresql/root.crt
	chown -R novlua:novlua /root/.postgresql
fi

configurereporting() {
	cd /idm/
	if [[  -z ${INSTALL_REPORTING}  && -z ${SILENT_INSTALL_FILE} ]]
	then         
		echo "Interactive install not supported. Exiting..."
		kill 1
		exit 1
		debug=$debug OSPPromptNotNeeded=true ENABLE_STANDALONE=true EXCLUSIVE_SSO=true IS_ADVANCED_MODE=true DOCKER_CONTAINER=y EXCLUSIVE_RPT=true $DEBUGVAR ./configure.sh 
	else         
         if  [ ! -z ${INSTALL_REPORTING} ]
         then
             timestamp=`date +"%Y%m%d%H%M%S"`
             SILENT_INSTALL_FILE=/tmp/silent-${timestamp}.properties
             env > ${SILENT_INSTALL_FILE}
         fi
		if [ ! -z ${SECRET_PROPERTY_PATH} ] && [ -f ${SECRET_PROPERTY_PATH} ]
		then
			cat ${SECRET_PROPERTY_PATH} >> ${SILENT_INSTALL_FILE}
		fi
         debug=$debug OSPPromptNotNeeded=true ENABLE_STANDALONE=true EXCLUSIVE_SSO=true IS_ADVANCED_MODE=true DOCKER_CONTAINER=y EXCLUSIVE_RPT=true $DEBUGVAR ./configure.sh -s -ssc -slc -f ${SILENT_INSTALL_FILE} &> /dev/null
	fi 
}

#function to move source file to destination and create link at source 
createLinkForFile() {         
	SOURCE_FILE=$1 #source file         
	DEST_FILE=$2 #dest file
	
	
	if [ -e $SOURCE_FILE ] ; then
		filedir=`dirname $DEST_FILE`
		if [ ! -d "${filedir}" ]
		then
		  mkdir -p "${filedir}"
		fi
               mv $SOURCE_FILE $DEST_FILE
	       ln -s $DEST_FILE $SOURCE_FILE
    fi 
		
	
}

if [ "$debug" = 'y' ]
then
	set -x
	DEBUGVAR="bash -x"
fi

if [ ! -e "/opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties" ] ; then	
	configurereporting
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
		configureKubeIngress rpt
	fi
	# Before back linking copying the edited files
	CopyBackEditedFiles &> /dev/null
	createBackLinkFiles
	chown -R novlua:novlua /opt/netiq/idm/apps/ /config/reporting &> /dev/null
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh &> /dev/null"
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh &> /dev/null"
	su -l novlua -c "yes|cp /idm/version.properties /config/reporting/"
else
	#Need to do check existing version
	VERSIONFILE=/config/reporting/version.properties
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
		#Back link files regardless ( directories done with start.sh )
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
		configureKubeIngress rpt
		# Before back linking copying the edited files
		CopyBackEditedFiles &> /dev/null
		# Linking files to /config
		createBackLinkFiles
	fi
	#At the end copy the image rpm version
	su -l novlua -c "yes|cp /idm/version.properties /config/reporting/"
	chown -R novlua:novlua /opt/netiq/idm/apps/ /config/reporting &> /dev/null
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

