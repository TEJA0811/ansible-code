#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

reporting_post_upgrade()
{
    rpm -qi netiq-tomcatconfig &> /dev/null
    if [ $? -eq 0 ]
    then
    	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
    else
    	INSTALLED_FOLDER_PATH=`grep -i 'TOMCAT_PARENT_DIR=' /etc/init.d/idmapps_tomcat_init | cut -d '=' -f2`
    fi
    get_rpt_host_port
    TOMCAT_SERVLET_HOSTNAME=$RPT_SERVER_HOSTNAME
    RPT_CONFIG_HOME=${INSTALLED_FOLDER_PATH}/IDMReporting

    strerr=`gettext install "Read Installed configuration"`
    readconfigproperties

    if [ -f /opt/rpt_upgrade.properties ]
    then
        sed -i 's#\\##g' /opt/rpt_upgrade.properties
        source /opt/rpt_upgrade.properties
    fi

    strerr=`gettext install "Tomcat: Configuration failed. Check configure logs for more details."`
    configure_tomcat
    check_errs $? $strerr
    RET=$?
    check_return_value $RET
    
    if [ "${IS_OSP_EXIST}" == "true" ] && [ $IS_UA_UPGRADED -eq 0 ]
    then
        upgrade_osp_configuration
        RET=$?
        check_return_value $RET
    else
        write_log "Skipping configuration of OSP for Reporting."
    fi
    
    #strerr=`gettext install "Auditing: Configuration failed. Check configure logs for more details."`
    #configure_auditing
    #check_errs $? $strerr
    #RET=$?
    #check_return_value $RET
    
    create_silent_property_file
    update_config_properties

    strerr=`gettext install "Configupdate: Updating Configupdate failed. Check logs for more details"`
    update_config_update
    check_errs $? $strerr
    RET=$?
    check_return_value $RET

     ###Woraround for now
     sed -i 's/-Dcom.netiq.idm.osp.audit.enabled=true/-Dcom.netiq.idm.osp.audit.enabled=false/g' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh

    strerr=`gettext install "Creating Roles and Schemas failed. Check logs for more details."`
    #configure_database
    RPT_DATABASE_NEW_OR_EXIST='exist'
if [ ! -z "$BLOCKED_CODE" ]
then
    configure_database_upgrade
    check_errs $? $strerr
    RET=$?
    check_return_value $RET
fi

    strerr=`gettext install "Configuring database failed. Check logs for more details."`
    #liquibase_database_schema
    RPT_DATABASE_NEW_OR_EXIST='exist'
if [ ! -z "$BLOCKED_CODE" ]
then
    liquibase_update
    check_errs $? $strerr
    RET=$?
    check_return_value $RET
fi

    strerr=`gettext install "Restore custom war files failed."`
    restore_other_wars
    restore_xmls
    grep -q "com.netiq.rpt.ssl-keystore" ${ISM_CONFIG}
    if [ $? -ne 0 ]
    then
      sed -i '/com.netiq.rpt.ssl-keystore/d' ${ISM_CONFIG}
      echo "com.netiq.rpt.ssl-keystore.file = /opt/netiq/idm/apps/tomcat/conf/idm.jks" >> ${ISM_CONFIG}
      echo "com.netiq.rpt.ssl-keystore.pwd._attr_obscurity = ENCRYPT" >> ${ISM_CONFIG}
      local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
      local ospoauthtruststorepwd=`grep -ir "com.netiq.idm.osp.oauth-truststore.pwd =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
      if [ -z $ospoauthtruststorepwd ] || [ "$ospoauthtruststorepwd" == "" ]
      then
        ospoauthtruststorepwd=changeit
	/opt/netiq/common/jre/bin/keytool -list -keystore /opt/netiq/idm/apps/tomcat/conf/idm.jks -storepass $ospoauthtruststorepwd | grep -i keystore | grep -i type | grep -q PKCS12
	RETPKCS=$?
	[ $RETPKCS -eq 0 ] && echo "com.netiq.rpt.ssl-keystore.type = PKCS12" >> ${ISM_CONFIG}
	[ $RETPKCS -ne 0 ] && echo "com.netiq.rpt.ssl-keystore.type = JKS" >> ${ISM_CONFIG}
	echo "com.netiq.rpt.ssl-keystore.pwd=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt $ospoauthtruststorepwd`" >> ${ISM_CONFIG}
      else
        grep "com.netiq.idm.osp.oauth-truststore.pwd._attr" ${ISM_CONFIG} | grep -q ENCRYPT
	if [ $? -eq 0 ]
	then
	  #then copy as is
	  echo "com.netiq.rpt.ssl-keystore.pwd=$ospoauthtruststorepwd" >> ${ISM_CONFIG}
	  decryptedospoauthtruststorepwd=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt $ospoauthtruststorepwd`
	  /opt/netiq/common/jre/bin/keytool -list -keystore /opt/netiq/idm/apps/tomcat/conf/idm.jks -storepass $decryptedospoauthtruststorepwd | grep -i keystore | grep -i type | grep -q PKCS12
	  RETPKCS=$?
	  [ $RETPKCS -eq 0 ] && echo "com.netiq.rpt.ssl-keystore.type = PKCS12" >> ${ISM_CONFIG}
	  [ $RETPKCS -ne 0 ] && echo "com.netiq.rpt.ssl-keystore.type = JKS" >> ${ISM_CONFIG}
	else
	  #encrypt and copy
	  /opt/netiq/common/jre/bin/keytool -list -keystore /opt/netiq/idm/apps/tomcat/conf/idm.jks -storepass $ospoauthtruststorepwd | grep -i keystore | grep -i type | grep -q PKCS12
	  RETPKCS=$?
	  [ $RETPKCS -eq 0 ] && echo "com.netiq.rpt.ssl-keystore.type = PKCS12" >> ${ISM_CONFIG}
	  [ $RETPKCS -ne 0 ] && echo "com.netiq.rpt.ssl-keystore.type = JKS" >> ${ISM_CONFIG}
	  echo "com.netiq.rpt.ssl-keystore.pwd=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt $ospoauthtruststorepwd`" >> ${ISM_CONFIG}
	fi
      fi
    fi

    #Restore client settings.
    if [ -d ${IDM_BACKUP_FOLDER}/tomcat/conf/clients ]
    then 
        cp -rpf ${IDM_BACKUP_FOLDER}/tomcat/conf/clients ${IDM_TOMCAT_HOME}/conf/
    fi
    
    if [ "$RPT_OSP_INSTALLED" == "n" ] && [ ! -f ${IDM_TOMCAT_HOME}/webapps/idmdash.war ]
    then
        sed -e "s/-Dcom.netiq.idm.osp.client.host=___TOMCAT_SERVLET_HOSTNAME___ //g" -i ${IDM_TOMCAT_HOME}/bin/setenv.sh
    fi
    if [ -z "$RPT_OSP_INSTALLED" ] && [ ! -f ${IDM_TOMCAT_HOME}/webapps/idmdash.war ]
    then
	rpm -e netiq-osp &> /dev/null
	rm -rf ${IDM_TOMCAT_HOME}/webapps/osp ${IDM_TOMCAT_HOME}/webapps/osp.war &> /dev/null
    fi

    if [ -d ${RPT_CONFIG_HOME} ]
    then
        chown -R novlua:novlua  ${RPT_CONFIG_HOME} >> "${log_file}" 2>&1
    fi

    if [ -d ${OSP_INSTALL_PATH} ]
    then
       /usr/bin/chown -R novlua:novlua ${OSP_INSTALL_PATH} >> "${log_file}" 2>&1
    fi
    #
    /usr/bin/chown -R novlua:novlua ${IDM_TOMCAT_HOME} >> "${log_file}" 2>&1
    sed -i.bak "s/rpt#6.5.0/rpt#6.6.0/g" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    idmdcsclientpass=$(grep -ir "com.netiq.idmdcs.clientPass =" ${ISM_CONFIG} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//')
    rptclientpass=$(grep -ir "com.netiq.rpt.clientPass =" ${ISM_CONFIG} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//')
    dcsdrvclientpass=$(grep -ir "com.netiq.dcsdrv.clientPass =" ${ISM_CONFIG} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//')
    if [ -z $idmdcsclientpass ] || [ "$idmdcsclientpass" == "" ]
    then
    	#Copying the com.netiq.dcsdrv.clientPass clientpass to idmdcs.clientPass when found empty or null
	sed -i '/com.netiq.idmdcs.clientPass =/d' ${ISM_CONFIG}
	sed -i '/com.netiq.idmdcs.clientPass=/d' ${ISM_CONFIG}
	echo "com.netiq.idmdcs.clientPass = $dcsdrvclientpass" >> ${ISM_CONFIG}
    fi
    if [ ! -z $idmdcsclientpass ] && [ "$idmdcsclientpass" != "" ] && [ ! -z $rptclientpass ] && [ "$rptclientpass" != "" ]
    then
    	if [ "$idmdcsclientpass" == "$rptclientpass" ]
	then
		#Copying the com.netiq.dcsdrv.clientPass clientpass to idmdcs.clientPass when password is found same as rpt since it may have space at the end
		sed -i '/com.netiq.idmdcs.clientPass =/d' ${ISM_CONFIG}
		sed -i '/com.netiq.idmdcs.clientPass=/d' ${ISM_CONFIG}
		echo "com.netiq.idmdcs.clientPass = $dcsdrvclientpass" >> ${ISM_CONFIG}
	fi
    fi
	local installed_keystore_path=`grep -ir "com.netiq.idm.osp.oauth-truststore.file" ${ISM_CONFIG} | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//'`
	local ospoauthtruststorepwd=`grep -ir "com.netiq.idm.osp.oauth-truststore.pwd =" ${ISM_CONFIG} | awk '{print $3}' | sed 's/^[ ]*//'`
	RETPKCS=1
	if [ -z $ospoauthtruststorepwd ] || [ "$ospoauthtruststorepwd" == "" ]
	then
		ospoauthtruststorepwd=changeit
		$IDM_JRE_HOME/bin/keytool -list -keystore $installed_keystore_path -storepass $ospoauthtruststorepwd | grep -i keystore | grep -i type | grep -q PKCS12
		RETPKCS=$?
	else
		grep "com.netiq.idm.osp.oauth-truststore.pwd._attr" ${ISM_CONFIG} | grep -q ENCRYPT
		if [ $? -eq 0 ]
		then
			#Password encrypted
			decryptedospoauthtruststorepwd=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil decrypt $ospoauthtruststorepwd`
			$IDM_JRE_HOME/bin/keytool -list -keystore $installed_keystore_path -storepass $decryptedospoauthtruststorepwd | grep -i keystore | grep -i type | grep -q PKCS12
			RETPKCS=$?
		else
			#Password not encrypted
			$IDM_JRE_HOME/bin/keytool -list -keystore $installed_keystore_path -storepass $ospoauthtruststorepwd | grep -i keystore | grep -i type | grep -q PKCS12
			RETPKCS=$?
		fi
	fi
	grep -q com.netiq.idm.ua.ldap.edit.keystore-type ${ISM_CONFIG}
	if [ $? -ne 0 ]
	then
		[ $RETPKCS -eq 0 ] && echo "com.netiq.idm.ua.ldap.edit.keystore-type = PKCS12" >> ${ISM_CONFIG}
		[ $RETPKCS -ne 0 ] && echo "com.netiq.idm.ua.ldap.edit.keystore-type = JKS" >> ${ISM_CONFIG}
	fi
    if [ -f "${IDM_BACKUP_FOLDER}/osp/osp.jks" ] && [ -d "${OSP_INSTALL_PATH}" ]
    then
        cp -p "${IDM_BACKUP_FOLDER}/osp/osp.jks" "${OSP_INSTALL_PATH}/osp.jks"
    fi
}
