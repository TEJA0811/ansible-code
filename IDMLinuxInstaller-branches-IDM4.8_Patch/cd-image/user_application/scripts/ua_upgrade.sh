#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

stopallservices()
{
  tomcat_service_file="/etc/init.d/idmapps_tomcat_init"
  activemq_service_file="/etc/init.d/idmapps_activemq_init"

    disp_str=`gettext install "Stopping tomcat"`
    write_and_log "$disp_str"
  if [ -e $tomcat_service_file ]
  then
    $tomcat_service_file stop >> "${LOG_FILE_NAME}" 2>&1
  else
  	systemctl stop netiq-tomcat >> "${LOG_FILE_NAME}" 2>&1
  fi
 
    disp_str=`gettext install "Stopping ActiveMQ"`
    write_and_log "$disp_str"
  if [ -e $activemq_service_file ]
  then
    $activemq_service_file stop >> "${LOG_FILE_NAME}" 2>&1
  else
  	systemctl stop netiq-activemq >> "${LOG_FILE_NAME}" 2>&1
  fi
  disp_str=`gettext install "Stopping nginx"`
  if [ -f /opt/netiq/common/nginx/nginx ]
  then
  	write_and_log "$disp_str"
  	service netiq-nginx reload &> /dev/null
  	systemctl stop netiq-nginx &> /dev/null
	killall -9 --user novlua nginx &> /dev/null
  	systemctl stop netiq-nginx &> /dev/null
  	service netiq-nginx reload &> /dev/null
  	systemctl enable netiq-nginx &> /dev/null
  	systemctl enable netiq-tomcat &> /dev/null
  fi
}

userappbackup()
{
  disp_str=`gettext install "Starting the User Application backup process..."`
  write_and_log "$disp_str"  
  
  disp_str=`gettext install "Backing up tomcat files"`
  write_and_log "$disp_str"
  tomcatfilesbackup

  disp_str=`gettext install "Backing up the ActiveMQ files"`
  write_and_log "$disp_str"
  activemqfilesbackup
 
  if [ ! -z $SSPR_INSTALLED_FOLDER_PATH ]
  then
   disp_str=`gettext install "Backing up the SSPR files"`
   write_and_log "$disp_str"
   ssprfilesbackup
  fi
  #If osp exist then only we have to take backup
  if [ "${IS_OSP_EXIST}" == "true" ]
  then
   disp_str=`gettext install "Backing up OAuth files"`
   write_and_log "$disp_str"
   ospfilesbackup
  fi

  disp_str=`gettext install "Backing up the User Application files"`
  write_and_log "$disp_str"
  uafilesbackup
  
  if [ -e ${UA_JRE_HOME_PATH}/lib/security/cacerts ]
  then
    disp_str=`gettext install "Backing up jre cacerts file"`
    write_and_log "$disp_str"
    mkdir -p ${IDM_BACKUP_FOLDER}/jre/
    cp -pf ${UA_JRE_HOME_PATH}/lib/security/cacerts ${IDM_BACKUP_FOLDER}/jre/
  fi

  disp_str=`gettext install "User Application backup is complete."`
  write_and_log "$disp_str"
}

tomcatfilesbackup()
{
 if [ -f ${INSTALLED_FOLDER_PATH}/tomcat/conf/ism-configuration.properties ]
 then
   cp -rpf ${INSTALLED_FOLDER_PATH}/tomcat/conf/ism-configuration.properties ${IDM_BACKUP_FOLDER}/
 fi
 #
 if [ -d ${INSTALLED_FOLDER_PATH}/tomcat/ ]
 then
    cp -rpf ${INSTALLED_FOLDER_PATH}/tomcat/ ${IDM_BACKUP_FOLDER}/
 fi
 if [ -d ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/ ]
 then 
    cp -rpf ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/ ${IDM_BACKUP_FOLDER}/
 fi
 if [ -d ${INSTALLED_FOLDER_PATH}/tomcat/webapps ]
 then
    rm -rf ${INSTALLED_FOLDER_PATH}/tomcat/webapps/*
 fi
 if [ $IS_RPT_UPGRADED -eq 0 ]
 then
     #if [ -d ${INSTALLED_FOLDER_PATH}/tomcat/ ]
     #then
     #   rm -rf ${INSTALLED_FOLDER_PATH}/tomcat/
     #fi
     if [ -d ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/ ]
     then
        rm -rf ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/
     fi
 fi
}

activemqfilesbackup()
{
 if [ -d ${INSTALLED_FOLDER_PATH}/../activemq/ ]
 then
    cp -rpf ${INSTALLED_FOLDER_PATH}/../activemq/ ${IDM_BACKUP_FOLDER}/
    #rm -rf ${INSTALLED_FOLDER_PATH}/../activemq/
 fi
}

ssprfilesbackup()
{
 if [ -d ${EXISTING_SSPR_INSTALLED_PATH} ] && [ ! -z "$BLOCKED_CODE" ]
 then
   if [ -f ${EXISTING_SSPR_INSTALLED_PATH}/SSPRConfiguration.xml ]
   then 
     cp -rpf ${EXISTING_SSPR_INSTALLED_PATH}/SSPRConfiguration.xml ${IDM_BACKUP_FOLDER}/
   fi

   if [ -d ${EXISTING_SSPR_INSTALLED_PATH}/LocalDB ]
   then
     cp -rpf ${EXISTING_SSPR_INSTALLED_PATH}/LocalDB ${IDM_BACKUP_FOLDER}/
   fi
 fi
 
 if [ -d ${SSPR_INSTALLED_FOLDER_PATH} ]
 then 
    cp -rpf ${SSPR_INSTALLED_FOLDER_PATH} ${IDM_BACKUP_FOLDER}/
    #rm -rf ${SSPR_INSTALLED_FOLDER_PATH}
 fi
}

ospfilesbackup()
{
 if [ -d ${OSP_INSTALLED_FOLDER_PATH} ]
 then
    cp -rpf ${OSP_INSTALLED_FOLDER_PATH} ${IDM_BACKUP_FOLDER}/
    if [ $IS_RPT_UPGRADED -eq 0 ]
    then 
        rm -rf ${OSP_INSTALLED_FOLDER_PATH}
    else
        #restore war back into webapps as it is cleaned up during tomcat backup process
        cp -p ${IDM_BACKUP_FOLDER}/tomcat/webapps/osp.war ${INSTALLED_FOLDER_PATH}/tomcat/webapps/
    fi
 elif [ -d ${INSTALLED_FOLDER_PATH}/osp_sspr/ ]
 then
  cp -rpf ${INSTALLED_FOLDER_PATH}/osp_sspr/ ${IDM_BACKUP_FOLDER}/
  rm -rf ${INSTALLED_FOLDER_PATH}/osp_sspr/
 fi
}


uafilesbackup()
{
 sitesDir=$(readlink -m ${UA_INSTALLED_FOLDER_PATH}/../sites)
 if [ -d ${UA_INSTALLED_FOLDER_PATH} ]
 then
    cp -rpf ${UA_INSTALLED_FOLDER_PATH} ${IDM_BACKUP_FOLDER}/ 
    cp -rpf ${CONFIG_UPDATE_HOME}/configupdate.sh.properties ${IDM_BACKUP_FOLDER}/ 
    rm -rf ${UA_INSTALLED_FOLDER_PATH}
 fi
 if [ -d ${sitesDir} ]
 then
    cp -rpf ${sitesDir} ${IDM_BACKUP_FOLDER}/ 
 fi
 if [ -d /opt/netiq/common/nginx ]
 then
    cp -rpf /opt/netiq/common/nginx ${IDM_BACKUP_FOLDER}/
 fi

 if [ -d ${INSTALLED_FOLDER_PATH}/Uninstall_Identity\ Manager\ Components/ ]
 then 
   cp -rpf ${INSTALLED_FOLDER_PATH}/Uninstall_Identity\ Manager\ Components/ ${IDM_BACKUP_FOLDER}/
   rm -rf ${INSTALLED_FOLDER_PATH}/Uninstall_Identity\ Manager\ Components/
 fi
}

update_tomcat_conf()
{
  if [ -f ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml ]
  then
    [ $IS_UPGRADE -eq 1 ] && return
    sed '/IDMUADataSource/d' ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml  > ${IDM_TOMCAT_HOME}/conf/server_mod.xml
    sed '/ConnectionFactory/d' ${IDM_TOMCAT_HOME}/conf/server_mod.xml  > ${IDM_TOMCAT_HOME}/conf/server_1.xml
    sed '/IDMNotificationDurableTopic/d' ${IDM_TOMCAT_HOME}/conf/server_1.xml  > ${IDM_TOMCAT_HOME}/conf/server_mod.xml
    cp -p ${IDM_TOMCAT_HOME}/conf/server.xml ${IDM_TOMCAT_HOME}/conf/server_org.xml
    mv ${IDM_TOMCAT_HOME}/conf/server_mod.xml ${IDM_TOMCAT_HOME}/conf/server.xml
    rm ${IDM_TOMCAT_HOME}/conf/server_1.xml
 fi
}
		   
readconfigpropertiesfordbconn()
{
  $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ReadConfigurations ${INSTALLED_FOLDER_PATH} /opt/uacon_upgrade.properties >> ${LOG_FILE_NAME}  
}
  
readconfigproperties()
{
  $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ReadConfigurations ${IDM_BACKUP_FOLDER} /opt/ua_upgrade.properties >> ${LOG_FILE_NAME}  

  local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
  local silent_prop_file=/opt/ua_upgrade.properties
  
  local UAURL=`grep -ir "com.netiq.rbpm.redirect.url =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`

  local PROTO="`echo $UAURL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
  local URL=`echo $UAURL | sed -e s,$PROTO,,g`
  local UA_SERVER_HOSTNAME="$(echo $URL | grep : | cut -d: -f1)"
  if [ -z ${UA_SERVER_HOSTNAME} ]
  then
    local UA_SERVER_HOSTNAME="$(echo $URL | grep / | cut -d/ -f1)"
    if [ -z ${UA_SERVER_HOSTNAME} ]
    then
      UA_SERVER_HOSTNAME=$URL
    fi
    local UA_SERVER_PORT=
  else
    local UA_SERVER_PORT=$(echo $URL | sed -e s,$UA_SERVER_HOSTNAME:,,g | cut -d/ -f1)
  fi

  echo TOMCAT_SERVLET_HOSTNAME=${UA_SERVER_HOSTNAME} >> ${silent_prop_file}
  #
  local osp_keystore_passwrd=`grep -ir "com.netiq.idm.osp.oauth-keystore.pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
  echo -e "\n#############" >> ${silent_prop_file}
  echo OSP_KEYSTORE_PWD=\"`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt ${osp_keystore_passwrd}`\" >> ${silent_prop_file} 
  #
  local idm_keystore_passwrd=`grep -ir "com.netiq.idm.ua.ldap.keystore-pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`  
  echo IDM_KEYSTORE_PWD=\"`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt ${idm_keystore_passwrd}`\" >> ${silent_prop_file}

  local idvalut_passwrd=`grep -ir "com.netiq.idm.osp.ldap.admin-pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
  if [ -z ${idvalut_passwrd} ]
  then
    idvalut_passwrd=`grep -ir "com.novell.idm.ldap.admin.pass =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
  fi
  echo ID_VAULT_PASSWORD=\"`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt ${idvalut_passwrd}`\" >> ${silent_prop_file}
  
  echo ADMIN_CONTAINER=`grep -ir "com.netiq.idm.osp.as.admins-container-dn" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}

  local idvaluthost=`grep -ir "com.netiq.idm.osp.ldap.host" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
  local ID_VAULT_HOST=
  if [ ! -z ${idvaluthost} ]
  then
     echo ID_VAULT_HOST=${idvaluthost} >> ${silent_prop_file}
  else
    idvaluthost=`grep -ir "DirectoryService/realms/jndi/params/AUTHORITY" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    echo ID_VAULT_HOST=${idvaluthost} >> ${silent_prop_file}
  fi
 
  local usercontainerDN=`grep -ir "com.netiq.idm.osp.as.users-container-dn" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
  if [ ! -z ${usercontainerDN} ]
  then
     echo USER_CONTAINER=${usercontainerDN} >> ${silent_prop_file}
  else
     usercontainerDN=`grep -ir "DirectoryService/realms/jndi/params/USER_ROOT_CONTAINER" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
     echo USER_CONTAINER=${usercontainerDN} >> ${silent_prop_file}
  fi
  
  ID_VAULT_ADMIN_LDAP=`echo $(awk -F'com.novell.idm.ldap.admin.user' '{print $2}' ${backup_ism_file} | cut -d"=" -f2- | sed '/^$/d')`

  echo ID_VAULT_ADMIN_LDAP=\"${ID_VAULT_ADMIN_LDAP}\" >> ${silent_prop_file}
  echo ID_VAULT_LDAPS_PORT=`grep -ir "DirectoryService/realms/jndi/params/SECURE_PORT" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
  echo ID_VAULT_LDAP_PORT=`grep -ir "DirectoryService/realms/jndi/params/PLAIN_PORT" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
  echo ID_VAULT_DRIVER_SET=\"`echo $(awk -F'DirectoryService/realms/jndi/params/PROVISION_ROOT' '{print $2}' ${backup_ism_file} | cut -d"=" -f2- | sed '/^$/d')`\" >> ${silent_prop_file}
 
  local installed_keystore_path=`grep -ir "DirectoryService/realms/jndi/params/KEYSTORE_PATH" ${backup_ism_file} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//'`
  local installed_osp_keystore_path=`grep -ir "com.netiq.idm.osp.oauth-keystore.file =" ${backup_ism_file} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//'`
  local installed_osp_ssl_keystore_path=`grep -ir "com.netiq.idm.osp.ssl-keystore.file =" ${backup_ism_file} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//'`
  #
  if [ -n "${installed_keystore_path}" ]
  then
      sed -i "s#$installed_keystore_path#$IDM_KEYSTORE_PATH#g" "${IDM_BACKUP_FOLDER}/ism-configuration.properties"
  fi
   
  get_ua_osp_host_port

  if [ -n "${installed_osp_ssl_keystore_path}" ] && [ "${PROTO}" == "http://" ] && [ -f ${IDM_BACKUP_FOLDER}/tomcat/webapps/osp.war ]
  then
      sed -i "s#com.netiq.idm.osp.ssl-keystore.file = ${installed_osp_ssl_keystore_path}#com.netiq.idm.osp.ssl-keystore.file = ${OSP_INSTALL_PATH}/osp.jks#g" "${IDM_BACKUP_FOLDER}/ism-configuration.properties"
  fi

  #Added for Users list VLV and NON-VLV
  echo "com.microfocus.idm.enable.vlv = true" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  echo "com.microfocus.idm.enable.vlv.count = true" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  echo "com.microfocus.idm.max.users.count.limit = 1000" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties

  if [ -n ${installed_osp_keystore_path} ] && [[ ${installed_osp_keystore_path} == *"/osp.jks"* ]]
  then
     sed -i "s#com.netiq.idm.osp.oauth-keystore.file = ${installed_osp_keystore_path}#com.netiq.idm.osp.oauth-keystore.file = ${OSP_INSTALL_PATH}/osp.jks#g" "${IDM_BACKUP_FOLDER}/ism-configuration.properties"
  fi
  #port=`echo $UAURL | awk -F ':' '{print $3}' | cut -d '/' -f 1`
  #if [ "${PROTO}" == "http://" ]
  #then
  #  echo "TOMCAT_HTTP_PORT=${port}" >> ${silent_prop_file}
  #else
  #  echo "TOMCAT_HTTPS_PORT=${port}" >> ${silent_prop_file}
  #fi
 
  echo "com.netiq.idm.ua.sso-configuration = auto" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  
  echo "com.netiq.idm.osp.ldap.admin-dn = ${ID_VAULT_ADMIN_LDAP}" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  
  #Start - Add missing osp configuration for User Application login should work Bug 1142796
  if ! grep -q com.netiq.idm.osp.token.init.cache.size ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  then
   echo "com.netiq.idm.osp.token.init.cache.size = 1000" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  fi

  if ! grep -q com.netiq.idm.osp.oauth.first.name ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  then
   echo "com.netiq.idm.osp.oauth.dn = name" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.first.name = first_name" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.last.name = last_name" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  fi

  if ! grep -q com.netiq.idm.osp.oauth.initials ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  then
   echo "com.netiq.idm.osp.oauth.initials = initials" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.email = email" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.language = language" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.cacheable = cacheable" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.expiration = expiration" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.auth.src.id = auth_src_id" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.client = client" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
   echo "com.netiq.idm.osp.oauth.txn = txn" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  fi
  #End - Bug 1142796
  
  # idmdash: If idmdash settings do not exist(i.e. upgrading from the version lower than 4.6.0), then add them
  if ! grep -q com.netiq.idmdash.clientID ${IDM_BACKUP_FOLDER}/ism-configuration.properties 
  then
       echo "com.netiq.idmdash.clientID = idmdash" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
       echo "com.netiq.idmdash.response-types = code" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
       if [ ! -z ${UA_SERVER_PORT} ] && [ "${UA_SERVER_PORT}" != "" ]
       then
         echo "com.netiq.idmdash.redirect.url = ${PROTO}${UA_SERVER_HOSTNAME}:${UA_SERVER_PORT}/idmdash/oauth.html" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
       else
         echo "com.netiq.idmdash.redirect.url = ${PROTO}${UA_SERVER_HOSTNAME}/idmdash/oauth.html" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
       fi
       echo "com.netiq.idmdash.clientPass._attr_obscurity = ENCRYPT" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
       echo "com.netiq.idmdash.clientPass = `$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt ${SSO_SERVICE_PWD}`" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
	   
	   # Also, change landing URLs to /idmdash/#/landing 
	   echo "com.netiq.idmdash.landing.url = /idmdash/#/landing" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
	   sed -i "s^/landing^/idmdash/#/landing^g" "${IDM_BACKUP_FOLDER}/ism-configuration.properties"   
  fi
  grep -q com.netiq.wf.engine.url ${IDM_BACKUP_FOLDER}/ism-configuration.properties
  if [ $? -ne 0 ] 
  then
    if [ ! -z ${UA_SERVER_PORT} ] && [ "${UA_SERVER_PORT}" != "" ]
    then
      echo "com.netiq.wf.engine.url = ${PROTO}${UA_SERVER_HOSTNAME}:${UA_SERVER_PORT}/workflow" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
    else
      echo "com.netiq.wf.engine.url = ${PROTO}${UA_SERVER_HOSTNAME}/workflow" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
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


restore_other_wars()
{
  disp_str=`gettext install "Restore required war files."`
  write_and_log "$disp_str"

  WAR_FILES=("IDMPwdMgt.war" "workflow.war" "idmadmin.war" "IDMProv.war" "rra.war" "dash.war" "landing.war" "RIS.war" "idmdash.war" "osp.war" "sspr.war" "idmappsdoc.war" "${UA_APP_CTX}.war")

  ls ${IDM_BACKUP_FOLDER}/tomcat/webapps/*.war > /opt/war_files.txt

  cat /opt/war_files.txt | while read warFilePath
  do
   war_name=`basename $warFilePath`;
   WAR_EXIST=`containsElement "$war_name" "${WAR_FILES[@]}"`
   #
   if [ $WAR_EXIST -eq 1 ]
   then
    cp -r ${IDM_BACKUP_FOLDER}/tomcat/webapps/${war_name} ${IDM_TOMCAT_HOME}/webapps/
   fi
  done
  #Remove the file
  rm -rf /opt/war_files.txt

}

search_resplace_osp_host()
{
   local osp_url_host=$1
   local PROTO="`echo ${osp_url_host} | grep '://' | sed -e 's,^\(.*://\).*,\1,g'`"
   local URL=`echo ${osp_url_host} | sed -e s,$PROTO,,g`
   local SSO_SERVER_HOST="$(echo $URL | grep : | cut -d: -f1)"
   if [ -z ${SSO_SERVER_HOST} ]
   then
     local SSO_SERVER_HOST="$(echo $URL | grep / | cut -d/ -f1)"
     if [ -z ${SSO_SERVER_HOST} ]
     then
       SSO_SERVER_HOST=$URL
     fi
     local SSO_SERVER_SSL_PORT=
   else
     local SSO_SERVER_SSL_PORT=$(echo $URL | sed -e s,$SSO_SERVER_HOST:,,g | cut -d/ -f1)
   fi


   local rbpm_url_data=`grep -ir "com.netiq.rbpm.redirect.url =" ${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties | awk '{print $3}' | sed 's/^[ ]*//'`
   local RBPM_PROTO="`echo ${rbpm_url_data} | grep '://' | sed -e 's,^\(.*://\).*,\1,g'`"
   local RBPM_URL=`echo ${rbpm_url_data} | sed -e s,$RBPM_PROTO,,g`
   local RBPM_SERVER_HOSTNAME="$(echo $RBPM_URL | grep : | cut -d: -f1)"
   if [ -z ${RBPM_SERVER_HOSTNAME} ]
   then
     local RBPM_SERVER_HOSTNAME="$(echo $RBPM_URL | grep / | cut -d/ -f1)"
     if [ -z ${RBPM_SERVER_HOSTNAME} ]
     then
       RBPM_SERVER_HOSTNAME=$RBPM_URL
     fi
     local RBPM_SERVER_PORT=
   else
     local RBPM_SERVER_PORT=$(echo $RBPM_URL | sed -e s,$RBPM_SERVER_HOSTNAME:,,g | cut -d/ -f1)
   fi

     if [ ! -z "${SSO_SERVER_SSL_PORT}" ]
     then
       search_and_replace "com.netiq.idm.osp.url.host = ${PROTO}${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}"  "com.netiq.idm.osp.url.host = ${RBPM_PROTO}${RBPM_SERVER_HOSTNAME}:${RBPM_SERVER_PORT}" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
     else
       if [ ! -z "${RBPM_SERVER_PORT}" ]
       then
         search_and_replace "com.netiq.idm.osp.url.host = ${PROTO}${SSO_SERVER_HOST}"  "com.netiq.idm.osp.url.host = ${RBPM_PROTO}${RBPM_SERVER_HOSTNAME}:${RBPM_SERVER_PORT}" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
       else
         search_and_replace "com.netiq.idm.osp.url.host = ${PROTO}${SSO_SERVER_HOST}"  "com.netiq.idm.osp.url.host = ${RBPM_PROTO}${RBPM_SERVER_HOSTNAME}" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
       fi
     fi
}

update_osphost_ism()
{
  local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties

  if [ ! -f ${IDM_BACKUP_FOLDER}/tomcat/webapps/osp.war ]
  then
       local osp_url_host=`grep -ir "com.netiq.idm.osp.url.host =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
       if [ ! -z "${osp_url_host}" ]
       then
          search_resplace_osp_host "${osp_url_host}"
       else
         #com.netiq.client.authserver.url.authorize
         local auth_url_host=`grep -ir "com.netiq.client.authserver.url.authorize =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
         if [ ! -z ${auth_url_host} ]
         then
             search_resplace_osp_host "${auth_url_host}"
         fi
      fi
  fi
}

update_ssprhost_ism()
{
  local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
  if [ "${UA_UPG_INSTALL_SSPR}" == "y" ]
  then
     local sspr_redirect_url=`awk -F'com.netiq.sspr.redirect.url' '{print $2}' ${backup_ism_file} | cut -d"=" -f2- | cut -d" " -f2- | sed '/^$/d'` 
     local SSPR_PROTO="`echo ${sspr_redirect_url} | grep '://' | sed -e 's,^\(.*://\).*,\1,g'`"
     local SSPR_URL=`echo ${sspr_redirect_url} | sed -e s,$SSPR_PROTO,,g`
     local SSPR_SERVER_HOSTNAME="$(echo $SSPR_URL | grep : | cut -d: -f1)"
     if [ -z ${SSPR_SERVER_HOSTNAME} ]
     then
       local SSPR_SERVER_HOSTNAME="$(echo $SSPR_URL | grep / | cut -d/ -f1)"
       if [ -z ${SSPR_SERVER_HOSTNAME} ]
       then
         SSPR_SERVER_HOSTNAME=$SSPR_URL
       fi
       local SSPR_SERVER_PORT=
     else
       local SSPR_SERVER_PORT=$(echo $URL | sed -e s,$SSPR_SERVER_HOSTNAME:,,g | cut -d/ -f1)
     fi
   
     local rbpm_url_data=`grep -ir "com.netiq.rbpm.redirect.url =" ${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties | awk '{print $3}' | sed 's/^[ ]*//'`
     local RBPM_PROTO="`echo ${rbpm_url_data} | grep '://' | sed -e 's,^\(.*://\).*,\1,g'`"
     local RBPM_URL=`echo ${rbpm_url_data} | sed -e s,$RBPM_PROTO,,g`
     local RBPM_SERVER_HOSTNAME="$(echo $RBPM_URL | grep : | cut -d: -f1)"
     if [ -z ${RBPM_SERVER_HOSTNAME} ]
     then
       local RBPM_SERVER_HOSTNAME="$(echo $RBPM_URL | grep / | cut -d/ -f1)"
       if [ -z ${RBPM_SERVER_HOSTNAME} ]
       then
         RBPM_SERVER_HOSTNAME=$RBPM_URL
       fi
       local RBPM_SERVER_PORT=
     else
       local RBPM_SERVER_PORT=$(echo $RBPM_URL | sed -e s,$RBPM_SERVER_HOSTNAME:,,g | cut -d/ -f1)
     fi
  
     local sspr_help_url=`grep -ir "com.netiq.idm.osp.login.sign-in-help-url =" ${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties | awk '{print $3}' | sed 's/^[ ]*//'`

     if [ ! -z "${RBPM_SERVER_PORT}" ]
     then
        search_and_replace "com.netiq.sspr.redirect.url = ${sspr_redirect_url}" "com.netiq.sspr.redirect.url = ${RBPM_PROTO}${RBPM_SERVER_HOSTNAME}:${RBPM_SERVER_PORT}/sspr/public/oauth" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
       if [ ! -z "${sspr_help_url}" ]
       then 
         search_and_replace "com.netiq.idm.osp.login.sign-in-help-url = ${sspr_help_url}" "com.netiq.idm.osp.login.sign-in-help-url = ${RBPM_PROTO}${RBPM_SERVER_HOSTNAME}:${RBPM_SERVER_PORT}/sspr/public" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
       fi
     else
        search_and_replace "com.netiq.sspr.redirect.url = ${sspr_redirect_url}" "com.netiq.sspr.redirect.url = ${RBPM_PROTO}${RBPM_SERVER_HOSTNAME}/sspr/public/oauth" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
       if [ ! -z "${sspr_help_url}" ]
       then
         search_and_replace "com.netiq.idm.osp.login.sign-in-help-url = ${sspr_help_url}" "com.netiq.idm.osp.login.sign-in-help-url = ${RBPM_PROTO}${RBPM_SERVER_HOSTNAME}/sspr/public" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
       fi

     fi
  fi 
}
