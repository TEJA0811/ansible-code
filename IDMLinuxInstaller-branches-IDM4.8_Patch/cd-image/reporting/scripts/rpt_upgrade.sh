#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################


stopallservices()
{
  tomcat_service_file="/etc/systemd/system/netiq-tomcat.service"
      disp_str=`gettext install "Stopping tomcat"`
      write_and_log "$disp_str"
  if [ -e $tomcat_service_file ]
  then
      systemctl stop netiq-tomcat >> "${LOG_FILE_NAME}" 2>&1
  else
      tomcat_service_file="/etc/init.d/idmapps_tomcat_init"

      if [ -e $tomcat_service_file ]
      then
          $tomcat_service_file stop >> "${LOG_FILE_NAME}" 2>&1
      fi
  fi

      disp_str=`gettext install "Stopping ActiveMQ"`
      write_and_log "$disp_str"
  activemq_service_file="/etc/init.d/idmapps_activemq_init"
  if [ -e $activemq_service_file ]
  then
      $activemq_service_file stop >> "${LOG_FILE_NAME}" 2>&1
  else
  	systemctl stop netiq-activemq >> "${LOG_FILE_NAME}" 2>&1
  fi

 
}

startallservices()
{
  tomcat_service_file="/etc/systemd/system/netiq-tomcat.service"
  if [ -f $tomcat_service_file ]
  then
      disp_str=`gettext install "Starting tomcat"`
      write_and_log "$disp_str"
      systemctl start netiq-tomcat >> "${LOG_FILE_NAME}" 2>&1
  else
      tomcat_service_file="/etc/init.d/idmapps_tomcat_init"

      if [ -f $tomcat_service_file ]
      then
          disp_str=`gettext install "Starting tomcat"`
          write_and_log "$disp_str"
          $tomcat_service_file start >> "${LOG_FILE_NAME}" 2>&1
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

reportingbackup()
{
  disp_str=`gettext install "Reporting Backup is Starting."`
  write_and_log "$disp_str"  

  disp_str=`gettext install "Backing up tomcat files"`
  write_and_log "$disp_str"
  tomcatfilesbackup

  disp_str=`gettext install "Backing up the ActiveMQ files"`
  write_and_log "$disp_str"
  activemqfilesbackup
 
  #If osp exist then only we have to take backup
  if [ "${IS_OSP_EXIST}" == "true" ]
  then
      disp_str=`gettext install "Backing up OAuth files"`
      write_and_log "$disp_str"
      ospfilesbackup
  fi

  disp_str=`gettext install "Backing up Reporting files"`
  write_and_log "$disp_str"
  reportingfilesbackup

  if [ -e ${RPT_JRE_HOME_PATH}/lib/security/cacerts ]
  then
        disp_str=`gettext install "Backing up jre cacerts file"`
        write_and_log "$disp_str"
        mkdir -p ${IDM_BACKUP_FOLDER}/jre/
        cp -pf ${RPT_JRE_HOME_PATH}/lib/security/cacerts ${IDM_BACKUP_FOLDER}/jre/
  fi

  disp_str=`gettext install "Reporting Backup is Completed Successfully."`
  write_and_log "$disp_str"
}

tomcatfilesbackup()
{
 if [ -f ${INSTALLED_FOLDER_PATH}/tomcat/conf/ism-configuration.properties ]
 then
     cp -rpf ${INSTALLED_FOLDER_PATH}/tomcat/conf/ism-configuration.properties ${IDM_BACKUP_FOLDER}/
 fi
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
    rm -rf ${INSTALLED_FOLDER_PATH}/tomcat/webapps/{IDMDCS-CORE*,IDMRPT*,dcsdoc*,idmdcs*,rptdoc*}
 fi
 if [ $IS_UA_UPGRADED -eq 0 ]
 then
    if [ -d ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/ ]
    then
        rm -rf ${INSTALLED_FOLDER_PATH}/TomcatPostgreSQL_Uninstaller/
    fi
 fi
}

ospfilesbackup()
{
 OSP_INSTALL_FOLDER=$INSTALLED_FOLDER_PATH/osp/
 if [ -d ${OSP_INSTALL_FOLDER} ]
 then
    cp -rpf ${OSP_INSTALL_FOLDER} ${IDM_BACKUP_FOLDER}/
    if [ $IS_UA_UPGRADED -eq 0 ]
    then
        rm -rf ${OSP_INSTALL_FOLDER}
    else
        #restore war back into webapps as it is cleaned up during tomcat backup process
        cp -p ${IDM_BACKUP_FOLDER}/tomcat/webapps/osp.war ${INSTALLED_FOLDER_PATH}/tomcat/webapps/
    fi
 fi
}


reportingfilesbackup()
{
 [ -z ${RPT_INSTALL_FOLDER} ] && export RPT_INSTALL_FOLDER=/opt/netiq/idm/apps/IDMReporting
 if [ -d ${RPT_INSTALL_FOLDER} ]
 then
    cp -rpf ${RPT_INSTALL_FOLDER} ${IDM_BACKUP_FOLDER}/ 
    cp -rpf ${CONFIG_UPDATE_HOME}/configupdate.sh.properties ${IDM_BACKUP_FOLDER}/ 
    #rm -rf ${RPT_INSTALL_FOLDER}
 fi
}

readconfigpropertiesfordbconn()
{
   if [ ! -f /opt/netiq/idm/apps/tomcat-jre8/webapps/IDMRPT.war ]
   then
   $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ReadRptConfigurations ${INSTALLED_FOLDER_PATH} /opt/rptcon_upgrade.properties old >> ${LOG_FILE_NAME}  
   else
   $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ReadRptConfigurations ${INSTALLED_FOLDER_PATH} /opt/rptcon_upgrade.properties new >> ${LOG_FILE_NAME}  
   fi
  
}

readconfigproperties()
{
   if [ ! -f /opt/netiq/idm/apps/tomcat-jre8/webapps/IDMRPT.war ]
   then
   $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ReadRptConfigurations ${IDM_BACKUP_FOLDER} /opt/rpt_upgrade.properties old >> ${LOG_FILE_NAME}  
   else
   $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.ReadRptConfigurations ${IDM_BACKUP_FOLDER} /opt/rpt_upgrade.properties new >> ${LOG_FILE_NAME}  
   fi
  
    local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
    local silent_prop_file=/opt/rpt_upgrade.properties
    #
    local osp_keystore_passwrd=`grep -ir "com.netiq.idm.osp.oauth-keystore.pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    echo -e "\n#############" >> ${silent_prop_file}
    echo OSP_KEYSTORE_PWD=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt ${osp_keystore_passwrd}` >> ${silent_prop_file}
    #
    local idm_keystore_passwrd=`grep -ir "com.netiq.idm.ua.ldap.keystore-pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    if [ -z $idm_keystore_passwrd ]
    then
        echo IDM_KEYSTORE_PWD=changeit >> ${silent_prop_file}
    else
        echo IDM_KEYSTORE_PWD=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt ${idm_keystore_passwrd}` >> ${silent_prop_file}
    fi
    #
    local rpt_sso_service_password=`grep -ir "com.netiq.rpt.clientPass =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    if [ $IS_UPGRADE -eq 1 ]
    then
        echo RPT_SSO_SERVICE_PWD=$rpt_sso_service_password >>  ${silent_prop_file}
    else
        echo RPT_SSO_SERVICE_PWD=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt ${rpt_sso_service_password}` >> ${silent_prop_file}
    fi

    local IDVault_passwrd=`grep -ir "com.novell.idm.ldap.admin.pass =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    echo ID_VAULT_PASSWORD=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt ${IDVault_passwrd}` >> ${silent_prop_file}

    echo ID_VAULT_HOST=`grep -ir "com.netiq.idm.osp.ldap.host" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo USER_CONTAINER=`grep -ir "com.netiq.idm.osp.as.users-container-dn" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo ADMIN_CONTAINER=`grep -ir "com.netiq.idm.osp.as.admins-container-dn" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo RPT_SMTP_SERVER=`grep -ir "com.novell.idm.rpt.core.smtp.host" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo RPT_SMTP_SERVER_PORT=`grep -ir "com.novell.idm.rpt.core.smtp.port" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo RPT_DEFAULT_EMAIL_ADDRESS=`grep -ir "com.novell.idm.rpt.core.defaultemail" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo ID_VAULT_DRIVER_SET=`grep -ir "DirectoryService/realms/jndi/params/DRIVER_SET_ROOT" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo SSO_SERVER_PORT=`grep -m1 osp.url.host ${backup_ism_file} | grep -v "host}" | cut -d":" -f3-` >> ${silent_prop_file}

    ID_VAULT_ADMIN_LDAP=`grep -ir "com.novell.idm.ldap.admin.user" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    if [ -z $ID_VAULT_ADMIN_LDAP ] || [ "$ID_VAULT_ADMIN_LDAP" == "" ]
    then
      ID_VAULT_ADMIN_LDAP=`grep -ir "com.netiq.idm.osp.ldap.admin-dn" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    fi
    echo ID_VAULT_ADMIN_LDAP=${ID_VAULT_ADMIN_LDAP} >> ${silent_prop_file}
    echo ID_VAULT_LDAPS_PORT=`grep -ir "com.netiq.idm.osp.ldap.port" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}
    echo ID_VAULT_LDAP_PORT=`grep -ir "DirectoryService/realms/jndi/params/PLAIN_PORT" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'` >> ${silent_prop_file}

    if [ $IS_UPGRADE -eq 1 ] && [ ! -z "$BLOCKED_CODE" ]
    then
        echo "com.netiq.idmdcs.clientID=idmdcs" >> ${IDM_BACKUP_FOLDER}/ism-configuration.properties
        local RPTURL=`grep -ir "com.netiq.rpt.redirect.url =" ${IDM_BACKUP_FOLDER}/ism-configuration.properties | awk '{print $3}' | sed 's/^[ ]*//'`
        local PROTO="`echo $RPTURL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
        local URL=`echo $RPTURL | sed -e s,$PROTO,,g`
        local RPT_SERVER_HOSTNAME="$(echo $URL | grep : | cut -d: -f1)"
        if [ -z ${RPT_SERVER_HOSTNAME} ]
        then
          local RPT_SERVER_HOSTNAME="$(echo $URL | grep / | cut -d/ -f1)"
          if [ -z ${RPT_SERVER_HOSTNAME} ]
          then
            local RPT_SERVER_HOSTNAME=$URL
          fi
          local RPT_SERVER_PORT=
        else
          local RPT_SERVER_PORT=$(echo $URL | sed -e s,$RPT_SERVER_HOSTNAME:,,g | cut -d/ -f1)
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

  WAR_FILES=("IDMDCS-CORE.war" "IDMRPT-CORE.war" "IDMRPT.war" "osp.war" "rptdoc.war" "idmdcs.war" "dcsdoc.war")

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


