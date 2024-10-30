#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../

. ../common/scripts/common_install_vars.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/multi_select.sh
. ../common/scripts/jre.sh
. ../common/scripts/tomcat.sh
. ../common/scripts/postgres.sh
. ../common/scripts/activemq.sh
. ../common/scripts/config_utils.sh


create_osp_keystore() {

  str=`gettext install "Creating OSP Keystore."`
  write_and_log "$str "
  
   LC_ALL=en_US ${IDM_JRE_HOME}/bin/keytool -genkey -keyalg RSA -keysize 2048 -keystore ${OSP_INSTALL_PATH}/osp.jks -storetype pkcs12 -storepass ${OSP_KEYSTORE_PWD} -keypass ${OSP_KEYSTORE_PWD} -alias osp -validity 730 -dname "cn=${ID_VAULT_HOST}" >> $LOG_FILE_NAME 2>&1
 
}

modify_server_xml()
{
     
	disp_str=`gettext install "Modifying Tomcat server.xml"`
	echo_sameline "$disp_str"

    #echo "${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "$TOMCAT_HTTP_PORT"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "$OSP_TOMCAT_HTTP_PORT"` >> $LOG_FILE_NAME 2>&1
    write_log "XML_MOD Response : ${result}"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8443']/@port" "$SSO_SERVER_SSL_PORT"` >> $LOG_FILE_NAME 2>&1
    write_log "XML_MOD Response : ${result}"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8009']/@port" "8109"` >> $LOG_FILE_NAME 2>&1
    write_log "XML_MOD Response : ${result}"
	keystorePassToCustom_OSP
    setTLSv12_OSP
}

get_osp_host_port()
{
    local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
    local OSPURL=`grep -ir "com.netiq.idm.osp.url.host =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`

    if [ -z "${OSPURL}" ]
    then
      OSPURL=`grep -ir "DirectoryService/realms/jndi/params/AUTHORITY" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    fi

    PROTO="`echo $OSPURL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
    URL=`echo $OSPURL | sed -e s,$PROTO,,g`
    SSO_SERVER_HOST="$(echo $URL | grep : | cut -d: -f1)"
    if [ -z ${SSO_SERVER_HOST} ]
    then
      SSO_SERVER_HOST="$(echo $URL | grep / | cut -d/ -f1)"
      if [ -z ${SSO_SERVER_HOST} ]
      then
        SSO_SERVER_HOST=$URL
      fi
      SSO_SERVER_SSL_PORT=
    else
      SSO_SERVER_SSL_PORT=$(echo $URL | sed -e s,$SSO_SERVER_HOST:,,g | cut -d/ -f1)
    fi
}

###
#
###
configure_props() {
if [ ! -z "$debug" ] && [ "$debug" = 'y' ]
then
	set -x
fi
        
   str2=`gettext install "Configuring OSP."`
   write_and_log "$str2 "
   local prop_file=${IDM_TEMP}/osp_init.properties
   
   if [ ! -d "${IDM_TEMP}" ]
   then
       mkdir "${IDM_TEMP}" >>$LOG_FILE_NAME
   fi

   if [ $IS_UPGRADE -eq 1 ]
   then
     get_osp_host_port
     local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
     idmjkspass=`grep -ir "com.netiq.idm.ua.ldap.keystore-pwd._attr_obscurity =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
     if [ ! -z "$idmjkspass" ] && [ "$idmjkspass" == "ENCRYPT" ]
     then
       encryptedidmjkspass=`grep -ir "com.netiq.idm.ua.ldap.keystore-pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
       decryptedidmjkspass=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt $encryptedidmjkspass`
     elif [ ! -z "$idmjkspass" ] && [ "$idmjkspass" == "NONE" ]
     then
       decryptedidmjkspass=`grep -ir "com.netiq.idm.ua.ldap.keystore-pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
     fi
     echo "${PROTO}" | grep -qw "https://"
     RET=$?
     if [ $RET -eq 0 ]
     then
       cp ${IDM_INSTALL_HOME}osp/conf/osp_init.properties ${prop_file} >>$LOG_FILE_NAME
       search_and_replace "___IDM_KEYSTORE_PWD___"  "$decryptedidmjkspass" "$prop_file"
       search_and_replace "___ID_VAULT_ADMIN_LDAP___"  "$ID_VAULT_ADMIN_LDAP" "$prop_file"
       search_and_replace "___ID_VAULT_PASSWORD___"  "$ID_VAULT_PASSWORD" "$prop_file"
       search_and_replace "___ID_VAULT_HOST___"  "$ID_VAULT_HOST" "$prop_file"
	   search_and_replace "___ID_VAULT_LDAPS_PORT___"  "$ID_VAULT_LDAPS_PORT" "$prop_file"
       search_and_replace "___USER_CONTAINER___"  "$USER_CONTAINER" "$prop_file"
       search_and_replace "___ADMIN_CONTAINER___"  "$ADMIN_CONTAINER" "$prop_file"
       search_and_replace "___OSP_KEYSTORE_PWD___"  "$OSP_KEYSTORE_PWD" "$prop_file"
       search_and_replace "___TOMCAT_SERVLET_HOSTNAME___"  "$SSO_SERVER_HOST" "$prop_file"
       search_and_replace "___SSO_SERVER_HOST___"  "$SSO_SERVER_HOST" "$prop_file"
       search_and_replace "___TOMCAT_SSL_PWD___"  "$TOMCAT_SSL_KEYSTORE_PASS" "$prop_file"
       search_and_replace "___TOMCAT_HOME_PATH___" "$IDM_TOMCAT_HOME" "$prop_file"
       if [ ! -z "$SSO_SERVER_SSL_PORT" ] && [ "$SSO_SERVER_SSL_PORT" != "" ]
       then
         search_and_replace "___TOMCAT_HTTPS_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace "___SSO_SERVER_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace "___SSO_SERVER_SSL_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
       else
         search_and_replace ":___TOMCAT_HTTPS_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace ":___SSO_SERVER_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace ":___SSO_SERVER_SSL_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
       fi
       search_and_replace "___FR_SERVER_HOST___"  "$FR_SERVER_HOST" "$prop_file"
       search_and_replace "___NGINX_HTTPS_PORT___"  "$NGINX_HTTPS_PORT" "$prop_file"
       search_and_replace "___SSO_SERVICE_PWD___"  "$SSO_SERVICE_PWD" "$prop_file"
       grep -qs "com.netiq.idm.osp.oauth-keystore.type" /opt/netiq/idm/apps/osp/conf/global.properties | grep -iq pkcs
       if [ $? -ne 0 ]
       then
         sed -i "/com.netiq.idm.osp.oauth-keystore.type/d" ${prop_file}
	 echo $(grep -qs "com.netiq.idm.osp.oauth-keystore.type" /opt/netiq/idm/apps/osp/conf/global.properties) >> ${prop_file}
       fi
     else 
       cp ${IDM_INSTALL_HOME}osp/conf/osp_up_init.properties ${prop_file} >>$LOG_FILE_NAME
       search_and_replace "___ID_VAULT_ADMIN_LDAP___"  "$ID_VAULT_ADMIN_LDAP" "$prop_file"
       search_and_replace "___ID_VAULT_PASSWORD___"  "$ID_VAULT_PASSWORD" "$prop_file"
       search_and_replace "___ID_VAULT_HOST___"  "$ID_VAULT_HOST" "$prop_file"
	   search_and_replace "___ID_VAULT_LDAPS_PORT___"  "$ID_VAULT_LDAPS_PORT" "$prop_file"
       search_and_replace "___USER_CONTAINER___"  "$USER_CONTAINER" "$prop_file"
       search_and_replace "___ADMIN_CONTAINER___"  "$ADMIN_CONTAINER" "$prop_file"
       search_and_replace "___OSP_KEYSTORE_PWD___"  "$OSP_KEYSTORE_PWD" "$prop_file"
       search_and_replace "___TOMCAT_SERVLET_HOSTNAME___"  "$SSO_SERVER_HOST" "$prop_file"
       if [ ! -z "$TOMCAT_HTTP_PORT" ] && [ "$TOMCAT_HTTP_PORT" != "" ]
       then
         search_and_replace "___TOMCAT_HTTP_PORT___" "$TOMCAT_HTTP_PORT"  "$prop_file"
       else
         search_and_replace ":___TOMCAT_HTTP_PORT___" "$TOMCAT_HTTP_PORT"  "$prop_file"
       fi
       search_and_replace "___SSO_SERVER_HOST___"  "$SSO_SERVER_HOST" "$prop_file"
       if [ ! -z "$SSO_SERVER_PORT" ] && [ "$SSO_SERVER_PORT" != "" ]
       then
         search_and_replace "___SSO_SERVER_PORT___" "$SSO_SERVER_PORT" "$prop_file"
       else
         search_and_replace ":___SSO_SERVER_PORT___" "$SSO_SERVER_PORT" "$prop_file"
       fi
       search_and_replace "___FR_SERVER_HOST___"  "$FR_SERVER_HOST" "$prop_file"
       search_and_replace "___NGINX_HTTPS_PORT___"  "$NGINX_HTTPS_PORT" "$prop_file"
       search_and_replace "___SSO_SERVICE_PWD___"  "$SSO_SERVICE_PWD" "$prop_file"
    fi
  fi

   if [ $IS_UPGRADE -ne 1 ]
   then
       ua_driver_driverset_dn="cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}"
       cp ${IDM_INSTALL_HOME}osp/conf/osp_init.properties ${prop_file} >>$LOG_FILE_NAME
       search_and_replace "___ID_VAULT_ADMIN_LDAP___"  "$ID_VAULT_ADMIN_LDAP" "$prop_file"
       search_and_replace "___ID_VAULT_PASSWORD___"  "$ID_VAULT_PASSWORD" "$prop_file"
       search_and_replace "___ID_VAULT_HOST___"  "$ID_VAULT_HOST" "$prop_file"
	   search_and_replace "___ID_VAULT_LDAPS_PORT___"  "$ID_VAULT_LDAPS_PORT" "$prop_file"
       search_and_replace "___USER_CONTAINER___"  "$USER_CONTAINER" "$prop_file"
       search_and_replace "___ADMIN_CONTAINER___"  "$ADMIN_CONTAINER" "$prop_file"
       search_and_replace "___OSP_KEYSTORE_PWD___"  "$OSP_KEYSTORE_PWD" "$prop_file"
       search_and_replace "___TOMCAT_SERVLET_HOSTNAME___"  "$SSO_SERVER_HOST" "$prop_file"
       search_and_replace "___SSO_SERVER_HOST___"  "$SSO_SERVER_HOST" "$prop_file"
       search_and_replace "___TOMCAT_SSL_PWD___"  "$OSP_COMM_TOMCAT_KEYSTORE_PWD" "$prop_file"
       search_and_replace "___TOMCAT_HOME_PATH___" "$IDM_TOMCAT_HOME" "$prop_file"
       if [ ! -z "$SSO_SERVER_SSL_PORT" ] && [ "$SSO_SERVER_SSL_PORT" != "" ]
       then
         search_and_replace "___TOMCAT_HTTPS_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace "___SSO_SERVER_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace "___SSO_SERVER_SSL_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
       else
         search_and_replace ":___TOMCAT_HTTPS_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace ":___SSO_SERVER_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
         search_and_replace ":___SSO_SERVER_SSL_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
       fi
       search_and_replace "__OSP_COMM_TOMCAT_KEYSTORE_FILE__" "$OSP_COMM_TOMCAT_KEYSTORE_FILE" "$prop_file"
       search_and_replace "___UA_IP___"  "$UA_SERVER_HOST" "$prop_file"
       search_and_replace "___SSPR_IP___"  "$SSPR_SERVER_HOST" "$prop_file"
       search_and_replace "___DRIVERSET_NAME___"  "${ua_driver_driverset_dn}" "$prop_file"
       search_and_replace "___UA_DRIVER_NAME___"  "${UA_DRIVER_NAME}" "$prop_file"
       search_and_replace "___SSO_SERVICE_PWD___"  "$SSO_SERVICE_PWD" "$prop_file"
       search_and_replace "___RPT_IP___"  "$RPT_SERVER_HOSTNAME" "$prop_file"
       if [ ! -z "$RPT_TOMCAT_HTTPS_PORT" ] && [ "$RPT_TOMCAT_HTTPS_PORT" != "" ]
       then
         search_and_replace "___RPT_TOMCAT_HTTPS_PORT___"  "$RPT_TOMCAT_HTTPS_PORT" "$prop_file"
       else
         search_and_replace ":___RPT_TOMCAT_HTTPS_PORT___"  "$RPT_TOMCAT_HTTPS_PORT" "$prop_file"
       fi
       if [ ! -z "$UA_SERVER_SSL_PORT" ] && [ "$UA_SERVER_SSL_PORT" != "" ]
       then
         search_and_replace "___UA_TOMCAT_HTTPS_PORT___"  "$UA_SERVER_SSL_PORT" "$prop_file"
       else
         search_and_replace ":___UA_TOMCAT_HTTPS_PORT___"  "$UA_SERVER_SSL_PORT" "$prop_file"
       fi
       if [ ! -z "$SSPR_SERVER_SSL_PORT" ] && [ "$SSPR_SERVER_SSL_PORT" != "" ]
       then
         search_and_replace "___SSPR_TOMCAT_HTTPS_PORT___"  "$SSPR_SERVER_SSL_PORT" "$prop_file"
       else
         search_and_replace ":___SSPR_TOMCAT_HTTPS_PORT___"  "$SSPR_SERVER_SSL_PORT" "$prop_file"
       fi
       search_and_replace "___IDM_KEYSTORE_PWD___"  "$IDM_KEYSTORE_PWD" "$prop_file"
       search_and_replace "___FR_SERVER_HOST___"  "$FR_SERVER_HOST" "$prop_file"
       search_and_replace "___NGINX_HTTPS_PORT___"  "$NGINX_HTTPS_PORT" "$prop_file"
       configupdate_idm
       update_configupdate_script
       if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
       then
         update_osp_config_properties
       fi
   fi

   files=($IDM_OSP_HOME/conf/GLOBAL-*)
   if [ -e "${files[0]}" ]
   then
       rm $IDM_OSP_HOME/conf/GLOBAL-* >>$LOG_FILE_NAME  2>&1
   fi
   sh ${IDM_INSTALL_HOME}osp/conf/configinit.sh ${prop_file}  >>$LOG_FILE_NAME 2>&1
#Do an error check here
   
   cat  $IDM_OSP_HOME/conf/GLOBAL-* > /opt/netiq/idm/apps/osp/conf/global.properties 
   grep -q com.netiq.idm.osp.token.init.cache.size ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
   firstkey=$?
   grep -q com.netiq.idm.osp.oauth.txn ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
   secondkey=$?
   keyupdate=false
   if [ $firstkey -ne 0 ] && [ $secondkey -ne 0 ]
   then
   	keyupdate=true
   fi
   if [ $IS_UPGRADE -eq 1 ] && [ "$keyupdate" == "true" ]
   then
	echo "com.netiq.idm.osp.token.init.cache.size = 1000" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.token.max.cache.size = 16000" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.dn = name" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.first.name = first_name" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.last.name = last_name" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.initials = initials" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.email = email" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.language = language" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.cacheable = cacheable" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.expiration = expiration" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.auth.src.id = auth_src_id" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.client = client" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.txn = txn" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.access-token-format.format = jwt" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	echo "com.netiq.idm.osp.oauth.attr.roles.maxValues =1" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
   fi
   if [ ! -z "$EDIRAPI_PROMPT_NEEDED" ] && [ "$EDIRAPI_PROMPT_NEEDED" == "y" ]
   then
     echo "com.netiq.edirapi.clientID = identityconsole" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
     echo "com.netiq.edirapi.redirect.url = https://${IDCONSOLE_HOST}:${IDCONSOLE_PORT}/eDirAPI/v1/${EDIRAPI_TREENAME}/authcoderedirect" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
     echo "com.netiq.edirapi.response-types = code,token" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
     encryptclientpass "com.netiq.edirapi.clientPass"
   fi
   ${IDM_JRE_HOME}/bin/java -Dlog4j.configuration=file:${IDM_OSP_HOME}/conf/log4j-config.xml -Dcom.netiq.ism.config=${ISM_CONFIG} -jar ${IDM_OSP_HOME}/lib/netiq-configutil.jar -script ${IDM_INSTALL_HOME}/osp/conf/import-configs.script >>$LOG_FILE_NAME  2>&1
   if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == 'y' ]
   then
   	cp ${prop_file} /tmp
	[ -f /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties ] && cp /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties /tmp/ism-configuration.properties.OSP
   fi

}

###
# Configure the tomcat/bin/setenv.sh file.
###

configure_setenv() {
 
 str=`gettext install "Updating OSP command line configurations in tomcat setenv file"`
 write_and_log "$str"
 
 #cp ${IDM_INSTALL_HOME}osp/tomcat/bin/setenv.sh $IDM_TEMP/
 #local prop_file=$IDM_TEMP/setenv.sh
 
 #sed -i "s/__IDM_JRE_HOME__/${IDM_JRE_HOME//\//\\/}/g" $prop_file
 #sed -i "s/__CATALINA_BASE__/${IDM_TOMCAT_HOME//\//\\/}/g" $prop_file
 #sed -i "s/__CONFIG_OSP_JAR__/${CONFIG_OSP_JAR//\//\\/}/g" $prop_file
 #sed -i "s/__ISM_CONFIG__/${ISM_CONFIG//\//\\/}/g" $prop_file
 #sed -i "s/__OSP_INSTALL_PATH__/${OSP_INSTALL_PATH//\//\\/}/g" $prop_file
 #sed -i "s/__SERVLET_HOSTNAME__/${SERVLET_HOSTNAME//\//\\/}/g" $prop_file
 # Temp fix. Need to fix this in osp's setevn script 
 #sed -i "s/___TOMCAT_SERVLET_HOSTNAME___/${TOMCAT_SERVLET_HOSTNAME//\//\\/}/g" $prop_file

 #cp $IDM_TEMP/setenv.sh ${IDM_TOMCAT_HOME}/bin
 
 # Temp fix. Need to fix this in osp's setenv script 
 local prop_file=${IDM_TOMCAT_HOME}/bin/setenv.sh
 if [ $IS_UPGRADE -ne 1 ]
 then
    search_and_replace "___TOMCAT_SERVLET_HOSTNAME___"  "$SSO_SERVER_HOST" "$prop_file"
 else
    search_and_replace "___TOMCAT_SERVLET_HOSTNAME___"  "$SSO_SERVER_HOST" "$prop_file"
 fi
 
}


###
# Configure the configupdate.sh.properties file.
###
update_configupdate_script() {
  
  cp ${IDM_INSTALL_HOME}osp/conf/configupdate.sh.properties ${OSP_INSTALL_PATH}/bin/
  # TODO Creating this file as workaround, but have to be fixed
  touch ${CONFIG_UPDATE_HOME}/framework-config_3_0.dtd

  local configupdate_prop_file=${OSP_INSTALL_PATH}/../configupdate/configupdate.sh.properties
  sed -i "s~\$NOVL_JAVA_HOME\$~${IDM_JRE_HOME}~g" $configupdate_prop_file
  sed -i "s~\$NOVL_TOMCAT_BASE_FOLDER\$~${IDM_TOMCAT_HOME}~g" $configupdate_prop_file
  sed -i "s~\$USER_INSTALL_DIR\$~${OSP_INSTALL_PATH}~g" $configupdate_prop_file
  if [ -z "$INSTALL_LANGUAGE" ]
  then
        INSTALL_LANGUAGE="en"
  fi
  sed -i "s/\$NOVL_USER_LANGUAGE\$/${INSTALL_LANGUAGE}/g" $configupdate_prop_file
  sed -i "s/\$NOVL_USER_COUNTRY\$/${INSTALL_COUNTRY}/g" $configupdate_prop_file
  if [ ! -z "${INSTALL_UA}" ] && [ "${INSTALL_UA}" == "false" ]
  then  	
	sed -i "s/edition=advanced/edition=standard/g" $configupdate_prop_file
    sed -i "s/sso_apps=ua,rpt/sso_apps=rpt/g" $configupdate_prop_file	
  fi
  sed -i "s#OSP_INSTALL_DIR#${OSP_INSTALL_PATH}#g" $configupdate_prop_file
}

update_osp_config_properties()
{
    local prop_file=${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    search_and_replace "\$NOVL_JAVA_HOME\$"  "$IDM_JRE_HOME" "$prop_file"
    search_and_replace "\$NOVL_APPLICATION_NAME\$"  "$UA_APP_CTX" "$prop_file"
    search_and_replace "\$NOVL_TOMCAT_BASE_FOLDER\$"  "$IDM_TOMCAT_HOME" "$prop_file"
    search_and_replace "\$USER_INSTALL_DIR\$"  "$IDM_OSP_HOME" "$prop_file"
    #TODO: Pick lang from locale
    search_and_replace "\$USER_LANG\$"  "en" "$prop_file"
    search_and_replace "\$NOVL_USER_LANGUAGE\$"  "en" "$prop_file"
    search_and_replace "\$NOVL_USER_COUNTRY\$"  "-" "$prop_file"
    search_and_replace "\$NOVL_UA_CONFIG_FILE_NAME\$"  "ism-configuration.properties" "$prop_file"
    if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
    then
      search_and_replace "\$NOVL_CONFIGUPDATE_USE_CONSOLE_FLAG\$"  "true" "$prop_file"
    else
      search_and_replace "\$NOVL_CONFIGUPDATE_USE_CONSOLE_FLAG\$"  "false" "$prop_file"
    fi
    search_and_replace "\$DOLLAR\$"  "\$" "$prop_file"
    search_and_replace "\$NOVL_UA_EDIT_ADMIN_FLAG\$"  "false" "$prop_file"
    search_and_replace "\$USER_INSTALL_DIR\$"  "$CONFIG_UPDATE_HOME" "$prop_file"
    sed -i "/CONTEXT_NAME/d" $prop_file
    sed -i "/extFile/d" $prop_file
}
