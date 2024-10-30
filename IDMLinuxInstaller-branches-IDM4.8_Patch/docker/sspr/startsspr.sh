#!/bin/sh

configuresspr() {
	cd /idm/sspr
	if [[ ( -z ${INSTALL_REPORTING} || -z ${INSTALL_UA} ) && -z ${SILENT_INSTALL_FILE} ]]
	then
		debug=$debug ENABLE_STANDALONE=true IS_ADVANCED_MODE=true EXCLUSIVE_SSPR=true ${DEBUGVAR} ./configure.sh
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
		debug=$debug ENABLE_STANDALONE=true IS_ADVANCED_MODE=true EXCLUSIVE_SSPR=true ./configure.sh -s -ssc -slc -f ${SILENT_INSTALL_FILE}
	fi
}

if [ "$debug" = 'y' ]
then
	set -x
	DEBUGVAR="bash -x"
fi

if [ ! -e "/opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml" ] ; then	
	configuresspr
	/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh
	chown -R novlua:novlua /config/sspr /opt/netiq/idm/apps/
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh"
else
	chown -R novlua:novlua /config/sspr /opt/netiq/idm/apps/
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh"	
fi

if [ "$debug" = 'y' ]
then
	set +x
fi
echo "Press ctrl+p ctrl+q to continue. This would detach you from the container."
tail -f /dev/null
#while true; do :; done
