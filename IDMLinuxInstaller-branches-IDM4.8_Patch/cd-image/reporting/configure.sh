#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../

. ../common/scripts/configureInput.sh
. ../common/scripts/common_install_vars.sh
. ../common/scripts/install_common_libs.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. conf/global_paths.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/multi_select.sh
. ../common/scripts/database_utils.sh
. ../common/scripts/jre.sh
. ../common/scripts/tomcat.sh
. ../common/scripts/postgres.sh
. ../common/scripts/activemq.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/prompts.sh
. ../common/scripts/ldap_utils.sh
. ../common/scripts/audit.sh
. ../common/scripts/install_check.sh
. ../common/scripts/locale.sh
. ../common/scripts/ism_cfg_util.sh
. ../common/scripts/dxcmd_util.sh
. ../common/scripts/components_version.sh
. ../common/scripts/install_info.sh
. ../common/scripts/common_install_error.sh

. scripts/pre_install.sh
. scripts/rpt_configure.sh


CONFIGURE_FILE=reporting
CONFIGURE_FILE_DISPLAY="Identity Reporting"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idmconfigure.log

initLocale

main()
{
    init
    create_IP_cfg_file_conditionally
    parse_install_params $*
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        cleanup_tmp
    fi
    check_installed_components
    config_mode

    init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf $IS_ADVANCED_MODE
    
    mkdir -p "${INITIALIZED_FILE_DIR}"
    if [ ! -f "${INITIALIZED_FILE_DIR}osp" ] && [ ${IS_WRAPPER_CFG_INST} -eq 0 ]
    then    	
    	#osp needs to be prompted and configured
		CFG_OSP="true"
	fi
	
	if [ "${CFG_OSP}" == "true" ]
	then
        CUR=`pwd`
        cd ../osp
		process_prompts "OSP" $IS_OSP_INSTALLED
        cd $CUR
	fi
	
     process_prompts "Identity reporting" $IS_REPORTING_INSTALLED
    
    if [ "${CFG_OSP}" == "true" ]
	then
		str1=`gettext install "Initializing Single Sign-on configuration... "`
        write_and_log "$str1"
        CUR=`pwd`
		if [ $UNATTENDED_INSTALL -eq 1 ]
		then
			OSP_PARAM_STR="-s -slc -ssc -log ${LOG_FILE_NAME} -sup"
		else
			OSP_PARAM_STR="-slc -ssc -log ${LOG_FILE_NAME} -sup"
		fi
		cd $DIR/../osp
		./configure.sh ${OSP_PARAM_STR} -prod "reporting"
		mkdir -p "${INITIALIZED_FILE_DIR}"
        touch "${INITIALIZED_FILE_DIR}osp"
        cd $CUR
    fi
    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
    then
    	if [ -z "$DOCKER_CONTAINER" ] || [ "$DOCKER_CONTAINER" != "y" ]
	then
    	  install_postgres
	fi
    fi
   
    str1=`gettext install "Initializing Identity Reporting configuration"`
    write_and_log $str1
       
	import_vault_certificates
	
    ## DO NOT remove this unless you know the side-effect
    touch ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
    cp ${IDM_INSTALL_HOME}/common/packages/utils/*.jar ${IDM_TOMCAT_HOME}/lib/
    mkdir -p ${IDM_TOMCAT_HOME}/logs
    
	if [ ! -d "$IDM_TEMP" ]; then
		mkdir $IDM_TEMP
	fi
	chown -R novlua:users ${RPT_CONFIG_HOME} >> "${log_file}" 2>&1
    
    configure_tomcat
    #configure_auditing
    
    # set this variable to 0=SE, 1=AE
    isAdvEdition=1
    if [ ! -z ${ID_VAULT_HOST} ] && [ ! -z ${ID_VAULT_LDAPS_PORT} ] && [ ! -z ${ID_VAULT_ADMIN_LDAP} ] && [ ! -z ${ID_VAULT_PASSWORD} ]
    then
    isAdvEdition=`is_advanced_edition "${ID_VAULT_HOST}" "${ID_VAULT_LDAPS_PORT}" "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}"`
    fi
    if [ "$RPT_CREATE_DRIVERS" == "y" ]
    then
	    if [ -f /etc/opt/netiq/idm/configure/advanced ]
	    then
    		isAdvEdition=1
	    else
    		enginever=`IDMVersion`
	    	uaver=`UAAppVersion`
		if [ "$uaver" != "" ]
		then
			isAdvEdition=1
		else
			isAdvEdition=`is_advanced_edition "${ID_VAULT_HOST}" "${ID_VAULT_LDAPS_PORT}" "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}"`
		fi
	    fi
    fi

    if [ "$RPT_CREATE_DRIVERS" == "y" ]
    then
    	str1=`gettext install "Initializing Identity Reporting drivers"`
        write_and_log "$str1"
        create_driver_property_file
   		install_service_drivers "RPT" "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}" "${ID_VAULT_HOST}" ${ID_VAULT_LDAPS_PORT} "cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}" ${isAdvEdition} >> "${log_file}" 2>&1
    fi

    # cleanup after use ... so no confusion
    if [ -f /etc/opt/netiq/idm/configure/advanced ]
    then
        rm /etc/opt/netiq/idm/configure/advanced
    fi
    
    ##
    # Creating ssl certificate
    ##
    
	
    if [ ! -f ${IDM_TOMCAT_HOME}/conf/tomcat.ks ]
    then  
      if [ ! -z "$CUSTOM_RPT_CERTIFICATE" ] && [ "$CUSTOM_RPT_CERTIFICATE" == "n" ]
      then
        create_ks_from_kmo ${ID_VAULT_HOST} ${ID_VAULT_LDAPS_PORT} ${ID_VAULT_ADMIN_LDAP} ${ID_VAULT_PASSWORD} dirxml $TOMCAT_SSL_KEYSTORE_PASS >> $LOG_FILE_NAME
        cp -rpf ${IDM_TEMP}/tomcat.ks ${IDM_TOMCAT_HOME}/conf/
        chmod 755 ${IDM_TOMCAT_HOME}/conf/tomcat.ks
      else
        if [ ! -z "$RPT_COMM_TOMCAT_KEYSTORE_FILE" ]
	then
	  cp $RPT_COMM_TOMCAT_KEYSTORE_FILE ${IDM_TOMCAT_HOME}/conf/tomcat.ks
	fi
      fi
    fi

    create_silent_property_file
	
    update_config_properties
    configupdate_idm
    update_config_update

    configure_database

    if [ "$EXTERNAL_SSO_SERVER" == "y" ] && [ ! -f ${IDM_TOMCAT_HOME}/webapps/idmdash.war ]
    then
        sed -e "s/-Dcom.netiq.idm.osp.client.host=___TOMCAT_SERVLET_HOSTNAME___ //g" -i ${IDM_TOMCAT_HOME}/bin/setenv.sh
        sed -i 's/-Dcom.netiq.idm.osp.audit.enabled=true/-Dcom.netiq.idm.osp.audit.enabled=false/g' ${IDM_TOMCAT_HOME}/bin/setenv.sh
        grep "com.netiq.idm.osp.url.host" ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | grep -v "{com.netiq.idm.osp.url.host}"
        RET=$?
        if [ ${RET} -ne 0 ]
        then
            if [ "$SSO_SERVER_SSL_PORT" == "443" ]
            then
                echo "com.netiq.idm.osp.url.host = https://$SSO_SERVER_HOST" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
            else
                echo "com.netiq.idm.osp.url.host = https://$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
            fi
        fi
    fi
    
    if [ ${IS_WRAPPER_CFG_INST} -ne 1 ]
    then
        if [ -f "${PASSCONF}" ]
        then
            rm "${PASSCONF}"
        fi
    fi
    
    if [ ${IS_WRAPPER_CFG_INST} -ne 1 ]
    then
        clean_pass_conf
        #backup_pass_conf
    fi

    remove_config_file ${CONFIGURE_FILE}
    addauditcachefiledir
    if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ]
    then
        systemctl restart netiq-tomcat
    fi
    
    if [ "$EXTERNAL_SSO_SERVER" == "y" ] && [ ! -f ${IDM_TOMCAT_HOME}/webapps/idmdash.war ]
    then
        rpm -e netiq-osp --nodeps &> /dev/null
    elif [ -n "${SSO_SERVER_HOST}" ] && [ "$RPT_OSP_INSTALLED" != "y" ]
    then
	    validateIP "${SSO_SERVER_HOST}"
        RET=$?

        if [ $RET -eq 1 ]
        then
            rpm -e netiq-osp --nodeps &> /dev/null
        fi
    fi
    if [ "$EXTERNAL_SSO_SERVER" == "n" ]
    then
    	rpm -qi netiq-osp &> /dev/null
	if [ $? -eq 0 ]
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
    fi
    [ $IS_UPGRADE -ne 1 ] && removeemptyConnectorPort
    if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
    then
      callremoveclientpass rpt
    fi
    encryptrptsslkeystorepwd
    grep -q ///idmdash ${ISM_CONFIG} &> /dev/null
    if [ $? -eq 0 ] && [ ! -z "$CONFIGURE_FILE_DIR" ] && [ ! -f $CONFIGURE_FILE_DIR/user_application ]
    then
      # user application is not configured, removing all related properties from ism-configuration.properties
      sed -i "/com.netiq.idmdash/d" ${ISM_CONFIG}
      sed -i "/com.netiq.idmadmin/d" ${ISM_CONFIG}
      sed -i "/com.netiq.rbpm/d" ${ISM_CONFIG}
      sed -i "/com.netiq.idm.ua/d" ${ISM_CONFIG}
      sed -i "/DirectoryService\/realms\/jndi\/params\/PROVISION_ROOT/d" ${ISM_CONFIG}
      sed -i "/com.microfocus.workflow/d" ${ISM_CONFIG}
      sed -i "/com.netiq.idm.forms/d" ${ISM_CONFIG}
      sed -i "/com.netiq.forms/d" ${ISM_CONFIG}
    else
      echo "Identity Applications configured" &> /dev/null
    fi
    ismPropertiesChangeUAandRPT
}

main $*
