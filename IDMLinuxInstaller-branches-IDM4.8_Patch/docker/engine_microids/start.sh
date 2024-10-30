#!/bin/sh
. /opt/novell/eDirectory/bin/ndspath
trap '/opt/novell/eDirectory/bin/ndsmanage stopall && exit 0' SIGTERM
if [ "$debug" = 'y' ]
then
	set -x
fi
if [ -z "${NDS_CONF_FILE}" ] || [ ! -f ${NDS_CONF_FILE} ]
then
	cd /idm47
	if [ -z ${SILENT_INSTALL_FILE} ]
	then
		./configure.sh
	else
		./configure.sh -s -ssc -slc -f ${SILENT_INSTALL_FILE}
	fi
	cat /var/opt/novell/eDirectory/log/ndsd.log
else
	echo "Starting eDirectory" 
	rcndsd start
fi
if [ "$debug" = 'y' ]
then
	set +x
fi
echo "Press ctrl+p ctrl+q to continue. This would detach you from the container."
tail -f /dev/null
#while true; do :; done
