#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

locationvalue=__LOCATION_VALUE__
if [ "${locationvalue}" == "__LOCATION_VALUE__" ]
then
  locationvalue=
fi

BACKUP_FOLDER=${locationvalue}/var/opt/novell/sentinel/idm_cust
if [ ! -d ${BACKUP_FOLDER} ]
then
	echo ""
	echo "Folder ${BACKUP_FOLDER} is missing"
	echo ""
	exit 1
fi
if [ ! -f ${BACKUP_FOLDER}/server_log.prop ] && [ ! -f ${BACKUP_FOLDER}/ui-configuration.properties ]
then
	echo ""
	echo "Folder ${BACKUP_FOLDER} does not have necessary file(s)"
	echo ""
	exit 1
fi
echo ""
echo "You are about to revert the customization of Sentinel Log Manager for IGA"
echo ""
echo "Are you sure you want to proceed?(yes/no)"
read entry
shopt -s nocasematch
case $entry in
	yes)
		echo ""
		echo "De-customizing..."
		echo ""
		;;
	*)
		echo ""
		echo "Canceling the de-customization"
		echo ""
		exit
		;;
esac
shopt -u nocasematch
rm -rf ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/styles
/bin/cp -f ${BACKUP_FOLDER}/{server_log.prop,server.xml,ui-configuration.properties,event-router.properties} ${locationvalue}/etc/opt/novell/sentinel/config/
/bin/cp -f ${BACKUP_FOLDER}/index.jsp ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/
#/bin/cp -rpf ${BACKUP_FOLDER}/styles/*  /var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/styles/
/bin/cp -f ${BACKUP_FOLDER}/server.sh ${locationvalue}/opt/novell/sentinel/bin/
#chown -R novell:novell /etc/opt/novell/sentinel/config/server_log.prop /etc/opt/novell/sentinel/config/server.xml /etc/opt/novell/sentinel/config/ui-configuration.properties /var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/styles /var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/index.jsp /etc/opt/novell/sentinel/config/event-router.properties /opt/novell/sentinel/bin/server.sh
chown -R novell:novell ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop ${locationvalue}/etc/opt/novell/sentinel/config/server.xml ${locationvalue}/etc/opt/novell/sentinel/config/ui-configuration.properties ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/index.jsp ${locationvalue}/etc/opt/novell/sentinel/config/event-router.properties ${locationvalue}/opt/novell/sentinel/bin/server.sh
chmod 600 ${locationvalue}/etc/opt/novell/sentinel/config/event-router.properties ${locationvalue}/etc/opt/novell/sentinel/config/server.xml ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop ${locationvalue}/etc/opt/novell/sentinel/config/ui-configuration.properties
chmod 700 ${locationvalue}/opt/novell/sentinel/bin/server.sh
chmod 644 ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/index.jsp
#chmod -R 755 /var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/styles
/etc/init.d/sentinel restart
