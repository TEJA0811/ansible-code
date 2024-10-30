#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

    if [ $IS_UPGRADE -ne 1 ]
    then
    prompt "INSTALL_REPORTING"
    getValidLocalIP "$RPT_DATABASE_HOST"
	
	if [ ! -z $TOMCAT_SERVLET_HOSTNAME ]
	then
		rpt_ip=$TOMCAT_SERVLET_HOSTNAME
	elif [ ! -z $ID_VAULT_HOST ]
	then
		rpt_ip=$ID_VAULT_HOST
	else
		rpt_ip=$IP_ADDR
	fi
	
	if [ -z "$IS_COMMON_PASSWORD" ]
    then
    	common_pwd
	fi
        prompt "RPT_SERVER_HOSTNAME" "$IP_ADDR"
	prompt_port "RPT_TOMCAT_HTTPS_PORT"
        prompt "SSO_SERVER_HOST" "$rpt_ip" 
		prompt "SSO_SERVER_PORT"
	if [ "$RPT_SERVER_HOSTNAME" != "$SSO_SERVER_HOST" ]
	then
          prompt_port "SSO_SERVER_SSL_PORT" '-' '-' "$SSO_SERVER_HOST"
	elif [ "$RPT_SERVER_HOSTNAME" == "$SSO_SERVER_HOST" ]
	then
	  SSO_SERVER_SSL_PORT=$RPT_TOMCAT_HTTPS_PORT
	  save_prompt "SSO_SERVER_SSL_PORT"
	fi
	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	then
	  prompt "FOR_SSPR_CONTAINER" - "y/n"
	  if [ ! -z "$FOR_SSPR_CONTAINER" ] && [ "$FOR_SSPR_CONTAINER" == "y" ]
	  then
	    SSPR_SERVER_SSL_PORT=8443
	    save_prompt "SSPR_SERVER_SSL_PORT"
	    CUSTOM_SSPR_CERTIFICATE=n
	    save_prompt "CUSTOM_SSPR_CERTIFICATE"
	    SSPR_COMM_TOMCAT_KEYSTORE_FILE=NA
	    save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_FILE"
	    SSPR_COMM_TOMCAT_KEYSTORE_PWD=notapplicable
	    save_prompt "SSPR_COMM_TOMCAT_KEYSTORE_PWD"
	    prompt_pwd "CONFIGURATION_PWD" confirm
	  fi
	fi
	prompt "SSPR_SERVER_HOST" "$rpt_ip"
	if [ "$RPT_SERVER_HOSTNAME" != "$SSPR_SERVER_HOST" ]
	then
          prompt_port "SSPR_SERVER_SSL_PORT" '-' '-' "$SSPR_SERVER_HOST"
	elif [ "$RPT_SERVER_HOSTNAME" == "$SSPR_SERVER_HOST" ]
	then
	  SSPR_SERVER_SSL_PORT=$RPT_TOMCAT_HTTPS_PORT
	  save_prompt "SSPR_SERVER_SSL_PORT"
	fi
	if [ ! -z "$SSO_SERVICE_PWD" ] && [ "$SSO_SERVICE_PWD" != "" ]
	then
	  RPT_SSO_SERVICE_PWD=$SSO_SERVICE_PWD
	  save_prompt "RPT_SSO_SERVICE_PWD"
	fi
        prompt_pwd "RPT_SSO_SERVICE_PWD" confirm
	
	if [ -f ${IDM_KEYSTORE_PATH} ] && [ ${IS_WRAPPER_CFG_INST} -ne 1 ] && [ "$CREATE_SILENT_FILE" != true ]
	then
	 str2=`gettext install "Installer has detected that an Identity Manager keystore exists."`
         write_log "$str2"
	fi
	
        prompt_pwd "IDM_KEYSTORE_PWD" confirm
	prompt "RPT_DATABASE_PLATFORM_OPTION" - "postgres/oracle/mssql"
	
  	if [ "$RPT_DATABASE_PLATFORM_OPTION" == "postgres" ]
	then
	    if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "n" ]
	    then
	    	prompt "INSTALL_PG_DB_FOR_REPORTING" - "y/n"
	    else
	    	INSTALL_PG_DB_FOR_REPORTING="n"
		save_prompt "INSTALL_PG_DB_FOR_REPORTING"
	    fi
	fi
	if [ ! -z $AZURE_POSTGRESQL_REQUIRED ] && [ "$AZURE_POSTGRESQL_REQUIRED" == "y" ]
	then
		export RPT_DB_PROMPTS_REQUIRED=true
		export AMPERSANDMARK=\&
		export AZUREPGSSL=ssl=true
		export QUESTIONMARK=?
	fi
   if [[  -z "$RPT_DATABASE_HOST"  ||  -z "$RPT_DATABASE_NAME" || -z "$RPT_DATABASE_USER"  || -z "$RPT_DATABASE_SHARE_PASSWORD"  ]] && [ -z $RPT_DB_PROMPTS_REQUIRED ]
   then

   PROMPT_SAVE="false"
   while true
   do
   
   if [ "$RPT_DATABASE_PLATFORM_OPTION" == "postgres" ]
   then   
     if [ "$INSTALL_PG_DB_FOR_REPORTING" == "n" ]
        then
	        prompt "RPT_DATABASE_HOST" "$rpt_ip"
	    else
	        RPT_DATABASE_HOST=$IP_ADDR	        
        fi
    else
	    prompt "RPT_DATABASE_HOST" "$IP_ADDR"
    fi	
 
    prompt "RPT_DATABASE_NAME"
	prompt "RPT_DATABASE_USER"
	if [ "$RPT_DATABASE_PLATFORM_OPTION" == "oracle" ]
	then
	    prompt "RPT_ORACLE_DATABASE_TYPE" - "sid/service"
	fi
	
	prompt "RPT_DATABASE_PORT" '-' '-' "$RPT_DATABASE_HOST"
	if [ ! -z "$IS_ADVANCED_MODE" ] && [ "$IS_ADVANCED_MODE" == "true" ]
	then
	prompt_pwd "RPT_DATABASE_SHARE_PASSWORD" confirm force
	else
	prompt_pwd "RPT_DATABASE_SHARE_PASSWORD" confirm
	fi

	if [ -z ${KUBERNETES_ORCHESTRATION} ]
	then
	prompt_file "RPT_DATABASE_JDBC_DRIVER_JAR"

	prompt "RPT_DATABASE_CREATE_OPTION" - "now/startup/file"

	if [ "$RPT_DATABASE_CREATE_OPTION" == "now" ]
	then
		prompt "RPT_DATABASE_NEW_OR_EXIST" - "new/exist"
	elif [ "$RPT_DATABASE_CREATE_OPTION" == "file" ]
	then
		prompt "RPT_DATABASE_NEW_OR_EXIST" - "new/exist"
	fi
	fi

    # Based on the selected database we have to create the schema
    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
    then
        RPT_DB_TYPE="PostgreSQL"
        RPT_DATABASE_CONNECTION_URL="jdbc:postgresql://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}?compatible=true${AMPERSANDMARK}${AZUREPGSSL}"
    elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
    then
        RPT_DB_TYPE="Oracle"
        if [ "${RPT_ORACLE_DATABASE_TYPE}" == "service" ]
        then
            RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
        elif [ "${RPT_ORACLE_DATABASE_TYPE}" == "sid" ]
        then
            RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}:${RPT_DATABASE_NAME}"
        fi
    elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
    then
        RPT_DB_TYPE="SQL Server"
        RPT_DATABASE_CONNECTION_URL="jdbc:sqlserver://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT};DatabaseName=${RPT_DATABASE_NAME}"
    fi

    if [ "$INSTALL_PG_DB_FOR_REPORTING" == "y" ]
    then
       SKIP_DATABASE_CONNECTION_VALIDATION=true
    fi 
         
    RET=0
    if [ "$SKIP_DATABASE_CONNECTION_VALIDATION" != "true" ] && [ "$CREATE_SILENT_FILE" != true ]
    then
       verify_db_connection ${RPT_DATABASE_USER} ${RPT_DATABASE_SHARE_PASSWORD} "${RPT_DATABASE_CONNECTION_URL}" "${RPT_DB_TYPE}" ${RPT_DATABASE_JDBC_DRIVER_JAR}
       RET=$?
    fi

    if (( $RET != 0 )); then
                echo_sameline ""
                echo_sameline "${txtred}"
                str1=`gettext install "ERROR: Could not connect to the Database."`
                write_and_log $str1
                echo_sameline "${txtrst}"
                echo_sameline "${txtylw}"
                read1=`gettext install "To re-enter the connection details, press Enter."`
                read -p "$read1"
                echo_sameline "${txtrst}"
                echo_sameline ""
    else
        if [ "$SKIP_DATABASE_CONNECTION_VALIDATION" != "true" ] && [ "$CREATE_SILENT_FILE" != true ]
       then
               str_sucess=`gettext install "Database Connection Successful."` 
               write_and_log $str_sucess
       fi
             break
    fi
   done
   save_prompt "RPT_DATABASE_HOST" 
   save_prompt "RPT_DATABASE_PORT"
   save_prompt "RPT_DATABASE_NAME"
   save_prompt "RPT_DATABASE_USER"
   save_prompt "RPT_ORACLE_DATABASE_TYPE"
   save_prompt "RPT_DATABASE_SHARE_PASSWORD"
   save_prompt "RPT_DATABASE_JDBC_DRIVER_JAR"
   save_prompt "RPT_DATABASE_CREATE_OPTION"
   save_prompt "RPT_DATABASE_NEW_OR_EXIST"
  fi
   
   

	if [ ! -z "$INSTALL_PG_DB_FOR_REPORTING" ] && [ "$INSTALL_PG_DB_FOR_REPORTING" == "y" ] && [ "$CREATE_SILENT_FILE" != true ]
	then
		install_postgres
	fi

	
	prompt "TOMCAT_HTTP_PORT"
	if [ -z "$TOMCAT_HTTP_PORT" ]
	then
		prompt "RPT_TOMCAT_HTTP_PORT"
	else
		 RPT_TOMCAT_HTTP_PORT=$TOMCAT_HTTP_PORT
		 save_prompt "RPT_TOMCAT_HTTP_PORT" 
 	fi	 		 	 		 			 	 		 	 		 		 	 		 			 	 		 	 
	prompt_pwd "TOMCAT_SSL_KEYSTORE_PASS" confirm
	if [ -z "$TOMCAT_HTTPS_PORT" ]
	then 
		prompt_port "RPT_TOMCAT_HTTPS_PORT"
		TOMCAT_HTTPS_PORT=$RPT_TOMCAT_HTTPS_PORT
		save_prompt "TOMCAT_HTTPS_PORT"
	else
	  if [ -z "$RPT_TOMCAT_HTTPS_PORT" ]
	  then
		RPT_TOMCAT_HTTPS_PORT=$TOMCAT_HTTPS_PORT
		save_prompt "RPT_TOMCAT_HTTPS_PORT" 
	  fi
	fi
	prompt "RPT_APP_CTX"
	
	prompt "RPT_DEFAULT_EMAIL_ADDRESS"
	
	prompt "RPT_SMTP_CONFIGURE" - "y/n"
	if [ "$RPT_SMTP_CONFIGURE" == "y" ]
	then
		prompt "RPT_SMTP_SERVER"
		prompt "RPT_SMTP_SERVER_PORT" '-' '-' "$RPT_SMTP_SERVER"
	fi

     prompt "RPT_ADMIN"
	prompt "RPT_CREATE_DRIVERS" - "y/n"

    if [ "$RPT_CREATE_DRIVERS" == "y" ] 
    then
          prompt "USER_CONTAINER"
	fi

        PROMPT_SAVE="false"
    	if [ -z "$ID_VAULT_HOST" -o  -z "$ID_VAULT_LDAPS_PORT" -o -z "$ID_VAULT_ADMIN_LDAP"  -o -z "$ID_VAULT_PASSWORD"    ]
    	then
        while true
	        do
	            prompt "ID_VAULT_HOST" "$rpt_ip"
	            prompt_port "ID_VAULT_LDAPS_PORT" '-' '-' "$ID_VAULT_HOST"
	            prompt "ID_VAULT_ADMIN_LDAP"
	            convert_dot_notation ${ID_VAULT_ADMIN_LDAP}
	
	            prompt "ID_VAULT_ADMIN" $RET
	            prompt_pwd "ID_VAULT_PASSWORD" 
	            RET=0
		
	            if [ "$SKIP_LDAP_SERVER_VALIDATION" != "true" ]
	            then
	               verify_ldap_connection $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD
	               RET=$?
	            fi
	        
	            if (( $RET != 0 )); then
	                echo ""
					disp_str=`gettext install "ERROR: Could not connect to the Identity Vault."`
					echo_sameline "${txtred}"
	                echo "$disp_str"
					echo_sameline "${txtrst}"
					disp_str=`gettext install "To re-enter the connection details, press Enter."`
					echo_sameline "${txtylw}"
	                echo "$disp_str"
					echo_sameline "${txtrst}"
					read -p "$disp_str"
	                echo ""
	            else
	                echo ""
	               break
	           fi
	       done
       save_prompt "ID_VAULT_HOST"
       save_prompt "ID_VAULT_LDAPS_PORT"
       save_prompt "ID_VAULT_ADMIN_LDAP"
       save_prompt "ID_VAULT_ADMIN"
       save_prompt "ID_VAULT_PASSWORD"
	fi
	   
	  
    if [ "$RPT_CREATE_DRIVERS" == "y" ] 
    then
	    if [ -z "$ID_VAULT_DEPLOY_CTX" ] || [ -z "$ID_VAULT_DRIVER_SET" ]
	    then
		    PROMPT_SAVE="false"
		    while true
		    do    	
		    	prompt "ID_VAULT_DRIVER_SET"
		    	prompt "ID_VAULT_DEPLOY_CTX"
		    	RET=0
		    	if [ "$CREATE_SILENT_FILE" != true ]
		    	then
		    		verify_ldap_dn $ID_VAULT_HOST $ID_VAULT_LDAPS_PORT $ID_VAULT_ADMIN_LDAP $ID_VAULT_PASSWORD "cn=$ID_VAULT_DRIVER_SET,$ID_VAULT_DEPLOY_CTX" 
		    		RET=$?
		    	fi
		    	if (( $RET != 0 )); 
		    		then
		             	echo_sameline ""
		                echo_sameline "${txtred}"
		                str2=`gettext install "ERROR: Container does not exist."`
		                write_and_log "$str2"
		                echo_sameline "${txtrst}"
		                echo_sameline "${txtylw}"
		                read1=`gettext install "To re-enter the container details, press Enter."`
		                read -p "$read1"
		                echo_sameline "${txtrst}"
		                echo_sameline ""
		            else
		                echo ""
		                break
		       fi
			done
			save_prompt "ID_VAULT_DRIVER_SET"
			save_prompt "ID_VAULT_DEPLOY_CTX"
		fi
	fi
    PROMPT_SAVE="true"		
	prompt_pwd "RPT_ADMIN_PWD" confirm
#        prompt "RPT_AUDIT_ENABLED"
#        prompt "RPT_CEF_AUDIT_ENABLED"
#        if [ "$RPT_AUDIT_ENABLED" == "y" ] || [ "$RPT_CEF_AUDIT_ENABLED" == "y" ]
#        then
#            PROMPT_SAVE="false"
#            if [ -z "$SENTINEL_AUDIT_SERVER" ]
#            then
#            prompt "SENTINEL_AUDIT_SERVER"
#            ipFromLogevent=$(echo "$1" | sed -e '/^#/d' /etc/logevent.conf | grep LogHost= | cut -f2- -d=)
#            if [ "$ipFromLogevent" == "Not Configured" ]
#            then
#                sed -i "s/^LogHost=.*$/LogHost=${SENTINEL_AUDIT_SERVER}/" /etc/logevent.conf
#            else
#                if [ "$ipFromLogevent" == "$SENTINEL_AUDIT_SERVER" ]
#                then
#                    echo_sameline ""
#                else
#                    echo_sameline "${txtylw}"
#                    msg=`gettext install "You must configure Identity Applications to use the same auditing server that is used by other Identity Manager components. Specifying a different auditing server disrupts the auditing functionality for other Identity Manager components."`
#                    echo_sameline "$msg"
#                    echo_sameline "${txtrst}"
#                    str1=`gettext install "Are you sure you want to configure a different auditing server. (y/n) [n]:"`
#                    read -p "$str1" reply
#                    echo_sameline ""
#                        if [ "$reply" == "y" ]
#                        then
#                            sed -i "s/^LogHost=.*$/LogHost=${SENTINEL_AUDIT_SERVER}/" /etc/logevent.conf
#                        elif [ "$reply" == "n" ]
#                        then
#                            SENTINEL_AUDIT_SERVER=$ipFromLogevent
#                            msg=`gettext install "Configured using existing auditing configuration for Identity Applications."`
#                            write_and_log "$msg"
#                        fi
#                    fi
#                fi
#            fi
#        save_prompt "SENTINEL_AUDIT_SERVER"
#        fi
#        echo_sameline "${txtrst}"
#    PROMPT_SAVE="true"
	elif [ $IS_UPGRADE -eq 1 ]
	then
		prompt "RPT_OSP_INSTALLED" - "y/n"
	     if [ "$RPT_OSP_INSTALLED" == "y" ]
		then
		    prompt "OSP_INSTALL_FOLDER"
		fi
		prompt "RPT_INSTALL_FOLDER"
		prompt "RPT_DATABASE_CREATE_OPTION" - "now/startup/file"
		prompt_file "RPT_DATABASE_JDBC_DRIVER_JAR"
		prompt "RPT_DATABASE_USER"
		if [ ! -z "$IS_ADVANCED_MODE" ] && [ "$IS_ADVANCED_MODE" == "true" ]
		then
		prompt_pwd "RPT_DATABASE_PASSWORD" confirm force
		else
		prompt_pwd "RPT_DATABASE_PASSWORD" confirm
		fi

	fi
	
	
	if [ ! -z "$CUSTOM_SSPR_CERTIFICATE" ] && [ "$CUSTOM_SSPR_CERTIFICATE" == "y" ] 
	then
	  if [ "$RPT_SERVER_HOSTNAME" == "$SSPR_SERVER_HOST" ]
	  then
	    export customuacertnotneeded=true
	  fi
	fi
	if [ ! -z "$CUSTOM_OSP_CERTIFICATE" ] && [ "$CUSTOM_OSP_CERTIFICATE" == "y" ]
	then
	  if [ "$RPT_SERVER_HOSTNAME" == "$SSO_SERVER_HOST" ]
	  then
	    export customuacertnotneeded=true
	  fi
	fi
	if [ ! -z "$CUSTOM_UA_CERTIFICATE" ] && [ "$CUSTOM_UA_CERTIFICATE" == "y" ] 
	then
	  if [ "$RPT_SERVER_HOSTNAME" == "$UA_SERVER_HOST" ]
	  then
	    export customuacertnotneeded=true
	  fi
	fi
	
if [ ! -z "$IS_UPGRADE" ] && [ $IS_UPGRADE -eq 0 ]
then
  if [ -z "$customuacertnotneeded" ]
  then
	if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
	then
		if [ ! -z "$IDM_ACCESS_VIA_SINGLE_DOMAIN" ]
		then
			CUSTOM_RPT_CERTIFICATE="n"
			save_prompt "CUSTOM_RPT_CERTIFICATE"
		else
			CUSTOM_RPT_CERTIFICATE="y"
			save_prompt "CUSTOM_RPT_CERTIFICATE"
		fi
	fi
	prompt CUSTOM_RPT_CERTIFICATE - "y/n"
        if [ "$CUSTOM_RPT_CERTIFICATE" == "n" ]
        then
                RPT_COMM_TOMCAT_KEYSTORE_FILE=$IDM_TOMCAT_HOME/conf/tomcat.ks
                save_prompt "RPT_COMM_TOMCAT_KEYSTORE_FILE"
                prompt_pwd "TOMCAT_SSL_KEYSTORE_PASS" confirm
                RPT_COMM_TOMCAT_KEYSTORE_PWD=$TOMCAT_SSL_KEYSTORE_PASS
                save_prompt "RPT_COMM_TOMCAT_KEYSTORE_PWD"
        else
                prompt_file "RPT_COMM_TOMCAT_KEYSTORE_FILE"
                prompt_pwd "RPT_COMM_TOMCAT_KEYSTORE_PWD" confirm
        fi
  else
	prompt_file "RPT_COMM_TOMCAT_KEYSTORE_FILE"
	prompt_pwd "RPT_COMM_TOMCAT_KEYSTORE_PWD" confirm
  fi
fi

