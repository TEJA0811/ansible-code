#!/bin/bash
source /commonfunctions.sh

configureFR() {
	cd /idm/user_application
	IDM_INSTALL_HOME=/idm
	if [ -z ${SILENT_INSTALL_FILE} ] && [ -z ${INSTALL_UA} ] 
	then         
		echo "Interactive install not supported. Exiting..."
		kill 1
		exit 1
		debug=$debug IDM_INSTALL_HOME=$IDM_INSTALL_HOME IS_ADVANCED_MODE=true ENABLE_STANDALONE=true DOCKER_CONTAINER=y $DEBUGVAR ./configure_fr.sh 
	else
       		if [ ! -z ${INSTALL_UA} ]
		then 
			timestamp=`date +"%Y%m%d%H%M%S"`
			SILENT_INSTALL_FILE=/tmp/silent-${timestamp}.properties
			env > ${SILENT_INSTALL_FILE}
		fi
		if [ ! -z ${SECRET_PROPERTY_PATH} ] && [ -f ${SECRET_PROPERTY_PATH} ]
		then
			cat ${SECRET_PROPERTY_PATH} >> ${SILENT_INSTALL_FILE}
		fi

		debug=$debug IDM_INSTALL_HOME=$IDM_INSTALL_HOME IS_ADVANCED_MODE=true ENABLE_STANDALONE=true DOCKER_CONTAINER=y $DEBUGVAR ./configure_fr.sh -s -ssc -slc -f ${SILENT_INSTALL_FILE} &> /dev/null
	fi
}

createnovluaUser()
{
	user="novlua"
	group="novlua"
	user_home="/var/opt/novell/novlua"
	if ! grep -q "^novlua:*" /etc/group
	then
		/usr/sbin/groupadd -r $group
	fi
	if ! grep -q "^novlua:*" /etc/passwd
	then
		/usr/sbin/useradd -r -g $group $user -d "$user_home" -m -s /bin/bash
	fi
}

#function to move source file to destination and create link at source 
createLinkForFile() {         
	SOURCE_FILE=$1 #source file         
	DEST_FILE=$2 #dest file
        if [ -e $SOURCE_FILE ] ; then
               mv $SOURCE_FILE $DEST_FILE
	       ln -s $DEST_FILE $SOURCE_FILE
        fi 
}

if [ "$debug" = 'y' ]
then
	set -x
	DEBUGVAR="bash -x"
fi

createnovluaUser
grep ___FR_GOLANG_PORT___ "/etc/init.d/netiq-golang.sh" &> /dev/null
if [ $? -eq 0 ] ; then
	configureFR
	if [ -f /idmpatch/common/scripts/common_install_vars.sh ]
	then
		#Apply patch functions
		source /idmpatch/common/scripts/common_install_vars.sh
		source /idmpatch/user_application/scripts/ua_configure.sh
		source /idmpatch/common/scripts/kube_utils.sh
		modify_nginx_conf
		configureKubeIngress fr
	fi
	# Before back linking copying the edited files
	CopyBackEditedFiles &> /dev/null
	createBackLinkFiles
	chown -R novlua:novlua /opt/netiq/idm/apps /config/FormRenderer/ &> /dev/null
	if [ -z $SILENT_INSTALL_FILE ]
	then
	  su -l novlua -c "/etc/init.d/netiq-golang.sh stop"
	  su -l novlua -c "/etc/init.d/netiq-golang.sh start"
	  sleep 5s
	  /opt/netiq/common/nginx/serv/netiq-nginx stop
	  /opt/netiq/common/nginx/serv/netiq-nginx start
	else
	  su -l novlua -c "/etc/init.d/netiq-golang.sh stop &> /dev/null"
	  su -l novlua -c "/etc/init.d/netiq-golang.sh start &> /dev/null"
	  sleep 5s
	  /opt/netiq/common/nginx/serv/netiq-nginx stop &> /dev/null
	  /opt/netiq/common/nginx/serv/netiq-nginx start &> /dev/null
	fi
	su -l novlua -c "yes|cp /idm/version.properties /config/FormRenderer/"
else
	#Need to do check existing version
	VERSIONFILE=/config/FormRenderer/version.properties
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
		source /idmpatch/user_application/scripts/ua_configure.sh
		source /idmpatch/common/scripts/kube_utils.sh
	else
		source /idm/common/scripts/common_install_vars.sh
		source /idm/user_application/scripts/ua_configure.sh
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
		# Run patch functions
		modify_nginx_conf
		configureKubeIngress fr
		# Before back linking copying the edited files
		CopyBackEditedFiles &> /dev/null
		# Linking files to /config
		createBackLinkFiles
	fi
	#At the end copy the image rpm version
	su -l novlua -c "yes|cp /idm/version.properties /config/FormRenderer/"
	# Already configured wfe and fr setup
	createnovluaUser
	chown -R novlua:novlua /opt/netiq/idm/apps /config/FormRenderer/ &> /dev/null
	modify_nginx_conf
	su -l novlua -c "/etc/init.d/netiq-golang.sh stop"
	su -l novlua -c "/etc/init.d/netiq-golang.sh start"
	sleep 5s
	/opt/netiq/common/nginx/serv/netiq-nginx start
fi

if [ "$debug" = 'y' ]
then
	set +x
fi
echo "Press ctrl+p ctrl+q to continue. This would detach you from the container."
sleep 10s
DefaultLogFile="/opt/netiq/idm/apps/sites/logs/formslogger.log"
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
