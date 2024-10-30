#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

userapp_post_upgrade()
{
    UA_APP_CTX=`grep -ir "portal.context" ${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties | cut -d "=" -f2 | sed 's/^[ ]*//'`
    if [ -z "$UA_APP_CTX" ] || [ "$UA_APP_CTX" == "" ]
    then
    	UA_APP_CTX="IDMProv"
    fi
    
    rpm -qi netiq-tomcatconfig &> /dev/null
    if [ $? -eq 0 ]
    then
    	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
    else
    	INSTALLED_FOLDER_PATH=`grep -i 'TOMCAT_PARENT_DIR=' /etc/init.d/idmapps_tomcat_init | cut -d '=' -f2`   
    fi
    UA_CONFIG_HOME=/opt/netiq/idm/apps/UserApplication

    #strerr=`gettext install "Read Installed configuration"`
    #readconfigproperties
    
    if [ -f "/opt/ua_upgrade.properties" ]
    then
      sed -i 's#\\##g' /opt/ua_upgrade.properties
      source /opt/ua_upgrade.properties
    fi

    strerr=`gettext install "Tomcat: Configuration failed. Check configure logs for more details."`
    configure_tomcat
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    strerr=`gettext install "ActiveMQ: Configuration failed: Check logs for more details."`
    configure_activemq
    check_errs $? $strerr
    RET=$?
    check_return_value $RET
 
    if [ $IS_RPT_UPGRADED -eq 0 ]
    then
        strerr=`gettext install "SSO: Configuration Failed: Check Logs for More Details"`
        upgrade_osp_configuration
        RET=$?
        check_return_value $RET
    else
        write_log "Skipping configuration of OSP for Identity Applications."
    fi

    if [ ! -z $SSPR_INSTALLED_FOLDER_PATH ] && [ ! -z "$BLOCKED_CODE" ]
    then
     strerr=`gettext install "SSPR: Configuration Failed: Check Logs for More Details"`
     upgrade_sspr_configuration
     RET=$?
     check_return_value $RET
    fi

    strerr=`gettext install "Auditing: Configuration failed. Check configure logs for more details."`
    # TODO: Uncomment this and configure the auditing based on user selection / current configuration
    # Temporarily commented out for EA2
    #configure_auditing
    #check_errs $? $strerr
    #RET=$?
    #check_return_value $RET
    
    update_config_properties

    strerr=`gettext install "Configupdate: Updating Configupdate failed. Check logs for more details"`
    update_config_update
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    ismcleanup
    
     ###Woraround for now
    sed -i 's/-Dcom.netiq.idm.osp.audit.enabled=true/-Dcom.netiq.idm.osp.audit.enabled=false/g' ${IDM_TOMCAT_HOME}/bin/setenv.sh
    
     str1=`gettext install "User Application context: ${UA_APP_CTX}"` 
     write_and_log "$str1"
      
     if [ "${UA_APP_CTX}" !=  "IDMProv" ]
      then
        if [ -f ${IDM_TOMCAT_HOME}/webapps/IDMProv.war ]
        then
          update_ua_context
          #Change ownership
          /usr/bin/chown novlua:novlua ${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war
        fi
      fi

 
    strerr=`gettext install "Configuring database failed. Check logs for more details."`
    UA_DB_NEW_OR_EXIST='exist'
    WFE_DB_NEW_OR_EXIST='exist'
    if [ $WFE_DB_CONN_RET -eq 1 ]
    then
    	create_wfe_db
    fi
    liquibase_database_schema
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    strerr=`gettext install "Restore custom war files failed."`
    restore_other_wars
    restore_xmls
    #Restore setemv file
    local backup_engineId=`grep 'Dcom.novell.afw.wf.engine-id' ${IDM_BACKUP_FOLDER}/tomcat/bin/setenv.sh | grep -v [[:blank:]]# | grep -v ^# | awk -F "Dcom.novell.afw.wf.engine-id" '{print $2}' | cut -d ' ' -f 1 | cut -d '=' -f 2`
    if [ ! -z ${backup_engineId} ]
    then
      local new_engineId=`grep 'Dcom.novell.afw.wf.engine-id' ${IDM_TOMCAT_HOME}/bin/setenv.sh | grep -v [[:blank:]]# | grep -v ^# | awk -F "Dcom.novell.afw.wf.engine-id" '{print $2}' | cut -d ' ' -f 1 | cut -d '=' -f 2`
      sed -i "s#${new_engineId}#${backup_engineId}#g" ${IDM_TOMCAT_HOME}/bin/setenv.sh
    fi
     
    #Restore client settings.
    if [ -d ${IDM_BACKUP_FOLDER}/tomcat/conf/clients ]
    then 
        cp -rpf ${IDM_BACKUP_FOLDER}/tomcat/conf/clients ${IDM_TOMCAT_HOME}/conf/
    fi
	
	#Restore forgot password and active user configurations
	local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
	local ism_conf_file=${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	local backup_config_props_file=${IDM_BACKUP_FOLDER}/UserApplication/configupdate.properties
	
    local ism_forgotten_username_url=`grep -ir "com.netiq.idm.osp.login.sspr.forgotten-username-url = " ${ism_conf_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
    local ism_activate_account_url=`grep -ir "com.netiq.idm.osp.login.sspr.activate-account-url = " ${ism_conf_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
    local ism_sign_help_url=`grep -ir "com.netiq.idm.osp.login.sign-in-help-url = " ${ism_conf_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
    local ism_forgot_pwd_url=`grep -ir "com.netiq.idm.forgot-pwd-url = " ${ism_conf_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`

    local forgotten_username_url=`grep -ir "com.netiq.idm.osp.login.sspr.forgotten-username-url = " ${backup_ism_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
    local activate_account_url=`grep -ir "com.netiq.idm.osp.login.sspr.activate-account-url = " ${backup_ism_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
    local sign_help_url=`grep -ir "com.netiq.idm.osp.login.sign-in-help-url = " ${backup_ism_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
    [ -f ${backup_config_props_file} ] && local forgot_pwd_url=`grep -ir "com.netiq.idm.forgot-pwd-url=" ${backup_config_props_file}  | awk -F= '{print $2}' | sed 's/^[ ]*//' | head -1`

    if [ ! -z ${forgotten_username_url} ] && [ -z ${ism_forgotten_username_url} ]
    then
     echo "com.netiq.idm.osp.login.sspr.forgotten-username-url = ${forgotten_username_url}" >> ${ism_conf_file}
    fi

    if [ ! -z ${activate_account_url} ] && [ -z ${ism_activate_account_url} ]
    then
     echo "com.netiq.idm.osp.login.sspr.activate-account-url = ${activate_account_url}" >> ${ism_conf_file}
    fi
    
    if [ -z ${sign_help_url} ] && [ ! -z ${ism_sign_help_url} ]
    then
     sed -i "/com.netiq.idm.osp.login.sign-in-help-url/d" ${ism_conf_file}
    fi

    if [ ! -z ${forgot_pwd_url} ] && [ -z ${ism_forgot_pwd_url} ]
    then
     echo "com.netiq.idm.forgot-pwd-url = ${forgot_pwd_url}" >> ${ism_conf_file}
    fi
    grep -q com.netiq.idm.osp.naaf.admin-name ${ism_conf_file} &> /dev/null
    firstret=$?
    grep -q com.netiq.idm.osp.naaf.admin-name ${backup_ism_file} &> /dev/null
    secondret=$?
    if [ $firstret -eq 0 ] && [ $secondret -eq 0 ]
    then
	local ism_osp_naaf_adminname=`grep -ir "com.netiq.idm.osp.naaf.admin-name = " ${ism_conf_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
        local osp_naaf_adminname=`grep -ir "com.netiq.idm.osp.naaf.admin-name = " ${backup_ism_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
    fi
	if [ ! -z ${osp_naaf_adminname} ] && [ ! -z ${ism_osp_naaf_adminname} ]
	then
          if [ ${osp_naaf_adminname} != ${ism_osp_naaf_adminname} ]
          then
                sed -i '/com.netiq.idm.osp.naaf.admin-name/d' ${ism_conf_file}
                echo "com.netiq.idm.osp.naaf.admin-name = ${osp_naaf_adminname}" >> ${ism_conf_file}
          fi
	fi
	#End of restoring forgot password and active user configurations
	
	#Start - Remove unused naudit keys
    local naudit_keys=`grep -ir "com.sssw.fw.security.sigcert.truststore.type = " ${ism_conf_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
   
    if [ ! -z ${naudit_keys} ]
    then
     sed -i "/com.sssw.fw.security.sigcert.truststore.type/d" ${ism_conf_file}
    fi
    #End - Remove unused naudit keys
	
    if [ ! -f ${IDM_TOMCAT_HOME}/webapps/sspr.war ]
    then 
       local ENV_SSPR_INSTALLED_PATH=`grep 'Dsspr' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh | grep -v [[:blank:]]# | grep -v ^# | awk -F "Dsspr" '{print $2}' | cut -d ' ' -f 1 | cut -d '=' -f 2`
       sed -i 's#-Dsspr.applicationPath=${ENV_SSPR_INSTALLED_PATH} ##g' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh
    fi
    # If Reporting is not installed locally, rpt configuration not required in setenv file
    if [ ! -f ${IDM_TOMCAT_HOME}/webapps/IDMRPT-CORE.war ]
    then
       local rptConfigFilePath=`grep 'Dcom.netiq.rpt.config.file' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh | awk -F "Dcom.netiq.rpt.config.file" '{print $2}' | cut -d ' ' -f 1 | cut -d '=' -f 2`
       sed -i 's#-Dcom.netiq.rpt.config.file=${rptConfigFilePath} ##g' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh
    fi
    grep -q "com.microfocus.workflow.logging.level" ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh
    if [ $? -ne 0 ]
    then
    	sed -i 's#-Djava.net.preferIPv4Stack#-Dcom.microfocus.workflow.logging.level=INFO -Djava.net.preferIPv4Stack#g' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh
    fi

    #
    /usr/bin/chown -R novlua:novlua ${IDM_TOMCAT_HOME} >> "${log_file}" 2>&1

    if [ -d ${SSPR_CONFIG_FILE_HOME} ]
    then
       /usr/bin/chown -R novlua:novlua ${SSPR_CONFIG_FILE_HOME} >> "${log_file}" 2>&1
    fi

    
    if [ -d ${OSP_INSTALL_PATH} ]
    then
       /usr/bin/chown -R novlua:novlua ${OSP_INSTALL_PATH} >> "${log_file}" 2>&1
    fi
     
    # import the recaptcha certs
    import_recaptcha_certs
	
	#Start - Update idmdash response-types
    local idmdash_keys=`grep -ir "com.netiq.idmdash.response-types =" ${ism_conf_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1`
   
    if [ ! -z ${idmdash_keys} ]
    then
     sed -i "/com.netiq.idmdash.response-types/d" ${ism_conf_file}
	 #
	 echo "com.netiq.idmdash.response-types = code,token" >> ${ism_conf_file}
    fi
    #End - Update idmdash response-types
	

    if [ -f "${IDM_BACKUP_FOLDER}/osp/osp.jks" ]
    then
        #mv "${OSP_INSTALL_PATH}/osp.jks" "${OSP_INSTALL_PATH}/osp-new.jks"
        cp -p "${IDM_BACKUP_FOLDER}/osp/osp.jks" "${OSP_INSTALL_PATH}/osp.jks"
    fi

    local osp_keystore_filename=`grep -ir "com.netiq.idm.osp.oauth-keystore.file = " ${backup_ism_file}  | awk '{print $3}' | sed 's/^[ ]*//' | head -1 | awk -F / '{print $NF}'`
    if [ -f "${IDM_BACKUP_FOLDER}/osp/${osp_keystore_filename}" ]
    then
        cp -p "${IDM_BACKUP_FOLDER}/osp/${osp_keystore_filename}" "${OSP_INSTALL_PATH}/${osp_keystore_filename}"
    fi
    sed -i.bak "s/no_nam_oauth=\"false\"/no_nam_oauth=\"true\"/g" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
}
