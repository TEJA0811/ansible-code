#!/bin/bash
##################################################################################
#
# Copyright © 2019 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################
loginuser=$(whoami)
id=`id | awk '{print $1}'|awk -F"=" '{print $2}'|awk -F"(" '{print $1}'`
if [ $id == 0 ] || [ "$loginuser" == "novell" ]
then
  validuser=true
else
  echo ""
  echo -e "\tThis script can be run only by root privileged or novell user"
  echo ""
  exit 1
fi
if [ $id != 0 ]
then
  echo ""
  read -s -e -p "Enter the root user password for install_prepare and install_finish : " rootpassword
  echo ""
fi
paramspassed=$@
locationvalue=$(echo $paramspassed | awk -F "--location" '{ print $2 }' | awk -F "--" '{ print $1 }' | sed -e 's/^[ \t]*//;s/[ \t]*$//' | awk -F "=" '{ print $2 }')
LOG_FILE=/tmp/logManInstall.log
CFG_FILE=configureSLM.sh
BACKUP_FOLDER=${locationvalue}/var/opt/novell/sentinel/idm_cust
BASEDIR=`pwd`
SCRIPT_DIR=`dirname $0`
FULL_SCRIPT_DIR=$(readlink -m ${SCRIPT_DIR})
if [ ! -z "$locationvalue" ] && [ "$locationvalue" != "" ]
then
  if [ $id != 0 ]
  then
    echo ${rootpassword} | su -s /bin/sh - root -c "cd $FULL_SCRIPT_DIR/packages && ./bin/root_install_prepare --location=${locationvalue}"
  fi
else
  if [ $id != 0 ]
  then
    echo ${rootpassword} | su -s /bin/sh - root -c "cd $FULL_SCRIPT_DIR/packages && ./bin/root_install_prepare"
  fi
fi
if [ ${SCRIPT_DIR} != "." ]
then
	BASEDIR=`echo ${SCRIPT_DIR}`
fi
SENTINELBASEDIR=`echo ${SCRIPT_DIR}/packages`
AWK=`which awk`
cd ${SENTINELBASEDIR}
response=1
configured=0

rm -f ${LOG_FILE} &> /dev/null

if [ ! -e ./install-sentinel ]
then
	echo "install-sentinel not found" | tee -a ${LOG_FILE}
	exit 1
fi

if [ -e ${locationvalue}/etc/opt/novell/sentinel/config/configuration.properties ]
then
	echo "sentinel found and is configured" | tee -a ${LOG_FILE}
	configured=1
	chown -R novell:users ${BASEDIR} &> /dev/null
	if [ $? -ne 0 ]
	then
		echo "Following command failed"
		echo ""
		echo "	chown -R novell:users ${BASEDIR}"
		exit 1
	fi
	su -l novell -c "cd ${BASEDIR} && touch novellrights" &> /dev/null
	if [ $? -ne 0 ]
	then
		echo "Following command failed for novell user"
		echo ""
		echo "	cd ${BASEDIR} && touch novellrights"
		exit 1
	fi
fi

if [ "$IDENTITYAUDITEVENTSTORESILENTINSTALL" == "true" ]
then
	./install-sentinel -u $1
	response=`echo $?`
else
	./install-sentinel "$@"
	response=`echo $?`
fi
if [ "$response" -ne 0 ]
then
	exit 1
fi
if [ ! -d ${locationvalue}/opt/novell/sentinel ]
then
	exit 1
fi
backup() {
mkdir -p ${BACKUP_FOLDER}
#For De-configure
/bin/cp -f ${BASEDIR}/scripts/deconfigureSLM.sh ${locationvalue}/opt/novell/sentinel/bin/
sed -i "s#__LOCATION_VALUE__#${locationvalue}#g" ${locationvalue}/opt/novell/sentinel/bin/deconfigureSLM.sh &> /dev/null
/bin/cp ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop ${BACKUP_FOLDER}
/bin/cp ${locationvalue}/etc/opt/novell/sentinel/config/server.xml ${BACKUP_FOLDER}
/bin/cp ${locationvalue}/etc/opt/novell/sentinel/config/ui-configuration.properties ${BACKUP_FOLDER}
#/bin/cp -rpf /var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/styles ${BACKUP_FOLDER}
/bin/cp ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/index.jsp ${BACKUP_FOLDER}
/bin/cp ${locationvalue}/etc/opt/novell/sentinel/config/event-router.properties ${BACKUP_FOLDER}
/bin/cp ${locationvalue}/opt/novell/sentinel/bin/server.sh ${BACKUP_FOLDER}
#For Configure
/bin/cp -rpf ${BASEDIR}/content ${BACKUP_FOLDER}
}

if [ "$response" == "0" ]
then
	echo "" | tee -a ${LOG_FILE}
	echo "Taking backup before customizing to Sentinel Log Manager for IGA" | tee -a ${LOG_FILE}
	echo "" | tee -a ${LOG_FILE}
	backup
	echo "" | tee -a ${LOG_FILE}
	echo "Copying ui configuration specific to IDM" | tee -a ${LOG_FILE}
	echo "" | tee -a ${LOG_FILE}
fi

copy_idmcfg() {
/bin/cp -f ${BASEDIR}/scripts/${CFG_FILE} ${locationvalue}/opt/novell/sentinel/bin/ | tee -a ${LOG_FILE} &> /dev/null
sed -i "s#__LOCATION_VALUE__#${locationvalue}#g" ${locationvalue}/opt/novell/sentinel/bin/${CFG_FILE} &> /dev/null
}
license() {
/bin/cp -f ${BASEDIR}/content/trial.license ${locationvalue}/etc/opt/novell/sentinel/config/.primary_key | tee -a ${LOG_FILE} &> /dev/null
/bin/cp -f ${BASEDIR}/content/trial.license ${locationvalue}/etc/opt/novell/sentinel/config/trial.license | tee -a ${LOG_FILE} &> /dev/null
}
collectors() {
/bin/cp -f ${BASEDIR}/content/sentinel-collector.zip ${locationvalue}/var/opt/novell/sentinel/data/updates/pending_new/ | tee -a ${LOG_FILE} &> /dev/null
/bin/cp -f ${BASEDIR}/content/*.c*z.zip ${locationvalue}/var/opt/novell/sentinel/data/updates/pending/ | tee -a ${LOG_FILE} &> /dev/null
}

sentinel_patch() {
## Sentinel Patch being applied
/bin/cp -f ${locationvalue}/opt/novell/sentinel/lib/postgresql-9.4-1201-jdbc4.jar ${locationvalue}/opt/novell/sentinel/lib/postgresql-9.4-1201-jdbc4.jar.bak | tee -a ${LOG_FILE} &> /dev/null
chown novell:novell ${locationvalue}/opt/novell/sentinel/lib/postgresql-9.4-1201-jdbc4.jar.bak
rm -f ${locationvalue}/opt/novell/sentinel/lib/postgresql-9.4-1201-jdbc4.jar &> /dev/null
/bin/cp -f ${SENTINELBASEDIR}/patches/postgresql-9.4-1212-jdbc4.jar ${locationvalue}/opt/novell/sentinel/lib/postgresql-9.4-1212-jdbc4.jar | tee -a ${LOG_FILE} &> /dev/null
chown novell:novell ${locationvalue}/opt/novell/sentinel/lib/postgresql-9.4-1212-jdbc4.jar &> /dev/null
chmod 600 ${locationvalue}/opt/novell/sentinel/lib/postgresql-9.4-1212-jdbc4.jar
/bin/cp -f ${locationvalue}/etc/opt/novell/sentinel/config/server.conf ${locationvalue}/etc/opt/novell/sentinel/config/server.conf.bak
string_to_replace="wrapper.java.classpath.6=%ESEC_HOME%/jdk/lib/tools.jar"
new_string="wrapper.java.classpath.6=%ESEC_HOME%/jdk/lib/tools.jar\nwrapper.java.classpath.7=%ESEC_HOME%/lib/postgresql-9.4-1212-jdbc4.jar"
sed -i "s#$string_to_replace#$new_string#" ${locationvalue}/etc/opt/novell/sentinel/config/server.conf
dos2unix ${locationvalue}/etc/opt/novell/sentinel/config/server.conf &> /dev/null
chown novell:novell ${locationvalue}/etc/opt/novell/sentinel/config/server.conf
chmod 600 ${locationvalue}/etc/opt/novell/sentinel/config/server.conf
## End of sentinel patch application
}

run_idmcfg() {
chmod +x ${locationvalue}/opt/novell/sentinel/bin/${CFG_FILE}
chown -R novell:novell ${locationvalue}/opt/novell/sentinel/bin/${CFG_FILE} &> /dev/null

#Execute the script to disable mongo, kibana and elasticsearch
if [ ! -z $loginuser ] && [ "$loginuser" == "novell" ]
then
  ${locationvalue}/opt/novell/sentinel/bin/${CFG_FILE} ${FULL_SCRIPT_DIR} ${rootpassword} | tee -a ${LOG_FILE} &> /dev/null
else
  su -s /bin/sh - novell -c "${locationvalue}/opt/novell/sentinel/bin/${CFG_FILE} ${FULL_SCRIPT_DIR} ${rootpassword} | tee -a ${LOG_FILE} &> /dev/null"
fi
[ -f /etc/init.d/sentinel ] && /etc/init.d/sentinel stopVA | tee -a ${LOG_FILE} &> /dev/null
[ -f /etc/init.d/sentinel ] && /etc/init.d/sentinel stopSIdb | tee -a ${LOG_FILE} &> /dev/null
}

copy_idmcfg
if [ "$configured" == "0" ]
then
	license
	collectors
fi
#sentinel_patch
run_idmcfg

if [ "$response" == "0" ]
then
	echo "" | tee -a ${LOG_FILE}
	echo "Finished with installation of Sentinel Log Management for IGA" | tee -a ${LOG_FILE}
fi
