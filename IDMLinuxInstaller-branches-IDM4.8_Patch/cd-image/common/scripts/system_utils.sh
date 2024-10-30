#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

OES_file_tocheck=/etc/OES-brand

get_ua_osp_host_port()
{
    local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
    local OSPURL=`grep -ir "com.netiq.idm.osp.url.host =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    if [ -z "${OSPURL}" ]
    then
      OSPURL=`grep -ir "com.netiq.rbpm.redirect.url =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    fi

    PROTO="`echo $OSPURL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
    URL=`echo $OSPURL | sed -e s,$PROTO,,g`
    export SSO_SERVER_HOST="$(echo $URL | grep : | cut -d: -f1)"
    if [ -z ${SSO_SERVER_HOST} ]
    then
      export SSO_SERVER_HOST="$(echo $URL | grep / | cut -d/ -f1)"
      if [ -z ${SSO_SERVER_HOST} ]
      then
        export SSO_SERVER_HOST=$URL
      fi
      export SSO_SERVER_SSL_PORT=
    else
      export SSO_SERVER_SSL_PORT=$(echo $URL | sed -e s,$SSO_SERVER_HOST:,,g | cut -d/ -f1)
    fi
}

get_rpt_osp_host_port()
{
    local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
    local OSPURL=`grep -ir "com.netiq.idm.osp.url.host =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    if [ -z "${OSPURL}" ]
    then
      OSPURL=`grep -ir "com.netiq.rpt.redirect.url =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    fi

    PROTO="`echo $OSPURL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
    URL=`echo $OSPURL | sed -e s,$PROTO,,g`
    export SSO_SERVER_HOST="$(echo $URL | grep : | cut -d: -f1)"
    if [ -z ${SSO_SERVER_HOST} ]
    then
      export SSO_SERVER_HOST="$(echo $URL | grep / | cut -d/ -f1)"
      if [ -z ${SSO_SERVER_HOST} ]
      then
        export SSO_SERVER_HOST=$URL
      fi
      export SSO_SERVER_SSL_PORT=
    else
      export SSO_SERVER_SSL_PORT=$(echo $URL | sed -e s,$SSO_SERVER_HOST:,,g | cut -d/ -f1)
    fi
}

removeobsoleterpms()
{
	rpm -e --nodeps novell-libstdc++6-* &> /dev/null
	rpm -e --nodeps novell-libstdc++6-32bit-* &> /dev/null
}

restore_xmls()
{
  disp_str=`gettext install "Restore required xml files."`
  write_and_log "$disp_str"
  ls ${IDM_BACKUP_FOLDER}/tomcat/conf/{*.xml,*.ks,*.dtd} > ${IDM_TEMP}/xml_files.txt 2> /dev/null
  cat ${IDM_TEMP}/xml_files.txt | while read xmlFilePath
  do
    xml_name=`basename $xmlFilePath`;
    if [ ! -f ${IDM_TOMCAT_HOME}/conf/$xml_name ]
    then
      yes | cp -r $xmlFilePath ${IDM_TOMCAT_HOME}/conf/
    fi
  done
}

RLonlysetup()
{
  engnxfile=$(find ${IDM_INSTALL_HOME} -iname novell-DXMLengnx*.rpm | grep /engine/)
  fanoutagentfile=$(find ${IDM_INSTALL_HOME} -iname novell-DXMLfanoutagent-*.rpm | grep /fanout/)
  rdxmlxfile=$(find ${IDM_INSTALL_HOME} -iname novell-DXMLrdxmlx*.rpm | grep /rl/)
  if [ ! -f "${engnxfile}" ] && [ ! -f "${fanoutagentfile}" ] && [ -f "${rdxmlxfile}" ]
  then
    PRODUCTS=("IDMRL")
    PRODUCTS_DISP_NAME=("Identity Manager Remote Loader Service")
    INSTALL_PROD=("INSTALL_RL")
    promptsforRLonly=true
  fi
}

DockerContainerSetup()
{
  if [ "$DOCKER_CONTAINER" == "y" ] && [ ! -z "$AZURE_CLOUD" ] && [ "$AZURE_CLOUD" == "y" ]
  then
    PRODUCTS=("IDM" "reporting" "idconsole" "user_application")
    PRODUCTS_DISP_NAME=("Identity Manager Engine" "Identity Reporting" "Identity Console" "Identity Applications")
  elif [ "$DOCKER_CONTAINER" == "y" ] && [ ! -z "$AZURE_CLOUD" ] && [ "$AZURE_CLOUD" != "y" ]
  then
    PRODUCTS=("IDM" "reporting" "user_application")
    PRODUCTS_DISP_NAME=("Identity Manager Engine" "Identity Reporting" "Identity Applications")
  fi
}

addtruststorepasswordTosetenv()
{
	grep -q javax.net.ssl.trustStorePassword ${IDM_TOMCAT_HOME}/bin/setenv.sh
	if [ $? -ne 0 ]
	then
	  JAVAOPTS_NEW=`grep -ir "JAVA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed "s/\"$/ -Djavax.net.ssl.trustStorePassword=${IDM_KEYSTORE_PWD}\"/g"`
	  sed -i.bak '/JAVA_OPTS/d' ${IDM_TOMCAT_HOME}/bin/setenv.sh
	  echo "export JAVA_OPTS=${JAVAOPTS_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv.sh
	fi
}

removetruststoreentryfromsetenv()
{
	grep -q javax.net.ssl.trustStore ${IDM_TOMCAT_HOME}/bin/setenv.sh
	if [ $? -eq 0 ]
	then
	  sed -i "s~\-Djavax.net.ssl.trustStore=\$CATALINA_BASE/conf/idm.jks~~g" ${IDM_TOMCAT_HOME}/bin/setenv.sh
	fi
}

addcrldpTosetenv()
{
	if [ ! -z ${KUBERNETES_ORCHESTRATION} ] && [ "${KUBERNETES_ORCHESTRATION}" == "y" ]
	then
	  echo "Enabling the CRLDP for docker since reminting of cert fails to load tomcat otherwise" &> /dev/null
	else
	  # Blocking the code for now as requested for all except kubernetes
	  return
	fi
	grep -q com.sun.security.enableCRLDP ${IDM_TOMCAT_HOME}/bin/setenv.sh
	if [ $? -ne 0 ]
	then
	   CATALINAOPTS_NEW=`grep -ir "CATALINA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed "s/\"$/ -Dcom.sun.security.enableCRLDP=true\"/g"`
	  sed -i.bak '/CATALINA_OPTS/d' ${IDM_TOMCAT_HOME}/bin/setenv.sh
	  echo "export CATALINA_OPTS=${CATALINAOPTS_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv.sh
	fi
}

addcheckrevocationTosetenv()
{
	# Blocking the code for now as requested for all
	return
	grep -q com.sun.net.ssl.checkRevocation ${IDM_TOMCAT_HOME}/bin/setenv.sh
	if [ $? -ne 0 ]
	then
	  JAVAOPTS_NEW=`grep -ir "JAVA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed "s/\"$/ -Dcom.sun.net.ssl.checkRevocation=false\"/g"`
	  sed -i.bak '/JAVA_OPTS/d' ${IDM_TOMCAT_HOME}/bin/setenv.sh
	  echo "export JAVA_OPTS=${JAVAOPTS_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv.sh
	fi
}

addtransformerfactoryTosetenv()
{
	grep -q com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl ${IDM_TOMCAT_HOME}/bin/setenv.sh
	if [ $? -ne 0 ]
	then
	   CATALINAOPTS_NEW=`grep -ir "CATALINA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed "s/\"$/ -Djavax.xml.transform.TransformerFactory=com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl\"/g"`
	  sed -i.bak '/CATALINA_OPTS/d' ${IDM_TOMCAT_HOME}/bin/setenv.sh
	  echo "export CATALINA_OPTS=${CATALINAOPTS_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv.sh
	fi
}

addlogbackTosetenv()
{
	grep -q logback.configurationFile ${IDM_TOMCAT_HOME}/bin/setenv.sh
	if [ $? -ne 0 ]
	then
	  CATALINAOPTS_NEW=`grep -ir "CATALINA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed "s/\"$/ -Dlogback.configurationFile=\/opt\/netiq\/idm\/apps\/tomcat\/conf\/logback.xml\"/g"`
	  sed -i.bak '/CATALINA_OPTS/d' ${IDM_TOMCAT_HOME}/bin/setenv.sh
	  echo "export CATALINA_OPTS=${CATALINAOPTS_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv.sh
	fi
}

removeemptyConnectorPort()
{
	sed -i '/    <Connector port=\"\"/d' ${IDM_TOMCAT_HOME}/conf/server.xml &> /dev/null
}

formsinstall()
{
	#FORMS
    rpm -Uvh ${IDM_INSTALL_HOME}common/packages/nginx/netiq-nginx-*.rpm ${IDM_INSTALL_HOME}IDM/packages/OpenSSL/x86_64/netiq-openssl-*.rpm >> "${LOG_FILE_NAME}" 2>&1
    service netiq-nginx reload &> /dev/null
    systemctl stop netiq-nginx &> /dev/null
    killall -9 --user novlua nginx &> /dev/null
    systemctl stop netiq-nginx &> /dev/null
    service netiq-nginx reload &> /dev/null
    systemctl enable netiq-nginx &> /dev/null
    systemctl enable netiq-tomcat &> /dev/null
    installrpm "${IDM_INSTALL_HOME}IDM/packages/OpenSSL/x86_64" ../IDM/openssl64.list
    installrpm "${IDM_INSTALL_HOME}common/packages/nginx" nginx.list
    installrpm "${IDM_INSTALL_HOME}user_application/packages/ua" forms.list
    if [ ! -f /etc/init.d/netiq-golang.sh ]
    then
		yes | cp "${IDM_INSTALL_HOME}user_application/scripts/netiq-golang.sh" /etc/init.d/
    else
    	grep -q "___FR_GOLANG_PORT___" /etc/init.d/netiq-golang.sh &> /dev/null
		if [ $? -ne 0 ]
		then
			# Already configured wfe and fr setup
			su -l novlua -c "/etc/init.d/netiq-golang.sh stop" >> "${LOG_FILE_NAME}" 2>&1
			su -l novlua -c "/etc/init.d/netiq-golang.sh start" >> "${LOG_FILE_NAME}" 2>&1
			sleep 5s
			systemctl restart netiq-nginx >> "${LOG_FILE_NAME}" 2>&1
		fi
    fi
}

configupdate_idm()
{
	grep sso_apps ${CONFIG_UPDATE_HOME}/configupdate.sh.properties | grep -q ig
	if [ $? -eq 0 ]
	then
		export ssoappsIGvalue=",ig"
	fi
    sed -i "/sso_apps/d" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    sed -i "/reporting_admins_app/d" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    rpm -qi netiq-IDMRPT &> /dev/null
    rptrpmpresence=$?
    actualrptpresent=$rptrpmpresence
    if [ $IS_UPGRADE -eq 1 ] && [ $rptrpmpresence -ne 0 ]
    then
      local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
      local RPTURL=`grep -ir "com.netiq.rpt.redirect.url =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
      if [ ! -z "$RPTURL" ] && [ "$RPTURL" != "" ]
      then
        rptrpmpresence=0
      fi
    fi
    rpm -qi netiq-userapp &> /dev/null
    userapprpmpresence=$?
    rpm -qi netiq-osp &> /dev/null
    osprpmpresence=$?
    if [ $rptrpmpresence -eq 0 ] && [ $userapprpmpresence -eq 0 ]
    then
      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
      echo "sso_apps=ua,rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    elif [ $rptrpmpresence -ne 0 ] && [ $userapprpmpresence -eq 0 ]
    then
      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
      echo "sso_apps=ua${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    elif [ $rptrpmpresence -eq 0 ] && [ $userapprpmpresence -ne 0 ]
    then
      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
      echo "sso_apps=rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    fi
    if [ $osprpmpresence -eq 0 ] && [ $actualrptpresent -ne 0 ] && [ $userapprpmpresence -ne 0 ]
    then
      # osp cloud container case
      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
      echo "sso_apps=ua,rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    fi
    echo "reporting_admins_app=ua" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
}

encryptclientpass()
{   
        ismconfigprop=$1
        rptclientpass=`grep -ir "${ismconfigprop} =" ${ISM_CONFIG} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//'`
        if [ "$rptclientpass" == "$SSO_SERVICE_PWD" ] || [ "$rptclientpass" == "" ]
        then
                sed -i "/${ismconfigprop}/d" ${ISM_CONFIG}
                echo "${ismconfigprop}._attr_obscurity = ENCRYPT" >> ${ISM_CONFIG}
                if [ -f "${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar" ]
                then
                  echo "${ismconfigprop} = `$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt ${SSO_SERVICE_PWD}`" >> ${ISM_CONFIG}
                else
                  echo "${ismconfigprop} = `$IDM_JRE_HOME/bin/java -cp /idm/common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt ${SSO_SERVICE_PWD}`" >> ${ISM_CONFIG}
                fi
        fi
}

encryptrptsslkeystorepwd()
{
	grep com.netiq.rpt.ssl-keystore.pwd._attr_obscurity ${ISM_CONFIG} | grep -q NONE
	if [ $? -eq 0 ]
	then
	  local rptsslkeystorepwd=`grep -ir "com.netiq.rpt.ssl-keystore.pwd =" ${ISM_CONFIG} | awk '{print $3}' | sed 's/^[ ]*//'`
	  sed -i "/com.netiq.rpt.ssl-keystore.pwd._attr_obscurity/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.rpt.ssl-keystore.pwd =/d" ${ISM_CONFIG}
	  echo "com.netiq.rpt.ssl-keystore.pwd._attr_obscurity = ENCRYPT" >> ${ISM_CONFIG}
	  echo "com.netiq.rpt.ssl-keystore.pwd = `$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt ${rptsslkeystorepwd}`" >> ${ISM_CONFIG}
	fi
}

addauditcachefiledir()
{
	grep -q com.netiq.ism.audit.cef.cache-file-dir ${ISM_CONFIG}
	if [ $? -ne 0 ]
	then
	  if [ ! -d /opt/netiq/idm/apps/tomcat/cache ]
	  then
	    mkdir -p /opt/netiq/idm/apps/tomcat/cache
	    chown -R novlua:novlua /opt/netiq/idm/apps/tomcat/cache
	  fi
	  sed -i "/com.netiq.ism.audit.cef.cache-file-dir/d" ${ISM_CONFIG}
	  echo "com.netiq.ism.audit.cef.cache-file-dir = /opt/netiq/idm/apps/tomcat/cache" >> ${ISM_CONFIG}
	fi
}

removeclientpass()
{
	# For cloud container
	ismconfigprop=$1
	sed -i "/${ismconfigprop}/d" ${ISM_CONFIG}
}

callencryptclientpass()
{
	encryptclientpass "com.netiq.rpt.clientPass"
        encryptclientpass "com.netiq.dcsdrv.clientPass"
        encryptclientpass "com.netiq.idmdcs.clientPass"
        encryptclientpass "com.netiq.sspr.clientPass"
        encryptclientpass "com.netiq.idmdash.clientPass"
        encryptclientpass "com.netiq.idmadmin.clientPass"
        encryptclientpass "com.netiq.rbpm.clientPass"
        encryptclientpass "com.netiq.rbpmrest.clientPass"
        encryptclientpass "com.netiq.idmengine.clientPass"
        encryptclientpass "com.microfocus.workflow.clientPass"
        encryptclientpass "com.netiq.forms.clientPass"
}

callremoveclientpass()
{
	# For cloud container
	component=$1
	if [ ! -z "$component" ] && [ "$component" == "userapp" ]
	then
	  removeclientpass "com.netiq.rpt.clientPass"
          removeclientpass "com.netiq.dcsdrv.clientPass"
          removeclientpass "com.netiq.idmdcs.clientPass"
          removeclientpass "com.netiq.sspr.clientPass"
	elif [ ! -z "$component" ] && [ "$component" == "rpt" ]
	then
          removeclientpass "com.netiq.sspr.clientPass"
          removeclientpass "com.netiq.idmdash.clientPass"
          removeclientpass "com.netiq.idmadmin.clientPass"
          removeclientpass "com.netiq.rbpm.clientPass"
          removeclientpass "com.netiq.rbpmrest.clientPass"
          removeclientpass "com.netiq.idmengine.clientPass"
          removeclientpass "com.microfocus.workflow.clientPass"
          removeclientpass "com.netiq.forms.clientPass"
	fi
}

overwriteidme()
{
	idmefile=$EDIR_INSTALL_DIR/.idme
	[ -f $idmefile ] && rm $idmefile
	[ "$IS_ADVANCED_EDITION" != "" ] && touch $idmefile
	if [ "$IS_ADVANCED_EDITION" == "true" ]
	then
		[ "$IS_ADVANCED_EDITION" != "" ] && echo "3" >> $idmefile
	else
		[ "$IS_ADVANCED_EDITION" != "" ] && echo "2" >> $idmefile
	fi
}

sslbinarycheckandexit()
{
if ! rpm -qa | grep -q netiq-openssl
then
	# Need to re-link with available ssl binaries in the system
	cd /usr/lib64
	find . -ilname 'libssl*' | grep -q libssl.so.1.0.0
	libsslBinaryPresence=$?
	find . -ilname 'libcrypto*' | grep -q libcrypto.so.1.0.0
	libcryptoBinaryPresence=$?
	str=$(gettext install "Missing mandatory library :")
	if [ $libsslBinaryPresence -ne 0 ]
	then
		libsslBinaryLink=$(ls -t libssl.* 2> /dev/null | grep libssl -m 1)
		if [ ! -z "$libsslBinaryLink" ] && [ "$libsslBinaryLink" != "" ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf $libsslBinaryLink libssl.so.1.0.0
		else
			write_and_log "$str /usr/lib64/libssl.so.1.0.0"
			exit 1
		fi
	fi
	if [ $libcryptoBinaryPresence -ne 0 ]
	then
		libcryptoBinaryLink=$(ls -t libcrypto.* 2> /dev/null | grep libcrypto -m 1)
		if [ ! -z "$libcryptoBinaryLink" ] && [ "$libcryptoBinaryLink" != "" ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf $libcryptoBinaryLink libcrypto.so.1.0.0
		else
			write_and_log "$str /usr/lib64/libcrypto.so.1.0.0"
			exit 1
		fi
	fi
	cd - &> /dev/null
else
	# Linking with locally built ssl binaries in the system
	cd /usr/lib64
	if [ -f /opt/netiq/common/openssl/lib64/libssl.so.1.0.0 ] && [ -f /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0 ]
	then
		if [ ! -f libssl.so.1.0.0 ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf /opt/netiq/common/openssl/lib64/libssl.so.1.0.0 libssl.so.1.0.0
		fi
		if [ ! -f libcrypto.so.1.0.0 ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0 libcrypto.so.1.0.0
		fi
	else
		# Error out
		msg=$(gettext install "One/Both of Mandatory libraries missing : /opt/netiq/common/openssl/lib64/libssl.so.1.0.0 /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0 ")
		write_and_log "$msg"
		write_and_log ""
		exit 1
	fi
	cd - &> /dev/null
fi
}

getTotalMemory()
{
	awk '/^MemTotal:/{print $2}' /proc/meminfo
}

getTotalCPUCore()
{
	awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo
}

getSystemArch()
{
	uname -m
}

#Given a directory return its existing parent directory cycling through the directory structure
getExistingParentDir(){
    local dirname="$1"
    if [ -z "${dirname}" ]
    then
        str1=`gettext install "Empty or missing argument :"`
        write_and_log "${str1} ${dirname}"
        return
    fi
    if [ -d "${dirname}" ]
    then
        write_and_log "${dirname}"
    else
        dirname="$(dirname "$dirname")"
        getExistingParentDir "${dirname}"
    fi
}

verify_hostname()
{
        hostname -f >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                str1=`gettext install "ERROR: The hostname -f command returned an error status. The hostname on this machine must be configured so that hostname -f returns a hostname before installing "`
                write_and_log "$INSTR $str1 $PRODUCT_NAME."
		exit 1
                return 1
        fi
        return 0
}



# validate an IP address
validateIP()
{
	if [ "$1" != "" ] && [ "$1" != "''" ]
	then
		nslookup $1 &> /dev/null
		[ $? -eq 0 ] && return 0
		grep $1 /etc/hosts &> /dev/null
		[ $? -eq 0 ] && return 0
	fi
        echo $1 | grep -E "^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$" > /dev/null || return 1

	local i
        for i in {1,2,3,4}
        do
                id=`echo $1 | awk -F "." "{print \\$${i}}"`
                if [ "$id" -lt 0 -o "$id" -gt 255 ]
                then
                        return 1
                fi
        done
}

keystorePassToCustom_SSPR(){
	result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port="$SSPR_SERVER_SSL_PORT"]/@keystorePass" "$SSPR_COMM_TOMCAT_KEYSTORE_PWD"`
    write_log "XML_MOD Response : ${result}"
}

keystorePassToCustom_UA(){
	result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port="$UA_SERVER_SSL_PORT"]/@keystorePass" "$UA_COMM_TOMCAT_KEYSTORE_PWD"`
    write_log "XML_MOD Response : ${result}"
}

keystorePassToCustom_OSP(){
	result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port="$SSO_SERVER_SSL_PORT"]/@keystorePass" "$OSP_COMM_TOMCAT_KEYSTORE_PWD"`
    write_log "XML_MOD Response : ${result}"
}

keystorePassToCustom_RPT(){
	result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port="$RPT_TOMCAT_HTTPS_PORT"]/@keystorePass" "$RPT_COMM_TOMCAT_KEYSTORE_PWD"`
    write_log "XML_MOD Response : ${result}"
}

tomcatServerXmlCfg_SSPR()
{
        # Do not change the configuration during upgrade
        if [ ${IS_UPGRADE} -ne 1 ] || [ -f "$CONFIGURE_FILE_DIR/sspr" ]
        then
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "$TOMCAT_HTTP_PORT"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@redirectPort='8443']/@redirectPort" "$SSPR_SERVER_SSL_PORT"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8443']/@port" "$SSPR_SERVER_SSL_PORT"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8009']/@port" "8109"`
                write_log "XML_MOD Response : ${result}"
        fi
}

setTLSv12_SSPR()
{
        # Do not change the configuration during upgrade
        if [ ${IS_UPGRADE} -ne 1 ] || [ -f "$CONFIGURE_FILE_DIR/sspr" ]
        then
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSPR_SERVER_SSL_PORT']" "@sslProtocol"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSPR_SERVER_SSL_PORT']/@sslProtocol" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSPR_SERVER_SSL_PORT']" "@sslEnabledProtocols"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSPR_SERVER_SSL_PORT']/@sslEnabledProtocols" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
        fi
}

setTLSv12_UA()
{
        # Do not change the configuration during upgrade
        if [ ${IS_UPGRADE} -ne 1 ]
        then
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$UA_SERVER_SSL_PORT']" "@sslProtocol"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$UA_SERVER_SSL_PORT']/@sslProtocol" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$UA_SERVER_SSL_PORT']" "@sslEnabledProtocols"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$UA_SERVER_SSL_PORT']/@sslEnabledProtocols" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
        fi
}
setTLSv12_OSP()
{
        # Do not change the configuration during upgrade
        if [ ${IS_UPGRADE} -ne 1 ]
        then
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSO_SERVER_SSL_PORT']" "@sslProtocol"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSO_SERVER_SSL_PORT']/@sslProtocol" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSO_SERVER_SSL_PORT']" "@sslEnabledProtocols"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$SSO_SERVER_SSL_PORT']/@sslEnabledProtocols" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
        fi
}

setTLSv12_RPT()
{
        # Do not change the configuration during upgrade
        if [ ${IS_UPGRADE} -ne 1 ]
        then
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$RPT_TOMCAT_HTTPS_PORT']" "@sslProtocol"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$RPT_TOMCAT_HTTPS_PORT']/@sslProtocol" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$RPT_TOMCAT_HTTPS_PORT']" "@sslEnabledProtocols"`
                write_log "XML_MOD Response : ${result}"
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='$RPT_TOMCAT_HTTPS_PORT']/@sslEnabledProtocols" "TLSv1.2"`
                write_log "XML_MOD Response : ${result}"
        fi
}

block_clear_port_OSP()
{
        if [ -f "${IDM_TOMCAT_HOME}/conf/server.xml" ]
        then
		sed -i.bak "s#<Connector port=\"\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" />#<!-- Connector port=\"${TOMCAT_HTTP_PORT}\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" / -->#g" "${IDM_TOMCAT_HOME}/conf/server.xml"
		#<Connector port="8109" protocol="AJP/1.3" redirectPort="8443" />
		sed -i.bak "s#<Connector port=\"8109\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />#<!-- <Connector port=\"8109\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />-->#g" "${IDM_TOMCAT_HOME}/conf/server.xml"
        fi
}

block_clear_port()
{
        if [ -f "${IDM_TOMCAT_HOME}/conf/server.xml" ]
        then
                sed -i "s~<Connector port=\"${TOMCAT_HTTP_PORT}\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"${TOMCAT_HTTPS_PORT}\" />~<!-- Connector port=\"${TOMCAT_HTTP_PORT}\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"${TOMCAT_HTTPS_PORT}\" / -->~g" "${IDM_TOMCAT_HOME}/conf/server.xml"
        fi
}

getValidLocalIP()
{
    if [ ! -d "${IDM_TEMP}" ]
    then
        mkdir "${IDM_TEMP}" >> /dev/null
    fi
    IP_SAVE_FILE="${IDM_TEMP}/IP.cfg"
    if [ -f ${IP_SAVE_FILE} ]
    then
        IP_ADDR=`cat ${IP_SAVE_FILE} | cut -d"=" -f2`
        if [ "IP_ADDR" != "" ] && [ $UNATTENDED_INSTALL -ne 1 ]
        then
            return
        fi
	# For silent install it should return and use IP_ADDR itself when first argument is empty
	if [ "IP_ADDR" != "" ] && [ $UNATTENDED_INSTALL -eq 1 ] && [ "$1" == "" ]
	then
            return
	fi
    fi
    local ip_address_list=( $(/sbin/ip -f inet addr list | grep -E '^[[:space:]]*inet' | sed -n '/127\.0\.0\./!p' | awk '{print $2}' | awk -F '/' '{print $1}') )
    DEFAULT_LOCAL_IP=`echo $ip_address_list | awk '{print $1}'`

        IP_ADDR="$1"

        validateIP "${IP_ADDR}"
        if [ $? -ne 0 ]
        then
                        IP_ADDR=""
        fi

        IP_IS_VALID=1

        #if [ -z "${IP_ADDR}" ]
        #then
         #       if [ `echo $ip_address_list | awk '{print NF}'` -eq 1 ]
          #  then
                #IP_ADDR="$DEFAULT_LOCAL_IP"
                #IP_IS_VALID=0
           # fi
        #fi
		

        while [ "$IP_IS_VALID" -ne 0 ] && [ "$CREATE_SILENT_FILE" != true ] && [ $IS_UPGRADE -ne 1 ]
        do
                if [ -z "${IP_ADDR}" ]
                then	
                        DEFAULT_IP="${DEFAULT_LOCAL_IP}"

                        write_and_log ""
                        if [ ! -z "${IP_PROMPT}" ]
                        then
								
                                disp_str=`gettext install "Select the IP address used for the %s."`
                                disp_str=`printf "$disp_str" "$IP_PROMPT"`
                                echo_text "$disp_str"
                        fi
						if [ ${#ip_address_list[@]} -gt 1 ]
						then
							disp_str=`gettext install "Choose your server IP address from the following list:"`
							echo_text "$disp_str"
							for (( i=0,j=1; i < ${#ip_address_list[@]}; i++,j++ ))
							do
								echo "$j: ${ip_address_list[i]} "
							done
						fi    
                        # echo $ip_address_list | awk '{ for (ipcount = 1; ipcount <=NF; ipcount++) printf("%d: %s\n", ipcount, $ipcount) }'
						
						
						if [ ${#ip_address_list[@]} -eq 1 ]
						then
							disp_str=`gettext install "Specify hostname(FQDN hostname in lower case) or continue to select default network interface.  To continue, press ENTER."`
						else
                        disp_str=`gettext install "Select a default network interface or specify hostname(FQDN hostname in lower case).  To continue, press ENTER."`
						fi
                        echo_text "$disp_str"
                        read -e -p "[$DEFAULT_IP]:" IP_ADDR

                        if [ -z "$IP_ADDR" ]
                        then

                                IP_ADDR="$DEFAULT_IP"
                        fi

                        # Test that it's actually an integer, as integer tests fail with text
                        # (and I'm allowing the user to type IP addresses, which do not seem to be
                        # counted as integers)
                        echo $IP_ADDR | grep [^0-9] > /dev/null 2>&1
                        if [ $? -ne 0 ]
                        then
                                if [ $IP_ADDR -gt 0 -a $IP_ADDR -le `echo $ip_address_list | awk '{print NF}'` ]
                                then
                                        IP_SELECTED=$IP_ADDR
                                        IP_ADDR=`echo $ip_address_list | awk "{print \\$$IP_SELECTED}"`
                                else
                                        write_and_log ""
                                        disp_str=`gettext install "Invalid IP: %s; selecting the default IP %s."`
                                        disp_str=`printf "$disp_str" "$IP_ADDR" "$DEFAULT_IP"`
                                        echo_text "$disp_str"
                                        IP_ADDR="${DEFAULT_IP}"
                                fi
                        fi
                fi

                validateIP "$IP_ADDR"
                IP_IS_VALID=$?

                if [ $IP_IS_VALID -ne 0 ]
                then
                        write_and_log ""
                        disp_str=`gettext install "Invalid IP: %s; Enter a valid IP address."`
                        disp_str=`printf "$disp_str" "$IP_ADDR"`
                        echo_text "$disp_str"
                        IP_ADDR=""
                fi
        done
        [ "${IP_ADDR}" != "" ] && echo "IP_ADDR=${IP_ADDR}" > ${IP_SAVE_FILE}
}        

btrfs_error_when_needed()
{
	if [ "$fstype" == "btrfs" ]
	then
		str1=`gettext install "File system $fileSystemToCheck is BTRFS and is not supported for hosting DIB"`
		echo_sameline "${txtred}"
		write_and_log "$str1"
		echo_sameline "${txtrst}"
		if [ "$1" != "" ]
		then
			rm -rf "$1"
		fi
		return 1
	else
		if [ "$1" != "" ]
		then
			rm -rf "$1"
		fi
		return 0
	fi
}

check_if_btrfs()
{
	if [ $SKIP_BTRFS_CHECK -eq 1 ]
	then
		return 0
	fi
	if [ $IS_UPGRADE -eq 1 ]
	then
		#Obtaining IDVault NCP interface
        echo "q" > /tmp/ndsmanage-input
        conf_file=`LC_ALL=en_US ndsmanage < /tmp/ndsmanage-input | grep " ACTIVE" | awk '{print $2}'`
        rm -f /tmp/ndsmanage-input
        IDVAULT_DIB_DIR=`LC_ALL=en_US.utf8 ndsconfig get "n4u.nds.dibdir" --config-file ${conf_file} | grep n4u.nds.dibdir | cut -d"=" -f2`
		fileSystemToCheck=$IDVAULT_DIB_DIR
	else
		if [ -d "$1" ]
		then
			fstype=$(df -Th "$1" | sed -n '2p' | awk '{print $2}')
			btrfs_error_when_needed
		else
			mkdir -p "$1"
			fstype=$(df -Th "$1" | sed -n '2p' | awk '{print $2}')
			btrfs_error_when_needed "$1"
		fi
	fi
}


################################################################################
# Verify that a IP address is configured for this machine.
#
# out:
#       $? - 0 address configured, non-zero no address configured.
################################################################################
verify_network_address()
{
        local NETCOUNT="$(/sbin/ip -o -f inet addr show up | grep -v '127.0.0' | wc -l)"

        if [ -z "${NETCOUNT}" ] || [ ${NETCOUNT} -lt 1 ]
        then
                str1=`gettext install "The IP address is not configured on this machine."`
                write_log "$INSTR $str1"
                return  1
        fi
        return  0
}

################################################################################
# Check for the passed port in use.
# in:
#       $1 - port number to check
#       $PRODUCT_BASE
# out:
#       $? - 0 : port in use, non-zero: port not in use
################################################################################
check_port_in_use()
{
        str1=`gettext install "Checking for port in use :"`
        write_log "$INSTR $str1 $1"
        local CHECK_PORT="$1"
        # check against either the to-be-installed base, or the legacy product base, which will be
        # set if we are upgrading a non-rpm installation.
        local CHECK_PATH="${PRODUCT_BASE}"
        [ -n "${LEGACY_PRODUCT_BASE}" ] && CHECK_PATH="${LEGACY_PRODUCT_BASE}"

        # local IN_USE_LIST="$(netstat -A inet6 -A inet -ln | awk '{ print $4}' | sed -nr 's/.+:([[:digit:]]+)([[:space:]]|$)/\1/p')"
	local IN_USE_LIST="$(ss -r -A inet -ln | awk '{ print $5}' | sed -nr 's/.+:([[:digit:]]+)([[:space:]]|$)/\1/p')"
        if echo "${IN_USE_LIST}" | grep -Eq '(^|[[:space:]])'${CHECK_PORT}'([[:space:]]|$)'
        then
                # port is in use...see if it is by the product
                local PORT_PID=$(lsof -i :${CHECK_PORT} | grep LISTEN | awk '{ print $2 }')
                if ! ps ${PORT_PID} | grep -q "${CHECK_PATH}"
                then
                        return  0
                fi
        fi
        return 1
}

################################################################################
# Validate that a value is an integer between 1025 and 65535.
# in:
#       $1 - value to check
# out:
#       $? - 0: valid, non-zero: invalid
################################################################################
validate_port()
{
        str1=`gettext install "Validating the port"`
        write_log "$INSTR $str1 $1" >> $log_file
        echo "$1" | grep -Eq '^[[:digit:]]{1,5}$' && [ $1 -gt 1024 ] && [ $1 -lt 65536 ]
}


make_readable()
{
        READABLE_VALUE="$1"
        KILO_VALUE=1024
        MEG_VALUE=$(( $KILO_VALUE * 1024 ))
        GIG_VALUE=$(( $MEG_VALUE * 1024 ))
        DIVIDE_BY=1
        VALUE_LABEL=" bytes"
        if [ "$READABLE_VALUE" -gt $MEG_VALUE ]
        then
                DIVIDE_BY=$MEG_VALUE
                VALUE_LABEL="MB"
        elif [ "$READABLE_VALUE" -gt $KILO_VALUE ]
        then
                DIVIDE_BY=$KILO_VALUE
                VALUE_LABEL="KB"
        fi

        READABLE_VALUE="$(( $READABLE_VALUE / $DIVIDE_BY ))${VALUE_LABEL}"
}

checkAndExitCPU()
{
    if [ $IS_SYSTEM_CHECK_DONE -eq 1 ]
    then
        str1=`gettext install "Installer has detected that either System check is already complete OR it should be skipped based on install parameter(s)..."`
        str2=`gettext install "Processor check will not be performed."`
        write_and_log "$str1 $str2" >> $log_file
	return
    fi
    local MIN_CPU=$1
    local CPU=$(getTotalCPUCore)
    if [ $CPU -lt $MIN_CPU ]
    then
	str1=`gettext install "The installer has detected that the system has less than the recommended number of processors. If you observe performance issues after the installation, increase the number of processors."`
	str2=`gettext install "Recommended : "`
        str3=`gettext install "Found : "`
        write_and_log " $str1 $str2 $MIN_CPU, $str3 $CPU" >> $log_file
        echo_sameline "${txtred}"
        write_and_log "$str1 $str2 $MIN_CPU, $str3 $CPU"
        echo_sameline "${txtrst}"
        if [ $UNATTENDED_INSTALL -eq 1 ]
        then
            write_and_log "$str1 $str2 $MIN_CPU, $str3 $CPU"
            str4=`gettext install "Refer to the install parameters in case you wish to continue installation on this platform ie., IS_SYSTEM_CHECK_DONE=1"`
            write_and_log "$INSTR $str4"
            exit
        else
            checkAndProceed
        fi
    else
        str1=`gettext install "System meets minimum CPU requirement."`
        str2=`gettext install "Required : "`
        str3=`gettext install "Found : "`
        write_and_log " $str1 $str2 $MIN_CPU, $str3 $CPU" >> $log_file
        echo_sameline "${txtgrn}"
	    write_and_log "$str1 $str2 $MIN_CPU, $str3 $CPU"
	    echo_sameline "${txtrst}"
    fi

}

checkIDMExist()
{
	IDMVERSIONINST=`rpm -qi novell-DXMLengnx 2>>$log_file | grep "Version" | awk '{print $3}'`
}

checkeDirExist()
{
	EDIRVERSIONINST=`rpm -qi novell-NDSserv 2>>$log_file | grep "Version" | awk '{print $3}'`
	if [ "$EDIRVERSIONINST" == "" ]
	then
		EDIRVERSIONINST=`rpm -qi edirectory-oes-server 2>>$log_file | grep "Version" | awk '{print $3}'`
	fi
}

checkAndExitIDMEngineInstall()
{
    checkeDirExist
    checkIDMExist
    EDIRVERSIONINST=`echo $EDIRVERSIONINST | cut -d"." -f1-2`
    if [ "$IDM_ENGINE_INSTALL_NEEDED" == "y" ] && [ "$EDIRVERSIONINST" != "" ] && [ "$IDMVERSIONINST" == "" ]
    then
        str1=`gettext install "Installer has not detected Identity Manager Engine. However, the check for Identity Manager Engine is being skipped based on install parameter(s)..."`
        str2=`gettext install "Skipping the check for detecting Identity Manager Engine..."`
        write_and_log "$str1 $str2" >> $log_file
	return
    elif [ "$EDIRVERSIONINST" != "" ] && [ "$IDMVERSIONINST" == "" ]
    then
        str1=`gettext install "Installer has detected Identity Vault but not Identity Manager Engine"`
        write_and_log " $str1" >> $log_file
        echo_sameline "${txtred}"
        write_and_log " $str1" >> $log_file
        echo_sameline "${txtrst}"
        if [ $UNATTENDED_INSTALL -eq 1 ]
        then
            write_and_log "$str1"
            str4=`gettext install "Refer to the install parameters in case you wish to continue installation on this platform ie., IDM_ENGINE_INSTALL_NEEDED=y"`
            write_and_log "$INSTR $str4"
            exit
        else
	    checkAndProceedInstall ENGINE
        fi
    fi

}

checkAndExitUnsupportedIDVault()
{
    checkeDirExist
    EDIRVERSIONINST=`echo $EDIRVERSIONINST | cut -d"." -f1-3`
    SUPPORTED_EDIR_VERSION=`echo $SUPPORTED_EDIR_VERSION | cut -d"." -f1-3`
    if [ "$ID_VAULT_VERSION_CHECK_SKIP" == "y" ] && [ "$EDIRVERSIONINST" != "$SUPPORTED_EDIR_VERSION" ] && [ "$EDIRVERSIONINST" != "" ]
    then
        str1=`gettext install "Installer has detected unsupported Identity Vault but the check is being skipped based on install parameter(s)..."`
        str2=`gettext install "Check for supported version of Identity Vault will be skipped..."`
        write_and_log "$str1 $str2" >> $log_file
	return
    elif [ "$EDIRVERSIONINST" != "" ] && [[ "$EDIRVERSIONINST" < "$SUPPORTED_EDIR_VERSION" ]]
    then
        str1=`gettext install "Installer has detected an unsupported version of Identity Vault."`
        write_and_log " $str1" >> $log_file
        echo_sameline "${txtred}"
        write_and_log " $str1" >> $log_file
        echo_sameline "${txtrst}"
        if [ $UNATTENDED_INSTALL -eq 1 ]
        then
            write_and_log "$str1"
            str4=`gettext install "Refer to the install parameters in case you wish to continue installation on this platform ie., ID_VAULT_VERSION_CHECK_SKIP=y"`
            #write_and_log "$INSTR $str4"
            exit
        else
	    checkAndProceedInstall
        fi
    fi

}

checkAndExitMemory()
{
    if [ $IS_SYSTEM_CHECK_DONE -eq 1 ]
    then
	
        str1=`gettext install "Installer has detected that either System check is already complete OR it should be skipped based on install parameter(s)..."`
        str2=`gettext install "Memory check will not be performed."`
        write_and_log "$INSTR $str1 $str2" >> $log_file
        return
    fi
    local MIN_MEM=$1
    local MEM=$(getTotalMemory)
    if [[ $MEM -lt $MIN_MEM ]]
    then
        str1=`gettext install "System does not meets minimum Memory requirement."`
        str2=`gettext install "Required : "`
        str3=`gettext install "Found : "`
        write_and_log "$str1 $str2 $MIN_MEM, $str3 $MEM" >> $log_file
	    echo_sameline "${txtred}"
	    write_and_log "$str1 $str2 $MIN_MEM, $str3 $MEM" 
        echo_sameline "${txtrst}"
        if [ $UNATTENDED_INSTALL -eq 1 ]
        then
            write_and_log "$str1 $str2 $MIN_MEM, $str3 $MEM" 
            str4=`gettext install "Refer to the install parameters in case you wish to continue installation on this platform ie., IS_SYSTEM_CHECK_DONE=1"`
            write_and_log "$INSTR $str4"
            exit
        else
            checkAndProceedMem
        fi
    else
        str1=`gettext install "System meets minimum Memory requirement."`
        str2=`gettext install "Required : "`
        str3=`gettext install "Found : "`
        write_and_log "$str1 $str2 $MIN_MEM, $str3 $MEM" >> $log_file
        echo_sameline "${txtgrn}"
	write_and_log "$str1 $str2 $MIN_MEM, $str3 $MEM"
	echo_sameline "${txtrst}"
    fi
}
checkAndProceed()
{
	str4=`gettext install "You may proceed with the installation, but Identity Manager may not function properly until all recommendations are met."`
        str5=`gettext install "Do you still want to continue? Type y/n [n]:"`
        str6=`gettext install "Proceeding with the installation based on user input"`
        str7=`gettext install "Terminating and Exiting the Installation"`
        echo_sameline "${txtpur}"
        write_and_log "$str4"
        echo_sameline "${txtrst}"
        #write_and_log "$str5"
        read -p "$str5" input
        write_and_log ""
        if [[ $input == "Y" || $input == "y" ]]; then
                echo_sameline "${txtylw}"
                write_and_log "$str6"
                echo_sameline "${txtrst}"
                MIN_CPU=$CPU		

        else
                echo_sameline "${txtred}"
                write_and_log "$str7"
                echo_sameline "${txtrst}"
                exit 1
        fi

}

checkDependenciesAndProceed()
{
        disp_str=`gettext install "Some of the dependencies required for installation of %s are not found. Run RHEL-Prerequisite.sh to know the missing dependencies"`
        disp_str=`printf "$disp_str" "$1"` 
        echo_sameline "${txtred}"
        write_and_log "$disp_str"
        echo_sameline "${txtrst}"
        str4=`gettext install "You may proceed with the installation, but Identity Manager may not function properly until all dependencies are met."`
        str5=`gettext install "Do you still want to continue? Type y/n [n]:"`
        str6=`gettext install "Proceeding with the installation based on user input"`
        str7=`gettext install "Terminating and Exiting the Installation"`
        echo_sameline "${txtpur}"
        write_and_log "$str4"
        echo_sameline "${txtrst}"
        #write_and_log "$str5"
        read -p "$str5" input
        write_and_log ""
        if [[ $input == "Y" || $input == "y" ]]; then
                echo_sameline "${txtylw}"
                write_and_log "$str6"
                echo_sameline "${txtrst}"	
        else
                echo_sameline "${txtred}"
                write_and_log "$str7"
                echo_sameline "${txtrst}"
                removePrerequisiteFile
                exit 1
        fi
}

checkPrerequisites()
{
        local component
        local search_str
        if [ "$1" == "IDME" ]
        then
           search_str="All the pre-requisites for Identity Manager have been met"
           component="Identity Manager Engine"
        elif [ "$1" == "IDV" ]
        then
           search_str="All the pre-requisites for Identity Vault have been met"
           component="Identity Vault"
        elif [ "$1" == "RL" ]
        then
           search_str="All the pre-requisites for Java Remote Loader have been met"
           component="Identity Manager Remote Loader Service"
        elif [ "$1" == "iManager" ]
        then
           search_str="All the pre-requisites for iManager Web Administration have been met"
           component="iManager Web Administration"
        fi     
        if [ -n "$search_str" ]
        then
                if [ $(cat /etc/os-release | grep \"rhel\" | wc -l) -eq 1 ]
                then
                        disp_str=`gettext install "Checking pre-requisites for %s..."`
                        disp_str=`printf "$disp_str" "$component"`
                        write_and_log "$disp_str"
                        if [ ! -e /tmp/idm_install_prerequisites.log ]
                        then
                                ${IDM_INSTALL_HOME}/RHEL-Prerequisite.sh >  /tmp/idm_install_prerequisites.log
                        fi
                        grep "$search_str" /tmp/idm_install_prerequisites.log  &> /dev/null
                        if [ $? -eq 1 ]
                        then
                                if [ $UNATTENDED_INSTALL -eq 1 ]
                                then
                                        disp_str=`gettext install "Some of the dependencies required for installation of %s are not found. Run RHEL-Prerequisite.sh to know the missing dependencies. Terminating and Exiting the Installation"`
                                        disp_str=`printf "$disp_str" "$component"`
                                        write_log "$disp_str"
                                        removePrerequisiteFile
                                        exit 1
                                else
                                        checkDependenciesAndProceed "$component"
                                fi
                        else
                                write_log "$search_str"
                        fi
                fi
        fi
}

removePrerequisiteFile()
{
        if [ -e /tmp/idm_install_prerequisites.log ]
        then
                rm /tmp/idm_install_prerequisites.log
        fi
}

checkAndProceedInstall()
{
	if [ "$1" == "ENGINE" ]
	then
		str4=`gettext install "Installer has detected an existing Identity Vault. It is recommended that the Identity Vault configuration is validated prior to proceeding with the install of Identity Manager Engine."`
	else
		available_eDir_Version=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/IDVault/setup/novell-NDSserv-*.rpm"`
		idvaultsetupDIR=$(readlink -m ${IDM_INSTALL_HOME}/IDVault/setup)
		str4=`gettext install "Installer has detected unsupported Identity Vault version. Upgrade to Identity Vault"`
		str5=`gettext install "version or later to continue..."`
		str6=`gettext install "For upgrading Identity Vault to"`
		str7=`gettext install "execute the following commands:"`
		str8=`gettext install "Exiting....."`
		echo_sameline "${txtred}"
		write_and_log "$str4 $SUPPORTED_EDIR_VERSION $str5"
		write_and_log ""
		write_and_log "$str6 $available_eDir_Version $str7"
		write_and_log ""
		write_and_log " 1) cd $idvaultsetupDIR"
		write_and_log " 2) ./nds-install"
		write_and_log ""
		write_and_log "$str8"
		echo_sameline "${txtrst}"
        exit 1
	fi
        str5=`gettext install "Do you want to continue? Type y/n [n]:"`
        str6=`gettext install "Proceeding with the installation based on user input"`
        str7=`gettext install "Terminating and Exiting the Installation"`
        echo_sameline "${txtpur}"
        write_and_log "$str4"
        echo_sameline "${txtrst}"
        #write_and_log "$str5"
        read -p "$str5" input
        write_and_log ""
        if [[ $input == "Y" || $input == "y" ]]; then
                echo_sameline "${txtylw}"
                write_and_log "$str6"
                echo_sameline "${txtrst}"
        else
                echo_sameline "${txtred}"
                write_and_log "$str7"
                echo_sameline "${txtrst}"
                exit 1
        fi

}

checkAndProceedUNInstall()
{
	#$1 = Product that exists
	#$2 = Product for which the check is happening.
	if [ "$1" == "userappANDreporting" ]
	then
		str2=`gettext install "Installer has detected an existing User Application and Reporting. Uninstalling"`
	elif [ "$1" == "userapp" ]
	then
		str2=`gettext install "Installer has detected an existing User Application. Uninstalling"`
	elif [ "$1" == "reporting" ]
	then
		str2=`gettext install "Installer has detected an existing Reporting. Uninstalling"`
	fi
	str3=`gettext install "may impact their function."`
        str5=`gettext install "Do you want to continue? Type y/n [n]:"`
        str6=`gettext install "Proceeding with the installation based on user input"`
        str7=`gettext install "Terminating and Exiting the Installation"`
        echo_sameline "${txtpur}"
        write_and_log "$str2 $2 $str3"
        echo_sameline "${txtrst}"
        #write_and_log "$str5"
        read -p "$str5" input
        write_and_log ""
        if [[ $input == "Y" || $input == "y" ]]; then
                echo_sameline "${txtylw}"
                write_and_log "$str6"
                echo_sameline "${txtrst}"
        else
                echo_sameline "${txtred}"
                write_and_log "$str7"
                echo_sameline "${txtrst}"
                exit 1
        fi

}

checkAndProceedMem()
{
        str4=`gettext install "You may proceed with the installation, but Identity Manager may not function properly until all recommendations are met."`
        str5=`gettext install "Do you still want to continue? Type y/n [n]:"`
        str6=`gettext install "Proceeding with the installation based on user input"`
        str7=`gettext install "Terminating and Exiting the Installation"`
        echo_sameline "${txtpur}"
        write_and_log "$str4"
        echo_sameline "${txtrst}"
        #write_and_log "$str5"
        read -p "$str5" input
        write_and_log ""
        if [[ $input == "Y" || $input == "y" ]]; then
                echo_sameline "${txtylw}"
                write_and_log "$str6"
                echo_sameline "${txtrst}"
                MIN_MEM=$MEM
        else
                echo_sameline "${txtred}"
                write_and_log "$str7"
                echo_sameline "${txtrst}"
                exit 1
        fi

}

checkAndExitDiskspace()
{
    if [ $IS_SYSTEM_CHECK_DONE -eq 1 ]
    then
        str1=`gettext install "Installer has detected that either System check is already complete OR it should be skipped based on install parameter(s)..."`
        str2=`gettext install "Disk check will not be performed."`
        write_and_log "$INSTR $str1 $str2" >> $log_file
        return
    fi

    str=`gettext install "Checking the disk information..."`
    write_and_log "$INSTR $str" >> $log_file
    df -Ph >> "${log_file}" 2>&1

        MOUNT_NAMES=( )
        MOUNT_SPACE=( )

        for (( dir_index = 0 ; dir_index < ${#DIRS_TO_CHECK[@]} ; dir_index++ ))
        do
                dirname=${DIRS_TO_CHECK[$dir_index]}
        	str=`gettext install "Configure dir"`
    		write_and_log "$INSTR $str ${dirname}" >> $log_file
          	dirname=$(getExistingParentDir "${dirname}")
        	str=`gettext install "Configured dir's parent dir:"`
    		write_and_log "$INSTR $str ${dirname}" >> $log_file
                DEV_NAME=`df -P $dirname | awk 'NR == 2 {print $6}'`
                IN_ARRAY=-1

                if [ ${#MOUNT_NAMES[@]} -gt 0 ]
                then
                        for (( i = 0 ; i < ${#MOUNT_NAMES[@]} ; i++ ))
                        do
                                mntpoint="${MOUNT_NAMES[$i]}"
                                if [ "$DEV_NAME" == "$mntpoint" ]
                                then
                                        IN_ARRAY=$i
                                        MOUNT_SPACE[$i]=$(( ${MOUNT_SPACE[$i]} + ${SPACE_NEEDED[$dir_index]} ))
                                fi
                        done
                fi

                if [ $IN_ARRAY -eq -1 ]
                then
                        MOUNT_NAMES[${#MOUNT_NAMES[@]}]="$DEV_NAME"
                        MOUNT_SPACE[${#MOUNT_SPACE[@]}]=${SPACE_NEEDED[$dir_index]}
                fi
        done

        for (( dir_index = 0 ; dir_index < ${#MOUNT_NAMES[@]} ; dir_index++ ))
        do
            str1=`gettext install "mount"`
            str2=`gettext install ", mount space"`
    	    write_and_log "$INSTR $str1 ${MOUNT_NAMES[$dir_index]} $str2 ${MOUNT_SPACE[$dir_index]}" >> $log_file 
        done

        SPACE_FAILURE=0

        for (( i = 0 ; i < ${#MOUNT_NAMES[@]} ; i++ ))
        do
                mntpoint="${MOUNT_NAMES[$i]}"
                if [ ! -z $mntpoint ]
                then
                        DEV_FREE=`df -PB 1 $mntpoint | awk 'NR == 2 {print $4}'`
                        if [ ! -z $DEV_FREE ]
                        then
                                if [ $DEV_FREE -lt ${MOUNT_SPACE[$i]} ]
                                then
                                        make_readable ${MOUNT_SPACE[$i]}
                                        SPACE_NEEDED="$READABLE_VALUE"
                                        make_readable ${DEV_FREE}
                                        SPACE_AVAIL="$READABLE_VALUE"

        				str1=`gettext install "The mountpoint"`
        				str2=`gettext install "needs"`
        				str3=`gettext install "of free space, but only has"`
        				str4=`gettext install "available"`
    					write_and_log "$INSTR $str1 $mntpoint $str2 $SPACE_NEEDED $str3 $SPACE_AVAIL $str4" >> $log_file
                                        SPACE_FAILURE=1
                                fi
                        fi
                fi
        done

	return $SPACE_FAILURE

}

highlightMsg()
{
        DT=`date`
	echo_sameline "${txtylw}"
        write_and_log "###############################################################"
        echo_sameline "${txtrst}"
        write_and_log " 	$1"
        write_and_log " 	$DT"
        echo_sameline "${txtylw}"
        write_and_log "###############################################################"
        write_and_log ""
 	echo_sameline "${txtrst}"
}

exitIfnotRunfromWrapper()
{
	strerr=`gettext install "Install supported from wrapper level only. Try running the install.sh @ "`
	if [ $IS_WRAPPER_CFG_INST -eq 0 ] && [ $UNATTENDED_INSTALL -ne 1 ]
	then
		write_and_log "$strerr $IDM_INSTALL_HOME"
		exit 1
	fi
}

changeownershipofAppsAndACMQ()
{
	[ $IS_UPGRADE -ne 1 ] && chown -R novlua:novlua /opt/netiq/idm/apps/ /opt/netiq/idm/activemq/ /config/osp /config/userapp /config/reporting /config/activemq &> /dev/null
	[ $IS_UPGRADE -eq 1 ] && chown -R novlua:novlua /opt/netiq/idm/apps/{IDMReporting,activemq,novlua,osp,UserApplication,sspr,tomcat} &> /dev/null
}

#returns 1, if UA is upgraded else returns 0
isUAUpgraded()
{
        local ua_cur_ver=`UAAppVersion`
        local RPMVersionToUpg=`rpm -qip "${IDM_INSTALL_HOME}/user_application/packages/ua/netiq-userapp-*.rpm" | awk -F': ' '/Version/ {print $2}'`
        #RPMVersionToUpg=`echo \"$RPMVersionToUpg\"`
        if [ "$ua_cur_ver" != "$RPMVersionToUpg" ]
        then
                return 0
        else
                return 1
        fi
}

#returns 1, if RPT is upgraded else returns 0
isRPTUpgraded()
{
        local rpt_cur_ver=`ReportingAppVersion`
        local RPMVersionToUpg=`rpm -qip "${IDM_INSTALL_HOME}/reporting/packages/netiq-IDMRPT*.rpm" | awk -F': ' '/Version/ {print $2}'`
        #RPMVersionToUpg=`echo \"$RPMVersionToUpg\"`
        if [ "$rpt_cur_ver" != "$RPMVersionToUpg" ]
        then
                return 0
        else
                return 1
        fi
}

PostUpgrade()
{
	if [ -f /opt/netiq/idm/jre/lib/security/java.security ]
	then
		loginurl=`grep login.config.url.1 /opt/netiq/idm/jre/lib/security/java.security`
		echo $loginurl | grep ^[^#] &> /dev/null
		if [ $? -eq 0 ]
		then
			if [ -f /opt/netiq/common/jre/lib/security/java.security ]
			then
				loginurl2=`grep login.config.url.1 /opt/netiq/common/jre/lib/security/java.security | grep -v ^#`
				echo $loginurl2 | grep ^[^#] &> /dev/null
				loginoutput=$?
				[ $loginoutput -eq 0 ] && return
				if [ $loginoutput -ne 0 ]
				then
					echo $loginurl >> /opt/netiq/common/jre/lib/security/java.security
				fi
			fi
		fi
	fi
}

Replace80and443PortWithNULL()
{
	local TomcatBaseDIR=${IDM_TOMCAT_HOME}
	if [ -f "$1/tomcat/conf/ism-configuration.properties" ]
	then
		TomcatBaseDIR="$1/tomcat"
	fi
	sed -i "s#:80\$##g" ${TomcatBaseDIR}/conf/ism-configuration.properties &> /dev/null
	sed -i "s#:80/#/#g" ${TomcatBaseDIR}/conf/ism-configuration.properties &> /dev/null
	sed -i "s#:443\$##g" ${TomcatBaseDIR}/conf/ism-configuration.properties &> /dev/null
	sed -i "s#:443/#/#g" ${TomcatBaseDIR}/conf/ism-configuration.properties &> /dev/null
}

RestrictAccess()
{
	if [ ! -z "$IDM_TOMCAT_HOME" ]
	then
		if [ -f "$IDM_TOMCAT_HOME/conf/server.xml" ]
		then
			chmod 600 "$IDM_TOMCAT_HOME/conf/server.xml" &> /dev/null
		fi
		if [ -f "$IDM_TOMCAT_HOME/conf/ism-configuration.properties" ]
		then
			chmod 600 "$IDM_TOMCAT_HOME/conf/ism-configuration.properties" &> /dev/null
		fi
		if [ -f "$IDM_TOMCAT_HOME/conf/idmrptdcs_logging.xml" ]
		then
			chmod 600 "$IDM_TOMCAT_HOME/conf/idmrptdcs_logging.xml" &> /dev/null
		fi
	fi
	if [ -f "/opt/netiq/idm/apps/sites/config.ini" ]
	then
		chmod 400 /opt/netiq/idm/apps/sites/config.ini* &> /dev/null
	fi
}

updateUserApplog4jSettingsInsetenv()
{
   grep -q Dlog4j.configurationFile ${IDM_TOMCAT_HOME}/bin/setenv.sh
   if [ $? -ne 0 ]
   then
      CATALINAOPTS_NEW=`grep -ir "CATALINA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed "s/\"$/ -Dlog4j.configurationFile=file:\/\/\/opt\/netiq\/idm\/apps\/tomcat\/conf\/userapp-log4j2.xml\"/g"`
      sed -i.bak '/CATALINA_OPTS/d' ${IDM_TOMCAT_HOME}/bin/setenv.sh
      echo "export CATALINA_OPTS=${CATALINAOPTS_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv.sh
   fi  
}

replaceospextcontextfileInsetenv()
{
   grep -q com.netiq.osp.ext-context-file ${IDM_TOMCAT_HOME}/bin/setenv.sh
   if [ $? -eq 0 ]
   then
      sed -i "s/com.netiq.osp.ext-context-file/internal.osp.framework.ext-context-file/g" ${IDM_TOMCAT_HOME}/bin/setenv.sh
   fi
}

updatewhiteListInismproperties()
{
  grep -q com.netiq.sspr.logout.inform-at-authentication $IDM_TOMCAT_HOME/conf/ism-configuration.properties
  if [ $? -ne 0 ]
  then
    echo "com.netiq.sspr.logout.inform-at-authentication = true" >> $IDM_TOMCAT_HOME/conf/ism-configuration.properties
  fi  
}

changeresourceToclass()
{
  grep -q com\.novell\.soa\.af\.impl\.core\.EngineStateImpl "${IDM_TOMCAT_HOME}/conf/hibernate-workflow.cfg.xml"
  if [ $? -ne 0 ]
  then
    sed -i 's#resource="com/novell/soa/af/impl/persist/EngineState.hbm.xml"#class="com.novell.soa.af.impl.core.EngineStateImpl"#g' "${IDM_TOMCAT_HOME}/conf/hibernate-workflow.cfg.xml"
  fi
}

RemoveAppsAndRptPropsConditionally()
{
	if [ ! -z $IS_UPGRADE ] && [ $IS_UPGRADE -eq 1 ]
	then
		return
	elif [ ! -z $DOCKER_CONTAINER ] && [ "$DOCKER_CONTAINER" == "y" ]
	then
		echo "continue" &> /dev/null
	fi
	if [ -z "$INSTALL_REPORTING" ] || [ "$INSTALL_REPORTING" != "true" ]
	then
	  sed -i "/com.netiq.rpt/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idmdcs/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.dcsdrv/d" ${ISM_CONFIG}
	  sed -i "/sso_apps/d" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  echo "sso_apps=ua" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	fi
	if [ -z "$INSTALL_SSPR" ] || [ "$INSTALL_SSPR" != "true" ]
	then
	  sed -i "/com.netiq.sspr/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idm.pwdmgt.provider/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idm.osp.login.sign-in-help-url/d" ${ISM_CONFIG}
	fi
	if [ -z "$INSTALL_UA" ] || [ "$INSTALL_UA" != "true" ]
	then
	  sed -i "/com.netiq.idmdash/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idmadmin/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idmengine/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.rbpm/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idm.ua/d" ${ISM_CONFIG}
	  sed -i "/DirectoryService\/realms\/jndi\/params\/PROVISION_ROOT/d" ${ISM_CONFIG}
	  sed -i "/com.microfocus.workflow/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.idm.forms/d" ${ISM_CONFIG}
	  sed -i "/com.netiq.forms/d" ${ISM_CONFIG}
	fi
}
     
ismPropertiesChangeUAandRPT()
{
        rpm -qi netiq-userapp &> /dev/null
        userapprpmpresence=$?
        rpm -qi netiq-osp &> /dev/null
        osprpmpresence=$?

        if [ ! -z $AZURE_POSTGRESQL_REQUIRED ] && [[ "$AZURE_POSTGRESQL_REQUIRED" == "y" || "$AZURE_POSTGRESQL_REQUIRED" == "true" ]]
	then
                export AMPERSANDMARK=\&
                export AZUREPGSSL=ssl=true
                export QUESTIONMARK=?
                if [ -f /opt/netiq/idm/apps/tomcat/conf/server.xml ]
                then
                        nooflines=$(sed -n '/<Resource auth="Container"/s/.*url="\(.*\)"[^\n]*/\1/p' /opt/netiq/idm/apps/tomcat/conf/server.xml | cut -d"\"" -f1 | uniq | wc -l)
                        while [ $nooflines -gt 0 ]
                        do
                                existingpgurl=$(sed -n '/<Resource auth="Container"/s/.*url="\(.*\)"[^\n]*/\1/p' /opt/netiq/idm/apps/tomcat/conf/server.xml | cut -d"\"" -f1 | sed -n ${nooflines}p)
                                echo $existingpgurl | grep -q ssl
                                if [ $? -eq 0 ]
                                then
                                        ((nooflines--))
                                        continue
                                fi
                                echo $existingpgurl | grep -q ?
                                if [ $? -eq 0 ]
                                then
                                        sed -i "s#$existingpgurl#$existingpgurl$AMPERSANDMARK$AZUREPGSSL#g" /opt/netiq/idm/apps/tomcat/conf/server.xml
                                else
                                        sed -i "s#$existingpgurl#$existingpgurl$QUESTIONMARK$AZUREPGSSL#g" /opt/netiq/idm/apps/tomcat/conf/server.xml
                                fi
                                ((nooflines--))
                        done
                fi
	fi
	grep sso_apps ${CONFIG_UPDATE_HOME}/configupdate.sh.properties | grep -q ig
	if [ $? -eq 0 ]
	then
		export ssoappsIGvalue=",ig"
		export ssoappsIGvaluewithoutcomma="ig"
	fi
    igvalue=$(grep app_versions ${CONFIG_UPDATE_HOME}/configupdate.sh.properties | awk -F\" '{print $2}' | awk -Fig# '{print $2}' | cut -d"," -f1)
    if [ ! -z $igvalue ] && [ "$igvalue" != "" ]
    then
    	igvaluewithcomma=$(echo ,ig#$igvalue)
    fi
    sed -i "s/no_nam_oauth=\"false\"/no_nam_oauth=\"true\"/g" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    sed -i "/com.sssw.fw.security.sigcert.truststore.type/d" ${ISM_CONFIG}
    newrptredirecthost=$(grep com.netiq.rpt.rpt-web.redirect.url ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | grep -iv "localhost:8180" | cut -d":" -f2 | cut -d"/" -f3)
    oldrptredirecthost=$(grep com.netiq.rpt.redirect.url ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | cut -d":" -f2 | cut -d"/" -f3)
    osphost=$(grep "com.netiq.idm.osp.url.host[[:blank:]]*=" ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | cut -d":" -f2 | cut -d"/" -f3)
    grep $osphost /etc/hosts | grep $newrptredirecthost &> /dev/null
    newrptospsamename=$?
    grep $osphost /etc/hosts | grep $oldrptredirecthost &> /dev/null
    oldrptospsamename=$?
    if [ "$newrptredirecthost" == "$osphost" ] || [ "$oldrptredirecthost" == "$osphost" ] || [ $newrptospsamename -eq 0 ] || [ $oldrptospsamename -eq 0 ]
    then
    	#OSP and RPT are having same host name
	osp_rpt_samename=true
    fi
    rpm -qi netiq-userapp &> /dev/null
    if [ $? -ne 0 ]
    then
	rpm -qi netiq-IDMRPT &> /dev/null
	if [ $? -eq 0 ]
	then
	  # Applicable for standalone rpt and cloud rpt
	  sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  echo "app_versions=\"rpt#6.6.0\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  rpm -qi netiq-osp &> /dev/null
	  if [ $? -eq 0 ]
	  then
	    # Applicable for standalone rpt only setup
	    sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    echo "sso_apps=${ssoappsIGvaluewithoutcomma}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  else
	    # Applicable for standalone rpt with remote osp
	    # Applicable for cloud rpt
	    sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    echo "sso_apps=rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  fi
	else
	  #OSP only setup - container

	  # Identity Console SSO Client Settings 
	  grep -q "com.netiq.edirapi.clientID" ${ISM_CONFIG} | grep -q identityconsole
	  if [ $? -ne 0 ] && [ ! -z $INSTALL_IDENTITY_CONSOLE ] && [ "$INSTALL_IDENTITY_CONSOLE" == "true" ] && [ ! -z $ID_CONSOLE_USE_OSP ] && [ "$ID_CONSOLE_USE_OSP" == "y" ]
	  then
	    echo "com.netiq.edirapi.clientID = identityconsole" >> ${ISM_CONFIG}
	    if [ "$KUBERNETES_ORCHESTRATION" == "y" ] && [ "${KUBE_INGRESS_ENABLED}" == "true" ]
	    then 
	      echo "com.netiq.edirapi.redirect.url = https://$IDM_ACCESS_VIA_SINGLE_DOMAIN/eDirAPI/v1/$ID_VAULT_TREENAME/authcoderedirect" >> ${ISM_CONFIG}
	      echo "com.netiq.edirapi.logout.url = https://$IDM_ACCESS_VIA_SINGLE_DOMAIN/eDirAPI/v1/$ID_VAULT_TREENAME/logoutredirect" >> ${ISM_CONFIG}
	    else
	      echo "com.netiq.edirapi.redirect.url = https://$ID_CONSOLE_SERVER_HOST:$ID_CONSOLE_SERVER_SSL_PORT/eDirAPI/v1/$ID_VAULT_TREENAME/authcoderedirect" >> ${ISM_CONFIG}
	      echo "com.netiq.edirapi.logout.url = https://$ID_CONSOLE_SERVER_HOST:$ID_CONSOLE_SERVER_SSL_PORT/eDirAPI/v1/$ID_VAULT_TREENAME/logoutredirect" >> ${ISM_CONFIG}
	    fi 
	    echo "com.netiq.edirapi.logout.return-param-name = logoutURL" >> ${ISM_CONFIG}
	    echo "com.netiq.edirapi.response-types = code,token" >> ${ISM_CONFIG}  

	    SSO_SERVICE_PWD=$(grep ^SSO_SERVICE_PWD /tmp/silent-*.properties | cut -d"=" -f2 | tr -d '"') encryptclientpass "com.netiq.edirapi.clientPass"
	  fi

	  grep -q "[[:blank:]]*edition=advanced" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  if [ $? -eq 0 ]
	  then
	    grep "com.netiq.edirapi.clientID" ${ISM_CONFIG} | grep -q identityconsole
	    idconsoleentry=$?
	    grep -q "com.netiq.rbpmrest.clientID" ${ISM_CONFIG}
	    if [ $? -ne 0 ] && [ $idconsoleentry -ne 0 ]
	    then
	      echo "com.netiq.rbpmrest.clientID = rbpmrest" >> ${ISM_CONFIG}
	    fi
	    grep -q "com.netiq.idmengine.clientID" ${ISM_CONFIG}
	    if [ $? -ne 0 ] && [ $idconsoleentry -ne 0 ]
	    then
	      echo "com.netiq.idmengine.clientID = idmengine" >> ${ISM_CONFIG}
	    fi
	    grep -q com.netiq.rbpmrest.response-types ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	    if [ $? -eq 0 ]
	    then
	      sed -i '/com.netiq.rbpmrest.response-types/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	      echo "com.netiq.rbpmrest.response-types = password" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	    fi
	    grep -q com.netiq.idmengine.response-types ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	    if [ $? -eq 0 ]
	    then
	      sed -i '/com.netiq.idmengine.response-types/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	      echo "com.netiq.idmengine.response-types = password" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	    fi
	    # IF osp and rpt are same name meaning; this osp is not serving rpt here
	    if [ ! -z "$osp_rpt_samename" ] && [ "$osp_rpt_samename" == "true" ]
	    then
	      # osp container serving UA 
	      sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "app_versions=\"ua#4.8.0$igvaluewithcomma\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "sso_apps=ua${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    else
	      # osp container serving UA and rpt
	      sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "app_versions=\"ua#4.8.0$igvaluewithcomma,rpt#6.6.0\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "sso_apps=ua,rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    fi
	  else
	    grep -q com.netiq.edirapi.redirect.url ${ISM_CONFIG}
	    if [ $? -eq 0 ]
	    then
	      # osp container serving IDConsole
	      sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "app_versions=\"ua#4.8.0$igvaluewithcomma,rpt#6.6.0\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "sso_apps=${ssoappsIGvaluewithoutcomma}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    else
	      # osp container serving rpt only
	      sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "app_versions=\"rpt#6.6.0\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "sso_apps=rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    fi
	  fi
	fi
    else
        rpm -qi netiq-osp &> /dev/null
	if [ $? -ne 0 ]
	then
	  #UA only container setup
	  sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  echo "app_versions=\"ua#4.8.0$igvaluewithcomma\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  echo "sso_apps=ua${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	else
	  #UA standalone setup
	  #IF osp and rpt are same name meaning; this osp is not serving rpt here
	  rpm -qi netiq-IDMRPT &> /dev/null
	  if [ $? -eq 0 ]
	  then
	    # Standalone setup with UA and RPT
	    sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    echo "app_versions=\"ua#4.8.0$igvaluewithcomma,rpt#6.6.0\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    echo "sso_apps=ua,rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	  else
	    # Standalone setup with UA only
	    if [ ! -z "$osp_rpt_samename" ] && [ "$osp_rpt_samename" == "true" ]
	    then
	      # standalone osp not serving rpt
	      sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "app_versions=\"ua#4.8.0$igvaluewithcomma\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "sso_apps=ua${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    else
	      # standalone osp serving rpt
	      sed -i '/app_versions/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "app_versions=\"ua#4.8.0$igvaluewithcomma,rpt#6.6.0\"" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      sed -i '/sso_apps/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	      echo "sso_apps=ua,rpt${ssoappsIGvalue}" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	    fi
	  fi
	fi
    fi
    rpm -qi netiq-IDMRPT &> /dev/null
    if [ $? -eq 0 ]
    then
	grep -q cache.use_second_level_cache ${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml &> /dev/null
	[ $? -eq 0 ] && sed -i '/cache.use_second_level_cache/d' ${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml
	grep -q cache.provider_class ${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml &> /dev/null
	[ $? -eq 0 ] && sed -i '/cache.provider_class/d' ${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml
	grep -q cache.use_second_level_cache ${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml &> /dev/null
	[ $? -eq 0 ] && sed -i '/cache.use_second_level_cache/d' ${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml
	grep -q cache.provider_class ${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml &> /dev/null
	[ $? -eq 0 ] && sed -i '/cache.provider_class/d' ${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml
	sed -i '/com.netiq.rpt.disable-db-create/d' ${ISM_CONFIG}
	echo "com.netiq.rpt.disable-db-create = false" >> ${ISM_CONFIG}
	grep dialect ${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml | grep "[[:blank:]]*<property" | grep -q com.netiq.persist.SQLServerDialect
	if [ $? -eq 0 ]
	then
		# only for mssql
		grep hibernate.jdbc.time_zone ${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml &> /dev/null
		[ $? -ne 0 ] && sed -i "s#<session-factory>#<session-factory>\n\t<property name=\"hibernate.jdbc.time_zone\">UTC</property>#g" ${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml
	fi
    fi
	grep -q "com.netiq.idm.session-timeout" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.session-timeout=1200" >> ${ISM_CONFIG}
	grep -q "com.netiq.rpt.rpt-web.clientID" ${ISM_CONFIG}
	if [ $? -ne 0 ]
	then
		echo "com.netiq.rpt.rpt-web.clientID = rptw" >> ${ISM_CONFIG}
		grep -q "com.netiq.rpt.redirect.url" ${ISM_CONFIG}
		rptredirecturl=$?
		grep -q "com.netiq.rpt.rpt-web.redirect.url" ${ISM_CONFIG}
		rptwebredirecturl=$?
		if [ $rptredirecturl -ne 0 ] && [ $rptwebredirecturl -ne 0 ]
		then
		  echo "com.netiq.rpt.rpt-web.redirect.url = https://___RPT_IP___:___RPT_TOMCAT_HTTPS_PORT___/IDMRPT/oauth.html" >> ${ISM_CONFIG}
		fi
	fi
	grep -q "com.netiq.rpt.rpt-web.response-types" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.rpt.rpt-web.response-types = code" >> ${ISM_CONFIG}
	grep -q "com.netiq.idm.osp.oauth.public.refreshTokenTTL" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.osp.oauth.public.refreshTokenTTL = 2700" >> ${ISM_CONFIG}
	grep -q "com.netiq.oauth.autologout.timeout" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.oauth.autologout.timeout = 60" >> ${ISM_CONFIG}
	grep -q "com.netiq.client.authserver.url.extend.session" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.client.authserver.url.extend.session = \${com.netiq.idm.osp.url.host}/osp/a/idm/auth/app/activity" >> ${ISM_CONFIG}
	grep -q "com.netiq.rpt.redirect.url" ${ISM_CONFIG}
	[ $? -eq 0 ] && sed -i "s/com.netiq.rpt.redirect.url/com.netiq.rpt.rpt-web.redirect.url/g" ${ISM_CONFIG}
	grep -q com.netiq.rpt.landing.url ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	if [ $? -eq 0 ]
	then
		grep com.netiq.rpt.landing.url ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | grep -q com.netiq.idm.osp.url.host
		if [ $? -ne 0 ]
		then
			sed -i '/com.netiq.rpt.landing.url/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
			echo "com.netiq.rpt.landing.url = \${com.netiq.idm.osp.url.host}/idmdash/#/landing" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
		fi
	fi
  grep -q com.netiq.rpt.response-types ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
  if [ $? -eq 0 ]
  then
	sed -i '/com.netiq.rpt.response-types/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.rpt.response-types = password" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
  fi
  grep -q com.netiq.idmdcs.response-types ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
  if [ $? -eq 0 ]
  then
	sed -i '/com.netiq.idmdcs.response-types/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idmdcs.response-types = code,token" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
  fi
  grep -q maxHttpHeaderSize ${IDM_TOMCAT_HOME}/conf/server.xml &> /dev/null
  if [ $? -ne 0 ]
  then
  	sed -i "s/SSLEnabled=/maxHttpHeaderSize=\"65536\" SSLEnabled=/g" ${IDM_TOMCAT_HOME}/conf/server.xml
  	sed -i "s/SSLEnabled =/maxHttpHeaderSize=\"65536\" SSLEnabled=/g" ${IDM_TOMCAT_HOME}/conf/server.xml
  fi
  grep -q com.netiq.rpt.clientPass ${ISM_CONFIG}
  if [ $? -eq 0 ]
  then
  	rptclientpass=$(grep -ir "com.netiq.rpt.clientPass =" ${ISM_CONFIG} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//')
	rptclientpassdecrypt=$($IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt $rptclientpass)
	rptclientpassdecryptwithoutspace=$(echo $rptclientpassdecrypt|xargs)
	if [ "$rptclientpassdecrypt" != "$rptclientpassdecryptwithoutspace" ]
	then
		rptclientpassencryptwithoutspace=$($IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt $rptclientpassdecryptwithoutspace)
		sed -i '/com.netiq.rpt.clientPass =/d' ${ISM_CONFIG}
		echo "com.netiq.rpt.clientPass = $rptclientpassencryptwithoutspace" >> ${ISM_CONFIG}
	fi
  fi
  grep -q "^is_prov=\"true\"" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties &> /dev/null
  oldadvedition=$?
  grep -q "^is_prov=\"false\"" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties &> /dev/null
  oldstdedition=$?
  if [ $oldadvedition -eq 0 ]
  then
  	sed -i '/is_prov=/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	echo "edition=advanced" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
  fi
  if [ $oldstdedition -eq 0 ]
  then
  	sed -i '/is_prov=/d' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
	echo "edition=standard" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
  fi
  sed -i 's/#.*$//;/^$/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
  grep -q org.apache.catalina.valves.ErrorReportValve ${IDM_TOMCAT_HOME}/conf/server.xml
  if [ $? -ne 0 ]
  then
  	sed -i 's/<\/Host>/<Valve className="org.apache.catalina.valves.ErrorReportValve" showReport="false" showServerInfo="false"\/>\n<\/Host>/g' ${IDM_TOMCAT_HOME}/conf/server.xml
  fi
  addSSPRLogoutURLToWhitelist
  addtransformerfactoryTosetenv
  updateUserApplog4jSettingsInsetenv
  replaceospextcontextfileInsetenv
  addcrldpTosetenv
  RemoveAppsAndRptPropsConditionally
  if [ $userapprpmpresence -eq 0 ] && [ $osprpmpresence -eq 0 ]
  then
     updatewhiteListInismproperties
  fi
  if [ $userapprpmpresence -eq 0 ]
  then
     if [[ $(type -t generate_master_key_file) == function ]]
     then
     	generate_master_key_file
     fi
     changeresourceToclass
  fi
}

commonJREswitch()
{
	[ ! -f /opt/netiq/idm/apps/tomcat/bin/setenv.sh ] && return
	grep idm/jre /opt/netiq/idm/apps/tomcat/bin/setenv.sh &> /dev/null
	if [ $? -eq 0 ]
	then
		export JRESwitch=1
		write_and_log "Switching the JRE under setenv.sh to common JRE. Restart tomcat instance for changes to take effect"
		sed -i "s#idm/jre#common/jre#g" /opt/netiq/idm/apps/tomcat/bin/setenv.sh
	fi
}

remove32bitJRE()
{
	rpm -qi novell-DXMLrdxmlx &> /dev/null
	Sixtyfourbitrl=$?
	rpm -qi novell-DXMLrdxml &> /dev/null
	Thirtytwobitrl=$?
	if [ $Sixtyfourbitrl -ne 0 ] && [ $Thirtytwobitrl -ne 0 ]
	then
	  rpm -e netiq-jre &> /dev/null
	fi
}

RemoveAJPConnector()
{
	if [ ! -z "$IDM_TOMCAT_HOME" ]
	then
		if [ -f "$IDM_TOMCAT_HOME/conf/server.xml" ]
		then
			sed -i '/protocol=\"AJP\/[0-9]/d' "$IDM_TOMCAT_HOME/conf/server.xml"
		fi
	fi
}

containsElement ()
{
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && echo 0 && return 0; done
        echo 1;return 1
}

importgpgpackagesign()
{
        rpm --import ${IDM_INSTALL_HOME}/common/license/MicroFocusGPGPackageSign.pub &> /dev/null
}

fixssprconfigurationxml()
{
        # This code should not be used once sspr works seamlessly with xpath itself
        if [ -f /opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml ]
        then
                xmllint --format /opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml > /tmp/SSPRConfiguration.xml
                echo yes | cp /tmp/SSPRConfiguration.xml /opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml
                echo yes | rm -f /tmp/SSPRConfiguration.xml
        fi
}

updateospcontextdirforrptonlysetup()
{
        #Only if osp.war is not found
        if [ ! -f /opt/netiq/idm/apps/tomcat/webapps/osp.war ]
        then
                sed -i "s#CONTEXT_DIR=\"/opt/netiq/idm/apps/tomcat\"#CONTEXT_DIR=\"/opt/netiq/idm/apps/tomcat-jre8\"#g" /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
        fi
}

fixforsecretstore()
{
        if [ -z $ISM_CONFIG ] || [ "$ISM_CONFIG" == "" ]
        then
                ISM_CONFIG=/opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
        fi
        if [ -z $IDM_JRE_HOME ] || [ "$IDM_JRE_HOME" == "" ]
        then
                IDM_JRE_HOME=/opt/netiq/common/jre
        fi
        if [ -z $CONFIG_UPDATE_HOME ] || [ "$CONFIG_UPDATE_HOME" == "" ]
        then
                CONFIG_UPDATE_HOME=/opt/netiq/idm/apps/configupdate
        fi
        if [ ! -f $ISM_CONFIG ]
        then
                return
        fi
        grep -q com.netiq.idm.migrate.secretstore ${ISM_CONFIG}
        if [ $? -eq 0 ]
        then
                return
        fi
	mailIVSecretkey=$(cat /dev/urandom | tr -dc '[:alnum:]' | fold -w ${1:-128} | head -n 1)
	encryptedmailIVSecretkey=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt ${mailIVSecretkey}`
	mailSecretkey=$(cat /dev/urandom | tr -dc '[:alnum:]' | fold -w ${1:-256} | head -n 1)
	encryptedmailSecretkey=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt ${mailSecretkey}`
	echo "com.opentext.mail.mailIVSecretkey._attr_obscurity = ENCRYPT" >> ${ISM_CONFIG}
	echo "com.opentext.mail.mailIVSecretkey = ${encryptedmailIVSecretkey}"
	echo "com.opentext.mail.mailSecretkey._attr_obscurity = ENCRYPT" >> ${ISM_CONFIG}
	echo "com.opentext.mail.mailSecretkey = ${encryptedmailSecretkey}"
        echo "com.netiq.idm.migrate.secretstore = true" >> ${ISM_CONFIG}
}

messageforoffcloudjre8()
{
        #Already reporting upgraded; then skip
        rpm -Uvh --test ${IDM_INSTALL_HOME}/reporting/packages/netiq-IDMRPT-*rpm &> /dev/null
        retCode=$?
        if [ $retCode -eq 0 ]
        then
                echo "Proceed with displaying the message" &> /dev/null
        else
                return
        fi
        # Message to be printed till the time reporting is with jre8
        if [ -z "$JRE8CODE_BLOCK" ]
        then
                if [ -f /opt/netiq/idm/apps/tomcat/webapps/IDMRPT.war ] || [ -f /opt/netiq/idm/apps/tomcat/webapps/idmdcs.war ]
                then
                        #Identified reporting installation in the machine
                        if [ -f /opt/netiq/idm/apps/tomcat/webapps/idmdash.war ]
                        then
                                #Both reporting and userapp installed in the machine
                                echo_sameline ""
                                echo_sameline "###############################################################"
                                echo_sameline ""
                                str1=`gettext install "   Identity Reporting Version 7.0.1 is not java11 compatible  
                It continues to work with jre8."`
                                echo_sameline ""
                                write_and_log "$str1"
                                str1=`gettext install "   Running Identity Reporting on this server along with any 
   other Identity Manager components might have performance 
   implications. For optimum performance, it is suggested to 
   move Identity Reporting to a standalone server.  If you 
   proceed with installation, Identity Reporting will get 
   upgraded."`
                                echo_sameline "${txtred}"
                                write_and_log "$str1"
                                echo_sameline "${txtrst}"
                                echo_sameline ""
                                str1=`gettext install "   Refer release notes for more information."`
                                write_and_log "$str1"
                                str1=`gettext install "Impacted Areas for Identity Reporting Version 7.0.1"`
                                echo_sameline "${txtylw}"
                                write_and_log "$str1"
                                echo_sameline ""
                                str1=`gettext install "- DCS Driver needs to be reconfigured"`
                                write_and_log "$str1"
                                str1=`gettext install "- Update all the Identity Manager components mandatorily on 
  your server"`
                                write_and_log "$str1"
                                str1=`gettext install "- Any reverse proxy configuration needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- Bookmarks defined on your browsers' needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- New netiq-tomcat-jre8 service would be created"`
                                write_and_log "$str1"
                                echo_sameline "${txtrst}"
                                echo_sameline ""
                                echo_sameline "###############################################################"
                        else
                                #Reporting only setup
                                echo_sameline ""
                                echo_sameline "###############################################################"
                                echo_sameline ""
                                str1=`gettext install "   Identity Reporting Version 7.0.1 is not java11 compatible  
                It continues to work with jre8."`
                                echo_sameline ""
                                write_and_log "$str1"
                                str1=`gettext install "Impacted Areas for Identity Reporting Version 7.0.1"`
                                echo_sameline "${txtylw}"
                                write_and_log "$str1"
                                echo_sameline ""
                                str1=`gettext install "- Any reverse proxy configuration needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- Bookmarks defined on your browsers' needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- New netiq-tomcat-jre8 service would be created"`
                                write_and_log "$str1"
                                echo_sameline "${txtrst}"
                                echo_sameline ""
                                echo_sameline "###############################################################"
                        fi
                fi
        fi
        rptVersion=$(rpm -q --queryformat '%{VERSION}' netiq-IDMRPT)
        if [ ! -z "$rptVersion" ] && [ "$rptVersion" == "7.0.1" ]
        then
                if [ -f /opt/netiq/idm/apps/tomcat-jre8/webapps/IDMRPT.war ] || [ -f /opt/netiq/idm/apps/tomcat-jre8/webapps/idmdcs.war ]
                then
                        #Identified reporting installation in the machine
                        if [ -f /opt/netiq/idm/apps/tomcat/webapps/idmdash.war ]
                        then
                                #Both reporting and userapp installed in the machine
                                echo_sameline ""
                                echo_sameline "###############################################################"
                                echo_sameline ""
                                str1=`gettext install "   Identity Reporting Version 7.2.0 supports java11   
   Upgrading would ensure Identity Reporting and 
   Identity Applications use same netiq-tomcat service."`
                                echo_sameline ""
                                write_and_log "$str1"
                                str1=`gettext install "   Running Identity Reporting on this server along with any 
   other Identity Manager components might have performance 
   implications. For optimum performance, it is suggested to 
   move Identity Reporting to a standalone server.  If you 
   proceed with installation, Identity Reporting will get 
   upgraded."`
                                #echo_sameline "${txtred}"
                                #write_and_log "$str1"
                                #echo_sameline "${txtrst}"
                                #echo_sameline ""
                                str1=`gettext install "   Refer release notes for more information."`
                                write_and_log "$str1"
                                str1=`gettext install "Impacted Areas for Identity Reporting Version 7.2.0"`
                                echo_sameline "${txtylw}"
                                write_and_log "$str1"
                                echo_sameline ""
                                str1=`gettext install "- DCS Driver needs to be reconfigured"`
                                write_and_log "$str1"
                                str1=`gettext install "- Update all the Identity Manager components mandatorily on 
  your server"`
                                write_and_log "$str1"
                                str1=`gettext install "- Any reverse proxy configuration needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- Bookmarks defined on your browsers' needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- netiq-tomcat-jre8 service would be disabled"`
                                write_and_log "$str1"
                                echo_sameline "${txtrst}"
                                echo_sameline ""
                                echo_sameline "###############################################################"
                        else
                                #Reporting only setup
                                echo_sameline ""
                                echo_sameline "###############################################################"
                                echo_sameline ""
                                str1=`gettext install "   Identity Reporting Version 7.2.0 supports java11   
                Upgrading would ensure Identity Reporting and Identity Applications use same netiq-tomcat service."`
                                echo_sameline ""
                                write_and_log "$str1"
                                str1=`gettext install "Impacted Areas for Identity Reporting Version 7.2.0"`
                                echo_sameline "${txtylw}"
                                write_and_log "$str1"
                                echo_sameline ""
                                str1=`gettext install "- Any reverse proxy configuration needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- Bookmarks defined on your browsers' needs to be updated"`
                                write_and_log "$str1"
                                str1=`gettext install "- netiq-tomcat-jre8 service would be disabled"`
                                write_and_log "$str1"
                                echo_sameline "${txtrst}"
                                echo_sameline ""
                                echo_sameline "###############################################################"
                        fi
                fi
        fi
}

jre8zipextract()
{
        #Fresh/Update of jre8 via zip file forced overwrite by excluding cacerts
        if [ -f ${IDM_INSTALL_HOME}/common/packages/java/netiq-jrex*zip ]
        then
                cd /opt/netiq/common
                if [ -f jre8/lib/security/cacerts ]
                then
                        # File already exists then take backup of this file and remove the directory
                        echo yes | cp jre8/lib/security/cacerts /tmp/root.cacerts.file
                        echo yes | rm -rf jre8
                fi
                unzip -oq ${IDM_INSTALL_HOME}/common/packages/java/netiq-jrex*zip -x "*cacerts"
                if [ -f /tmp/root.cacerts.file ]
                then
                        echo yes | cp /tmp/root.cacerts.file /opt/netiq/common/jre8/lib/security/cacerts
                else
                        if [ -f /opt/netiq/common/jre/lib/security/cacerts ]
                        then
                                echo yes | cp /opt/netiq/common/jre/lib/security/cacerts /opt/netiq/common/jre8/lib/security/
                        fi
                fi
                echo yes | rm -f /tmp/root.cacerts.file
                cd - &> /dev/null
        fi
}

configupdatejre8link()
{
        if [ -f /opt/netiq/idm/apps/configupdate/configupdate.sh.properties ]
        then
                grep -q jre8 /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
                if [ $? -ne 0 ]
                then
                        sed -i "s|jre|jre8|g" /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
                fi
        fi
}

configupdatejre8unlink()
{
        if [ -f /opt/netiq/idm/apps/configupdate/configupdate.sh.properties ]
        then
                grep -q jre8 /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
                if [ $? -eq 0 ]
                then
                        sed -i "s|jre8|jre|g" /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
                fi
        fi
}

removeunsetrptproperties()
{
        sed -i "/___RPT_IP___/d" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
}

updatetomcatversion_for_osp()
{
        sed -i "/internal.osp.container.plugin.server-version/d" /opt/netiq/idm/apps/tomcat/bin/setenv.sh
        tomcatversion=$(rpm -qa --queryformat '%{version}' netiq-idmtomcat)
        echo export CATALINA_OPTS=\"\$CATALINA_OPTS -Dinternal.osp.container.plugin.server-version=$tomcatversion\" >> /opt/netiq/idm/apps/tomcat/bin/setenv.sh
}

offcloudjre8()
{
        skipportchange=false
        if [ -z "$JRE8CODE_BLOCK" ]
        then
                removeunsetrptproperties
                #Deciding whether port change in server.xml should happen or not
                totalwars=$(ls /opt/netiq/idm/apps/tomcat/webapps/*.war | wc  -l)
                totalrptwars=$(ls /opt/netiq/idm/apps/tomcat/webapps/*.war | grep -Ei "dcs|rpt" | wc -l)
                if [ "$totalwars" == "$totalrptwars" ]
                then
                        export skipportchange=true
                fi
                jre8zipextract
                configupdatejre8link
                if [ ! -d /opt/netiq/idm/apps/tomcat-jre8 ]
                then
                        cp -rpf /opt/netiq/idm/apps/tomcat /opt/netiq/idm/apps/tomcat-jre8
                        #Setting jre path to /opt/netiq/common/jre8
                        sed -i "s|jre|jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/setenv.sh
                        sed -i "s|/tomcat|/tomcat-jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/setenv.sh
                        sed -i "s|jre|jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/startUA.sh
                        sed -i "s|/tomcat|/tomcat-jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/startUA.sh
                        sed -i "s|idm/tomcat-jre8|idm/tomcat|g" /opt/netiq/idm/apps/tomcat-jre8/bin/startUA.sh
                        sed -i "s|jre|jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/shutdownUA.sh
                        sed -i "s|/tomcat|/tomcat-jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/shutdownUA.sh
                        #Last replace in shutdownUA.sh for shutdown script
                        sed -i "s|/opt/netiq/idm/tomcat-jre8/bin/shutdown.sh|/opt/netiq/idm/tomcat/bin/shutdown.sh|g" /opt/netiq/idm/apps/tomcat-jre8/bin/shutdownUA.sh
                        mv /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat-jre8
                        mv /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat.service /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat-jre8.service
                        sed -i "s|/tomcat|/tomcat-jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat-jre8
                        sed -i "s|netiq-tomcat|netiq-tomcat-jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat-jre8
                        sed -i "s|netiq-tomcat|netiq-tomcat-jre8|g" /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat-jre8.service
                        #Port changes
                        # For shutdown port
                        # xmlmod -s server.xml 'string(/Server/@port)'
                        # check next number till available and choose one
                        # Replace with double quotes
                        serverport=$(${XML_MOD} -s /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml 'string(/Server/@port)')
                        totalConnectorportsconfigured=$(${XML_MOD} -s /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml 'count(/Server/Service[1]/Connector)' | cut -d'.' -f1)
                        portsconfigured=()
                        portsconfigured[0]=$(echo ${serverport})
                        i=1
                        while [ $totalConnectorportsconfigured -gt 0 ]
                        do
                                thisport=$(${XML_MOD} -s /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml "string(/Server/Service[1]/Connector[${totalConnectorportsconfigured}]/@port)")
                                portsconfigured[$i]=$thisport
                                ((i++))
                                ((totalConnectorportsconfigured--))
                        done
                        #At this point portsconfigured array will have all configured ports.  New port shouldn't be from this array.
                        availableserverport=$(expr $serverport + 1)
                        while [ true ]
                        do
                                portavailable=$(containsElement "$availableserverport" "${portsconfigured[@]}")
                                if [ $portavailable -eq 1 ]
                                then
                                        echo "we can proceed with this port" &> /dev/null
                                else
                                        echo "we can't proceed with this port" &> /dev/null
                                        ((availableserverport++))
                                        continue
                                fi
                                check_port_in_use $availableserverport
                                if [ $? -eq 0 ]
                                then
                                        #Port is in use need to check next port
                                        ((availableserverport++))
                                else
                                        #Port is free
                                        break
                                fi
                        done
                        if [ "$skipportchange" != "true" ]
                        then
                                sed -i "s|\"$serverport\"|\"$availableserverport\"|g" /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml
                        fi
                        # For application connector port
                        # Taking only first sample as below
                        availableconnectorport=$(expr ${portsconfigured[1]} + 1)
                        while [ true ]
                        do
                                portavailable=$(containsElement "$availableconnectorport" "${portsconfigured[@]}")
                                if [ $portavailable -eq 1 ]
                                then
                                        echo "we can proceed with this port" &> /dev/null
                                else
                                        echo "we can't proceed with this port" &> /dev/null
                                        ((availableconnectorport++))
                                        continue
                                fi
                                check_port_in_use $availableconnectorport
                                if [ $? -eq 0 ]
                                then
                                        #Port is in use need to check next port
                                        ((availableconnectorport++))
                                else
                                        #Port is free
                                        break
                                fi
                        done
                        if [ "$skipportchange" != "true" ]
                        then
                                sed -i "s|\"${portsconfigured[1]}\"|\"$availableconnectorport\"|g" /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml
                        fi
                        #traverse through each Connector port like below when needed
                        # xmlmod -s server.xml 'string(/Server/Service[1]/Connector[2]/@port)'
                        #Deleting all Connector element entries other than the first one
                        totalConnectorportsconfigured=$(${XML_MOD} -s /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml 'count(/Server/Service[1]/Connector)' | cut -d'.' -f1)
                        while [ $totalConnectorportsconfigured -gt 0 ]
                        do
                                ${XML_MOD} -r /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml '/Server/Service[1]/Connector[2]'
                                ((totalConnectorportsconfigured--))
                        done
                        bindaddressport=$(awk -F'address=' '{print $2}' /opt/netiq/idm/apps/tomcat-jre8/bin/setenv.sh | awk -F',' '{print $1}' | grep "[0-9]\{1,3\}")
                        bindaddressportavailable=$(expr $bindaddressport + 1)
                        if [ ! -z $bindaddressportavailable ] && [ "$bindaddressportavailable" != "" ] && [ "$bindaddressportavailable" != "1" ]
                        then
                                while [ true ]
                                do
                                        portavailable=$(containsElement "$bindaddressportavailable" "${portsconfigured[@]}")
                                        if [ $portavailable -eq 1 ]
                                        then
                                                echo "we can proceed with this port" &> /dev/null
                                        else
                                                echo "we can't proceed with this port" &> /dev/null
                                                ((bindaddressportavailable++))
                                                continue
                                        fi
                                        check_port_in_use $bindaddressportavailable
                                        if [ $? -eq 0 ]
                                        then
                                                #Port is in use need to check next port
                                                ((bindaddressportavailable++))
                                        else
                                                #Port is free
                                                break
                                        fi
                                done
                                if [ "$skipportchange" != "true" ]
                                then
                                        sed -i "s|$bindaddressport|$bindaddressportavailable|g" /opt/netiq/idm/apps/tomcat-jre8/bin/setenv.sh
                                fi
                        fi
                        #Fetch rpt Connector port
                        existingrptport=$(grep com.netiq.rpt.rpt-web.redirect.url /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties | grep -iv "localhost:8180" | grep -v \/\/\/ | grep -v ___RPT_IP___ | cut -d":" -f3 | cut -d"/" -f1)
                        if [ -z $existingrptport ] || [ "$existingrptport" == "" ]
                        then
                                echo "Either 443 or proxy enabled" &> /dev/null
                                echo "User need to manually update the setup" &> /dev/null
                        else
                                if [ "$skipportchange" != "true" ]
                                then
                                        #Need to replace the existing reporting port with newly identified port only when skip port is not set
                                        sed -i "s|$existingrptport/IDMRPT|$availableconnectorport/IDMRPT|g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
                                        sed -i "s|$existingrptport/idmdcs|$availableconnectorport/idmdcs|g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
                                fi
                                rm -f /opt/netiq/idm/apps/tomcat-jre8/conf/ism-configuration.properties
                                ln -sf /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties /opt/netiq/idm/apps/tomcat-jre8/conf/ism-configuration.properties
                        fi
                        echo yes | cp /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat-jre8 /etc/init.d/
                        echo yes | cp /opt/netiq/idm/apps/tomcat-jre8/bin/netiq-tomcat-jre8.service /etc/systemd/system/
                        systemctl enable netiq-tomcat-jre8.service &> /dev/null
                        #systemctl start netiq-tomcat-jre8.service
                        # If the setup is a reporting only setup then we need to retain the bind address and Connector ports
                        ls /opt/netiq/idm/apps/tomcat/webapps/*war &> /dev/null
                        if [ $? -ne 0 ]
                        then
                                #There are no other war files in original tomcat location; hence we can use same bind address and Connector ports
                                if [ ! -z $bindaddressport ] && [ "$bindaddressport" != "" ]
                                then
                                        sed -i "s|$bindaddressportavailable|$bindaddressport|g" /opt/netiq/idm/apps/tomcat-jre8/bin/setenv.sh
                                fi

                                sed -i "s|\"$availableconnectorport\"|\"${portsconfigured[1]}\"|g" /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml
                                #Stop and Disable the original tomcat
                                systemctl stop netiq-tomcat &> /dev/null
                                systemctl disable netiq-tomcat &> /dev/null
                        fi
                else
                        #To get the latest reporting wars from regular location
                        cd /opt/netiq/idm/apps/tomcat/webapps/
                        cp -rpf dcsdoc* idmdcs* IDMDCS-CORE* IDMRPT* rptdoc* /opt/netiq/idm/apps/tomcat-jre8/webapps/
                        cd - &> /dev/null
                fi
                cd /opt/netiq/idm/apps/tomcat-jre8/webapps/
                rm -rf idmdash* idmappsdoc* IDMProv* osp* sspr* workflow* idmadmin* dcsdoc idmdcs IDMDCS-CORE IDMRPT IDMRPT-CORE rptdoc
                cd - &> /dev/null
                rm -rf /opt/netiq/idm/apps/tomcat-jre8/logs/*
                rm -rf /opt/netiq/idm/apps/tomcat-jre8/work/Catalina/localhost/*
                cd /opt/netiq/idm/apps/tomcat/webapps/
                rm -rf dcsdoc* idmdcs* IDMDCS-CORE* IDMRPT* rptdoc*
                cd - &> /dev/null
                # Delete any amq jar inside tomcat-jre8/lib for offcloud rpt and to tomcat/lib for cloud rpt
                # Copy amq 5.16.6 to tomcat-jre8/lib for offcloud rpt and to tomcat/lib for cloud rpt
                if [ -d /opt/netiq/idm/apps/tomcat-jre8/lib ]
                then
                        # reporting offcloud
                        echo yes | rm -f /opt/netiq/idm/apps/tomcat-jre8/lib/activemq-all-*jar
                        echo yes | cp ${IDM_INSTALL_HOME}/common/packages/activemq/activemq-all-*jar /opt/netiq/idm/apps/tomcat-jre8/lib/
                fi
                # Within tomcat remove reporting entries
                "${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMDCSDataSource']"
                "${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMRPTCfgUpdateSource']"
                "${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMRPTDataSource']"
                "${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='shared/IDMRPTCfgUpdateSource']"
                "${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='shared/IDMDCSDataSource']"
                "${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='shared/IDMRPTDataSource']"
                # Within tomcat-jre8 remove userapp entries
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMUADataSource']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/context.xml" "/Context/ResourceLink[@name='shared/IGADataSource']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/context.xml" "/Context/ResourceLink[@name='jms/ConnectionFactory']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/context.xml" "/Context/ResourceLink[@name='topic/IDMNotificationDurableTopic']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/context.xml" "/Context/ResourceLink[@name='topic/EmailBasedApprovalTopic']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='shared/IDMUADataSource']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='shared/IGADataSource']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='jms/ConnectionFactory']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='topic/IDMNotificationDurableTopic']"
                "${XML_MOD}" "-r" "/opt/netiq/idm/apps/tomcat-jre8/conf/server.xml" "/Server/GlobalNamingResources/Resource[@name='topic/EmailBasedApprovalTopic']"
                chown -R novlua:novlua /opt/netiq/common/jre8 /opt/netiq/idm/apps/tomcat-jre8
                if [ "$skipportchange" == "true" ]
                then
                        #Stop and Disable the original tomcat
                        systemctl stop netiq-tomcat &> /dev/null
                        systemctl disable netiq-tomcat &> /dev/null
                        updateospcontextdirforrptonlysetup
                fi
        fi
}

cutthefirstelement()
{
        inputvar=$@
        outputvar=$(echo $inputvar | cut -d"<" -f2)
        outputvar=$(echo \<$outputvar)
        echo $outputvar
}

revertoffcloudjre8()
{
        #When jre8 found rename it for deprecation
        # if [ -d /opt/netiq/common/jre8 ]
        # then
        #         mv /opt/netiq/common/jre8 /opt/netiq/common/deprecate-jre8
        # fi
        #Need to remove deprecated jre8 next release
        #When tomcat-jre8 found rename it for deprecation
        if [ -d /opt/netiq/idm/apps/tomcat-jre8 ]
        then
                #for server.xml
                rptresource1=$("${XML_MOD}" -s /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml "/Server/GlobalNamingResources/Resource[@name='shared/IDMRPTCfgUpdateSource']")
                rptresource1=$(cutthefirstelement $rptresource1)
                if [ ! -z "$rptresource1" ]
                then
                        "${XML_MOD}" /opt/netiq/idm/apps/tomcat/conf/server.xml "/Server/GlobalNamingResources[1]/." "/$rptresource1"
                fi
                rptresource2=$("${XML_MOD}" -s /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml "/Server/GlobalNamingResources/Resource[@name='shared/IDMDCSDataSource']")
                rptresource2=$(cutthefirstelement $rptresource2)
                if [ ! -z "$rptresource2" ]
                then
                        "${XML_MOD}" /opt/netiq/idm/apps/tomcat/conf/server.xml "/Server/GlobalNamingResources[1]/." "/$rptresource2"
                fi
                rptresource3=$("${XML_MOD}" -s /opt/netiq/idm/apps/tomcat-jre8/conf/server.xml "/Server/GlobalNamingResources/Resource[@name='shared/IDMRPTDataSource']")
                rptresource3=$(cutthefirstelement $rptresource3)
                if [ ! -z "$rptresource3" ]
                then
                        "${XML_MOD}" /opt/netiq/idm/apps/tomcat/conf/server.xml "/Server/GlobalNamingResources[1]/." "/$rptresource3"
                fi
                #for context.xml
                rptresource1=$("${XML_MOD}" -s /opt/netiq/idm/apps/tomcat-jre8/conf/context.xml "/Context/ResourceLink[@name='jdbc/IDMDCSDataSource']")
                rptresource1=$(cutthefirstelement $rptresource1)
                if [ ! -z "$rptresource1" ]
                then
                        "${XML_MOD}" /opt/netiq/idm/apps/tomcat/conf/context.xml "/Context[1]/." "/$rptresource1"
                fi
                rptresource2=$("${XML_MOD}" -s /opt/netiq/idm/apps/tomcat-jre8/conf/context.xml "/Context/ResourceLink[@name='jdbc/IDMRPTCfgUpdateSource']")
                rptresource2=$(cutthefirstelement $rptresource2)
                if [ ! -z "$rptresource2" ]
                then
                        "${XML_MOD}" /opt/netiq/idm/apps/tomcat/conf/context.xml "/Context[1]/." "/$rptresource2"
                fi
                rptresource3=$("${XML_MOD}" -s /opt/netiq/idm/apps/tomcat-jre8/conf/context.xml "/Context/ResourceLink[@name='jdbc/IDMRPTDataSource']")
                rptresource3=$(cutthefirstelement $rptresource3)
                if [ ! -z "$rptresource3" ]
                then
                        "${XML_MOD}" /opt/netiq/idm/apps/tomcat/conf/context.xml "/Context[1]/." "/$rptresource3"
                fi
                #Fetch rpt Connector port
                existingrptport=$(grep com.netiq.rpt.rpt-web.redirect.url /opt/netiq/idm/apps/tomcat-jre8/conf/ism-configuration.properties | grep -iv "localhost:8180" | grep -v \/\/\/ | grep -v ___RPT_IP___ | cut -d":" -f3 | cut -d"/" -f1)
                #Fetch ua Connector port
                availableconnectorport=$(grep com.netiq.idmdash.redirect.url /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties | grep -iv "localhost:8180" | grep -v \/\/\/ | cut -d":" -f3 | cut -d"/" -f1)
                if [ -z $existingrptport ] || [ "$existingrptport" == "" ]
                then
                        echo "Either 443 or proxy enabled" &> /dev/null
                        echo "User need to manually update the setup" &> /dev/null
                else
                        if [ "$skipportchange" != "true" ]
                        then
                                #Need to replace the existing reporting port with newly identified port only when skip port is not set
                                sed -i "s|$existingrptport/IDMRPT|$availableconnectorport/IDMRPT|g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
                                sed -i "s|$existingrptport/idmdcs|$availableconnectorport/idmdcs|g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
                        fi
                fi
                systemctl disable netiq-tomcat-jre8.service &> /dev/null
                systemctl stop netiq-tomcat-jre8.service &> /dev/null
                mv /opt/netiq/idm/apps/tomcat-jre8 /opt/netiq/idm/apps/deprecate-tomcat-jre8  
        fi
        #Need to remove deprecated tomcat-jre8 next release
        configupdatejre8unlink
}

copyThirdPartyLicense()
{
    if [ -z "$DEDUCED_NONROOT_IDVAULT_LOCATION" ]
    then
		yes | cp -f "${IDM_INSTALL_HOME}/common/license/IdentityManager-3rdParty-license.txt" /opt/netiq/idm/
    else
	if [ ! -d $DEDUCED_NONROOT_IDVAULT_LOCATION/../../netiq/idm/ ]
	then
		mkdir -p $DEDUCED_NONROOT_IDVAULT_LOCATION/../../netiq/idm
	fi
	yes | cp -f "${IDM_INSTALL_HOME}/common/license/IdentityManager-3rdParty-license.txt" $DEDUCED_NONROOT_IDVAULT_LOCATION/../../netiq/idm/
    fi
}

removelibstdcbinariesNonRoot()
{
        if [ ! -z "$DEDUCED_NONROOT_IDVAULT_LOCATION" ] && [ "$DEDUCED_NONROOT_IDVAULT_LOCATION" != "" ]
        then
                echo yes | rm -f $DEDUCED_NONROOT_IDVAULT_LOCATION/../lib64/libstdc++.so.6*
        fi
}

removesslcryptolinks()
{
   if [ -f /usr/lib64/libssl.so.1.0.0 ]
   then
	ls -l /usr/lib64/libssl.so.1.0.0 | grep -q /opt/netiq/common/openssl/lib64/libssl.so.1.0.0
	[ $? -eq 0 ] && rm /usr/lib64/libssl.so.1.0.0
   fi
   if [ -f /usr/lib64/libcrypto.so.1.0.0 ]
   then
	ls -l /usr/lib64/libcrypto.so.1.0.0 | grep -q /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0
	[ $? -eq 0 ] && rm /usr/lib64/libcrypto.so.1.0.0
   fi
}

grantToauth()
{
   if [ -f /opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml ]
   then
   	grep -q osp/a/idm/auth/oauth2/grant /opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml &> /dev/null
   	if [ $? -eq 0 ]
   	then
   		sed -i "s|osp/a/idm/auth/oauth2/grant|osp/a/idm/auth/oauth2/auth|g" /opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml
   	fi
   fi
}

deduced_nonroot_path()
{
  fileTocheck=dxcmd
  dirTocheck=${NONROOT_IDVAULT_LOCATION}
  fileLocation=`find "$dirTocheck" -iname "$fileTocheck" 2> /dev/null`
  dirTocheck=$(dirname `dirname $fileLocation 2> /dev/null` 2> /dev/null)
  NONROOT_IDVAULT_LOCATION=$dirTocheck
  export DEDUCED_NONROOT_IDVAULT_LOCATION=$NONROOT_IDVAULT_LOCATION
}

checksize()
{
	existinguafolder="/opt/netiq/idm"
	olddatasize=$(du -s $existinguafolder | awk '{print $1}')
	# Adding 1 GB additionally to the old data size
	olddatasize=$(expr $olddatasize + 1000000)
	if [ ! -d $IDM_BACKUP_FOLDER ]
	then
		mkdir -p $IDM_BACKUP_FOLDER
	fi
	newdatasize=$(df -k $IDM_BACKUP_FOLDER | grep -v Avail | awk '{print $4}')
	if [ $newdatasize -lt $olddatasize ]
	then
		msg=$(gettext install "Backup base directory $existinguafolder does not have sufficient disk space. Exiting...")
		echo "$msg"
		exit 1
	fi
}

addSSPRLogoutURLToWhitelist()
{
  local SSPR_APPLICATIONPATH="/opt/netiq/idm/apps/sspr/sspr_data"
  if [ ! -f $SSPR_APPLICATIONPATH/SSPRConfiguration.xml ]
  then 
    return 
  fi
  wc=$(grep -0 -i /osp/a/idm/auth/app/logout?target $SSPR_APPLICATIONPATH/SSPRConfiguration.xml | wc -l)
  if [ $wc -ne 1 ]
  then
    return
  fi
  # Read SSPR logout url from SSPRConfiguration.xml
  cp $SSPR_APPLICATIONPATH/SSPRConfiguration.xml $IDM_TEMP/
  SSPR_LOGOUTURL=$(echo $(${XML_MOD} -r $IDM_TEMP/SSPRConfiguration.xml '/PwmConfiguration/settings/setting[@key="pwm.logoutURL"]/value/text()' | cut -d':' -f2- | cut -d' ' -f2- | cut -d']' -f1))


  # Add LOGOUTURL to whiteList 
  ${IDM_JRE_HOME}/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.XmlUtil "$SSPR_APPLICATIONPATH/SSPRConfiguration.xml" "/PwmConfiguration/settings/setting[@key=\"security.redirectUrl.whiteList\"]" "value" "${SSPR_LOGOUTURL}"
}

addSimpleTcpCluster()
{
	tcpentries=0
	tcpentries=$(grep SimpleTcpCluster ${IDM_TOMCAT_HOME}/conf/server.xml | wc -l)
	if [ $tcpentries -gt 1 ]
	then
		echo "skipping" &> /dev/null
	else
		result=`"/idm/common/bin/xmlmod" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service/Engine[1]" "/" << XMLOUT 
<Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster" channelSendOptions="8">
 <Manager className="org.apache.catalina.ha.session.DeltaManager" expireSessionsOnShutdown="false" notifyListenersOnReplication="true" />
 <Channel className="org.apache.catalina.tribes.group.GroupChannel">
   <Membership className="org.apache.catalina.tribes.membership.McastService" address="228.0.0.4" port="45564" frequency="500" dropTime="3000" />
   <Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver" address="auto" port="4000" autoBind="100" selectorTimeout="5000" maxThreads="6" />
   <Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">
	<Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender" />
   </Sender>
   <Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector" />
   <Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatchInterceptor" />
 </Channel>
 <Valve className="org.apache.catalina.ha.tcp.ReplicationValve" filter="" />
 <Valve className="org.apache.catalina.ha.session.JvmRouteBinderValve" />
 <Deployer className="org.apache.catalina.ha.deploy.FarmWarDeployer" tempDir="/tmp/war-temp/" deployDir="/tmp/war-deploy/" watchDir="/tmp/war-listen/" watchEnabled="false" />
 <ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener" />
</Cluster>
XMLOUT`
		write_log "XML_MOD Response : ${result}"
	fi
}

clusterenableviarestcall()
{
	if [ -f /config/userapp/restcallcompleted ]
	then
		return
	fi
	while [ true ]
	do
		#wait till the first instance is configured
		#/config/userapp is the first instance data layer
		grep -q "Done building the Entitlement CODE MAP tables" /config/userapp/tomcat/logs/catalina.out &> /dev/null
		if [ $? -ne 0 ]
		then
			sleep 10s
			continue
		else
			break
		fi
	done
	if [ ${CONF_HOME} == "/config/userapp" ] && [ ! -f /config/userapp/restcallcompleted ]
	then
		if [ -f /tmp/silent-*.properties ]
		then
			source /tmp/silent-*.properties
		fi
		if [ -f /commonfunctions-sub.sh ]
		then
			source /commonfunctions-sub.sh
		fi
		curl -k -X POST https://${IDM_ACCESS_VIA_SINGLE_DOMAIN}/IDMProv/rest/admin/cache/configuration -H 'Content-Type: application/json' -H 'Accept: application/json' --user ${UAADMIN_ATOMIC}:${UA_ADMIN_PWD} -d '{"permIndexClusterEnabled":true,"clusterEnabled":true,"groupID":"c373e901aba5e8ee9966444553544200","clusterProps":"UDP(mcast_addr=228.8.8.8;mcast_port=45654):PING:FD(timeout=10000;max_tries=5):VERIFY_SUSPECT:pbcast.NAKACK2:UNICAST3:pbcast.STABLE:FRAG:pbcast.GMS","permIndexGroupID":"com.netiq.idm.cis.perm.groupId","permIndexClusterProps":"UDP(mcast_addr=228.8.8.8;mcast_port=45655):PING:FD(timeout=10000;max_tries=5):VERIFY_SUSPECT:pbcast.NAKACK2:UNICAST3:pbcast.STABLE:FRAG:pbcast.GMS","lockAcquTimeout":"15000","evictionPolicyClass":"org.jboss.cache.eviction.LRUPolicy","wakeUpIntervalSeconds":"5","maxNodes":"10000","timeToLiveSeconds":"0","localClusterEnabled":"","localGroupID":"","localClusterProps":"","localLockAcquTimeout":"","localEvictionPolicyClass":"","localWakeUpIntervalSeconds":"","localMaxNodes":"","localTimeToLiveSeconds":"","lockAcquCurrentTimeout":"0","currentWakeUpInterval":"5000","currentEvictionPolicyClass":"","currentGroupID":"c373e901aba5e8ee9966444553544200","currentPermIndexGroupID":"com.netiq.idm.cis.perm.groupId","clusterCurrentProps":"UDP(mcast_addr=228.8.8.8;mcast_port=45654):PING:FD(timeout=10000;max_tries=5):VERIFY_SUSPECT:pbcast.NAKACK2:UNICAST3:pbcast.STABLE:FRAG:pbcast.GMS","clusterPermIndexCurrentProps":"com.netiq.idm.cis.perm.groupId","clusterEnabledCurrentValue":"false","permIndexClusterEnabledCurrentValue":"false","currentMaxNodes":"","currentTimeToLive":""}'
		curl -k -X POST https://${IDM_ACCESS_VIA_SINGLE_DOMAIN}/IDMProv/rest/admin/cache/configuration -H 'Content-Type: application/json' -H 'Accept: application/json' --user ${UAADMIN_ATOMIC}:${UA_ADMIN_PWD} -d '{"permIndexClusterEnabled":true,"clusterEnabled":true,"groupID":"c373e901aba5e8ee9966444553544200","clusterProps":"UDP(mcast_addr=228.8.8.8;mcast_port=45654):PING:FD(timeout=10000;max_tries=5):VERIFY_SUSPECT:pbcast.NAKACK2:UNICAST3:pbcast.STABLE:FRAG:pbcast.GMS","permIndexGroupID":"com.netiq.idm.cis.perm.groupId","permIndexClusterProps":"UDP(mcast_addr=228.8.8.8;mcast_port=45655):PING:FD(timeout=10000;max_tries=5):VERIFY_SUSPECT:pbcast.NAKACK2:UNICAST3:pbcast.STABLE:FRAG:pbcast.GMS","lockAcquTimeout":"15000","evictionPolicyClass":"org.jboss.cache.eviction.LRUPolicy","wakeUpIntervalSeconds":"5","maxNodes":"10000","timeToLiveSeconds":"0","localClusterEnabled":"","localGroupID":"","localClusterProps":"","localLockAcquTimeout":"","localEvictionPolicyClass":"","localWakeUpIntervalSeconds":"","localMaxNodes":"","localTimeToLiveSeconds":"","lockAcquCurrentTimeout":"0","currentWakeUpInterval":"5000","currentEvictionPolicyClass":"","currentGroupID":"c373e901aba5e8ee9966444553544200","currentPermIndexGroupID":"com.netiq.idm.cis.perm.groupId","clusterCurrentProps":"UDP(mcast_addr=228.8.8.8;mcast_port=45654):PING:FD(timeout=10000;max_tries=5):VERIFY_SUSPECT:pbcast.NAKACK2:UNICAST3:pbcast.STABLE:FRAG:pbcast.GMS","clusterPermIndexCurrentProps":"com.netiq.idm.cis.perm.groupId","clusterEnabledCurrentValue":"false","permIndexClusterEnabledCurrentValue":"false","currentMaxNodes":"","currentTimeToLive":""}'
		touch /config/userapp/restcallcompleted
	fi
}

removeworkflowengineid()
{
	if [ -f /tmp/silent-*.properties ]
	then
		source /tmp/silent-*.properties
	fi
	if [ -f /commonfunctions-sub.sh ]
	then
		source /commonfunctions-sub.sh
	fi
	if [ ! -z ${KUBERNETES_ORCHESTRATION} ] && [ "${KUBERNETES_ORCHESTRATION}" == "y" ]
	then
		sed -i "s#-Dcom.novell.afw.wf.engine-id=ENGINE ##g" /opt/netiq/idm/apps/tomcat/bin/setenv.sh
	fi
	return
	## Unreachable code below for new engine id
	if [ -z ${UA_WORKFLOW_ENGINE_ID} ]
	then
		return
	fi
	sed -i "s#engine-id=ENGINE #engine-id=${UA_WORKFLOW_ENGINE_ID} #g" /opt/netiq/idm/apps/tomcat/bin/setenv.sh
}

