##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

##
# Import SSPR related ldif files.
##
import_sspr_ldifs()
{
    
	disp_str=`gettext install "Importing SSPR LDIF configurations to Identity Vault"`
	echo_sameline "$disp_str"

    cp -r ${IDM_INSTALL_HOME}sspr/ldif/* $IDM_TEMP/
    local ldif_file=$IDM_TEMP/ua.ldif
    search_and_replace "___UA_ADMIN___"  $UA_ADMIN "$ldif_file"
    search_and_replace "___UA_ADMIN_PWD___"  "$UA_ADMIN_PWD" "$ldif_file"
    new_import_ldif "$ldif_file"
    rm "$ldif_file"

    ldif_file=$IDM_TEMP/rbpm_sspr_uaadmin_pwdpolicy.ldif
    search_and_replace "___ID_VAULT_ADMIN_LDAP___"  $ID_VAULT_ADMIN_LDAP "$ldif_file"
    search_and_replace "___UA_ADMIN___"  $UA_ADMIN "$ldif_file"
    new_import_ldif "$ldif_file"
    s1=$?
    rm "$ldif_file"

    ldif_file=$IDM_TEMP/sspr-edir-rights.ldif
    search_and_replace "___USER_CONTAINER___"  $USER_CONTAINER "$ldif_file"
    new_import_ldif "$ldif_file"
    s2=$?
    rm "$ldif_file"
    run_sspr_pwdpolicy=0
    if [ ! -z "$EXCLUSIVE_SSPR" ] && [ "$EXCLUSIVE_SSPR" == "true" ]
    then
    	run_sspr_pwdpolicy=1
    fi
    if [ $IS_WRAPPER_CFG_INST -ne 1 ] || [ $run_sspr_pwdpolicy -eq 1 ]
    then
        ldif_file=$IDM_TEMP/sspr_pwdpolicy.ldif
        search_and_replace "___USER_CONTAINER___"  $USER_CONTAINER "$ldif_file"
        new_import_ldif "$ldif_file"
        s3=$?
        rm "$ldif_file"

         if [ $s1 -eq 0 ] && [ $s2 -eq 0 ] && [ $s3 -eq 0 ]
            then
                return 0
            else
                return 1
         fi
    else
        if [ $s1 -eq 0 ] && [ $s2 -eq 0 ]
            then
                return 0
            else
                return 1
        fi
    fi
}

sspr_restore_server_xml()
{
    #later we might need to revisit this function if some new tag appears in server.xml with tomcat upgrade.
    str1=`gettext install "Updating Tomcat configuration "`
    write_and_log "$str1"

     if [ $IS_UPGRADE -eq 1 ]
     then
        if [ -f ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml ]
        then
            cp -p ${IDM_BACKUP_FOLDER}/tomcat/conf/server.xml ${IDM_TOMCAT_HOME}/conf/
        fi
    fi
}

create_SSPRConfiguration()
{
    disp_str=`gettext install "Generating SSPR Configuration.."`
    echo_sameline -e "$disp_str"

    export JAVA_HOME=${IDM_JRE_HOME}
    export SSPR_APPLICATIONPATH=${SSPR_CONFIG_FILE_HOME}
    local sspr_war_file=${IDM_TOMCAT_HOME}/webapps/sspr.war
    local default_idm_sspr_settings="${IDM_TEMP}/default_idm_sspr_settings.xml"

    # Create a temporary folder to expand the war
    mkdir -p  "${IDM_TEMP}/sspr_expanded_war"

    unzip -qq "$sspr_war_file" -d "${IDM_TEMP}/sspr_expanded_war"

    cd ${IDM_TEMP}/sspr_expanded_war/WEB-INF
    chmod +x command.sh
    ./command.sh ConfigNew /opt/netiq/idm/apps/sspr/sspr_data/SSPRConfiguration.xml >> ${LOG_FILE_NAME} 2>&1

    cp ${IDM_INSTALL_HOME}sspr/conf/default_idm_sspr_settings.xml "$default_idm_sspr_settings"
    cd "${IDM_TEMP}"

    search_and_replace "___ID_VAULT_HOST___"  $ID_VAULT_HOST "$default_idm_sspr_settings"
    search_and_replace "___ID_VAULT_LDAPS_PORT___"  $ID_VAULT_LDAPS_PORT "$default_idm_sspr_settings"
    search_and_replace "___ID_VAULT_ADMIN_LDAP___"  $ID_VAULT_ADMIN_LDAP "$default_idm_sspr_settings"
    search_and_replace "___ID_VAULT_PASSWORD___"  $ID_VAULT_PASSWORD "$default_idm_sspr_settings"
    search_and_replace "___USER_CONTAINER___"  $USER_CONTAINER "$default_idm_sspr_settings"
    search_and_replace "___ADMIN_CONTAINER___"  $ADMIN_CONTAINER "$default_idm_sspr_settings"
    search_and_replace "___TOMCAT_SERVLET_HOSTNAME___"  $SSPR_SERVER_HOST "$default_idm_sspr_settings"
    search_and_replace "___TOMCAT_HTTPS_PORT___"  $SSPR_SERVER_SSL_PORT "$default_idm_sspr_settings"
    search_and_replace "___SSO_SERVER_HOST___"  $SSO_SERVER_HOST "$default_idm_sspr_settings"
    search_and_replace "___SSO_SERVER_PORT___"  $SSO_SERVER_SSL_PORT "$default_idm_sspr_settings"
    search_and_replace "___SSO_SERVICE_PWD___"  $SSO_SERVICE_PWD "$default_idm_sspr_settings"
    search_and_replace "___UA_ADMIN___"  $UA_ADMIN "$default_idm_sspr_settings"

    merge_default_idm_settings "$default_idm_sspr_settings" "$SSPR_APPLICATIONPATH/SSPRConfiguration.xml"

    cd ${IDM_TEMP}/sspr_expanded_war/WEB-INF
    ./command.sh ConfigSetPassword $CONFIGURATION_PWD >> ${LOG_FILE_NAME} 2>&1

    ./command.sh ConfigLock >> ${LOG_FILE_NAME} 2>&1

    cd ${IDM_TEMP}
    rm -rf sspr_expanded_war/

}

update_sspr_whitelist()
{
  if [ "${SSO_SERVER_HOST}" != "${UA_SERVER_HOST}" ]
  then
     ${IDM_JRE_HOME}/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar com.netiq.installer.utils.XmlUtil "$SSPR_APPLICATIONPATH/SSPRConfiguration.xml" "/PwmConfiguration/settings/setting[@key=\"security.redirectUrl.whiteList\"]" "value" "https://$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT"
  fi
}

#modify_server_xml()
# {
#     
#	disp_str=`gettext install "Modifying Tomcat server.xml"`
#	echo_sameline "$disp_str"
#
#    #echo "${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "$TOMCAT_HTTP_PORT"
#    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8080']/@port" "$TOMCAT_HTTP_PORT"`
#    write_log "XML_MOD Response : ${result}"
#    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@redirectPort='8443']/@redirectPort" "$TOMCAT_HTTPS_PORT"`
#    write_log "XML_MOD Response : ${result}"
#    result=`"${XML_MOD}" "${IDM_TOMCAT_HOME}/conf/server.xml" "/Server/Service[1]/Connector[@port='8009']/@port" "8109"`
#    write_log "XML_MOD Response : ${result}"
#	keystorePassToCustom
#    setTLSv12
#}

