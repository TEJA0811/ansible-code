#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

configure_tomcat()
{
    chown -R novlua:novlua ${IDM_TOMCAT_HOME} >> "$LOG_FILE_NAME" 2>&1
    modify_server_xml
    modify_context_xml	
    #addtruststorepasswordTosetenv
    removetruststoreentryfromsetenv
    addcheckrevocationTosetenv
    addlogbackTosetenv
}


modify_context_xml()
{
    str1=`gettext install "Modifying Tomcat context.xml"`
    write_and_log "$str1"
    if [ $IS_UPGRADE -eq 1 ]
    then
        if [ -f ${IDM_BACKUP_FOLDER}/tomcat/conf/context.xml ]
	   then
                  cp -p ${IDM_BACKUP_FOLDER}/tomcat/conf/context.xml ${IDM_TOMCAT_HOME}/conf/
                  #
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMRPTCfgUpdateSource']"`
                  write_log "XML_MOD Response : ${result}"
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMRPTCfgDataSource']"`
                  write_log "XML_MOD Response : ${result}"
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMRPTDataSource']"`
                  write_log "XML_MOD Response : ${result}"
	   fi
    fi
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="shared/IDMDCSDataSource" name="jdbc/IDMDCSDataSource" type="javax.sql.DataSource"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"

    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="shared/IDMRPTCfgUpdateSource" name="jdbc/IDMRPTCfgUpdateSource" type="javax.sql.DataSource"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"

    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="shared/IDMRPTDataSource" name="jdbc/IDMRPTDataSource" type="javax.sql.DataSource"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"
}


modify_server_xml()
{
    str1=`gettext install "Modifying Tomcat server.xml"`
    write_and_log "$str1"
    
    if [ $IS_UPGRADE -eq 1 ]
    then
        if [ -f ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml ]
	   then
                  cp -p ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml ${IDM_TOMCAT_HOME}/conf/
                  #
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]/Resource[@name='shared/IDMRPTCfgUpdateSource']"`
                  write_log "XML_MOD Response : ${result}"
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]/Resource[@name='shared/IDMRPTCfgDataSource']"`
                  write_log "XML_MOD Response : ${result}"
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]/Resource[@name='shared/IDMRPTDataSource']"`
                  write_log "XML_MOD Response : ${result}"
				  

	   fi
    fi
    if [ $IS_UPGRADE -eq 1 ]
    then
        RPT_DATABASE_SHARE_PASSWORD=${RPT_DATABASE_PASSWORD}
    fi
    
    if [ $IS_UPGRADE -eq 1 ]
    then
        get_rpt_host_port
    else
        RPT_SERVER_PORT=$RPT_TOMCAT_HTTPS_PORT
    fi
    local PWD=`$IDM_JRE_HOME/bin/java -jar $IDM_TOMCAT_HOME/lib/idm-datasource-factory-uber.jar ${RPT_DATABASE_SHARE_PASSWORD}`

    if [ ! -z "$TOMCAT_HTTP_PORT" ] && [ "$TOMCAT_HTTP_PORT" != "" ]
    then
      result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "$TOMCAT_HTTP_PORT"`
    else
      result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "80"`
    fi
    write_log "XML_MOD Response : ${result}"
    if [ ! -z "$RPT_SERVER_PORT" ] && [ "$RPT_SERVER_PORT" != "" ]
    then
      result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@redirectPort='8443']/@redirectPort" "$RPT_SERVER_PORT"`
    else
      result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@redirectPort='8443']/@redirectPort" "443"`
    fi
    write_log "XML_MOD Response : ${result}"
    if [ ! -z "$RPT_SERVER_PORT" ] && [ "$RPT_SERVER_PORT" != "" ]
    then
      result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8443']/@port" "$RPT_SERVER_PORT"`
    else
      result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8443']/@port" "443"`
    fi
    write_log "XML_MOD Response : ${result}"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8009']/@port" "8109"`
    write_log "XML_MOD Response : ${result}"

    if [ $IS_UPGRADE -eq 1 ]
    then
        if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
        then
        	    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
        <Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTCfgUpdateSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_cfg" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"

            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMDCSDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_data" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
    
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
        <Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idmrptuser" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
        elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
	   then
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
        <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTCfgUpdateSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_cfg" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
            write_and_log "XML_MOD Response : ${result}"

            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
        <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMDCSDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_data" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
            write_and_log "XML_MOD Response : ${result}"
    
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idmrptuser" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
            write_and_log "XML_MOD Response : ${result}"
        elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
        then
        	    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
        <Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTCfgUpdateSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_cfg" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"

            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMDCSDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_data" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
    
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
        <Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idmrptuser" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
	    fi
    elif [ $IS_UPGRADE -ne 1 ]
    then
        if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
        then
	       result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTCfgUpdateSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}" username="idm_rpt_cfg" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"

            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMDCSDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}" username="idm_rpt_data" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
    
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}" username="idmrptuser" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
        elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
	then
               if [ "${RPT_ORACLE_DATABASE_TYPE}" == "service" ]
	       then
                RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
	       elif [ "${RPT_ORACLE_DATABASE_TYPE}" == "sid" ]
	       then
                RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}:${RPT_DATABASE_NAME}"
	       fi
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTCfgUpdateSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_cfg" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
            write_and_log "XML_MOD Response : ${result}"

            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMDCSDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_data" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
            write_and_log "XML_MOD Response : ${result}"
    
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idmrptuser" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
            write_and_log "XML_MOD Response : ${result}"
        elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
        then
		RPT_DATABASE_CONNECTION_URL="jdbc:sqlserver://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT};DatabaseName=${RPT_DATABASE_NAME}"
	       result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTCfgUpdateSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_cfg" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"

            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMDCSDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idm_rpt_data" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
    
            result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
            <Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxIdle="10" maxTotal="50" maxWaitMillis="30000" minIdle="10" name="shared/IDMRPTDataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${RPT_DATABASE_CONNECTION_URL}" username="idmrptuser" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
            write_log "XML_MOD Response : ${result}"
	fi
    fi
	#Keystore password can be reset only for fresh installation
    if [ $IS_UPGRADE -ne 1 ]
    then
	  keystorePassToCustom_RPT
    fi

    setTLSv12_RPT
}

update_config_properties()
{
    local prop_file=${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    rpm -qi netiq-userapp &> /dev/null
    if [ $? -ne 0 ]
    then 
    sed -i -r 's/edition=advanced/edition=standard/' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    fi 
    search_and_replace "\$NOVL_JAVA_HOME\$"  $IDM_JRE_HOME "$prop_file"
    search_and_replace "\$NOVL_APPLICATION_NAME\$"  $RPT_APP_CTX "$prop_file"
    search_and_replace "\$NOVL_TOMCAT_BASE_FOLDER\$"  $IDM_TOMCAT_HOME "$prop_file"
    search_and_replace "\$USER_INSTALL_DIR\$"  $RPT_CONFIG_HOME "$prop_file"
    #TODO: Pick lang from locale
    search_and_replace "\$NOVL_USER_LANGUAGE\$"  "en" "$prop_file"
    search_and_replace "\$NOVL_USER_COUNTRY\$"  "-" "$prop_file"
    search_and_replace "\$NOVL_UA_CONFIG_FILE_NAME\$"  "ism-configuration.properties" "$prop_file"
    search_and_replace "\$NOVL_CONFIGUPDATE_USE_CONSOLE_FLAG\$"  "false" "$prop_file"
    search_and_replace "\$DOLLAR\$"  "\$" "$prop_file"
    search_and_replace "\$NOVL_UA_EDIT_ADMIN_FLAG\$"  "false" "$prop_file"
    search_and_replace "\$USER_INSTALL_DIR\$"  "$CONFIG_UPDATE_HOME" "$prop_file"
    if [ ! -z "$isAdvEdition" ] && [ $isAdvEdition -eq 0 ]
    then
        sed -i 's/\(^edition=\).*/\1"standard"/' "$prop_file"
    fi
}

get_rpt_host_port()
{
    local backup_ism_file=${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties
    local RPTURL=`grep -ir "com.netiq.rpt.authserver.url =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    if [ -z "${RPTURL}" ]
    then
        local RPTURL=`grep -ir "com.netiq.rpt.redirect.url =" ${backup_ism_file} | awk '{print $3}' | sed 's/^[ ]*//'`
    fi

    PROTO="`echo $RPTURL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
    URL=`echo $RPTURL | sed -e s,$PROTO,,g`
    RPT_SERVER_HOSTNAME="$(echo $URL | grep : | cut -d: -f1)"
    if [ -z ${RPT_SERVER_HOSTNAME} ]
    then
      RPT_SERVER_HOSTNAME="$(echo $URL | grep / | cut -d/ -f1)"
      if [ -z ${RPT_SERVER_HOSTNAME} ]
      then
        RPT_SERVER_HOSTNAME=$URL
      fi
      RPT_SERVER_PORT=
    else
      RPT_SERVER_PORT=$(echo $URL | sed -e s,$RPT_SERVER_HOSTNAME:,,g | cut -d/ -f1)
    fi
    SSO_SERVER_HOST=$RPT_SERVER_HOSTNAME
    SSO_SERVER_PORT=$RPT_SERVER_PORT
}

create_silent_property_file()
{
    str1=`gettext install "Creating configurations files "`
    write_and_log "$str1"
    cp ${IDM_INSTALL_HOME}reporting/configupdate.properties $IDM_TEMP/ >>$LOG_FILE_NAME
    local prop_file=$IDM_TEMP/configupdate.properties

    if [ $IS_UPGRADE -eq 1 ]
    then
        get_rpt_host_port
	   echo "${PROTO}" | grep -w "https://"
	   RET=$?

	   if [ $RET -eq 1 ]
	   then
            search_and_replace "https"  "http" "$prop_file"
	   fi
	   echo "com.netiq.idmdcs.clientPass._attr_obscurity = ENCRYPT" >> "$prop_file"
    else
        RPT_SERVER_PORT=$RPT_TOMCAT_HTTPS_PORT
    fi
    if [ ! -z "$EXTERNAL_SSO_SERVER" ] && [ "$EXTERNAL_SSO_SERVER" == "y" ]
    then
      grep -q com.netiq.idm.osp.url.host $prop_file | grep -v "{com.netiq.idm.osp.url.host}" &> /dev/null
      ospurlhostret=$?
      if [ ! -z "$SSO_SERVER_SSL_PORT" ] && [ "$SSO_SERVER_SSL_PORT" != "" ]
      then
	if [ $ospurlhostret -ne 0 ]
	then
	  echo "com.netiq.idm.osp.url.host = https://$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT" >> $prop_file
	fi
      else
        if [ $ospurlhostret -ne 0 ]
	then
	  echo "com.netiq.idm.osp.url.host = https://$SSO_SERVER_HOST" >> $prop_file
	fi
      fi
    fi
    search_and_replace "___RPT_SERVER_IP___"  "$RPT_SERVER_HOSTNAME" "$prop_file"
    if [ ! -z "$RPT_SERVER_PORT" ] && [ "$RPT_SERVER_PORT" != "" ]
    then
      search_and_replace "___RPT_SERVER_PORT___"  "$RPT_SERVER_PORT" "$prop_file"
    else
      search_and_replace ":___RPT_SERVER_PORT___"  "$RPT_SERVER_PORT" "$prop_file"
    fi
    search_and_replace "___SSPR_IP___"  "$SSPR_SERVER_HOST" "$prop_file"
    if [ ! -z "$SSPR_SERVER_SSL_PORT" ] && [ "$SSPR_SERVER_SSL_PORT" != "" ]
    then
      search_and_replace "___SSPR_TOMCAT_HTTPS_PORT___"  "$SSPR_SERVER_SSL_PORT" "$prop_file"
    else
      search_and_replace ":___SSPR_TOMCAT_HTTPS_PORT___"  "$SSPR_SERVER_SSL_PORT" "$prop_file"
    fi
    search_and_replace "___ID_VAULT_ADMIN___"  "$ID_VAULT_ADMIN_LDAP" "$prop_file"
    search_and_replace "___ID_VAULT_PASSWORD___"  "$ID_VAULT_PASSWORD" "$prop_file"
    search_and_replace "___DRIVERSET_NAME___"  "$ID_VAULT_DRIVER_SET" "$prop_file"
    search_and_replace "___AUTH_SERVER_IP___"  "$SSO_SERVER_HOST" "$prop_file"
    if [ ! -z "$SSO_SERVER_SSL_PORT" ] && [ "$SSO_SERVER_SSL_PORT" != "" ]
    then
      search_and_replace "___AUTH_SERVER_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
    else
      search_and_replace ":___AUTH_SERVER_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
    fi
    search_and_replace "___SSO_SERVICE_PWD___"  "$RPT_SSO_SERVICE_PWD" "$prop_file"
    search_and_replace "___IDM_KEYSTORE_PWD___"  "$IDM_KEYSTORE_PWD" "$prop_file"
    if [ ! -z $RPT_SMTP_SERVER ]
    then
        search_and_replace "___SMTP_SERVER_IP___"  $RPT_SMTP_SERVER "$prop_file"
    else
        sed '/___SMTP_SERVER_IP___/d' $prop_file > $IDM_TEMP/configupdate_1.properties
	   cp -p $IDM_TEMP/configupdate_1.properties $IDM_TEMP/configupdate.properties
    fi
    if [ ! -z $RPT_SMTP_SERVER_PORT ]
    then
        search_and_replace "___SMTP_SERVER_PORT___"  "$RPT_SMTP_SERVER_PORT" "$prop_file"
    else
        sed '/___SMTP_SERVER_PORT___/d' $prop_file > $IDM_TEMP/configupdate_1.properties
	   cp -p $IDM_TEMP/configupdate_1.properties $IDM_TEMP/configupdate.properties
    fi
    search_and_replace "___DEFAULT_EMAIL___"  "$RPT_DEFAULT_EMAIL_ADDRESS" "$prop_file"
}

deleteclientpasswhenfound()
{
	grep com.netiq.rpt.clientPass ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	[ $? -eq 0 ] &&  sed -i '/com.netiq.rpt.clientPass/d' $IDM_TEMP/configupdate.properties
	grep com.netiq.dcsdrv.clientPass ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	[ $? -eq 0 ] &&  sed -i '/com.netiq.dcsdrv.clientPass/d' $IDM_TEMP/configupdate.properties
	grep com.netiq.idmdcs.clientPass ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	[ $? -eq 0 ] &&  sed -i '/com.netiq.idmdcs.clientPass/d' $IDM_TEMP/configupdate.properties
	grep com.netiq.idm.osp.oauth-truststore.pwd ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	[ $? -eq 0 ] &&  sed -i '/com.netiq.idm.osp.oauth-truststore.pwd/d' $IDM_TEMP/configupdate.properties
	grep com.netiq.rpt.ssl-keystore.pwd ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	[ $? -eq 0 ] &&  sed -i '/com.netiq.rpt.ssl-keystore.pwd/d' $IDM_TEMP/configupdate.properties
	grep com.netiq.sspr.clientPass ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties &> /dev/null
	[ $? -eq 0 ] &&  sed -i '/com.netiq.sspr.clientPass/d' $IDM_TEMP/configupdate.properties
}
update_config_update()
{
    write_log "Updating ISM configurations "
    local prop_file=${CONFIG_UPDATE_HOME}/configupdate.sh.properties

    if [ $IS_UPGRADE -eq 1 ]
    then
        if [ -f ${IDM_BACKUP_FOLDER}/tomcat/conf/ism-configuration.properties ]
        then
	       if [ -f ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties ]
		  then
		  yes | cp ${IDM_BACKUP_FOLDER}/ism-configuration.properties ${IDM_TEMP}/
	          sed -i.bak 's#\\#\\\\#g' ${IDM_TEMP}/ism-configuration.properties
		  if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == "y" ]
		  then
		    cp ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties /tmp/ism-configuration.properties.justbefore-merge
		  fi
                merge_ism_props ${IDM_TEMP}/ism-configuration.properties ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties >>$LOG_FILE_NAME  2>&1
		  if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == "y" ]
		  then
		    cp ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties /tmp/ism-configuration.properties.justafter-merge
		  fi
	       else
                cp -p ${IDM_BACKUP_FOLDER}/ism-configuration.properties ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	       fi
        fi
	if [ ! -z "$UPGRADE_OSP_CONFIGURATION" ] && [ "$UPGRADE_OSP_CONFIGURATION" == "true" ]
	then
	  grep "com.netiq.idm.osp.localhost-auto-add" ${ISM_CONFIG} &> /dev/null
	  if [ $? -eq 0 ]
	  then
	    sed -i "/com.netiq.idm.osp.localhost-auto-add/d" ${ISM_CONFIG}
	    echo "com.netiq.idm.osp.localhost-auto-add = true" >> ${ISM_CONFIG}
	  fi
	fi
        sed -i 's/\(^com.netiq.rpt.iglookandfeel.enabled\).*/\1 = true/' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	grep -q no_nam_oauth $prop_file
	[ $? -ne 0 ] && echo "no_nam_oauth=\"false\"" >> $prop_file
	grep -q "^is_prov=\"true\"" $prop_file &> /dev/null
	oldadvedition=$?
	grep -q ^edition=advanced $prop_file &> /dev/null
	newadvedition=$?
	grep -q app_versions $prop_file
	if [ $? -ne 0 ]
	then
	  if [ $oldadvedition -eq 0 ] || [ $newadvedition -eq 0 ]
	  then
	    echo "app_versions=\"ua#4.8.0,rpt#6.5.0\"" >> $prop_file
	  else
	    echo "app_versions=\"rpt#6.5.0\"" >> $prop_file
	  fi
	fi
	configupdate_idm
	grep -q "com.netiq.idm.session-timeout" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.session-timeout=1200" >> ${ISM_CONFIG}
    else
        local currentDir=`pwd`
        cd ${CONFIG_UPDATE_HOME}
        touch framework-config_3_0.dtd
        [ ! -f ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties ] && touch ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	   cp -p ${IDM_INSTALL_HOME}reporting/conf/password_attr_obscurity.properties ${IDM_TEMP}/password_attr_obscurity.properties
	deleteclientpasswhenfound
        merge_ism_props ${IDM_TEMP}/password_attr_obscurity.properties ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties >>$LOG_FILE_NAME  2>&1
	if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == 'y' ]
	then
		cp $IDM_TEMP/configupdate.properties /tmp/configupdate.properties.RPT.beforeCU
		cp /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties /tmp/ism-configuration.properties.RPT.beforeCU
	fi
        ./configupdate.sh --silent $IDM_TEMP/configupdate.properties >>$LOG_FILE_NAME  2>&1
	sed -i '/com.netiq.idm.osp.login.sign-in-help-url/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	if [ ! -z "$SSPR_SERVER_SSL_PORT" ] && [ "$SSPR_SERVER_SSL_PORT" != "" ]
	then
	  echo "com.netiq.idm.osp.login.sign-in-help-url = https://$SSPR_SERVER_HOST:$SSPR_SERVER_SSL_PORT/sspr/public" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	else
	  echo "com.netiq.idm.osp.login.sign-in-help-url = https://$SSPR_SERVER_HOST/sspr/public" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	fi
	sed -i '/com.netiq.client.authserver.url.authorize/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	sed -i '/com.netiq.client.authserver.url.token/d' ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	if [ ! -z "$SSO_SERVER_SSL_PORT" ] && [ "$SSO_SERVER_SSL_PORT" != "" ]
	then
	  echo "com.netiq.client.authserver.url.authorize = https://$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT/osp/a/idm/auth/oauth2/grant" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	  echo "com.netiq.client.authserver.url.token = https://$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT/osp/a/idm/auth/oauth2/getattributes" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	else
	  echo "com.netiq.client.authserver.url.authorize = https://$SSO_SERVER_HOST/osp/a/idm/auth/oauth2/grant" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	  echo "com.netiq.client.authserver.url.token = https://$SSO_SERVER_HOST/osp/a/idm/auth/oauth2/getattributes" >> ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
	fi
	# May need to remove later
	SSO_SERVICE_PWD=$RPT_SSO_SERVICE_PWD
	callencryptclientpass

        cd $currentDir
	if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == 'y' ]
	then
	        cp $IDM_TEMP/configupdate.properties /tmp/configupdate.properties.RPT
		[ -f /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties ] && cp /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties /tmp/ism-configuration.properties.RPT
	fi
        rm $IDM_TEMP/configupdate.properties >>$LOG_FILE_NAME  2>&1
        chown -R novlua:novlua /opt/netiq/idm/apps/tomcat >>$LOG_FILE_NAME 
	sed -i.bak "s/rpt#6.6.0/rpt#6.5.0/g" ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    fi
    [ $IS_UPGRADE -eq 1 ] && get_rpt_osp_host_port
    grep -q com.netiq.idm.osp.oauth.issuer ${ISM_CONFIG}
    if [ $? -ne 0 ]
    then
      sed -i '/com.netiq.idm.osp.oauth.issuer/d' ${ISM_CONFIG}
      PROTO=https://
      if [ ! -z ${SSO_SERVER_SSL_PORT} ] && [ "${SSO_SERVER_SSL_PORT}" != "" ]
      then
        echo "com.netiq.idm.osp.oauth.issuer = ${PROTO}${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}/osp/a/idm/auth/oauth2" >> ${ISM_CONFIG}
      else
        echo "com.netiq.idm.osp.oauth.issuer = ${PROTO}${SSO_SERVER_HOST}/osp/a/idm/auth/oauth2" >> ${ISM_CONFIG}
      fi
    fi
}

forAzurePGSSL()
{
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
}

configure_database()
{
    str1=`gettext install "Configuring database"`
    write_and_log "$str1"

    #Incase of upgrade we will read the database configuration from server.xml file
    if [ ${IS_UPGRADE} -ne 1 ]
    then
      # Based on the selected database we have to create the schema
      if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
      then
        RPT_DATABASE_DRIVER_CLASS="liquibase.database.core.PostgresDatabase"
        RPT_DATABASE_CONNECTION_URL="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}?compatible=true"
        if [ ! -z $AZURE_POSTGRESQL_REQUIRED ] && [[ "$AZURE_POSTGRESQL_REQUIRED" == "y" || "$AZURE_POSTGRESQL_REQUIRED" == "true" ]]
        then
          RPT_DATABASE_CONNECTION_URL="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}?compatible=true&ssl=true"
        fi
      elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
      then
        RPT_DATABASE_DRIVER_CLASS="liquibase.database.ext.OracleUnicodeDatabase"
        if [ "${RPT_ORACLE_DATABASE_TYPE}" == "service" ]
	   then
            RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
	   elif [ "${RPT_ORACLE_DATABASE_TYPE}" == "sid" ]
	   then
            RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}:${RPT_DATABASE_NAME}"
	   fi
      elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
      then
        RPT_DATABASE_DRIVER_CLASS="com.novell.soa.persist.MSSQLUnicodeDatabase"
        RPT_DATABASE_CONNECTION_URL="jdbc:sqlserver://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT};DatabaseName=${RPT_DATABASE_NAME}"
      fi
    fi

    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
    then
        if [ $IS_UA_INSTALLED == "false"  ]
        then
	       echo postgres:${RPT_DATABASE_SHARE_PASSWORD}| /usr/sbin/chpasswd >> "${LOG_FILE_NAME}" 2>&1
            mkdir ${POSTGRES_HOME}/data &> /dev/null
            mkdir /home/users/postgres &> /dev/null
		  chown -R postgres:postgres ${POSTGRES_HOME} &> /dev/null
		  chown -R postgres:postgres /home/users/postgres &> /dev/null
		  su -s /bin/sh - postgres -c "ls" &> /dev/null
		  if [ $? -eq 0 ]
		  then
		    su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH ${POSTGRES_HOME}/bin/initdb -D ${POSTGRES_HOME}/data" >> "${LOG_FILE_NAME}" 2>&1
		  fi
	   fi
        BACKED_UP=0
        if [ -f ${POSTGRES_HOME}/data/pg_hba.conf.idmcfg ]
        then
            systemctl stop netiq-postgresql >> "${LOG_FILE_NAME}" 2>&1
            mv ${POSTGRES_HOME}/data/pg_hba.conf ${POSTGRES_HOME}/data/pg_hba.conf.bkp
            cp ${POSTGRES_HOME}/data/pg_hba.conf.idmcfg ${POSTGRES_HOME}/data/pg_hba.conf
            systemctl restart netiq-postgresql >> "${LOG_FILE_NAME}" 2>&1
            BACKED_UP=1
        fi

        if  [ "${INSTALL_PG_DB_FOR_REPORTING}" == "y" ]
	   then
            if [ ! -d ${POSTGRES_HOME}/data/pg_log ]
            then
                mkdir ${POSTGRES_HOME}/data/pg_log >> "${LOG_FILE_NAME}" 2>&1
            fi
            chown -R postgres:postgres ${POSTGRES_HOME} >> "${LOG_FILE_NAME}" 2>&1
	   fi
   
        if [ $IS_UA_INSTALLED == "false"  ]
        then
            [ -f ${POSTGRES_HOME}/data/pg_hba.conf ] && echo "host    all             all       0.0.0.0/0    trust" >> ${POSTGRES_HOME}/data/pg_hba.conf
 	    [ -f ${POSTGRES_HOME}/data/postgresql.conf ] && echo "listen_addresses = '*'" >> ${POSTGRES_HOME}/data/postgresql.conf
        fi
	
        export PGPASSWORD=$RPT_DATABASE_SHARE_PASSWORD
        systemctl stop netiq-postgresql >> "${LOG_FILE_NAME}" 2>&1
        systemctl start netiq-postgresql >> "${LOG_FILE_NAME}" 2>&1
    
        if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ] || [ "$RPT_DATABASE_CREATE_OPTION" == "startup" ]
        then
            str1=`gettext install "Setting up database users and schema..."`
            write_and_log "$str1"
            forAzurePGSSL

            if  [ "${INSTALL_PG_DB_FOR_REPORTING}" == "y" ]
	       then
                su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH PGPASSWORD='${RPT_DATABASE_SHARE_PASSWORD}' ${POSTGRES_HOME}/bin/createdb -h ${RPT_DATABASE_HOST} -p ${RPT_DATABASE_PORT} -U postgres ${RPT_DATABASE_NAME}" >> "${LOG_FILE_NAME}" 2>&1
	       fi

            str1=`gettext install "Adding roles and schemas function..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_rpt_roles_and_schemas.sql" >> "${LOG_FILE_NAME}" 2>&1
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_dcs_roles_and_schemas.sql" >> "${LOG_FILE_NAME}" 2>&1

            str1=`gettext install "Creating roles and schemas..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "SELECT create_rpt_roles_and_schemas('${RPT_DATABASE_SHARE_PASSWORD}') AS RETURN;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "SELECT create_dcs_roles_and_schemas('${RPT_DATABASE_SHARE_PASSWORD}', '${RPT_DATABASE_SHARE_PASSWORD}') AS RETURN;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/get_formatted_user_dn.sql" >> "${LOG_FILE_NAME}" 2>&1
        fi

    fi

    # Based on the selected database we have to create the schema
    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
    then
        if [ "${RPT_ORACLE_DATABASE_TYPE}" == "service" ]
	   then
            RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
	   elif [ "${RPT_ORACLE_DATABASE_TYPE}" == "sid" ]
	   then
            RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}:${RPT_DATABASE_NAME}"
	   fi
	   #RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
	   #Update the xml file with oracle details
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle12cDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle12cDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle12cDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml"

        if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ] || [ "$RPT_DATABASE_CREATE_OPTION" == "startup" ]
        then
	       str1=`gettext install "Adding roles and schemas function..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_rpt_roles_and_schemas-oracle.sql" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_dcs_roles_and_schemas-oracle.sql" >> "${LOG_FILE_NAME}" 2>&1

	       str1=`gettext install "Creating roles and schemas..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "BEGIN create_rpt_roles_and_schemas('${RPT_DATABASE_SHARE_PASSWORD}'); END;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "BEGIN create_dcs_roles_and_schemas('${RPT_DATABASE_SHARE_PASSWORD}', '${RPT_DATABASE_SHARE_PASSWORD}'); END;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/get_formatted_user_dn-oracle.sql" >> "${LOG_FILE_NAME}" 2>&1
	   fi
    fi

    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
    then
	   #Update the xml file with oracle details
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml"

        if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ] || [ "$RPT_DATABASE_CREATE_OPTION" == "startup" ]
        then
	       str1=`gettext install "Adding roles and schemas function..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/delete_create_dcs_roles_and_schemas-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_dcs_roles_and_schemas-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1

	       str1=`gettext install "Creating roles and schemas..."`
            write_and_log "$str1"
#            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "BEGIN create_rpt_roles_and_schemas('${RPT_DATABASE_SHARE_PASSWORD}'); END;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "exec create_dcs_roles_and_schemas @idm_rpt_data_password = '${RPT_DATABASE_SHARE_PASSWORD}', @idmrptuser_password = '${RPT_DATABASE_SHARE_PASSWORD}';" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/delete_get_formatted_user_dn-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/get_formatted_user_dn-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1
	   fi
    fi
    
    if [ -f ${RPT_DATABASE_JDBC_DRIVER_JAR} ] && [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
    then
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${RPT_CONFIG_HOME}/ojdbc.jar
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${IDM_TOMCAT_HOME}/lib/ojdbc.jar
    fi
    if [ -f ${RPT_DATABASE_JDBC_DRIVER_JAR} ] && [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
    then
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${RPT_CONFIG_HOME}/sqljdbc.jar
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${IDM_TOMCAT_HOME}/lib/sqljdbc.jar
    fi

    if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ] || [ "$RPT_DATABASE_CREATE_OPTION" == "file" ]
    then
        liquibase_update
    fi

    if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ]
    then
        add_datasource
    fi

    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
    then
        if [ ${BACKED_UP} -eq 1 ] && [ -f ${POSTGRES_HOME}/data/pg_hba.conf.bkp ]
        then
            systemctl stop netiq-postgresql  >> "${log_file}" 2>&1
            rm ${POSTGRES_HOME}/data/pg_hba.conf
            mv ${POSTGRES_HOME}/data/pg_hba.conf.bkp ${POSTGRES_HOME}/data/pg_hba.conf
            systemctl restart netiq-postgresql >> "${log_file}" 2>&1
        else
            if  [ "${INSTALL_PG_DB_FOR_REPORTING}" == "y" ]
	       then
                set_pg_pass
	       fi
        fi
    fi
    
    cd $CURRENT_DIR  
}

configure_database_upgrade()
{
    str1=`gettext install "Configuring database for upgrade"`
    write_and_log "$str1"

    # Based on the selected database we have to create the schema
    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
    then
        RPT_DATABASE_CONNECTION_URL="${RPT_DATABASE_CONNECTION_URL}?compatible=true"
    fi

    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
    then
        if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ] || [ "$RPT_DATABASE_CREATE_OPTION" == "startup" ]
        then
            str1=`gettext install "Adding roles and schemas function in postgres..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_rpt_roles_and_schemas.sql" >> "${LOG_FILE_NAME}" 2>&1
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_dcs_roles_and_schemas.sql" >> "${LOG_FILE_NAME}" 2>&1

            str1=`gettext install "Creating roles and schemas in postgres..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -s "SELECT create_rpt_roles_and_schemas('${RPT_DATABASE_PASSWORD}') AS RETURN;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -s "SELECT create_dcs_roles_and_schemas('${RPT_DATABASE_PASSWORD}', '${RPT_DATABASE_PASSWORD}') AS RETURN;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/get_formatted_user_dn.sql" >> "${LOG_FILE_NAME}" 2>&1
        fi
    fi

    # Based on the selected database we have to create the schema
    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
    then
	   #Update the xml file with oracle details
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle12cDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle12cDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle12cDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml"

        if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ] || [ "$RPT_DATABASE_CREATE_OPTION" == "startup" ]
        then
            str1=`gettext install "Adding roles and schemas function..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_rpt_roles_and_schemas-oracle.sql" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_dcs_roles_and_schemas-oracle.sql" >> "${LOG_FILE_NAME}" 2>&1

            str1=`gettext install "Creating roles and schemas..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -s "BEGIN create_rpt_roles_and_schemas('${RPT_DATABASE_PASSWORD}'); END;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -s "BEGIN create_dcs_roles_and_schemas('${RPT_DATABASE_PASSWORD}', '${RPT_DATABASE_PASSWORD}'); END;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/get_formatted_user_dn-oracle.sql" >> "${LOG_FILE_NAME}" 2>&1
        fi
    fi

    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
    then
	   #Update the xml file with oracle details
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_data_hibernate.cfg.xml"
	   sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/rpt_mgt_cfg_hibernate.cfg.xml"

        if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ] || [ "$RPT_DATABASE_CREATE_OPTION" == "startup" ]
        then
            str1=`gettext install "Adding roles and schemas function..."`
            write_and_log "$str1"
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/delete_create_dcs_roles_and_schemas-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/create_dcs_roles_and_schemas-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1

            str1=`gettext install "Creating roles and schemas..."`
            write_and_log "$str1"
#            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -s "BEGIN create_rpt_roles_and_schemas('${RPT_DATABASE_PASSWORD}'); END;" >> "${LOG_FILE_NAME}" 2>&1

            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_PASSWORD} -s "exec create_dcs_roles_and_schemas @idm_rpt_data_password = '${RPT_DATABASE_SHARE_PASSWORD}', @idmrptuser_password = '${RPT_DATABASE_SHARE_PASSWORD}';" >> "${LOG_FILE_NAME}" 2>&1
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/delete_get_formatted_user_dn-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1
            "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}" -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -f "${RPT_CONFIG_HOME}/sql/get_formatted_user_dn-mssql.sql" >> "${LOG_FILE_NAME}" 2>&1
        fi
    fi

    if [ -f ${RPT_DATABASE_JDBC_DRIVER_JAR} ] && [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
    then
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${RPT_CONFIG_HOME}/ojdbc.jar
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${IDM_TOMCAT_HOME}/lib/ojdbc.jar
	   /usr/bin/chown -R novlua:novlua ${RPT_CONFIG_HOME}/ojdbc.jar >> "${LOG_FILE_NAME}" 2>&1
	   /usr/bin/chown -R novlua:novlua ${IDM_TOMCAT_HOME}/lib/ojdbc.jar >> "${LOG_FILE_NAME}" 2>&1
    fi
    if [ -f ${RPT_DATABASE_JDBC_DRIVER_JAR} ] && [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
    then
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${RPT_CONFIG_HOME}/sqljdbc.jar
	   cp -pf ${RPT_DATABASE_JDBC_DRIVER_JAR} ${IDM_TOMCAT_HOME}/lib/sqljdbc.jar
	   /usr/bin/chown -R novlua:novlua ${RPT_CONFIG_HOME}/sqljdbc.jar >> "${LOG_FILE_NAME}" 2>&1
	   /usr/bin/chown -R novlua:novlua ${IDM_TOMCAT_HOME}/lib/sqljdbc.jar >> "${LOG_FILE_NAME}" 2>&1
    fi

    if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ]
    then
        update_datasource
    fi

}

set_pg_pass()
{
        sed -i "s/# TYPE  DATABASE        USER            ADDRESS                 METHOD/local    postgres     postgres     peer/g" ${POSTGRES_HOME}/data/pg_hba.conf
        su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH PGPASSWORD='${RPT_DATABASE_SHARE_PASSWORD}' ${POSTGRES_HOME}/bin/psql -h ${RPT_DATABASE_HOST} -p ${RPT_DATABASE_PORT} -U postgres -c \"ALTER USER postgres PASSWORD '${RPT_DATABASE_SHARE_PASSWORD}';\"" >> "${LOG_FILE_NAME}" 2>&1
        sed -i "s/local    postgres     postgres     peer/# TYPE  DATABASE        USER            ADDRESS                 METHOD/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/local   all             all                                     trust/local   all             all                                     md5/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/host    all             all             127.0.0.1\/32            trust/host    all             all             127.0.0.1\/0            md5/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/host    all             all             ::1\/128                 trust/host    all             all             ::1\/128                 md5/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/host    all             all       0.0.0.0\/0    trust//g" ${POSTGRES_HOME}/data/pg_hba.conf
        systemctl restart netiq-postgresql >> "${log_file}" 2>&1
}

add_datasource()
{
	str1=`gettext install "Adding data source..."`
	write_and_log "$str1"
	uuid=$(uuidgen)
	if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
	then
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "INSERT into idm_rpt_cfg.idmrpt_data_source(data_source_id, data_source_name, host_name) values('$uuid', 'Installed Database', 'IDMDCSDataSource');" >> "${LOG_FILE_NAME}" 2>&1
	elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
	then
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "INSERT into idm_rpt_cfg.idmrpt_data_source(data_source_id, data_source_name, host_name) values('$uuid', 'Installed Database', 'IDMDCSDataSource')" >> "${LOG_FILE_NAME}" 2>&1
	elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
	then
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "INSERT into idm_rpt_cfg.idmrpt_data_source(data_source_id, data_source_name, host_name) values('$uuid', 'Installed Database', 'IDMDCSDataSource');" >> "${LOG_FILE_NAME}" 2>&1
	fi
}

update_datasource()
{
	str1=`gettext install "Updating data source..."`
	write_and_log "$str1"
	if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
	then
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "update IDM_RPT_CFG.IDMRPT_DATA_SOURCE set HOST_NAME='IDMDCSDataSource' where HOST_NAME='IDMRPTCfgDataSource';" >> "${LOG_FILE_NAME}" 2>&1
	elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
	then
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d oracle.jdbc.OracleDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "update IDM_RPT_CFG.IDMRPT_DATA_SOURCE set HOST_NAME='IDMDCSDataSource' where HOST_NAME='IDMRPTCfgDataSource'" >> "${LOG_FILE_NAME}" 2>&1
	elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
	then
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/idmjdbc.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d com.microsoft.sqlserver.jdbc.SQLServerDriver -j "${RPT_DATABASE_CONNECTION_URL}"  -u ${RPT_DATABASE_USER} -p ${RPT_DATABASE_SHARE_PASSWORD} -s "update IDM_RPT_CFG.IDMRPT_DATA_SOURCE set HOST_NAME='IDMDCSDataSource' where HOST_NAME='IDMRPTCfgDataSource';" >> "${LOG_FILE_NAME}" 2>&1
	fi
}

liquibase_update_startup()
{
    str1=`gettext install "Clearing Checksum for : IdmRptDataSchemaChangeLog.xml"`
    write_log "$str1"
    "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-03-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataSchemaChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1

}

liquibase_update()
{
    str1=`gettext install "Performing liquibase updates..."`
    write_and_log "$str1"
    
    str1=`gettext install "Performing liquibase update for : IdmDcsDataDropViews.xml"`
    write_and_log "$str1"

    if [ ${IS_UPGRADE} -ne 1 ]
    then
	# Based on the selected database we have to create the schema
	if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
	then
	    RPT_DATABASE_DRIVER_CLASS="liquibase.database.core.PostgresDatabase"
    	    RPT_DATABASE_CONNECTION_URL="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}?compatible=true"
          if [ ! -z $AZURE_POSTGRESQL_REQUIRED ] && [[ "$AZURE_POSTGRESQL_REQUIRED" == "y" || "$AZURE_POSTGRESQL_REQUIRED" == "true" ]]
          then
            RPT_DATABASE_CONNECTION_URL="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}?compatible=true&ssl=true"
          fi
	elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
	then
    	    RPT_DATABASE_DRIVER_CLASS="liquibase.database.ext.OracleUnicodeDatabase"
            if [ "${RPT_ORACLE_DATABASE_TYPE}" == "service" ]
	    then
             RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
	    elif [ "${RPT_ORACLE_DATABASE_TYPE}" == "sid" ]
	    then
             RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}:${RPT_DATABASE_NAME}"
	    fi
	    #RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
	elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
	then
	    RPT_DATABASE_DRIVER_CLASS="com.novell.soa.persist.MSSQLUnicodeDatabase"
    	    RPT_DATABASE_CONNECTION_URL="jdbc:sqlserver://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT};DatabaseName=${RPT_DATABASE_NAME}"
	    RPT_CONFIG_HOME_PERSIST_JAR="${RPT_CONFIG_HOME}/persist-liquibase.jar"
	fi
    fi

	if [ $IS_UPGRADE -eq 1 ]
	then
         RPT_DATABASE_SHARE_PASSWORD=${RPT_DATABASE_PASSWORD}
	fi
    
    if [ "${RPT_DATABASE_CREATE_OPTION}" == "now" ]
    then
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-001-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataDropViews.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
    
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-001-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataDropViews.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  update >> "${LOG_FILE_NAME}" 2>&1
        str1=`gettext install "Performing liquibase update for : IdmRptCfgDropViews.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-01-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgDropViews.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
    
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-01-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgDropViews.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  update >> "${LOG_FILE_NAME}" 2>&1
    
        str1=`gettext install "Performing liquibase update for : IdmRptCfgSchemaChangeLog.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -Ddefault.datasource.name="Installed Database" -classpath "${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-02-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgSchemaChangeLog.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
    
        "${IDM_JRE_HOME}/bin/java" -Ddefault.datasource.name="Installed Database" -classpath "${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-02-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgSchemaChangeLog.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  update >> "${LOG_FILE_NAME}" 2>&1
    
        str1=`gettext install "Performing liquibase update for : IdmRptDataSchemaChangeLog.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-03-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataSchemaChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
    
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-03-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataSchemaChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  update >> "${LOG_FILE_NAME}" 2>&1
    
        str1=`gettext install "Performing liquibase update for : IdmRptDataOTBDataChangeLog.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-04-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataOTBDataChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
    
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-04-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataOTBDataChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  update >> "${LOG_FILE_NAME}" 2>&1
    
        str1=`gettext install "Performing liquibase update for : IdmDcsDataViewChangeLogNew.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-05-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataViewChangeLogNew.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
    
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-05-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataViewChangeLogNew.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  update >> "${LOG_FILE_NAME}" 2>&1
    
        str1=`gettext install "Performing liquibase update for : IdmDcsDataGrantPrivileges.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-06-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataGrantPrivileges.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
    
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-06-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataGrantPrivileges.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  update >> "${LOG_FILE_NAME}" 2>&1
    fi
    
    if [ "${RPT_DATABASE_NEW_OR_EXIST}" == "exist" ]
    then
        RPT_CONTEXT_DATABASE_UPDATE="updatedb"
    elif [ "${RPT_DATABASE_NEW_OR_EXIST}" == "new" ]
    then
        RPT_CONTEXT_DATABASE_UPDATE="newdb"
    fi
    
    if [ "${RPT_DATABASE_CREATE_OPTION}" == "file" ]
    then
        str1=`gettext install "Performing liquibase update for : IdmDcsDataDropViews.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-001-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataDropViews.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-001-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataDropViews.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  updateSQL > ${RPT_CONFIG_HOME}/sql/DbUpdate-001-run-as-idm_rpt_data.sql
        str1=`gettext install "Performing liquibase update for : IdmRptCfgDropViews.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-01-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgDropViews.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-01-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgDropViews.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  updateSQL > ${RPT_CONFIG_HOME}/sql/DbUpdate-01-run-as-idm_rpt_cfg.sql

        str1=`gettext install "Performing liquibase update for : IdmRptCfgSchemaChangeLog.xml"`
        write_and_log "$str1"
	   "${IDM_JRE_HOME}/bin/java" -Ddefault.datasource.name="Installed Database" -classpath "${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-02-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgSchemaChangeLog.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
	   "${IDM_JRE_HOME}/bin/java" -Ddefault.datasource.name="Installed Database" -classpath "${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-02-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgSchemaChangeLog.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  updateSQL > ${RPT_CONFIG_HOME}/sql/DbUpdate-02-run-as-idm_rpt_cfg.sql

        str1=`gettext install "Performing liquibase update for : IdmRptDataSchemaChangeLog.xml"`
        write_and_log "$str1"
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-03-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataSchemaChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-03-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataSchemaChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  updateSQL > ${RPT_CONFIG_HOME}/sql/DbUpdate-03-run-as-idm_rpt_data.sql

        str1=`gettext install "Performing liquibase update for : IdmRptDataOTBDataChangeLog.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-04-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataOTBDataChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-04-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataOTBDataChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  updateSQL > ${RPT_CONFIG_HOME}/sql/DbUpdate-04-run-as-idm_rpt_data.sql

        str1=`gettext install "Performing liquibase update for : IdmDcsDataViewChangeLogNew.xml"`
        write_and_log "$str1"
        "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-05-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataViewChangeLogNew.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-05-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataViewChangeLogNew.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  updateSQL > ${RPT_CONFIG_HOME}/sql/DbUpdate-05-run-as-idm_rpt_data.sql

        str1=`gettext install "Performing liquibase update for : IdmDcsDataGrantPrivileges.xml"`
        write_and_log "$str1"
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-06-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataGrantPrivileges.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums >> "${LOG_FILE_NAME}" 2>&1
	   "${IDM_JRE_HOME}/bin/java" -classpath "${RPT_CONFIG_HOME}/DbSchema-DCS.jar:${RPT_CONFIG_HOME}/DbSchema.jar:${RPT_DATABASE_JDBC_DRIVER_JAR}:${RPT_CONFIG_HOME}/liquibase.jar:${RPT_CONFIG_HOME_PERSIST_JAR}" liquibase.integration.commandline.Main --url="${RPT_DATABASE_CONNECTION_URL}" --logFile="/var/opt/netiq/idm/log/RptDb-06-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataGrantPrivileges.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  updateSQL > ${RPT_CONFIG_HOME}/sql/DbUpdate-06-run-as-idm_rpt_cfg.sql

        if [ -f ${IDM_INSTALL_HOME}/reporting/scripts/rpt_file_execute.sh ]
        then
            cp ${IDM_INSTALL_HOME}/reporting/scripts/rpt_file_execute.sh ${RPT_CONFIG_HOME}/

            local rpt_file_execute=${RPT_CONFIG_HOME}/rpt_file_execute.sh

            search_and_replace "__RPT_DATABASE_CONNECTION_URL__"  "${RPT_DATABASE_CONNECTION_URL}" "$rpt_file_execute"
            search_and_replace "__RPT_DATABASE_JDBC_DRIVER_JAR__"  "${RPT_DATABASE_JDBC_DRIVER_JAR}" "$rpt_file_execute"
            search_and_replace "__RPT_CONFIG_HOME_PERSIST_JAR__"  "${RPT_CONFIG_HOME_PERSIST_JAR}" "$rpt_file_execute"
        fi
    fi

    if [ "$RPT_DATABASE_CREATE_OPTION" == "startup" ] && [ $IS_UPGRADE -eq 1 ]
    then
        liquibase_update_startup
    fi

    str1=`gettext install "Completed liquibase updates..."`
    write_and_log "$str1"
}

configure_activemq()
{
    str1=`gettext install "Configuring ActiveMQ ..."`
    write_and_log "$str1"
}

configure_auditing()
{
    str1=`gettext install "Configuring auditing ..."`
    write_and_log "$str1"
	configure_audit
}

create_driver_property_file()
{
    str1=`gettext install "Creating driver configuration files"`
    write_and_log "$str1"
    cp ${IDM_INSTALL_HOME}reporting/driver_conf/NOV*.properties $IDM_TEMP/
    local msgw_prop_file=$IDM_TEMP/NOVLIDMMSGWB.properties
    local dcs_prop_file=$IDM_TEMP/NOVLIDMDCSB.properties
}
