#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

configure_tomcat()
{
    modify_server_xml
    modify_context_xml
    modify_setenv_sh	
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

modify_nginx_conf()
{
	grep "[[:space:]]ssl[[:space:]]*on" /opt/netiq/common/nginx/nginx.conf &> /dev/null
	if [ $? -ne 0 ]
	then
	  unzip -q -d /opt/netiq/common/nginx/ "${IDM_INSTALL_HOME}/user_application/cert.zip"
	fi
	if [ -f /opt/netiq/common/nginx/nginx.conf ]
	then
		sed -i.bak "s#server_name  localhost;#server_name  $FR_SERVER_HOST;\n\t\tssl on;\n\tssl_protocols TLSv1.2;\n\t\tssl_password_file /opt/netiq/common/nginx/cert/pass.txt;\n\t\tssl_certificate /opt/netiq/common/nginx/cert/nginx.crt;\n\t\tssl_certificate_key /opt/netiq/common/nginx/cert/nginx.key;#g" /opt/netiq/common/nginx/nginx.conf
		sed -i.bak "s#listen       8600#listen $NGINX_HTTPS_PORT ssl#g" /opt/netiq/common/nginx/nginx.conf
		sed -i.bak "s/#user  nobody;/user novlua;/g" /opt/netiq/common/nginx/nginx.conf
		foundunusedPort=false
		golangInternalPort=3000
		while ( ! $foundunusedPort )
		do
			lsof -t -i:$golangInternalPort &> /dev/null
			if [ $? -ne 0 ]
			then
				foundunusedPort=true
			else
				((golangInternalPort++))
			fi
		done
		sed -i.bak ':a;N;s/       error_page   500 502 503 504  \/50x.html;/\n\terror_page 500 503 504 502 \/502.html;\n\terror_page 404 \/404.html;\n\tlocation \/502.html {\n\t\troot \/opt\/netiq\/idm\/apps\/sites\/forms\/;\n\t\tindex 502.html;\n\t}\n\tlocation \/404.html {\n\t\troot \/opt\/netiq\/idm\/apps\/sites\/forms\/;\n\t\tindex 404.html;\n\t}\n\n\n\tadd_header X-XSS-Protection "1; mode=block";\n\tadd_header X-Content-Type-Options "nosniff";\n\tadd_header Strict-Transport-Security "max-age=31536000; includeSubdomains";\n/;ba' /opt/netiq/common/nginx/nginx.conf

		sed -i.bak ':a;N;s/        location = \/50x.html {.*        }//;ba' /opt/netiq/common/nginx/nginx.conf
		
		sed -i.bak ':a;N;s/        location \/ {.*        }/        location \/ {\n\t\tproxy_set_header X-Real-IP $remote_addr;\n\t\tproxy_set_header X-Forwarded-For $remote_addr;\n\t\tproxy_set_header Host $host;\n\t\tproxy_pass http:\/\/127.0.0.1:3000;\n         }\n        location \/forms {\n\t\troot \/opt\/netiq\/idm\/apps\/sites\/;\n\t\tindex index.html;\n         }/;ba' /opt/netiq/common/nginx/nginx.conf
		sed -i.bak "s#127.0.0.1:3000#127.0.0.1:$golangInternalPort#g" /opt/netiq/common/nginx/nginx.conf
		
		sed -i.bak ':a;N;s/    keepalive_timeout  65;/\tkeepalive_timeout  90;/;ba' /opt/netiq/common/nginx/nginx.conf
		
		#Adding server tokens off configuration
        sed -i.bak ':a;N;s/    sendfile        on;/\tsendfile        on;\n\n\tserver_tokens off;\n/;ba' /opt/netiq/common/nginx/nginx.conf
	fi
	if [ ! -f /opt/netiq/idm/apps/sites/config.ini ]
	then
		if [ ! -d /opt/netiq/idm/apps/sites ]
		then
		  mkdir -p /opt/netiq/idm/apps/sites
		fi
		cp ${IDM_INSTALL_HOME}/user_application/config.ini /opt/netiq/idm/apps/sites/config.ini
	fi
	grep -q ___SSO_SERVICE_PWD_B64___ /opt/netiq/idm/apps/sites/config.ini
	if [ $? -eq 0 ]
	then
		SSO_SERVICE_PWD_B64=$(echo -n "$SSO_SERVICE_PWD" | base64)
		sed -i.bak "s#___SSO_SERVICE_PWD_B64___#$SSO_SERVICE_PWD_B64#g" /opt/netiq/idm/apps/sites/config.ini
		if [ ! -z $SSO_SERVER_SSL_PORT ] && [ "$SSO_SERVER_SSL_PORT" != "" ]
		then
		  sed -i.bak "s#localhost:8543#$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT#g" /opt/netiq/idm/apps/sites/config.ini
		else
		  sed -i.bak "s#localhost:8543#$SSO_SERVER_HOST#g" /opt/netiq/idm/apps/sites/config.ini
		fi
		sed -i.bak "s#https://localhost:8600#https://$FR_SERVER_HOST:$NGINX_HTTPS_PORT#g" /opt/netiq/idm/apps/sites/config.ini
	fi
	rm -rf /opt/netiq/idm/apps/sites/forms
	mkdir -p /opt/netiq/idm/apps/sites/forms
	cd /opt/netiq/idm/apps/sites/forms
	[ -f ../IgaFormRendererUI*tar.gz ] && tar zxf ../IgaFormRendererUI*tar.gz
	chmod 755 /etc/init.d/netiq-golang.sh
	chown -R novlua:novlua /opt/netiq/idm/apps/sites /etc/init.d/netiq-golang.sh /opt/netiq/common/nginx/
	cd - &> /dev/null
	grep -q "___FR_GOLANG_PORT___" /etc/init.d/netiq-golang.sh &> /dev/null
	if [ $? -eq 0 ]
	then
		sed -i.bak "s#___FR_GOLANG_PORT___#$golangInternalPort#g" /etc/init.d/netiq-golang.sh
		if [ $UNATTENDED_INSTALL -eq 1 ]
		then
		  su -l novlua -c "/etc/init.d/netiq-golang.sh start &> /dev/null"
		else
		  su -l novlua -c "/etc/init.d/netiq-golang.sh start"
		fi
		sleep 5s
		loop=5
		while [ ! -f /opt/netiq/idm/apps/sites/ServiceRegistry.json ]
		do
			sleep 5s
			((loop--))
			if [ $loop -eq 0 ]
			then
				break
			fi
		done
		lsof -t -i:$golangInternalPort &> /dev/null
		if [ $? -eq 1 ]
		then
			if [ $UNATTENDED_INSTALL -eq 1 ]
			then
			  su -l novlua -c "/etc/init.d/netiq-golang.sh start &> /dev/null"
			else
			  su -l novlua -c "/etc/init.d/netiq-golang.sh start"
			fi
		fi
		if [ ! -z "$debugprompt" ] && [ "$debugprompt" == "y" ]
		then
			prompt UA_DEBUG_PROMPT
		fi
		if [ ! -z "$UA_SERVER_SSL_PORT" ] && [ "$UA_SERVER_SSL_PORT" != "" ]
		then
		  sed -i.bak "s#localhost:8543#$UA_SERVER_HOST:$UA_SERVER_SSL_PORT#g" /opt/netiq/idm/apps/sites/ServiceRegistry.json
		else
		  sed -i.bak "s#localhost:8543#$UA_SERVER_HOST#g" /opt/netiq/idm/apps/sites/ServiceRegistry.json
		fi
		systemctl start netiq-nginx >> "${LOG_FILE_NAME}" 2>&1
		if [ $? -ne 0 ]
		then
			/opt/netiq/common/nginx/serv/netiq-nginx start >> "${LOG_FILE_NAME}" 2>&1
		fi
	fi
}

configure_nginx()
{
	modify_nginx_conf
}

modify_setenv_sh()
{
  #addtruststorepasswordTosetenv
  removetruststoreentryfromsetenv
  addcheckrevocationTosetenv
  addlogbackTosetenv
  if [ ! -z ${UA_WORKFLOW_ENGINE_ID} ]
  then
   CATALINA_NEW=`grep -ir "CATALINA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed "s/\"$/ -Dcom.novell.afw.wf.engine-id=${UA_WORKFLOW_ENGINE_ID} -Dcom.microfocus.workflow.logging.level=INFO -Djdk.tls.rejectClientInitiatedRenegotiation=true -Djava.net.preferIPv4Stack=true\"/g"`
   sed '/CATALINA_OPTS=/d' /opt/netiq/idm/apps/tomcat/bin/setenv.sh > ${IDM_TOMCAT_HOME}/bin/setenv_new.sh
   echo "export CATALINA_OPTS=${CATALINA_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv_new.sh
   mv ${IDM_TOMCAT_HOME}/bin/setenv.sh ${IDM_TOMCAT_HOME}/bin/setenv_org.sh
   mv ${IDM_TOMCAT_HOME}/bin/setenv_new.sh ${IDM_TOMCAT_HOME}/bin/setenv.sh
   rm -rf ${IDM_TOMCAT_HOME}/bin/setenv_org.sh
  else
   grep -q com.novell.afw.wf.engine-id ${IDM_TOMCAT_HOME}/bin/setenv.sh
   if [ $? -ne 0 ]
   then
    CATALINA_NEW=`grep -ir "CATALINA_OPTS=" ${IDM_TOMCAT_HOME}/bin/setenv.sh | cut -d"=" -f2- | sed s'/"$/ -Dcom.novell.afw.wf.engine-id=ENGINE -Dcom.microfocus.workflow.logging.level=INFO -Djdk.tls.rejectClientInitiatedRenegotiation=true -Djava.net.preferIPv4Stack=true"/g'`
    sed '/CATALINA_OPTS=/d' /opt/netiq/idm/apps/tomcat/bin/setenv.sh > ${IDM_TOMCAT_HOME}/bin/setenv_new.sh
    echo "export CATALINA_OPTS=${CATALINA_NEW}" >> ${IDM_TOMCAT_HOME}/bin/setenv_new.sh
    mv ${IDM_TOMCAT_HOME}/bin/setenv.sh ${IDM_TOMCAT_HOME}/bin/setenv_org.sh
    mv ${IDM_TOMCAT_HOME}/bin/setenv_new.sh ${IDM_TOMCAT_HOME}/bin/setenv.sh
    rm -rf ${IDM_TOMCAT_HOME}/bin/setenv_org.sh
   fi
  fi
  sed -i.bak "s#___SSO_SERVER_HOST___#$SSO_SERVER_HOST#g" "${IDM_TOMCAT_HOME}/bin/setenv.sh"
  sed -i.bak "s#___TOMCAT_SERVLET_HOSTNAME___#$SSO_SERVER_HOST#g" "${IDM_TOMCAT_HOME}/bin/setenv.sh"
}

configure_sspr()
{
    cd ${IDM_INSTALL_HOME}sspr
    ./configure.sh $*
    cd -
}

##
# Import UA related ldif files.
##
import_ldifs()
{

    str1=`gettext install "Importing ldif schema "`
    write_and_log "$str1"
   
    cp -r ${IDM_INSTALL_HOME}user_application/ldif $IDM_TEMP/ua_ldif >>$LOG_FILE_NAME
     
    if [ "${ENABLE_CUSTOM_CONTAINER_CREATION}" == "y" ]
    then
     local ldif_file=${CUSTOM_CONTAINER_LDIF_PATH}
     new_import_ldif "$ldif_file"
    else

      local ldif_file=$IDM_TEMP/ua_ldif/base_containers.ldif
      search_and_replace "___ROOT_CONATINER___"  "$ROOT_CONTAINER" "$ldif_file"
      new_import_ldif "$ldif_file"

      local ldif_file=$IDM_TEMP/ua_ldif/ua.ldif
      search_and_replace "___ROOT_CONATINER___"  "$ROOT_CONTAINER" "$ldif_file"
      search_and_replace "___UA_ADMIN___"  "$UA_ADMIN" "$ldif_file"
      search_and_replace "___UA_ADMIN_PWD___"  "$UA_ADMIN_PWD" "$ldif_file"
      new_import_ldif "$ldif_file"
    fi

    # Iterate through the list of dn's
    while IFS= read -r entry
    do
        SRV_DN=`echo "$entry" | awk -F ':' '{print $2}' | xargs`
        cp $IDM_TEMP/ua_ldif/compoundIndex.ldif ${IDM_TEMP}/ua_ldif/compoundIndex.ldif.tmp
        local ldif_file=$IDM_TEMP/ua_ldif/compoundIndex.ldif.tmp
        search_and_replace "___NCP_SERVER_DN___"  "$SRV_DN" "$ldif_file"
        new_import_ldif "$ldif_file"
        rm ${ldif_file}
    done <<< "${NCP_SERVERS}"
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
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jdbc/IDMUADataSource']"`
                  write_log "XML_MOD Response : ${result}"
                  result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='jms/ConnectionFactory']"`
                  write_log "XML_MOD Response : ${result}"
			   grep -q "topic/IDMNotificationDurableTopic" ${IDM_TOMCAT_HOME}/conf/context.xml
                  RET=$?
                  if [ $RET -eq 0 ]
                  then
                      result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='topic/IDMNotificationDurableTopic']"`
                      write_log "XML_MOD Response : ${result}"
			   fi
			   grep -q "topic/EmailBasedApprovalTopic" ${IDM_TOMCAT_HOME}/conf/context.xml
                  RET=$?
                  if [ $RET -eq 0 ]
                  then
                      result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context/ResourceLink[@name='topic/EmailBasedApprovalTopic']"`
                      write_log "XML_MOD Response : ${result}"
			   fi

           fi
    fi

    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="shared/IDMUADataSource" name="jdbc/IDMUADataSource" type="javax.sql.DataSource"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="shared/IGADataSource" name="jdbc/IGADataSource" type="javax.sql.DataSource" />
XMLOUT`
    write_log "XML_MOD Response : ${result}"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="jms/ConnectionFactory" name="jms/ConnectionFactory" type="javax.jms.ConnectionFactory"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="topic/IDMNotificationDurableTopic" name="topic/IDMNotificationDurableTopic" type="javax.jms.Topic"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/context.xml" "/Context[1]" "/" << XMLOUT 
<ResourceLink global="topic/EmailBasedApprovalTopic" name="topic/EmailBasedApprovalTopic" type="javax.jms.Topic"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"
}


copy_tomcat_configs()
{
    str1=`gettext install "Creating tomcat configuration"`
    write_and_log "$str1"
    mkdir ${IDM_TOMCAT_HOME}/conf
    cp ${IDM_TOMCAT_HOME_BASE}/conf/* ${IDM_TOMCAT_HOME}/conf/
}

modify_logging_xml()
{
  write_log "Enabling Audit Configuration in logging xml "
  
  if [ "$UA_NAUDIT_AUDIT_ENABLED" == "y" ]
  then
   sed -i "s/<\!-- remove this line to turn on Novell Audit/<\!--Novell Audit-->/g" "${IDM_TOMCAT_HOME}/conf/idmuserapp_logging.xml" >> "${LOG_FILE_NAME}" 2>&1
   sed -i "s/remove this line to turn on Novell Audit -->/<\!--Novell Audit-->/g" "${IDM_TOMCAT_HOME}/conf/idmuserapp_logging.xml" >> "${LOG_FILE_NAME}" 2>&1
  fi

  if [ "$UA_CEF_AUDIT_ENABLED" == "y" ]
  then
    sed -i "s/<\!-- remove this line to turn on CEF auditing/<\!-- CEF -->/g" "${IDM_TOMCAT_HOME}/conf/idmuserapp_logging.xml" >> "${LOG_FILE_NAME}" 2>&1
    sed -i "s/remove this line to turn on CEF auditing -->/<\!-- CEF -->/g" "${IDM_TOMCAT_HOME}/conf/idmuserapp_logging.xml" >> "${LOG_FILE_NAME}" 2>&1
  fi
}

modify_server_xml()
{
  forAzurePGSSL
if [ "$debug" == 'y' ]
then
	set -x
fi
    str1=`gettext install "Updating Tomcat configuration "`
    write_and_log "$str1"
    
     if [ $IS_UPGRADE -eq 1 ]
     then
        if [ -f ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml ]
        then
            cp -p ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml ${IDM_TOMCAT_HOME}/conf/
            #
            result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]/Resource[@name='shared/IDMUADataSource']"`
            write_log "XML_MOD Response : ${result}"
            result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]/Resource[@name='jms/ConnectionFactory']"`
            write_log "XML_MOD Response : ${result}"
            grep -q "topic/IDMNotificationDurableTopic" ${IDM_TOMCAT_HOME}/conf/server.xml
            RET=$?
            if [ $RET -eq 0 ]
            then
                result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]/Resource[@name='topic/IDMNotificationDurableTopic']"`
                write_log "XML_MOD Response : ${result}"
            fi
            grep -q "topic/EmailBasedApprovalTopic" ${IDM_TOMCAT_HOME}/conf/server.xml
            RET=$?
            if [ $RET -eq 0 ]
            then
                result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]/Resource[@name='topic/EmailBasedApprovalTopic']"`
                write_log "XML_MOD Response : ${result}"
		  fi
            #Remove
            grep -q "org.apache.catalina.core.JasperListener" ${IDM_TOMCAT_HOME}/conf/server.xml
            RET=$?
            if [ $RET -eq 0 ]
            then
                result=`"${XML_MOD}" "-r" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Listener[@className='org.apache.catalina.core.JasperListener']"`
                write_log "XML_MOD Response : ${result}"
                
                result=`"${XML_MOD}" "-a" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server" "/" << XMLOUT
<Listener className="org.apache.catalina.startup.VersionLoggerListener" />
XMLOUT`
                write_log "XML_MOD Response : ${result}"
                #
                result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@protocol='org.apache.coyote.http11.Http11Protocol']/@protocol" "org.apache.coyote.http11.Http11NioProtocol"`
                write_log "XML_MOD Response : ${result}"
            fi
        fi
    fi

    local PWD=`$IDM_JRE_HOME/bin/java -jar $IDM_TOMCAT_HOME/lib/idm-datasource-factory-uber.jar "${UA_WFE_DATABASE_PWD}"`
    #Ports has to be updated only for fresh installation
    if [ $IS_UPGRADE -ne 1 ]
    then
       if [ ! -z "$TOMCAT_HTTP_PORT" ] && [ "$TOMCAT_HTTP_PORT" != "" ]
       then
         result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "$TOMCAT_HTTP_PORT"`
       else
         result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "80"`
       fi
       write_log "XML_MOD Response : ${result}"
       if [ ! -z "$UA_SERVER_SSL_PORT" ] && [ "$UA_SERVER_SSL_PORT" != "" ]
       then
         result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@redirectPort='8443']/@redirectPort" "$UA_SERVER_SSL_PORT"`
         write_log "XML_MOD Response : ${result}"
         result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8443']/@port" "$UA_SERVER_SSL_PORT"`
         write_log "XML_MOD Response : ${result}"
       else
         result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@redirectPort='8443']/@redirectPort" "443"`
         write_log "XML_MOD Response : ${result}"
         result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8443']/@port" "443"`
         write_log "XML_MOD Response : ${result}"
       fi
       result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8009']/@port" "8109"`
       write_log "XML_MOD Response : ${result}"
    fi

    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
  <Resource auth="Container" description="User database that can be updated and saved" factory="org.apache.catalina.users.MemoryUserDatabaseFactory" name="UserDatabase" pathname="conf/tomcat-users.xml" type="org.apache.catalina.UserDatabase"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"

  if [ $IS_UPGRADE -ne 1 ]
  then

    if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
    then
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
<Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IDMUADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:postgresql://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${UA_DATABASE_NAME}$QUESTIONMARK$AZUREPGSSL" username="$UA_WFE_DATABASE_USER" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
    result2=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
<Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IGADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:postgresql://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}$QUESTIONMARK$AZUREPGSSL" username="$UA_WFE_DATABASE_USER" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
    elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
    then
	  if [ "${UA_ORACLE_DATABASE_TYPE}" == "service" ]
      then
      result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
 <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IDMUADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${UA_DATABASE_NAME}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
      result2=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
 <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IGADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
     elif [ "${UA_ORACLE_DATABASE_TYPE}" == "sid" ]
     then
	  result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
 <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IDMUADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${UA_DATABASE_NAME}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
      result2=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
 <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IGADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${WFE_DATABASE_NAME}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
     fi

    elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
    then
     result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
<Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IDMUADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${UA_DATABASE_NAME}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
     result2=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
<Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IGADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${WFE_DATABASE_NAME}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
    fi

    write_log "XML_MOD Response : ${result}"
    write_log "XML_MOD Response : ${result2}"
  elif [ $IS_UPGRADE -eq 1 ]
  then
    if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
    then
     result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
<Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IDMUADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${UA_DB_CONNECTION_URL}" username="$UA_WFE_DATABASE_USER" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
    result2=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
<Resource auth="Container" driverClassName="org.postgresql.Driver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IGADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${WFE_DB_CONNECTION_URL}" username="$UA_WFE_DATABASE_USER" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
    elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
    then
     result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
 <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IDMUADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${UA_DB_CONNECTION_URL}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
      result2=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
 <Resource auth="Container" driverClassName="oracle.jdbc.driver.OracleDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IGADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${WFE_DB_CONNECTION_URL}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1 from DUAL"/>
XMLOUT`
    elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
    then
     result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
<Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IDMUADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${UA_DB_CONNECTION_URL}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
     result2=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
<Resource auth="Container" driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver" factory="com.netiq.tomcat.jdbc.pool.CustomBasicDataSourceFactory" initialSize="10" maxTotal="100" maxActive="50" maxIdle="10" maxWait="30000" minIdle="10" name="shared/IGADataSource" password="${PWD}" testOnBorrow="true" type="javax.sql.DataSource" url="${WFE_DB_CONNECTION_URL}" username="${UA_WFE_DATABASE_USER}" validationInterval="120000" validationQuery="SELECT 1"/>
XMLOUT`
    fi

    write_log "XML_MOD Response : ${result}"
    write_log "XML_MOD Response : ${result2}"

  fi
    
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
<Resource auth="Container" brokerName="LocalActiveMQBroker" brokerURL="tcp://${ACTIVEMQ_SERVER_HOST}:${ACTIVEMQ_SERVER_TCP_PORT}" description="JMS Connection Factory" factory="org.apache.activemq.jndi.JNDIReferenceFactory" name="jms/ConnectionFactory" type="org.apache.activemq.ActiveMQConnectionFactory"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"
    if [ $IS_UPGRADE -ne 1 ]
    then
      tcpvar=tcp://$ACTIVEMQ_SERVER_HOST:$ACTIVEMQ_SERVER_TCP_PORT
      search_and_replace "tcp://0.0.0.0:61616" $tcpvar /opt/netiq/idm/activemq/conf/activemq.xml
    fi
    
    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT 
<Resource auth="Container" description="Topic for IdmApps" factory="org.apache.activemq.jndi.JNDIReferenceFactory" name="topic/IDMNotificationDurableTopic" physicalName="IDMNotificationDurableTopic" type="org.apache.activemq.command.ActiveMQTopic"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"

    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/GlobalNamingResources[1]" "/" << XMLOUT
    <Resource auth="Container" description="Topic for IdmApps email based approval" factory="org.apache.activemq.jndi.JNDIReferenceFactory" name="topic/EmailBasedApprovalTopic" physicalName="EmailBasedApprovalTopic" type="org.apache.activemq.command.ActiveMQTopic"/>
XMLOUT`
    write_log "XML_MOD Response : ${result}"
   #Keystore password can be reset only for fresh installation
   if [ $IS_UPGRADE -ne 1 ]
   then
	  keystorePassToCustom_UA
   fi

   setTLSv12_UA
}


update_config_properties()
{

    local prop_file=${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    rpm -qi netiq-userapp &> /dev/null
    if [ $? -eq 0 ]
    then
    sed -i -r 's/edition=standard/edition=advanced/' ${CONFIG_UPDATE_HOME}/configupdate.sh.properties
    fi
    grep -q no_nam_oauth $prop_file
    [ $? -ne 0 ] && echo "no_nam_oauth=\"false\"" >> $prop_file
    grep -q app_versions $prop_file
    if [ $? -ne 0 ]
    then
      echo "app_versions=\"ua#4.8.0,rpt#6.5.0\"" >> $prop_file
    fi
    configupdate_idm
    search_and_replace "\$NOVL_JAVA_HOME\$"  "$IDM_JRE_HOME" "$prop_file"
    search_and_replace "\$NOVL_APPLICATION_NAME\$"  "$UA_APP_CTX" "$prop_file"
    search_and_replace "\$NOVL_TOMCAT_BASE_FOLDER\$"  "$IDM_TOMCAT_HOME" "$prop_file"
    search_and_replace "\$USER_INSTALL_DIR\$"  "$UA_CONFIG_HOME" "$prop_file"
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



}

create_silent_property_file()
{
    local ua_driver_dn=
    if [ ${IS_UPGRADE} -eq 1 ]
    then
        ua_driver_dn="${ID_VAULT_DRIVER_SET}"
    else
        ua_driver_dn="cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}"
    fi
    str1=`gettext install "Creating configurations files "`
    write_and_log "$str1"
    cp ${IDM_INSTALL_HOME}user_application/configupdate.properties $IDM_TEMP/ >>$LOG_FILE_NAME
    local prop_file=$IDM_TEMP/configupdate.properties

    search_and_replace "___UA_IP___"  "$UA_SERVER_HOST" "$prop_file"
    search_and_replace "___SSPR_IP___"  "$SSPR_SERVER_HOST" "$prop_file"
    # Bug 1113613 - Apps fail to contact IDV
    # Due to Azul JRE - hence using the short name of ID_VAULT_HOST instead of FQDN
    # Blocking this code for now - START
    #ID_VAULT_HOST_SHORT=$(echo $ID_VAULT_HOST | cut -d"." -f1)
    #re='^[0-9]+$'
    #if [[ $ID_VAULT_HOST_SHORT =~ $re ]]
    #then
    #	ID_VAULT_HOST_SHORT=$ID_VAULT_HOST
    #fi
    # Blocking this code for now - END
    ID_VAULT_HOST_SHORT=$ID_VAULT_HOST
    search_and_replace "___ID_VAULT_HOST___"  "$ID_VAULT_HOST_SHORT" "$prop_file"
    search_and_replace "___ID_VAULT_ADMIN___"  "$ID_VAULT_ADMIN_LDAP" "$prop_file"
    search_and_replace "___ID_VAULT_PASSWORD___"  "$ID_VAULT_PASSWORD" "$prop_file"
    search_and_replace "___OSP_JKS_KEY_PWD___"  "$OSP_KEYSTORE_PWD" "$prop_file"
    search_and_replace "___OSP_JKS_PWD___"  "$OSP_KEYSTORE_PWD" "$prop_file"
    search_and_replace "___IDM_KEYSTORE_PATH___" "$IDM_KEYSTORE_PATH" "$prop_file"
    search_and_replace "___IDM_KEYSTORE_PWD___"  "$IDM_KEYSTORE_PWD" "$prop_file"
    search_and_replace "___UA_ADMIN___"  "$UA_ADMIN" "$prop_file"
    search_and_replace "___DRIVERSET_NAME___"  "${ua_driver_dn}" "$prop_file"
    search_and_replace "___UA_DRIVER_NAME___"  "${UA_DRIVER_NAME}" "$prop_file"
    search_and_replace "___IDM_KEYSTORE_PWD___"  "$IDM_KEYSTORE_PWD" "$prop_file"
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
    if [ ! -z "$SSO_SERVER_SSL_PORT" ] && [ "$SSO_SERVER_SSL_PORT" != "" ]
    then
      search_and_replace "___OSP_TOMCAT_HTTPS_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
    else
      search_and_replace ":___OSP_TOMCAT_HTTPS_PORT___"  "$SSO_SERVER_SSL_PORT" "$prop_file"
    fi
    if [ ! -z "$SSPR_SERVER_SSL_PORT" ] && [ "$SSPR_SERVER_SSL_PORT" != "" ]
    then
      search_and_replace "___SSPR_TOMCAT_HTTPS_PORT___"  "$SSPR_SERVER_SSL_PORT" "$prop_file"
    else
      search_and_replace ":___SSPR_TOMCAT_HTTPS_PORT___"  "$SSPR_SERVER_SSL_PORT" "$prop_file"
    fi
    search_and_replace "___ID_VAULT_LDAP_PORT___"  "$ID_VAULT_LDAP_PORT" "$prop_file"
    search_and_replace "___ID_VAULT_LDAPS_PORT___"  "$ID_VAULT_LDAPS_PORT" "$prop_file"
    search_and_replace "__OSP_TOMCAT_HOST__"  "$IDM_TOMCAT_HOME" "$prop_file"
    search_and_replace "__SSL_KEYSTORE_PASS__"  "$OSP_COMM_TOMCAT_KEYSTORE_PWD" "$prop_file"
    search_and_replace "__OSP_SSL_KEYSTORE_PASS__"  "$OSP_COMM_TOMCAT_KEYSTORE_PWD" "$prop_file"
    search_and_replace "___USER_ROOT_CONTAINER___"  "$USER_CONTAINER" "$prop_file"
    search_and_replace "___GROUP_ROOT_CONTAINER___"  "$GROUP_ROOT_CONTAINER" "$prop_file"
    search_and_replace "___ROOT_CONTAINER____"  "$ROOT_CONTAINER" "$prop_file"
    search_and_replace "___ADMIN_CONTAINER___"  "$ADMIN_CONTAINER" "$prop_file"
     
}

ismcleanup()
{
   sed -i '/com.netiq.uadash/d' ${ISM_CONFIG}
   sed -i '/com.netiq.rra/d' ${ISM_CONFIG}
   sed -i '/com.netiq.ualanding/d' ${ISM_CONFIG}
}

update_config_update()
{
if [ "$debug" = 'y' ]
then
	set -x
fi
    write_log "Updating ISM configurations "
    # TODO Creating this file as workaround, but have to be fixed
    touch ${CONFIG_UPDATE_HOME}/framework-config_3_0.dtd
    local CURR_DIR=`pwd`
    cd "${CONFIG_UPDATE_HOME}/"
    if [ ${IS_UPGRADE} -eq 1 ]
    then   
        #${IDM_JRE_HOME}/bin/java -cp "${CONFIG_UPDATE_HOME}/*" com.netiq.installer.configupdate.RunConfigUpdate ${IDM_BACKUP_FOLDER}/ism-configuration.properties ${UA_APP_CTX} ${IDM_KEYSTORE_PWD} ${IDM_KEYSTORE_PATH} ${ISM_CONFIG}
	yes | cp ${IDM_BACKUP_FOLDER}/ism-configuration.properties ${IDM_TEMP}/
	sed -i.bak 's#\\#\\\\#g' ${IDM_TEMP}/ism-configuration.properties
        merge_ism_props ${IDM_TEMP}/ism-configuration.properties ${ISM_CONFIG}
	if [ ! -z "$UPGRADE_OSP_CONFIGURATION" ] && [ "$UPGRADE_OSP_CONFIGURATION" == "true" ]
	then
	  grep "com.netiq.idm.osp.localhost-auto-add" ${ISM_CONFIG} &> /dev/null
	  if [ $? -eq 0 ]
	  then
	    sed -i "/com.netiq.idm.osp.localhost-auto-add/d" ${ISM_CONFIG}
	    echo "com.netiq.idm.osp.localhost-auto-add = true" >> ${ISM_CONFIG}
	  fi
	fi
        grep -q "com.netiq.idm.rbpm.updateConfig-On-StartUp" ${ISM_CONFIG}
        local result=$?
        if [ ${result} -eq 0 ]
        then
            # from 4.6 onwards
            sed -i 's/com.netiq.idm.rbpm.updateConfig-On-StartUp.*$/com.netiq.idm.rbpm.updateConfig-On-StartUp = true/g' ${ISM_CONFIG}
        else
            # on 4.5.6...
            echo "com.netiq.idm.rbpm.updateConfig-On-StartUp = true" >> ${ISM_CONFIG}
        fi
	grep -q "com.netiq.idm.ua.ldap.keystore-type" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.ua.ldap.keystore-type = JKS" >> ${ISM_CONFIG}
	grep -q "com.netiq.idm.ua.ldap.edit.keystore-type" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.ua.ldap.edit.keystore-type = JKS" >> ${ISM_CONFIG}
	grep -q "com.netiq.idm.ua.ldap.edit.keystore-type.other" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.ua.ldap.edit.keystore-type.other = JKS" >> ${ISM_CONFIG}
	grep -q "com.netiq.idm.osp.oauth-keystore.type" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.osp.oauth-keystore.type = JKS" >> ${ISM_CONFIG}
	grep -q "com.netiq.idm.osp.ssl-keystore.type" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.osp.ssl-keystore.type = JKS" >> ${ISM_CONFIG}
	grep -q "com.netiq.idm.session-timeout" ${ISM_CONFIG}
	[ $? -ne 0 ] && echo "com.netiq.idm.session-timeout=1200" >> ${ISM_CONFIG}
	local ssprhostname=`grep -ir "com.netiq.sspr.redirect.url" ${ISM_CONFIG} | awk '{print $3}' | sed 's/^[ ]*//' | awk -F'oauth' '{print $1}'`
	if ! grep -q com.netiq.idm.osp.login.sspr.forgotten-username-url ${ISM_CONFIG} && [ ! -z "${ssprhostname}" ]
	then
	  echo "com.netiq.idm.osp.login.sspr.forgotten-username-url = ${ssprhostname}/ForgottenUsername" >> ${ISM_CONFIG}
	fi
	if ! grep -q com.netiq.idm.osp.login.sspr.activate-account-url  ${ISM_CONFIG} && [ ! -z "${ssprhostname}" ]
	then
	  echo "com.netiq.idm.osp.login.sspr.activate-account-url = ${ssprhostname}/ActivateUser" >> ${ISM_CONFIG}
	fi
	if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == 'y' ]
	then
	  cp ${ISM_CONFIG} /tmp/ism-configuration.properties.justbeforeCUR
	fi
	sed -i "/com.netiq.rbpm.response-types/d" ${ISM_CONFIG}
	echo "com.netiq.rbpm.response-types = code,client_credentials" >> ${ISM_CONFIG}
	# For new algorithm changing the master key contents before running RunUpgradeConfigUpdate - start
	generate_master_key_file
	# For new algorithm changing the master key contents before running RunUpgradeConfigUpdate - end
        ${IDM_JRE_HOME}/bin/java -cp "${CONFIG_UPDATE_HOME}/*" com.netiq.installer.configupdate.RunUpgradeConfigUpdate "${ISM_CONFIG}" "${UA_APP_CTX}"
	get_ua_osp_host_port
    else
if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == 'y' ]
then
	cp $IDM_TEMP/configupdate.properties /tmp/configupdate.properties.UA.JustbeforeCU
	[ -f /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties ] && cp /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties /tmp/ism-configuration.properties.UA.JustbeforeCU
fi
       ${IDM_JRE_HOME}/bin/java -cp "${CONFIG_UPDATE_HOME}/*" com.netiq.installer.configupdate.RunConfigUpdate $IDM_TEMP/configupdate.properties ${UA_APP_CTX} ${IDM_KEYSTORE_PWD} ${IDM_KEYSTORE_PATH} ${ISM_CONFIG}
    fi
    cd "${CURR_DIR}"  
   chown -R novlua:novlua ${IDM_TOMCAT_HOME} >>$LOG_FILE_NAME
if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == 'y' ]
then
	cp $IDM_TEMP/configupdate.properties /tmp/configupdate.properties.UA
	[ -f /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties ] && cp /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties /tmp/ism-configuration.properties.UA
fi
sed -i '/com.netiq.idm.osp.url.host/d' ${ISM_CONFIG}
sed -i '/com.netiq.client.authserver.url.authorize/d' ${ISM_CONFIG}
sed -i '/com.netiq.client.authserver.url.token/d' ${ISM_CONFIG}
sed -i '/com.netiq.client.authserver.url.logout/d' ${ISM_CONFIG}
sed -i '/com.netiq.client.authserver.url.revoke/d' ${ISM_CONFIG}
sed -i '/com.netiq.idm.osp.oauth.issuer/d' ${ISM_CONFIG}
sed -i '/com.microfocus.idm.application.url/d' ${ISM_CONFIG}
if [ -z ${PROTO} ] || [ "${PROTO}" == "" ]
then
	PROTO=https://
fi
if [ ! -z ${SSO_SERVER_SSL_PORT} ] && [ "${SSO_SERVER_SSL_PORT}" != "" ]
then
  echo "com.netiq.idm.osp.url.host = ${PROTO}${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.authorize = ${PROTO}$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT/osp/a/idm/auth/oauth2/grant" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.token = ${PROTO}${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}/osp/a/idm/auth/oauth2/getattributes" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.logout = ${PROTO}${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}/osp/a/idm/auth/app/logout" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.revoke = ${PROTO}${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}/osp/a/idm/auth/oauth2/revoke" >> ${ISM_CONFIG}
  echo "com.netiq.idm.osp.oauth.issuer = ${PROTO}${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}/osp/a/idm/auth/oauth2" >> ${ISM_CONFIG}
else
  echo "com.netiq.idm.osp.url.host = ${PROTO}${SSO_SERVER_HOST}" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.authorize = ${PROTO}$SSO_SERVER_HOST/osp/a/idm/auth/oauth2/grant" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.token = ${PROTO}${SSO_SERVER_HOST}/osp/a/idm/auth/oauth2/getattributes" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.logout = ${PROTO}${SSO_SERVER_HOST}/osp/a/idm/auth/app/logout" >> ${ISM_CONFIG}
  echo "com.netiq.client.authserver.url.revoke = ${PROTO}${SSO_SERVER_HOST}/osp/a/idm/auth/oauth2/revoke" >> ${ISM_CONFIG}
  echo "com.netiq.idm.osp.oauth.issuer = ${PROTO}${SSO_SERVER_HOST}/osp/a/idm/auth/oauth2" >> ${ISM_CONFIG}
fi
if [ ! -z $UA_SERVER_SSL_PORT ] && [ "$UA_SERVER_SSL_PORT" != "" ]
then
  echo "com.microfocus.idm.application.url = ${PROTO}$UA_SERVER_HOST:$UA_SERVER_SSL_PORT/IDMProv" >> ${ISM_CONFIG}
else
  echo "com.microfocus.idm.application.url = ${PROTO}$UA_SERVER_HOST/IDMProv" >> ${ISM_CONFIG}
fi

if [ "$EXTERNAL_SSO_SERVER" == 'y' ]
then
	sed -i '/com.netiq.idm.osp.oauth-keystore.file/d' ${ISM_CONFIG}
	sed -i '/com.netiq.idmadmin.landing.url/d' ${ISM_CONFIG}
	echo "com.netiq.idmadmin.landing.url = /idmdash/#/landing" >> ${ISM_CONFIG}
	sed -i '/com.microfocus.workflow.clientID/d' ${ISM_CONFIG}
	echo "com.microfocus.workflow.clientID = workflow" >> ${ISM_CONFIG}
	sed -i '/com.microfocus.workflow.landing.url/d' ${ISM_CONFIG}
	echo "com.microfocus.workflow.landing.url = workflow" >> ${ISM_CONFIG}
	sed -i '/com.microfocus.workflow.redirect.url/d' ${ISM_CONFIG}
	echo "com.microfocus.workflow.redirect.url = workflow" >> ${ISM_CONFIG}
	sed -i '/com.microfocus.workflow.response-types/d' ${ISM_CONFIG}
	echo "com.microfocus.workflow.response-types = client_credentials" >> ${ISM_CONFIG}
	sed -i '/com.netiq.idm.forms.url.host/d' ${ISM_CONFIG}
	echo "com.netiq.idm.forms.url.host = https://$FR_SERVER_HOST:$NGINX_HTTPS_PORT" >> ${ISM_CONFIG}
	sed -i '/com.netiq.idm.forms.url.context/d' ${ISM_CONFIG}
	echo "com.netiq.idm.forms.url.context = forms" >> ${ISM_CONFIG}
	sed -i '/com.netiq.forms.clientID/d' ${ISM_CONFIG}
	echo "com.netiq.forms.clientID = forms" >> ${ISM_CONFIG}
	sed -i '/com.netiq.forms.redirect.url/d' ${ISM_CONFIG}
	echo "com.netiq.forms.redirect.url = https://$FR_SERVER_HOST:$NGINX_HTTPS_PORT/forms/oauth.html" >> ${ISM_CONFIG}
	sed -i '/com.netiq.forms.response-types/d' ${ISM_CONFIG}
	echo "com.netiq.forms.response-types = code,token" >> ${ISM_CONFIG}
fi
grep -q "com.microfocus.idm.enable.vlv =" ${ISM_CONFIG}
[ $? -ne 0 ] && echo "com.microfocus.idm.enable.vlv = true" >> ${ISM_CONFIG}
grep -q "com.microfocus.idm.max.users.limit" ${ISM_CONFIG}
[ $? -ne 0 ] && echo "com.microfocus.idm.max.users.limit = 1000" >> ${ISM_CONFIG}
grep -q "com.microfocus.idm.min.search.characters" ${ISM_CONFIG}
[ $? -ne 0 ] && echo "com.microfocus.idm.min.search.characters = 3" >> ${ISM_CONFIG}
sed -i '/com.microfocus.workflow.migration.tables/d' ${ISM_CONFIG}
#echo "com.microfocus.workflow.migration.tables = afmodel,afprocess,afdocument,afactivity,afactivitytimertasks,afbranch,afcomment,afprovisioningstatus,afquorum,afworktask,configuration,email_approval_token,localization,processed_eba_mails" >> ${ISM_CONFIG}
grep -q "com.netiq.rbpm.pwd-expiry.sspr.redirect.enable" ${ISM_CONFIG}
if [ $? -ne 0 ] 
then
  echo "com.netiq.rbpm.pwd-expiry.sspr.redirect.enable=false" >> ${ISM_CONFIG}
fi

	grep -q "com.netiq.idmengine.clientPass" ${ISM_CONFIG}
        if [ $? -ne 0 ]
        then
                echo "com.netiq.idmengine.clientPass._attr_obscurity = ENCRYPT" >> ${ISM_CONFIG}
                echo "com.netiq.idmengine.clientPass = `$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${CONFIG_UPDATE_HOME}/* com.netiq.installer.utils.CryptUtil encrypt ${SSO_SERVICE_PWD}`" >> ${ISM_CONFIG}
        fi
}

#Temperory Fix to update ism-configupdate.properties with old Keys
update_old_keys()
{
        local ism_file=${IDM_TOMCAT_HOME}/conf/ism-configuration.properties
        search_and_replace "com.novell.idm.ldap.admin.pwd" "com.novell.idm.ldap.admin.pass" "$ism_file"
        search_and_replace "com.netiq.rpt.client.pass" "com.netiq.rpt.clientPass" "$ism_file"
        search_and_replace "com.netiq.dcsdrv.client.pass" "com.netiq.dcsdrv.clientPass" "$ism_file"
        search_and_replace "com.netiq.idmdash.clientpass" "com.netiq.idmdash.clientPass" "$ism_file"
        search_and_replace "com.netiq.rbpm.client.pass" "com.netiq.rbpm.clientPass" "$ism_file"
        search_and_replace "com.netiq.uadash.client.pass" "com.netiq.uadash.clientPass" "$ism_file"
        search_and_replace "com.netiq.sspr.client.pass" "com.netiq.sspr.clientPass" "$ism_file"

}

create_wfe_db()
{
	su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH PGPASSWORD='${UA_WFE_DATABASE_ADMIN_PWD}' ${POSTGRES_HOME}/bin/createdb -h ${UA_WFE_DB_HOST} -p ${UA_WFE_DB_PORT} -U postgres ${WFE_DATABASE_NAME} -O ${UA_WFE_DATABASE_USER}" >> "${LOG_FILE_NAME}" 2>&1
}

configure_database()
{

    str1=`gettext install "Configuring the database. The configuration may take few minutes"`
    write_and_log "$str1"
    if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ] && [ "${INSTALL_PG_DB}" == "y" ]
    then
    echo postgres:${UA_WFE_DATABASE_ADMIN_PWD}| /usr/sbin/chpasswd >> "${LOG_FILE_NAME}" 2>&1
    mkdir ${POSTGRES_HOME}/data >> "${LOG_FILE_NAME}" 2>&1
    mkdir /home/users/postgres >> "${log_file}" 2>&1
    chown -R postgres:postgres ${POSTGRES_HOME} >> "${log_file}" 2>&1
    chown -R postgres:postgres /home/users/postgres >> "${log_file}" 2>&1
    #mkdir ${POSTGRES_HOME}/data/pg_log/
    mkdir /home/postgres >> "${LOG_FILE_NAME}" 2>&1

    chown -R postgres:postgres /home/postgres >> "${LOG_FILE_NAME}" 2>&1

    su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH ${POSTGRES_HOME}/bin/initdb -D ${POSTGRES_HOME}/data" >> "${LOG_FILE_NAME}" 2>&1
    if [ ! -d ${POSTGRES_HOME}/data/pg_log ]
    then
        mkdir ${POSTGRES_HOME}/data/pg_log >> "${LOG_FILE_NAME}" 2>&1
    fi
    chown -R postgres:postgres /opt/netiq/idm/postgres >> "${LOG_FILE_NAME}" 2>&1

    echo "host    all             all       0.0.0.0/0    trust" >> ${POSTGRES_HOME}/data/pg_hba.conf
    echo "listen_addresses = '*'" >> ${POSTGRES_HOME}/data/postgresql.conf
    #If the Database port is not the default port 5432
    if [ ${UA_WFE_DB_PORT} != "5432" ]
    then
       sed -i "s/#port = 5432/port = ${UA_WFE_DB_PORT}/g" ${POSTGRES_HOME}/data/postgresql.conf
    fi

    cp ${POSTGRES_HOME}/data/pg_hba.conf ${POSTGRES_HOME}/data/pg_hba.conf.idmcfg
    
    export PGPASSWORD=${UA_WFE_DATABASE_ADMIN_PWD}
    #Since restart is not working, stopping and then starting.
    systemctl stop netiq-postgresql >> "${LOG_FILE_NAME}" 2>&1
	if [ $? -ne 0 ]
	then
		/etc/init.d/netiq-postgresql stop >> "${LOG_FILE_NAME}" 2>&1
	fi
    systemctl start netiq-postgresql >> "${LOG_FILE_NAME}" 2>&1
	if [ $? -ne 0 ]
	then
		/etc/init.d/netiq-postgresql start >> "${LOG_FILE_NAME}" 2>&1
	fi

    str1=`gettext install "Setting up database users and schema..."`
    write_and_log "$str1"

    local ua_db_pwd=`echo ${UA_WFE_DATABASE_PWD} | sed 's|\\$|\\\\\$|g'`
    local ua_db_admin_pwd=`echo ${UA_WFE_DATABASE_ADMIN_PWD} | sed 's|\\$|\\\\\$|g'`
    su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH PGPASSWORD='${ua_db_admin_pwd}' ${POSTGRES_HOME}/bin/psql -h ${UA_WFE_DB_HOST} -p ${UA_WFE_DB_PORT} -c \"CREATE USER ${UA_WFE_DATABASE_USER} WITH PASSWORD '$ua_db_pwd';\"" >> "${LOG_FILE_NAME}" 2>&1
    su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH PGPASSWORD='${ua_db_admin_pwd}' ${POSTGRES_HOME}/bin/createdb -h ${UA_WFE_DB_HOST} -p ${UA_WFE_DB_PORT} -U postgres ${UA_DATABASE_NAME} -O ${UA_WFE_DATABASE_USER}" >> "${LOG_FILE_NAME}" 2>&1
    create_wfe_db
    
    #set password for postgres user
    set_pg_pass
     #postgres - end
    fi
    
    #Schema creation
    liquibase_database_schema
}

liquibase_database_schema()
{ 
    forAzurePGSSL
    local ua_driver_dn=
    if [ ${IS_UPGRADE} -eq 1 ]
    then
        ua_driver_dn="${ID_VAULT_DRIVER_SET}"
    else
        ua_driver_dn="cn=${UA_DRIVER_NAME},cn=${ID_VAULT_DRIVER_SET},${ID_VAULT_DEPLOY_CTX}"
    fi
  
    if [ -f "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml" ]
    then
    	grep -q com.novell.idm.nrf.persist.RequestCounter "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	if [ $? -ne 0 ]
	then
		sed -i "s#com.netiq.icfg.srv.persist.ItemCategory'/>#com.netiq.icfg.srv.persist.ItemCategory'/>\n\t<mapping class='com.novell.idm.nrf.persist.RequestCounter'/>#" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	fi
	grep -q com.netiq.icfg.srv.persist.PageItem "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	if [ $? -ne 0 ]
	then
		sed -i "s#com.netiq.icfg.srv.persist.ItemCategory'/>#com.netiq.icfg.srv.persist.ItemCategory'/>\n\t<mapping class='com.netiq.icfg.srv.persist.PageItem'/>#" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	fi
	grep -q com.netiq.idm.cart.impl.UserCartEntry "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	if [ $? -ne 0 ]
	then
		sed -i "s#com.netiq.icfg.srv.persist.ItemCategory'/>#com.netiq.icfg.srv.persist.ItemCategory'/>\n\t<mapping class='com.netiq.idm.cart.impl.UserCartEntry'/>#" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	fi
	grep -q com.netiq.idm.cart.impl.UserCartItemEntry "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	if [ $? -ne 0 ]
	then
		sed -i "s#com.netiq.icfg.srv.persist.ItemCategory'/>#com.netiq.icfg.srv.persist.ItemCategory'/>\n\t<mapping class='com.netiq.idm.cart.impl.UserCartItemEntry'/>#" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	fi
	grep -q com.netiq.idm.cart.impl.UserCartItemEntryDetail "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	if [ $? -ne 0 ]
	then
		sed -i "s#com.netiq.icfg.srv.persist.ItemCategory'/>#com.netiq.icfg.srv.persist.ItemCategory'/>\n\t<mapping class='com.netiq.idm.cart.impl.UserCartItemEntryDetail'/>#" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	fi
	grep -q com.netiq.idm.cprs.CprsRequests "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	if [ $? -ne 0 ]
	then
		sed -i "s#com.netiq.icfg.srv.persist.ItemCategory'/>#com.netiq.icfg.srv.persist.ItemCategory'/>\n\t<mapping class='com.netiq.idm.cprs.CprsRequests'/>#" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	fi
	grep -q com.netiq.idm.settings.DashboardGlobalTiles "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	if [ $? -ne 0 ]
	then
		sed -i "s#com.netiq.icfg.srv.persist.ItemCategory'/>#com.netiq.icfg.srv.persist.ItemCategory'/>\n\t<mapping class='com.netiq.idm.settings.DashboardGlobalTiles'/>#" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
	fi
    fi
    #Incase of upgrade we will read the database configuration from server.xml file
    if [ ${IS_UPGRADE} -ne 1 ]
    then
        # Based on the selected database we have to create the schema
        if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
	then
	  UA_DB_DRIVER_CLASS="liquibase.database.core.PostgresDatabase"
	  UA_DB_DRIVER="org.postgresql.Driver"
          UA_DB_CONNECTION_URL="jdbc:postgresql://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${UA_DATABASE_NAME}?compatible=true$AMPERSANDMARK$AZUREPGSSL"
          WFE_DB_CONNECTION_URL="jdbc:postgresql://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}?compatible=true$AMPERSANDMARK$AZUREPGSSL"

        elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
        then
	       UA_DB_DRIVER_CLASS="com.novell.soa.persist.OracleUnicodeDatabase"
	       UA_DB_DRIVER="oracle.jdbc.driver.OracleDriver"
	       if [ "${UA_ORACLE_DATABASE_TYPE}" == "service" ]
           then
	         UA_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${UA_DATABASE_NAME}"
	         WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}"
	       elif [ "${UA_ORACLE_DATABASE_TYPE}" == "sid" ]
           then
	  	      UA_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${UA_DATABASE_NAME}"
	          WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${WFE_DATABASE_NAME}"
	       fi
          #Update the hibernate.cfg.xml file
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle10gDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle10gDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate-workflow.cfg.xml"

        elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
	then
	  UA_DB_DRIVER_CLASS="com.novell.soa.persist.MSSQLUnicodeDatabase"
	  UA_DB_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
          UA_DB_CONNECTION_URL="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${UA_DATABASE_NAME}"
          WFE_DB_CONNECTION_URL="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${WFE_DATABASE_NAME}"
          #Update the hibernate.cfg.xml file
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"  
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate-workflow.cfg.xml"  
        fi
    else 
      if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
      then
         #Update the hibernate.cfg.xml file
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle10gDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.Oracle10gDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate-workflow.cfg.xml"
		  if [ "${UA_ORACLE_DATABASE_TYPE}" == "service" ]
          then
	        WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}"
		  elif [ "${UA_ORACLE_DATABASE_TYPE}" == "sid" ]
          then
		    WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${WFE_DATABASE_NAME}"
		  fi
      elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
      then
          #Update the hibernate.cfg.xml file
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate.cfg.xml"
          sed -i "s#com.netiq.persist.PostgreSQLDialect#com.netiq.persist.SQLServerDialect#g" "${IDM_TOMCAT_HOME}/conf/hibernate-workflow.cfg.xml"  
	  WFE_DB_CONNECTION_URL="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${WFE_DATABASE_NAME}"
      elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
      then
      	WFE_DB_CONNECTION_URL="jdbc:postgresql://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}?compatible=true$AMPERSANDMARK$AZUREPGSSL"
        fi
    fi

    #Copy the jdbc jar file to tomcat/lib folder.
    if [ -f ${UA_WFE_DB_JDBC_DRIVER_JAR} ] 
    then
       cp -p ${UA_WFE_DB_JDBC_DRIVER_JAR} ${IDM_TOMCAT_HOME}/lib/ &> /dev/null
    fi 

	
    cd $UA_CONFIG_HOME >> "${LOG_FILE_NAME}"

    cp ${IDM_INSTALL_HOME}user_application/scripts/clear-checksums.sh ${UA_CONFIG_HOME}/
    cp ${IDM_INSTALL_HOME}user_application/scripts/update-context.sh ${UA_CONFIG_HOME}/

    local checksum_file=${UA_CONFIG_HOME}/clear-checksums.sh
    search_and_replace "__IDM_JRE_HOME_"  "$IDM_JRE_HOME" "$checksum_file"
    search_and_replace "__UA_CONFIG_HOME__"  "$UA_CONFIG_HOME" "$checksum_file"
    search_and_replace "__UA_DB_JDBC_DRIVER_JAR__"  "$UA_WFE_DB_JDBC_DRIVER_JAR" "$checksum_file"
    search_and_replace "__IDM_TOMCAT_HOME__"  "$IDM_TOMCAT_HOME" "$checksum_file"
    search_and_replace "__UA_APP_CTX__"  "$UA_APP_CTX" "$checksum_file"
    search_and_replace "__WFE_APP_CTX__"  "$WFE_APP_CTX" "$checksum_file"
    search_and_replace "_UA_DB_DRIVER__"  "$UA_DB_DRIVER" "$checksum_file"
    search_and_replace "__UA_DB_CONNECTION_URL__"  "$UA_DB_CONNECTION_URL" "$checksum_file"
    search_and_replace "__WFE_DB_CONNECTION_URL__"  "$WFE_DB_CONNECTION_URL" "$checksum_file"
    	
    local update_context_file=${UA_CONFIG_HOME}/update-context.sh
    search_and_replace "__IDM_JRE_HOME_"  "$IDM_JRE_HOME" "$update_context_file"
    search_and_replace "__UA_CONFIG_HOME__"  "$UA_CONFIG_HOME" "$update_context_file"
    search_and_replace "__UA_DB_JDBC_DRIVER_JAR__"  "$UA_WFE_DB_JDBC_DRIVER_JAR" "$update_context_file"
    search_and_replace "__IDM_TOMCAT_HOME__"  "$IDM_TOMCAT_HOME" "$update_context_file"
    search_and_replace "__UA_APP_CTX__"  "$UA_APP_CTX" "$update_context_file"
    search_and_replace "__WFE_APP_CTX__"  "$WFE_APP_CTX" "$update_context_file"
    search_and_replace "_UA_DB_DRIVER__"  "$UA_DB_DRIVER" "$update_context_file"
    search_and_replace "__UA_DB_CONNECTION_URL__"  "$UA_DB_CONNECTION_URL" "$update_context_file"
    search_and_replace "__WFE_DB_CONNECTION_URL__"  "$WFE_DB_CONNECTION_URL" "$update_context_file"
	
    if [ "${UA_DB_NEW_OR_EXIST}" == "exist" ]
    then
     UA_CONTEXT_DB_UPDATE="updatedb"
   
    ${IDM_JRE_HOME}/bin/java -cp "${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war --url="${UA_DB_CONNECTION_URL}" --contexts="prov,updatedb" --logLevel=debug  --username=${UA_WFE_DATABASE_USER} --password=${UA_WFE_DATABASE_PWD} clearCheckSums >> "${DB_LOG_OUT}" 2>&1
    
    elif [ "${UA_DB_NEW_OR_EXIST}" == "new" ]
    then
     UA_CONTEXT_DB_UPDATE="newdb"
    fi

    if [ "${WFE_DB_NEW_OR_EXIST}" == "exist" ]
    then
     WFE_CONTEXT_DB_UPDATE="updatedb"
   
    ${IDM_JRE_HOME}/bin/java -cp "${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${WFE_APP_CTX}.war --url="${WFE_DB_CONNECTION_URL}" --contexts="prov,updatedb" --logLevel=debug  --username=${UA_WFE_DATABASE_USER} --password=${UA_WFE_DATABASE_PWD} clearCheckSums >> "${DB_LOG_OUT}" 2>&1
    
    elif [ "${WFE_DB_NEW_OR_EXIST}" == "new" ]
    then
     WFE_CONTEXT_DB_UPDATE="newdb"
    fi
    
    cd $UA_CONFIG_HOME >> "${LOG_FILE_NAME}"
    unzip -q -d $IDM_TEMP/WorkflowMigration ${IDM_INSTALL_HOME}user_application/IDM_Tools/WorkflowMigration.zip
    cp -p ${UA_WFE_DB_JDBC_DRIVER_JAR} $IDM_TEMP/WorkflowMigration/WEB-INF/lib/jdbcDriver.jar &> /dev/null

    if [ "${UA_WFE_DB_CREATE_OPTION}" == "file" ]
    then
     ${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${UA_APP_CTX} -Ddriver.dn="${ua_driver_dn}" -Duser.container="${USER_CONTAINER}" -cp "${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url="${UA_DB_CONNECTION_URL}" --contexts="prov,${UA_CONTEXT_DB_UPDATE}" --logLevel=debug  --username=${UA_WFE_DATABASE_USER} --password=${UA_WFE_DATABASE_PWD} updateSQL > ${UA_DB_SCHEMA_FILE} 2>> "${DB_LOG_OUT}"
    
    execCmdToLog="${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${UA_APP_CTX} -Ddriver.dn=\"${ua_driver_dn}\" -Duser.container=\"${USER_CONTAINER}\" -cp ${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/* liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url=\"${UA_DB_CONNECTION_URL}\" --contexts=\"prov,${UA_CONTEXT_DB_UPDATE}\" --logLevel=debug  --username=**** --password=**** updateSQL > ${UA_DB_SCHEMA_FILE}"
    # WFE
     ${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${WFE_APP_CTX} -Ddriver.dn="${ua_driver_dn}" -Duser.container="${USER_CONTAINER}" -cp "${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${WFE_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url="${WFE_DB_CONNECTION_URL}" --contexts="prov,${WFE_CONTEXT_DB_UPDATE}" --logLevel=debug  --username=${UA_WFE_DATABASE_USER} --password=${UA_WFE_DATABASE_PWD} updateSQL > ${WFE_DB_SCHEMA_FILE} 2>> "${DB_LOG_OUT}"
    execCmd2ToLog="${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${WFE_APP_CTX} -Ddriver.dn=\"${ua_driver_dn}\" -Duser.container=\"${USER_CONTAINER}\" -cp ${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/* liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${WFE_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url=\"${WFE_DB_CONNECTION_URL}\" --contexts=\"prov,${WFE_CONTEXT_DB_UPDATE}\" --logLevel=debug  --username=**** --password=**** updateSQL > ${WFE_DB_SCHEMA_FILE}"
    write_log "*************************************************"
    write_log "$execCmdToLog"
    write_log "$execCmd2ToLog"
    write_log "*************************************************"

    elif [ "${UA_WFE_DB_CREATE_OPTION}" == "now" ]
    then
      ##Need to correct later
      if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
      then
           "${IDM_JRE_HOME}/bin/java" -classpath "${IDM_INSTALL_HOME}common/lib/idmjdbc.jar:${UA_WFE_DB_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${UA_DB_CONNECTION_URL}"  -u ${UA_WFE_DATABASE_USER} -p ${UA_WFE_DATABASE_PWD} -s "insert into databasechangelog(id, author, filename, dateexecuted, orderexecuted,exectype, description,comments, liquibase) values('410', 'IDMRBPM', 'ProvisioningViewValueConstraint45.xml', now(), 796, 'EXECUTED', 'sql', 'Dummy RECORD - TEMP SOLUTION', '3.2.2');" >> /dev/null 2>&1
           "${IDM_JRE_HOME}/bin/java" -classpath "${IDM_INSTALL_HOME}common/lib/idmjdbc.jar:${UA_WFE_DB_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${UA_DB_CONNECTION_URL}"  -u ${UA_WFE_DATABASE_USER} -p ${UA_WFE_DATABASE_PWD} -s "GRANT ALL PRIVILEGES ON DATABASE ${UA_DATABASE_NAME} to ${UA_WFE_DATABASE_USER};" >> /dev/null 2>&1
	   # WFE
           "${IDM_JRE_HOME}/bin/java" -classpath "${IDM_INSTALL_HOME}common/lib/idmjdbc.jar:${UA_WFE_DB_JDBC_DRIVER_JAR}" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "${WFE_DB_CONNECTION_URL}"  -u ${UA_WFE_DATABASE_USER} -p ${UA_WFE_DATABASE_PWD} -s "GRANT ALL PRIVILEGES ON DATABASE ${WFE_DATABASE_NAME} to ${UA_WFE_DATABASE_USER};" >> /dev/null 2>&1
      fi

      ${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${UA_APP_CTX} -Ddriver.dn="${ua_driver_dn}" -Duser.container="${USER_CONTAINER}" -cp "${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url="${UA_DB_CONNECTION_URL}" --contexts="prov,newdb,updatedb" --logLevel=debug  --username=${UA_WFE_DATABASE_USER} --password=${UA_WFE_DATABASE_PWD} update >> "${DB_LOG_OUT}" 2>&1
    
     execCmdToLog="${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${UA_APP_CTX} -Ddriver.dn=\"${ua_driver_dn}\" -Duser.container=\"${USER_CONTAINER}\" -cp ${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/* liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${UA_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url=\"${UA_DB_CONNECTION_URL}\" --contexts=\"prov,newdb,updatedb\" --logLevel=debug  --username=***** --password=**** update"
     # WFE
      ${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${WFE_APP_CTX} -Ddriver.dn="${ua_driver_dn}" -Duser.container="${USER_CONTAINER}" -cp "${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${WFE_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url="${WFE_DB_CONNECTION_URL}" --contexts="prov,newdb,updatedb" --logLevel=debug  --username=${UA_WFE_DATABASE_USER} --password=${UA_WFE_DATABASE_PWD} update >> "${DB_LOG_OUT}" 2>&1
      if [ $IS_UPGRADE -eq 1 ]
      then
	cd $IDM_TEMP/WorkflowMigration
	${IDM_JRE_HOME}/bin/java -jar Workflow-Migration.jar -e workflowdata.zip -surl "${UA_DB_CONNECTION_URL}" -suser ${UA_WFE_DATABASE_USER} -spwd ${UA_WFE_DATABASE_PWD} -sdb $UA_WFE_DB_PLATFORM_OPTION >> "${DB_LOG_OUT}" 2>&1
	${IDM_JRE_HOME}/bin/java -jar Workflow-Migration.jar -i workflowdata.zip -durl "${WFE_DB_CONNECTION_URL}" -duser ${UA_WFE_DATABASE_USER} -dpwd ${UA_WFE_DATABASE_PWD} -ddb $UA_WFE_DB_PLATFORM_OPTION >> "${DB_LOG_OUT}" 2>&1
	cd - &> /dev/null
      fi
    
     execCmd2ToLog="${IDM_JRE_HOME}/bin/java  -Dwar.context.name=${WFE_APP_CTX} -Ddriver.dn=\"${ua_driver_dn}\" -Duser.container=\"${USER_CONTAINER}\" -cp ${UA_CONFIG_HOME}/liquibase.jar:${UA_CONFIG_HOME}/liquibase/lib/* liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=${UA_DB_DRIVER} --classpath=${UA_WFE_DB_JDBC_DRIVER_JAR}:${IDM_TOMCAT_HOME}/webapps/${WFE_APP_CTX}.war --changeLogFile=DatabaseChangeLog.xml  --url=\"${WFE_DB_CONNECTION_URL}\" --contexts=\"prov,newdb,updatedb\" --logLevel=debug  --username=***** --password=**** update"
    write_log "*************************************************" 
    write_log "$execCmdToLog" 
    write_log "$execCmd2ToLog" 
    write_log "*************************************************"

  elif [ "${UA_WFE_DB_CREATE_OPTION}" == "startup" ]
   then
      str1=`gettext install "User chose to Create tables at startup"`
      write_and_log "$str1"
      sed -i "s#com.netiq.idm.create-db-on-startup = false#com.netiq.idm.create-db-on-startup = true#g" "${IDM_TOMCAT_HOME}/conf/ism-configuration.properties"
   fi

    
    cd $CURRENT_DIR  
}

set_pg_pass()
{
        sed -i "s/# TYPE  DATABASE        USER            ADDRESS                 METHOD/local    postgres     postgres     peer/g" ${POSTGRES_HOME}/data/pg_hba.conf
        local ua_db_admin_pwd=`echo ${UA_WFE_DATABASE_ADMIN_PWD} | sed 's|\\$|\\\\\$|g'`
        su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH PGPASSWORD='${ua_db_admin_pwd}' ${POSTGRES_HOME}/bin/psql -h ${UA_WFE_DB_HOST} -p ${UA_WFE_DB_PORT} -U postgres -c \"ALTER USER postgres PASSWORD '${ua_db_admin_pwd}';\"" >> "${LOG_FILE_NAME}" 2>&1
        sed -i "s/local    postgres     postgres     peer/# TYPE  DATABASE        USER            ADDRESS                 METHOD/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/local   all             all                                     trust/local   all             all                                     md5/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/host    all             all             127.0.0.1\/32            trust/host    all             all             127.0.0.1\/0            md5/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/host    all             all             ::1\/128                 trust/host    all             all             ::1\/128                 md5/g" ${POSTGRES_HOME}/data/pg_hba.conf
        sed -i "s/host    all             all       0.0.0.0\/0    trust//g" ${POSTGRES_HOME}/data/pg_hba.conf
        systemctl restart netiq-postgresql >> "${log_file}" 2>&1
	if [ $? -ne 0 ]
	then
		/etc/init.d/netiq-postgresql stop >> "${log_file}" 2>&1
		/etc/init.d/netiq-postgresql start >> "${log_file}" 2>&1
	fi
}

configure_activemq()
{

    write_log "Configuring Message Queue "
}


generate_master_key_file()
{
    grep -q com.novell.idm.masterkey.is.encrypted ${ISM_CONFIG}
    if [ $? -eq 0 ]
    then
    	grep com.novell.idm.masterkey.is.encrypted ${ISM_CONFIG} | grep -q true
	if [ $? -eq 0 ]
	then
		#Need not update the master key as it is already with the new algorithm required
		return
	fi
    fi
    str1=`gettext install "Generating/Updating master key"`
    write_and_log "$str1"
    touch ${ISM_CONFIG}
    $IDM_JRE_HOME/bin/java -cp "${CONFIG_UPDATE_HOME}/*" com.sssw.fw.util.crypto.SensitiveDataManagement -newmaster ${ISM_CONFIG_HOME} ${ISM_CONFIG_FILE_NAME} 

    $IDM_JRE_HOME/bin/java -cp "${CONFIG_UPDATE_HOME}/*" com.sssw.fw.util.crypto.SensitiveDataManagement -exportmaster ${ISM_CONFIG_HOME} ${ISM_CONFIG_FILE_NAME} >${UA_CONFIG_HOME}/master-key.txt

}


configure_auditing()
{
   write_log "Configuring Auditing "
   modify_logging_xml
   configure_audit
}

create_driver_property_file()
{
    write_log "Creating driver configuration files. "
    cp ${IDM_INSTALL_HOME}user_application/driver_conf/NOV*.properties $IDM_TEMP/ >>$LOG_FILE_NAME  2>&1
    local rrsd_prop_file=$IDM_TEMP/NOVLRSERVB.properties
    local ua_prop_file=$IDM_TEMP/NOVLUABASE.properties

# Temprorarly copy back,
#cp $IDM_TEMP/NOV*.properties ${IDM_INSTALL_HOME}user_application/driver_conf

    #ua_url="http://${LOCAL_IP}:${TOMCAT_HTTP_PORT}/${UA_APP_CTX}"

    #search_and_replace "___UA_URL___"  $LOCAL_IP "$rrsd_prop_file"
    #search_and_replace "___ID_VAULT_ADMIN___"  $ID_VAULT_ADMIN "$prop_file"
    #search_and_replace "___ID_VAULT_PASSWORD___"  $ID_VAULT_PASSWORD "$prop_file"

}

update_ua_context()
{
 disp_str=`gettext install "Updating User Application Context"`
 write_and_log "$disp_str"
 #
 local ua_war_file=${IDM_TOMCAT_HOME}/webapps/IDMProv.war

 local CURRENT_FOLDER=`pwd`
 mkdir -p  "${IDM_TEMP}/ua_expanded_war"
 unzip -qq "$ua_war_file" -d "${IDM_TEMP}/ua_expanded_war"
 sed -i "s#IDMProv#${UA_APP_CTX}#g" "${IDM_TEMP}/ua_expanded_war/WEB-INF/web.xml"
 cd ${IDM_TEMP}/ua_expanded_war/
 zip -rq ${UA_APP_CTX}.war *
 #echo ${IDM_TEMP}/ua_expanded_war/${UA_APP_CTX}.war
 cp -r ${IDM_TEMP}/ua_expanded_war/${UA_APP_CTX}.war ${IDM_TOMCAT_HOME}/webapps/
 rm -rf ${IDM_TOMCAT_HOME}/webapps/IDMProv.war
 cd $CURRENT_FOLDER

 #rm -rf ${IDM_TEMP}/ua_expanded_war
}

import_recaptcha_certs()
{
    str1=`gettext install "Import recaptcha public key certificate into keystore."` 
    write_log "$str1"
    import_from_cacert "geotrustglobalca [jdk]"
    import_from_cacert "geotrustprimaryca [jdk]"
    import_from_cacert "geotrustprimarycag2 [jdk]"
    import_from_cacert "geotrustprimarycag3 [jdk]"
}
