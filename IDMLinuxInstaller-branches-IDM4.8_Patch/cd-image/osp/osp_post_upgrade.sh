#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

upgrade_osp_configuration()
{

    import_vault_certificates
    ##TODO : Fix the packages and remove this workaround
    ## DO NOT remove this unless you know the side-effect
    touch /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
    cp ${IDM_INSTALL_HOME}/common/packages/utils/*.jar /opt/netiq/idm/apps/tomcat/lib/ >>$LOG_FILE_NAME
    mkdir -p /opt/netiq/idm/apps/tomcat/logs >> $LOG_FILE_NAME
    chown -R novlua:novlua /opt/netiq/idm/apps/tomcat/ >>$LOG_FILE_NAME

 #   update_configupdate_script
    configure_setenv
    strerr=`gettext install "Configuration of Configupdate/ism-configuration failed"`
   
    if [ "$PROD_NAME" == "user_application" ] && [ ! -z "$BLOCKED_CODE" ]
    then
    # Not running in the case of reporting
      configure_props
      check_errs $? $strerr
      RET=$?
      check_return_value $RET
    fi
    export UPGRADE_OSP_CONFIGURATION=true
    sed -i "/com.netiq.idm.osp.oauth.issuer/d" ${ISM_CONFIG}
    echo "com.netiq.idm.osp.oauth.issuer = \${com.netiq.idm.osp.url.host}/osp/a/idm/auth/oauth2" >> ${ISM_CONFIG}
    grep -q com.netiq.idm.osp.oauth.access-token-format.format ${ISM_CONFIG}
    if [ $? -ne 0 ]
    then
      sed -i "/com.netiq.idm.osp.oauth.access-token-format.format/d" ${ISM_CONFIG}
      echo "com.netiq.idm.osp.oauth.access-token-format.format = jwt" >> ${ISM_CONFIG}
    fi
    grep -q com.netiq.idm.osp.oauth.attr.roles.maxValues ${ISM_CONFIG}
    if [ $? -ne 0 ]
    then
      sed -i "/com.netiq.idm.osp.oauth.attr.roles.maxValues/d" ${ISM_CONFIG}
      echo "com.netiq.idm.osp.oauth.attr.roles.maxValues = 1" >> ${ISM_CONFIG}
    fi
if [ ! -z "$BLOCKED_CODE" ]
then
    strerr=`gettext install "Creation of One SSO Provider keystore failed"`
    create_osp_keystore &> ${IDM_TEMP}/crt_osp_ks.log
    exitCode=$?
    if [ $exitCode -ne 0 ]
    then
    	grep "Key pair not generated" ${IDM_TEMP}/crt_osp_ks.log | grep "already exists"
	if [ $? -eq 0 ]
	then
		exitCode=0
	else
	  if [ $IS_UPGRADE -eq 1 ]
	  then
	    exitCode=0
	  fi
	fi
    fi
    check_errs $exitCode $strerr
    RET=$?
    check_return_value $RET
fi
    
    OSP_CUSTOM_LOG=/var/opt/netiq/idm/log/osp_upgrade_custom.log

    strerr=`gettext install "Restoring the OSP Customizations"`
    #custom_jar=${IDM_BACKUP_FOLDER}/osp/osp-extras/l10n-resources/osp-custom-resource.jar
    custom_jar=${IDM_BACKUP_FOLDER}/tomcat/lib/osp-custom-resource.jar
    if [ -f $custom_jar ] && [ -f ${IDM_OSP_HOME}/osp-extras/l10n-resources/osp-custom-resource.jar ]
    then
      merge_jars ${custom_jar} ${IDM_OSP_HOME}/osp-extras/l10n-resources/osp-custom-resource.jar >> $OSP_CUSTOM_LOG
      check_errs $? $strerr
      RET=$?
      check_return_value $RET
      #If the osp customization exist, Upgrade should copy the merged jar file into
      cp -rpf ${IDM_OSP_HOME}/osp-extras/l10n-resources/osp-custom-resource.jar ${IDM_TOMCAT_HOME}/lib/
    fi
}

