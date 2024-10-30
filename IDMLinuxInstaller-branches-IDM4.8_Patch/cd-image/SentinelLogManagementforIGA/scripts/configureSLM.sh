#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

#-----------------------------------------------------------------------------
#
# idm_cfg script.
#
#-----------------------------------------------------------------------------
locationvalue=__LOCATION_VALUE__
FULL_SCRIPT_DIR=$1
rootpassword=$2
id=`id | awk '{print $1}'|awk -F"=" '{print $2}'|awk -F"(" '{print $1}'`
BASEDIR=${locationvalue}/var/opt/novell/sentinel/idm_cust
if [ ! -d ${BASEDIR} ]
then
	echo ""
	echo "Folder ${BASEDIR} is missing"
	echo ""
	exit 1
fi
if [ ! -d ${BASEDIR}/content ] || [ ! -f ${BASEDIR}/content/server.xml ] || [ ! -f ${BASEDIR}/content/ui-configuration.properties ]
then
	echo ""
	echo "Folder ${BASEDIR} does not have necessary file/folder"
	echo ""
	exit 1
fi
AWK=`which awk`
configured=0
LOG_FILE=/tmp/logManConfigure.log
sentinel_loglevel_setting() {
grep esecurity.base.ccs.proxy.level=OFF ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop
loggingoff=`echo $?`
## Sentinel log level setting
if [ "$loggingoff" != "0" ]
then
/bin/cp -f ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop.bak
string_to_replace="esecurity.base.query.db.BaseJDBCQuery.level=FINE"
new_string="esecurity.base.query.db.BaseJDBCQuery.level=FINE\nesecurity.ccs.comp.correlation.level=OFF\nesecurity.ccs.comp.advisor.level=OFF\nesecurity.ccs.comp.cases.level=OFF\nsecurity.ccs.comp.image.level=OFF\ncom.novell.sentinel.analytics.level=OFF\nesecurity.ccs.comp.incident.level=OFF\nesecurity.base.ccs.proxy.level=OFF\nesecurity.ccs.comp.alert.level=OFF"
sed -i "s#$string_to_replace#$new_string#" ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop
dos2unix ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop &> /dev/null
chown novell:novell ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop
chmod 600 ${locationvalue}/etc/opt/novell/sentinel/config/server_log.prop
fi
cd ${locationvalue}/etc/opt/novell/sentinel/3rdparty/jetty/contexts
if [ -e netflow-api.xml ]; then mv netflow-api.xml netflow-api.xml.noop; fi
if [ -e baselining-rest.xml ]; then mv baselining-rest.xml baselining-rest.xml.noop; fi
if [ -e baselining-ui.xml ]; then mv baselining-ui.xml baselining-ui.xml.noop; fi
if [ -e cg-rest.xml ]; then mv cg-rest.xml cg-rest.xml.noop; fi
if [ -e cg-webclient.xml ]; then mv cg-webclient.xml cg-webclient.xml.noop; fi
if [ -e scm-rest.xml ]; then mv scm-rest.xml scm-rest.xml.noop; fi
if [ -e scm-webclient.xml ]; then mv scm-webclient.xml scm-webclient.xml.noop; fi
cd -
mv ${locationvalue}/etc/opt/novell/sentinel/config/server.xml ${locationvalue}/etc/opt/novell/sentinel/config/server.xml.bak
/bin/cp -f $BASEDIR/content/server.xml ${locationvalue}/etc/opt/novell/sentinel/config/server.xml
chown novell:novell ${locationvalue}/etc/opt/novell/sentinel/config/server.xml
chmod 600 ${locationvalue}/etc/opt/novell/sentinel/config/server.xml
## Sentinel log level setting
}

ui_config() {
/bin/cp -f $BASEDIR/content/ui-configuration.properties ${locationvalue}/etc/opt/novell/sentinel/config/ui-configuration.properties | tee -a ${LOG_FILE} &> /dev/null
}

ui_config_defaultdash_false() {
  if [ -f ${locationvalue}/etc/opt/novell/sentinel/config/ui-configuration.properties ]
  then
  	grep -q default.auditorReport.dashboard ${locationvalue}/etc/opt/novell/sentinel/config/ui-configuration.properties &> /dev/null
	if [ $? -ne 0 ]
	then
		echo "default.auditorReport.dashboard=false" >> ${locationvalue}/etc/opt/novell/sentinel/config/ui-configuration.properties
	fi
  fi
}

ui_config_sentinelredirection_true() {
  if [ -f ${locationvalue}/etc/opt/novell/sentinel/config/configuration.properties ]
  then
  	sed -i "/sentinel.sentinel.redirection/d" ${locationvalue}/etc/opt/novell/sentinel/config/configuration.properties
	echo "sentinel.sentinel.redirection=true" >> ${locationvalue}/etc/opt/novell/sentinel/config/configuration.properties
  fi
}

ui_styles() {
/bin/cp -rpf $BASEDIR/content/styles ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/ | tee -a ${LOG_FILE} &> /dev/null
chown -R novell:novell ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/styles &> /dev/null
}

setup_index_redirect() {
# setup proper redirection in index.jsp
dirName=${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/
/bin/mkdir ${dirName}/tmp &> /dev/null
/bin/cp ${dirName}/index.jsp ${dirName}/tmp/ &> /dev/null
cd ${dirName}/tmp/ &> /dev/null
${AWK} '/<head>/{n++}{print >"out" n ".txt" }' index.jsp &> /dev/null
rm index.jsp out1.txt &> /dev/null
mv out.txt index.jsp &> /dev/null
cat ../styles/idm_redir.htm >> index.jsp 
mv ../index.jsp ../index.jsp.bkp &> /dev/null
mv index.jsp ../index.jsp &> /dev/null
cd .. &> /dev/null
rm -rf ${dirName}/tmp/ &> /dev/null
chown -R novell:novell ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/index.jsp &> /dev/null
}

restart_sentinel() {
# Starting sentinel
[ -f /etc/init.d/sentinel ] && /etc/init.d/sentinel restart | tee -a ${LOG_FILE} &> /dev/null

[ -f /etc/init.d/sentinel ] && /etc/init.d/sentinel stopVA | tee -a ${LOG_FILE} &> /dev/null
[ -f /etc/init.d/sentinel ] && /etc/init.d/sentinel stopSIdb | tee -a ${LOG_FILE} &> /dev/null
}

sentinel_loglevel_setting
cp -rpf ${locationvalue}/var/opt/novell/sentinel/3rdparty/jetty/webapps/ROOT/styles /tmp/ &> /dev/null
ui_styles
if [ "$configured" == "0" ]
then
	ui_config
	setup_index_redirect
fi
ui_config_defaultdash_false
ui_config_sentinelredirection_true
# Stop raw data storage
sed -i -e 's/esecurity.router.event.rawdata.send=true/esecurity.router.event.rawdata.send=false/g' ${locationvalue}/etc/opt/novell/sentinel/config/event-router.properties
# Remove Mongo startup
sed -i 's/RUN_AS_USER=$RUN_AS_USER "${ESEC_HOME}\/bin\/si_db.sh" start --quiet | serversh_log_tee/#RUN_AS_USER=$RUN_AS_USER "${ESEC_HOME}\/bin\/si_db.sh" start --quiet | serversh_log_tee\n echo "" \&\>\/dev\/null/g' ${locationvalue}/opt/novell/sentinel/bin/server.sh
# Remove Kibana/ES startup
sed -i 's/start_VA/#start_VA/g' ${locationvalue}/opt/novell/sentinel/bin/server.sh
# Uncomment the function
sed -i 's/#start_VA()/start_VA()/g' ${locationvalue}/opt/novell/sentinel/bin/server.sh
# Remove Mongo stop
sed -i 's/RUN_AS_USER=$RUN_AS_USER "${ESEC_HOME}\/bin\/si_db.sh" stop --quiet | serversh_log_tee/#RUN_AS_USER=$RUN_AS_USER "${ESEC_HOME}\/bin\/si_db.sh" stop --quiet | serversh_log_tee\n echo "" \&\>\/dev\/null/g' ${locationvalue}/opt/novell/sentinel/bin/server.sh
sed -i 's/local STOP_SIDB_RESULT=$?/local STOP_SIDB_RESULT=0/g' ${locationvalue}/opt/novell/sentinel/bin/server.sh
# Remove Kibana/ES stop
sed -i 's/RUN_AS_USER=$RUN_AS_USER "${ESEC_HOME}\/bin\/visual_analytics.sh" stop | serversh_log_tee/#RUN_AS_USER=$RUN_AS_USER "${ESEC_HOME}\/bin\/visual_analytics.sh" stop | serversh_log_tee\n echo "" \&\>\/dev\/null/g' ${locationvalue}/opt/novell/sentinel/bin/server.sh
sed -i 's/local STOP_KIBANA_RESULT=$?/local STOP_KIBANA_RESULT=0/g' ${locationvalue}/opt/novell/sentinel/bin/server.sh

if [ $id != 0 ]
then
 if [ ! -z ${rootpassword} ] && [ "${rootpassword}" != "" ]
 then
  echo ${rootpassword} | su -s /bin/sh - root -c "cd $FULL_SCRIPT_DIR/packages/ && ./bin/root_install_finish"
 fi
fi
restart_sentinel
