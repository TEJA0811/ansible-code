#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

upgrade_sspr_configuration()
{
 
    disp_str=`gettext install "Upgrading Self Service Password Reset (SSPR)"`
    write_and_log "$disp_str"
 
    readconfigurations
    
    if [ -f /opt/sspr_upgrade.properties ]
    then
        #sed -i "s#\\\##g" "/opt/sspr_upgrade.properties"
        sed -i 's/\\//g' "/opt/sspr_upgrade.properties"
        local sspr_idvault_pwd=`grep  "SSPR_ID_VAULT_PASSWORD=" /opt/sspr_upgrade.properties | awk -F'=' '{print $2}'`
        sed -i "/SSPR_ID_VAULT_PASSWORD=/d" /opt/sspr_upgrade.properties
        echo "SSPR_ID_VAULT_PASSWORD='${sspr_idvault_pwd}'" >> /opt/sspr_upgrade.properties
        local sspr_ssoservice_pwd=`grep  "SSPR_SSO_SERVICE_PWD=" /opt/sspr_upgrade.properties | awk -F'=' '{print $2}'`
        sed -i "/SSPR_SSO_SERVICE_PWD=/d" /opt/sspr_upgrade.properties
        echo "SSPR_SSO_SERVICE_PWD='${sspr_ssoservice_pwd}'" >> /opt/sspr_upgrade.properties
        source /opt/sspr_upgrade.properties
    fi

    init_upgrade_vars

    import_vault_certificates

    if [ $IS_WRAPPER_CFG_INST -eq 1 ]
    then
       create_SSPRConfiguration
    fi

    #import_sspr_ldifs
    #Replace the existing localDB and configuration file.
    replace_configuraton 
    
    chown -R novlua:novlua ${IDM_TOMCAT_HOME}
    chown -R novlua:novlua ${SSPR_CONFIG_FILE_HOME}

    if [ -f /opt/sspr_upgrade.properties ]
    then
       rm -rf /opt/sspr_upgrade.properties
    fi
}

init_upgrade_vars()
{
    ID_VAULT_HOST=${SSPR_ID_VAULT_HOST}
    ID_VAULT_LDAPS_PORT=${SSPR_ID_VAULT_LDAPS_PORT}
    ID_VAULT_ADMIN_LDAP=${SSPR_ID_VAULT_ADMIN_LDAP}
    USER_CONTAINER=${SSPR_USER_CONTAINER}
    ADMIN_CONTAINER=${SSPR_ADMIN_CONTAINER}
    TOMCAT_SERVLET_HOSTNAME=${SSPR_TOMCAT_SERVLET_HOSTNAME}
    SSO_SERVER_HOST=${SSPR_SSO_SERVER_HOST}
    SSO_SERVER_SSL_PORT=${SSPR_SSO_SERVER_PORT}
    SSO_SERVICE_PWD=${SSPR_SSO_SERVICE_PWD}
    UA_ADMIN=${SSPR_UA_ADMIN}
}

replace_configuraton()
{
  if [ -f ${SSPR_CONFIG_FILE_HOME}/SSPRConfiguration.xml ]
  then
    cp -rpf ${SSPR_CONFIG_FILE_HOME}/SSPRConfiguration.xml ${SSPR_CONFIG_FILE_HOME}/SSPRConfiguration_new.xml.save
  fi

  if [ -d ${IDM_BACKUP_FOLDER}/LocalDB ]
  then
      #SSPR LocalDB
      cp -rpf ${IDM_BACKUP_FOLDER}/LocalDB/ ${SSPR_CONFIG_FILE_HOME}/
      /bin/chmod 750 ${SSPR_CONFIG_FILE_HOME}/LocalDB/
  fi

  if [ -f ${IDM_BACKUP_FOLDER}/SSPRConfiguration.xml ]
  then
    #SSPR Configuration file
    cp -rpf ${IDM_BACKUP_FOLDER}/SSPRConfiguration.xml ${SSPR_CONFIG_FILE_HOME}/
  fi
}

readconfigurations()
{
 
 cp -r ${IDM_INSTALL_HOME}sspr/sspr_upgrade.properties /opt/

 if [ $IS_WRAPPER_CFG_INST -eq 0 ]
 then
      $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.sspr.ReadInstalledSSPRConfiguration ${IDM_BACKUP_FOLDER} /opt/sspr_upgrade.properties  
 else
     $IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.sspr.ReadSSPRConfiguration ${IDM_BACKUP_FOLDER} /opt/sspr_upgrade.properties

 fi

}
