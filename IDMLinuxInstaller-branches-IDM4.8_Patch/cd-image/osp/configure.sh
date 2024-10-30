#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../

. ../common/scripts/common_install_vars.sh
. ../common/scripts/common_install_error.sh
. ../common/scripts/install_common_libs.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/multi_select.sh

. ../common/scripts/jre.sh
. ../common/scripts/tomcat.sh
. ../common/scripts/postgres.sh
. ../common/scripts/activemq.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/prompts.sh
. ../common/scripts/ldap_utils.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/install_check.sh
. ../common/scripts/locale.sh
. ../common/scripts/dxcmd_util.sh
. ../user_application/scripts/ua_configure.sh

. scripts/osp_configure.sh
. scripts/pre_install.sh


LOG_FILE_NAME=/var/opt/netiq/idm/log/idmconfigure.log

initLocale

main()
{
    parse_install_params $*
    set_log_file $LOG_FILE_NAME   
    init
    create_IP_cfg_file_conditionally
    check_installed_components
    config_mode
    init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf $IS_ADVANCED_MODE
    process_prompts "OSP" $IS_OSP_INSTALLED
	
    import_vault_certificates    
    ##TODO : Fix the packages and remove this workaround
    ## DO NOT remove this unless you know the side-effect
    touch /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
    cp ${IDM_INSTALL_HOME}/common/packages/utils/*.jar /opt/netiq/idm/apps/tomcat/lib/ >>$LOG_FILE_NAME 
    mkdir -p /opt/netiq/idm/apps/tomcat/logs >> $LOG_FILE_NAME
    chown -R novlua:novlua /opt/netiq/idm/apps/tomcat/ >>$LOG_FILE_NAME

    #update_configupdate_script
    configure_setenv
    strerr=`gettext install "Configuration of Configupdate/ism-configuration failed"`
    configure_props
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    strerr=`gettext install "Creation of One SSO Provider keystore failed"`
    create_osp_keystore 
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

    modify_server_xml

    #disable the osp auditing
    sed -i 's/-Dcom.netiq.idm.osp.audit.enabled=true/-Dcom.netiq.idm.osp.audit.enabled=false/g' ${IDM_TOMCAT_HOME}/bin/setenv.sh
    
    ##
	

    if [ $IS_WRAPPER_CFG_INST -eq 0 ] && [ ${SKIP_PROMPTS} -ne 1 ]
    then
        clean_pass_conf
        backup_prompt_conf
    fi
    changeToCustomName
    if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == "y" ]
    then
    	[ -f $IDM_TEMP/input.properties ] && cp $IDM_TEMP/input.properties /tmp/input.properties.OSP &> /dev/null
    fi
    if [ ! -z $ENABLE_STANDALONE ] && [ $IS_ADVANCED_MODE == "true" ]
    then
	if [ ! -z $IDM_TEMP ] && [ ! -d $IDM_TEMP ]
	then
		mkdir -p $IDM_TEMP
		removetemplater=true
	fi
	if [ "$CUSTOM_OSP_CERTIFICATE" == "n" ]
	then
		create_ks_from_kmo ${ID_VAULT_HOST} ${ID_VAULT_LDAPS_PORT} ${ID_VAULT_ADMIN_LDAP} ${ID_VAULT_PASSWORD} dirxml $TOMCAT_SSL_KEYSTORE_PASS >> $LOG_FILE_NAME
        	cp -rpf ${IDM_TEMP}/tomcat.ks ${IDM_TOMCAT_HOME}/conf/
	else
		# copying the given keystore file as tomcat.ks
		cp $OSP_COMM_TOMCAT_KEYSTORE_FILE ${IDM_TOMCAT_HOME}/conf/tomcat.ks
	fi
	systemctl restart netiq-tomcat >> "${LOG_FILE_NAME}" 2>&1
	if [ $? -ne 0 ]
	then
		su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh" >> "${LOG_FILE_NAME}" 2> /dev/null
		su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh" >> "${LOG_FILE_NAME}" 2>&1
	fi
	if [ ! -z $removetemplater ] && [ $removetemplater == "true" ]
	then
		rm -rf $IDM_TEMP
		removetemplater=
	fi
    fi
    if [ ! -z $EXCLUSIVE_SSO ] && [ "$EXCLUSIVE_SSO" == "true" ]
    then
    	#addtruststorepasswordTosetenv
	removetruststoreentryfromsetenv
	addcheckrevocationTosetenv
	addcrldpTosetenv
	addlogbackTosetenv
	if [ "${ENABLE_CUSTOM_CONTAINER_CREATION}" == "y" ]
	then
		local ldif_file=${CUSTOM_CONTAINER_LDIF_PATH}
		new_import_ldif "$ldif_file"
	else
	  if [ ! -z "$EDIRAPI_PROMPT_NEEDED" ] && [ "$EDIRAPI_PROMPT_NEEDED" == "y" ]
	  then
	  	echo "No need to import anything here" &> /dev/null
	  else
		local ldif_file=$IDM_INSTALL_HOME/user_application/ldif/base_containers.ldif
		new_import_ldif "$ldif_file"
	  fi
	fi
	#block_clear_port_OSP
	sed -i.bak "s#<Connector port=\"\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" />#<Connector port=\"8180\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" />#g" "${IDM_TOMCAT_HOME}/conf/server.xml"
	sed -i.bak "s#<Connector port=\"8109\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />#<Connector port=\"8109\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />#g" "${IDM_TOMCAT_HOME}/conf/server.xml"
    	RestrictAccess
	changeownershipofAppsAndACMQ
	addauditcachefiledir
	#su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/shutdownUA.sh" >> "${LOG_FILE_NAME}" 2> /dev/null
	su -l novlua -c "/opt/netiq/idm/apps/tomcat/bin/startUA.sh" >> "${LOG_FILE_NAME}" 2>&1
    fi
}

#This method changes the osp login screen name to the custom name entered by the user
changeToCustomName()
{
	csspath=/opt/netiq/idm/apps/tomcat/webapps/osp/css
	tempOspJar=/tmp/ospjar
	tempOspWar=/tmp/ospwar
	
	rm -rf $tempOspJar
	mkdir $tempOspJar
	
	rm -rf $tempOspWar
	mkdir $tempOspWar
	
	myhome=/opt/netiq/idm/apps/osp/osp-extras/l10n-resources
	tomcatlib=/opt/netiq/idm/apps/tomcat/lib/
	ospwar=/opt/netiq/idm/apps/tomcat/webapps
	
	cd $tempOspJar
	unzip $myhome/osp-custom-resource.jar &> /dev/null 
	
	cd resources
	loginname="${OSP_CUSTOM_NAME}"
	loginname=`echo "$loginname" | sed 's/ /[nbsp]/g'`
	filetobechanged=oidp_enduser_custom_resources_en_US.properties
	
	search_and_replace "#OIDPENDUSER.LoginProductName=Company[nbsp]Name[reg]" "OIDPENDUSER.LoginProductName=$loginname" $filetobechanged
	#search_and_replace "#OIDPENDUSER.LoginBrowserTitle=Company[nbsp]Name[reg]" "OIDPENDUSER.LoginBrowserTitle=$loginname" $filetobechanged
	#search_and_replace "#OIDPENDUSER.AuthBrowserTitle=Company[nbsp]Name[reg]" "OIDPENDUSER.AuthBrowserTitle=$loginname" $filetobechanged
	
	cd ..
	zip -r osp-custom-resource.jar * &> /dev/null
	chmod +x osp-custom-resource.jar &> /dev/null
	
	cp $tempOspJar/osp-custom-resource.jar $myhome &> /dev/null
	cp $tempOspJar/osp-custom-resource.jar $tomcatlib &> /dev/null
	
	#systemctl restart netiq-tomcat
	
	cd $tempOspJar
	cd ..
	rm -rf ospjar
	
	cd $tempOspWar
	unzip $ospwar/osp.war &> /dev/null
	cd css
	echo ".dialog-header-content { text-align: center; }" >> uistyles.css
	cd ..
	zip -r osp.war * &> /dev/null
	chmod +x osp.war &> /dev/null
	cp $tempOspWar/osp.war $ospwar &> /dev/null

	cd $tempOspWar
	cd ..
	rm -rf ospwar
	[ $IS_UPGRADE -ne 1 ] && removeemptyConnectorPort
	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	then
		callencryptclientpass
		if [ ! -z "$RPT_PROMPT_NEEDED" ] && [ "$RPT_PROMPT_NEEDED" != "y" ]
		then
		  sed -i "/com.netiq.rpt/d" ${ISM_CONFIG}
		  sed -i "/com.netiq.idmdcs/d" ${ISM_CONFIG}
		  sed -i "/com.netiq.dcsdrv/d" ${ISM_CONFIG}
		  sed -i "/sso_apps/d" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
		  echo "sso_apps=ua" >> ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
		fi
		if [ ! -z "$SSPR_PROMPT_NEEDED" ] && [ "$SSPR_PROMPT_NEEDED" != "y" ]
		then
		  sed -i "/com.netiq.sspr/d" ${ISM_CONFIG}
		  sed -i "/com.netiq.idm.pwdmgt.provider/d" ${ISM_CONFIG}
		  sed -i "/com.netiq.idm.osp.login.sign-in-help-url/d" ${ISM_CONFIG}
		fi
		if [ ! -z "$UA_PROMPT_NEEDED" ] && [ "$UA_PROMPT_NEEDED" != "y" ]
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
		if [ ! -z "$EDIRAPI_PROMPT_NEEDED" ] && [ "$EDIRAPI_PROMPT_NEEDED" == "n" ]
		then
		  isAdvEdition=`is_advanced_edition "${ID_VAULT_HOST}" "${ID_VAULT_LDAPS_PORT}" "${ID_VAULT_ADMIN_LDAP}" "${ID_VAULT_PASSWORD}"`
		  if [ ${isAdvEdition} -ne 1 ]
		  then
		    #standard edition
		    sed -i -r 's/edition=advanced/edition=standard/' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
			sed -i -r 's/sso_apps=ua,rpt/sso_apps=rpt/' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
		  fi
		fi
	fi
}

main $*

