#!/bin/bash
source /commonfunctions-sub.sh
source <( awk ' /'"#STARTINGPOINT"'/ {flag=1;next} /'"#ENDINGPOINT"'/{flag=0} flag { print }' /commonfunctions.sh )

if [ ! -z $UA_PG_DATABASE_ROOT_CRT ] && [ -f $UA_PG_DATABASE_ROOT_CRT ]
then
	mkdir -p /home/users/novlua/.postgresql
	openssl x509 -outform der -in $UA_PG_DATABASE_ROOT_CRT -out /home/users/novlua/.postgresql/root.crt
	chown -R novlua:novlua /home/users/novlua/
	mkdir -p /root/.postgresql
	openssl x509 -outform der -in $UA_PG_DATABASE_ROOT_CRT -out /root/.postgresql/root.crt
	chown -R novlua:novlua /root/.postgresql
fi

retryRestart()
{
	#Some times EBO error occurs due to network.  Giving a re-try for restart
	sleep 5m
	if [ -f /opt/netiq/idm/apps/tomcat/logs/catalina.out ]
	then
		grep -q "com.sssw.fw.directory.api.EboDirectoryConnectionException: An unexpected exception occurred in the directory layer" /opt/netiq/idm/apps/tomcat/logs/catalina.out
		if [ $? -eq 0 ]
		then
			echo "EBO error occurred -trying restart once"
			su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh &> /dev/null"
			su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh &> /dev/null"
		fi
	fi
}

updatejrepathforuserappcontainer()
{
        sed -i "s@\${IDM_JRE_HOME}/bin:\$PATH \${DESIGNER_HOME}/Designer@/opt/netiq/common/jre8/bin:\$PATH \${DESIGNER_HOME}/Designer@g" /idm/common/scripts/install_common_libs.sh
}

configureUA() {
	updatejrepathforuserappcontainer
	cd /idm/
	if [ -z ${SILENT_INSTALL_FILE} ] && [ -z ${INSTALL_UA} ] 
	then         
		echo "Interactive install not supported. Exiting..."
		kill 1
		exit 1
		debug=$debug OSPPromptNotNeeded=true IS_ADVANCED_MODE=true ENABLE_STANDALONE=true DOCKER_CONTAINER=y FR_STANDALONE=true $DEBUGVAR ./configure.sh 
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
		source /idmpatch/common/scripts/common_install_vars.sh
		source /idmpatch/common/scripts/database_utils.sh
		source ${SILENT_INSTALL_FILE}
                if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
                then
                   DB_TYPE="PostgreSQL"
                   if [ -z "$WFE_DB_CONNECTION_URL" ] || [ "$WFE_DB_CONNECTION_URL" == "" ]
                   then
                      WFE_DB_CONNECTION_URL="jdbc:postgresql://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}?compatible=true"
                   fi
                elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
                then
                  DB_TYPE="Oracle"
                  if [ -z "$WFE_DB_CONNECTION_URL" ] || [ "$WFE_DB_CONNECTION_URL" == "" ]
                  then
                     WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${WFE_DATABASE_NAME}"
                  fi
               elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
               then
                  DB_TYPE="SQL Server"
                  if [ -z "$WFE_DB_CONNECTION_URL" ] || [ "$WFE_DB_CONNECTION_URL" == "" ]
                  then
                     WFE_DB_CONNECTION_URL="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${WFE_DATABASE_NAME}"
                  fi
               fi
	       AZUREPGUSED=false
	       if [ ! -z $AZURE_POSTGRESQL_REQUIRED ] && [[ "$AZURE_POSTGRESQL_REQUIRED" == "y" || "$AZURE_POSTGRESQL_REQUIRED" == "true" ]]
	       then
	       	AZUREPGUSED=true
	       fi
	       if [ "${DB_TYPE}" == "PostgreSQL" ] && [ "${AZUREPGUSED}" == "true" ]
	       then
	       	ORG_WFE_DB_CONNECTION_URL=$WFE_DB_CONNECTION_URL
	       	WFE_DB_CONNECTION_URL=$(echo $WFE_DB_CONNECTION_URL\&sslmode=require)
	       else
	       	SKIP_DB_CHECK=1
	       fi
               IDM_INSTALL_HOME=/idmpatch LOG_FILE_NAME=/tmp/dbcon.txt verify_db_connection ${UA_WFE_DATABASE_USER} ${UA_WFE_DATABASE_PWD} "${WFE_DB_CONNECTION_URL}" "${DB_TYPE}" ${UA_WFE_DB_JDBC_DRIVER_JAR}
		if [ $? -eq 0 ] || [ $SKIP_DB_CHECK -eq 1 ]
		then
		   rm -f /tmp/dbcon.txt
		   if [ "${DB_TYPE}" == "PostgreSQL" ] && [ "${AZUREPGUSED}" == "true" ]
		   then
		   	WFE_DB_CONNECTION_URL=$ORG_WFE_DB_CONNECTION_URL
		   fi
		   debug=$debug OSPPromptNotNeeded=true IS_ADVANCED_MODE=true ENABLE_STANDALONE=true DOCKER_CONTAINER=y FR_STANDALONE=true $DEBUGVAR ./configure.sh -s -ssc -slc -f ${SILENT_INSTALL_FILE} &> /dev/null
		else
		   echo " Database connection unsuccessful, exiting..."
		   kill 1
		   exit 1
		fi
	fi
}

if [ "$debug" = 'y' ]
then
	set -x
	DEBUGVAR="bash -x"
fi

if [ ! -e "/opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties" ] ; then
	configureUA
	if [ -f /idmpatch/common/scripts/common_install_vars.sh ]
	then
		source /idmpatch/common/scripts/common_install_vars.sh
		source /idmpatch/common/conf/global_paths.sh
		source /idmpatch/common/scripts/system_utils.sh
		source /idmpatch/user_application/scripts/ua_configure.sh
		source /idmpatch/common/scripts/kube_utils.sh
		# Run upgrade functions
		setIDM_INSTALL_HOME
		ismPropertiesChangeUAandRPT
		RemoveAJPConnector
		UAonlyprops-upgrade
		UAonlyprops-fresh
		configureKubeIngress ua
		if [ ! -z $UA_REPLICA_COUNT ] && [ $UA_REPLICA_COUNT -gt 1 ]
		then
			addSimpleTcpCluster
		fi
		removeworkflowengineid
	fi
	# Before back linking copying the edited files
	CopyBackEditedFiles &> /dev/null
	createBackLinkFiles
	fixforsecretstore
	chown -R novlua:novlua /opt/netiq/idm/apps $CONF_HOME &> /dev/null
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh &> /dev/null"
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh &> /dev/null"
	su -l novlua -c "yes|cp /idm/version.properties $CONF_HOME/"
	if [ ! -z ${KUBERNETES_ORCHESTRATION} ] && [ "${KUBERNETES_ORCHESTRATION}" == "y" ]
	then
		clusterenableviarestcall
	fi
else
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
		source /idmpatch/user_application/scripts/ua_configure.sh
		source /idmpatch/common/scripts/kube_utils.sh
	else
		source /idm/common/scripts/common_install_vars.sh
		source /idm/common/conf/global_paths.sh
		source /idm/common/scripts/system_utils.sh
		source /idm/user_application/scripts/ua_configure.sh
	fi
	IMAGE_IDM_VERSION=$(grep novell-DXMLengnx /idm/version.properties | cut -d"-" -f3)
	if [ "$RUNNING_IDM_VERSION" == "$IMAGE_IDM_VERSION" ]
	then
		echo "Proceeding" 
		#Back link regardless
		createBackLinkFiles
		echo "UA_REPLICA_COUNT=$UA_REPLICA_COUNT"
		if [ ! -z $UA_REPLICA_COUNT ] && [ $UA_REPLICA_COUNT -gt 1 ]
		then
			# Copied from first instance
			# Before back linking copying the edited files
			CopyBackEditedFiles &> /dev/null
			# Linking back to /config
			createBackLinkFiles
		fi
		removeworkflowengineid
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
		UAonlyprops-upgrade
		UAonlyprops-fresh
		configureKubeIngress ua
		if [ ! -z $UA_REPLICA_COUNT ] && [ $UA_REPLICA_COUNT -gt 1 ]
		then
			addSimpleTcpCluster
		fi
		removeworkflowengineid
		# Before back linking copying the edited files
		CopyBackEditedFiles &> /dev/null
		# Linking back to /config
		createBackLinkFiles
	fi
	fixforsecretstore
	#At the end copy the image rpm version
	su -l novlua -c "yes|cp /idm/version.properties $CONF_HOME/"
	#Need to do check existing version
	chown -R novlua:novlua /opt/netiq/idm/apps $CONF_HOME &> /dev/null
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh"
	if [ ! -z $UA_REPLICA_COUNT ] && [ $UA_REPLICA_COUNT -gt 1 ]
	then
		clusterenableviarestcall
	fi
	retryRestart
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
