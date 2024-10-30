#!/bin/bash
##################################################################################
#
# Copyright © 2018 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

README="https://www.netiq.com/documentation/identity-manager-48/identity-manager-48-release-notes/data/identity-manager-48-release-notes.html"
DOC="https://www.netiq.com/documentation/identity-manager-48/"

add_install_info()
{
    . gettext.sh
    TEXTDOMAIN=install
    export TEXTDOMAIN
    TEXTDOMAINDIR=/opt/netiq/idm/uninstall_data/common/locale/
    export TEXTDOMAINDIR
    local component=$1

    if [ ! -f "${INFO_FILENAME}" ]
    then
        str1=`gettext install "Identity Manager installation information"`
        echo "###############################################################" >>  "${INFO_FILENAME}"
        echo "" >>  "${INFO_FILENAME}"
        echo "         ${str1}" >>  "${INFO_FILENAME}"
        echo "" >>  "${INFO_FILENAME}"
        echo "###############################################################" >>  "${INFO_FILENAME}"
    fi

    if [ "${component}" == "IDM" ]
    then
        add_idm_info >> "${INFO_FILENAME}"
    elif [ "${component}" == "iManager" ]
    then
        add_iman_info >> "${INFO_FILENAME}"
    elif [ "${component}" == "reporting" ]
    then
        add_rpt_info >> "${INFO_FILENAME}"
    elif [ "${component}" == "user_application" ]
    then
        add_ua_info >> "${INFO_FILENAME}"
    fi
}

set_idm_info()
{
	PRINT_ID_VAULT_LDAP_PORT=`LC_ALL=en_US ldapconfig get "ldapInterfaces" -a ${ID_VAULT_ADMIN} -w ${ID_VAULT_PASSWORD} | grep ldapInterfaces | awk -F 'ldap://:' '{print $2}' | awk -F ',' '{print $1}'`
	PRINT_ID_VAULT_LDAPS_PORT=`LC_ALL=en_US ldapconfig get "ldapInterfaces" -a ${ID_VAULT_ADMIN} -w ${ID_VAULT_PASSWORD} | grep ldapInterfaces | awk -F 'ldaps://:' '{print $2}' | awk -F ',' '{print $1}'`
	echo "q" > /tmp/ndsmanage-input
	conf_file=`LC_ALL=en_US ndsmanage < /tmp/ndsmanage-input | grep " ACTIVE" | awk '{print $2}'`
	rm -f /tmp/ndsmanage-input
	LC_ALL=en_US ndsconfig get n4u.base.tree-name --config-file ${conf_file} &> /dev/null
	if [ $? -eq 0 ]
	then
		PRINT_ID_VAULT_HTTP_PORT=`LC_ALL=en_US ndsconfig get http.server.interfaces | grep http.server.interfaces | awk -F'@' '{print $2}'`
		PRINT_ID_VAULT_HTTPS_PORT=`LC_ALL=en_US ndsconfig get https.server.interfaces | grep https.server.interfaces | awk -F'@' '{print $2}'`
		PRINT_ID_VAULT_NCP_PORT=`LC_ALL=en_US ndsconfig get n4u.server.interfaces | grep n4u.server.interfaces | awk -F'@' '{print $2}'`
	fi

}

add_idm_info()
{
    echo ""
    str1=`gettext install "Component : Identity Manager Engine / Identity Vault"`
    echo "---------------------------------------------------------------"
    echo "$str1"
    echo "---------------------------------------------------------------"
    set_idm_info
    
    str2=`gettext install "Administrative user : %s"`
    str2=`printf "$str2" "$ID_VAULT_ADMIN_LDAP"`
    echo "$str2"
    
    str3=`gettext install "LDAP port  : %s"`
    str3=`printf "$str3" "$PRINT_ID_VAULT_LDAP_PORT"`
    echo "$str3"

    str4=`gettext install "LDAPS port : %s"`
    str4=`printf "$str4" "$PRINT_ID_VAULT_LDAPS_PORT"`
    echo "$str4"

    str5=`gettext install "NCP port   : %s"`
    str5=`printf "$str5" "$PRINT_ID_VAULT_NCP_PORT"`
    echo "$str5"

    str6=`gettext install "HTTP port  : %s"`
    str6=`printf "$str6" "$PRINT_ID_VAULT_HTTP_PORT"`
    echo "$str6"

    str7=`gettext install "HTTPS port : %s"`
    str7=`printf "$str7" "$PRINT_ID_VAULT_HTTPS_PORT"`
    echo "$str7"
}

add_iman_info()
{
    echo ""
    str1=`gettext install "Component : iManager Web Administration"`
    echo "---------------------------------------------------------------"
    echo "$str1"
    echo "---------------------------------------------------------------"
    
    str2=`gettext install "HTTP port  : %s"`
    str2=`printf "$str2" "$IMAN_TOMCAT_HTTP_PORT"`
    echo "$str2"

    str3=`gettext install "HTTPS port : %s"`
    str3=`printf "$str3" "$IMAN_TOMCAT_SSL_PORT"`
    echo "$str3"

    str4=`gettext install "iManager url : %s"`
    if [ "$IMAN_TOMCAT_SSL_PORT" == "443" ]
    then
        str4=`printf "$str4" "https://${IP_ADDR}/nps"`
    else
        str4=`printf "$str4" "https://${IP_ADDR}:${IMAN_TOMCAT_SSL_PORT}/nps"`
    fi
    echo "$str4"
}

add_rpt_info()
{
    echo ""
    str1=`gettext install "Component : Identity Reporting(jre8)"`
    echo "---------------------------------------------------------------"
    echo "$str1"
    echo "---------------------------------------------------------------"
    
    str2=`gettext install "Administrative user : %s"`
    str2=`printf "$str2" "$RPT_ADMIN"`
    echo "$str2"

    str3_1=`gettext install "Database platform : %s"`
    str3_1=`printf "$str3_1" "$RPT_DATABASE_PLATFORM_OPTION"`
    echo "$str3_1"
    
    str3=`gettext install "Database host : %s"`
    str3=`printf "$str3" "$RPT_DATABASE_HOST"`
    echo "$str3"

    str4=`gettext install "Database port : %s"`
    str4=`printf "$str4" "$RPT_DATABASE_PORT"`
    echo "$str4"

    str5=`gettext install "Database name : %s"`
    str5=`printf "$str5" "$RPT_DATABASE_NAME"`
    echo "$str5"

    str5_1=`gettext install "Database administrator : %s"`
    str5_1=`printf "$str5_1" "$RPT_DATABASE_USER"`
    echo "$str5_1"  

#    str6=`gettext install "HTTP port  : %s"`
#    str6=`printf "$str6" "$RPT_TOMCAT_HTTP_PORT"`
#    echo "$str6"

    # str7=`gettext install "HTTPS port : %s"`
    # str7=`printf "$str7" "$RPT_TOMCAT_HTTPS_PORT"`
    # echo "$str7"

    # str8=`gettext install "Reporting url : %s"`
    # if [ "$IMAN_TOMCAT_SSL_PORT" == "443" ]
    # then
    #     str8=`printf "$str8" "https://${RPT_SERVER_HOSTNAME}/IDMRPT"`
    # else
    #     str8=`printf "$str8" "https://${RPT_SERVER_HOSTNAME}:${RPT_TOMCAT_HTTPS_PORT}/IDMRPT"`
    # fi
    # echo "$str8"

    # str9=`gettext install "Data Collection Service url : %s"`
    # if [ "$IMAN_TOMCAT_SSL_PORT" == "443" ]
    # then
    #     str9=`printf "$str9" "https://${RPT_SERVER_HOSTNAME}/idmdcs"`
    # else
    #     str9=`printf "$str9" "https://${RPT_SERVER_HOSTNAME}:${RPT_TOMCAT_HTTPS_PORT}/idmdcs"`
    # fi
    # echo "$str9"
}

add_rptpatch_info()
{
    echo ""
    str1=`gettext install "Component : Identity Reporting(jre8)"`
    echo "---------------------------------------------------------------"
    echo "$str1"
    echo "---------------------------------------------------------------"
    existingrptport=$(grep com.netiq.rpt.rpt-web.redirect.url /opt/netiq/idm/apps/tomcat-jre8/conf/ism-configuration.properties | grep -iv "localhost:8180" | grep -v ___RPT_IP___ | cut -d":" -f3 | cut -d"/" -f1)
    newrptredirecthost=$(grep com.netiq.rpt.rpt-web.redirect.url /opt/netiq/idm/apps/tomcat-jre8/conf/ism-configuration.properties | grep -iv "localhost:8180" | grep -v ___RPT_IP___ | cut -d":" -f2 | cut -d"/" -f3)
    if [ -z $existingrptport ] || [ "$existingrptport" == "" ]
    then
            RPT_TOMCAT_HTTPS_PORT=443
    else
            RPT_TOMCAT_HTTPS_PORT=$existingrptport
    fi
    RPT_SERVER_HOSTNAME=$newrptredirecthost
    str7=`gettext install "HTTPS port : %s"`
    str7=`printf "$str7" "$RPT_TOMCAT_HTTPS_PORT"`
    echo "$str7"

    str8=`gettext install "Reporting url : %s"`
    if [ "$RPT_TOMCAT_HTTPS_PORT" == "443" ]
    then
        str8=`printf "$str8" "https://${RPT_SERVER_HOSTNAME}/IDMRPT"`
    else
        str8=`printf "$str8" "https://${RPT_SERVER_HOSTNAME}:${RPT_TOMCAT_HTTPS_PORT}/IDMRPT"`
    fi
    echo "$str8"

    str9=`gettext install "Data Collection Service url : %s"`
    if [ "$IMAN_TOMCAT_SSL_PORT" == "443" ]
    then
        str9=`printf "$str9" "https://${RPT_SERVER_HOSTNAME}/idmdcs"`
    else
        str9=`printf "$str9" "https://${RPT_SERVER_HOSTNAME}:${RPT_TOMCAT_HTTPS_PORT}/idmdcs"`
    fi
    echo "$str9"
}

add_ua_info()
{
    echo ""
    str1=`gettext install "Component : Identity Applications"`
    echo "---------------------------------------------------------------"
    echo "$str1"
    echo "---------------------------------------------------------------"
    
    str2=`gettext install "Administrative user : %s"`
    str2=`printf "$str2" "$UA_ADMIN"`
    echo "$str2"
    
    str3_1=`gettext install "Database platform : %s"`
    str3_1=`printf "$str3_1" "$UA_WFE_DB_PLATFORM_OPTION"`
    echo "$str3_1"

    str3=`gettext install "Database host : %s"`
    str3=`printf "$str3" "$UA_WFE_DB_HOST"`
    echo "$str3"

    str4=`gettext install "Database port : %s"`
    str4=`printf "$str4" "$UA_WFE_DB_PORT"`
    echo "$str4"

    str5=`gettext install "Database name : %s"`
    str5=`printf "$str5" "$UA_DATABASE_NAME & $WFE_DATABASE_NAME"`
    echo "$str5"

    str5_1=`gettext install "Database user : %s"`
    str5_1=`printf "$str5_1" "$UA_WFE_DATABASE_USER"`
    echo "$str5_1"  

#    str6=`gettext install "HTTP port  : %s"`
#    str6=`printf "$str6" "$TOMCAT_HTTP_PORT"`
#    echo "$str6"

    str7=`gettext install "HTTPS port : %s"`
    str7=`printf "$str7" "$UA_SERVER_SSL_PORT"`
    echo "$str7"

    str8=`gettext install "Application url : %s"`
    if [ "$IMAN_TOMCAT_SSL_PORT" == "443" ]
    then
        str8=`printf "$str8" "https://${UA_SERVER_HOST}/idmdash"`
    else
        str8=`printf "$str8" "https://${UA_SERVER_HOST}:${UA_SERVER_SSL_PORT}/idmdash"`
    fi
    echo "$str8"

    str9=`gettext install "Application administrator url : %s"`
    if [ "$IMAN_TOMCAT_SSL_PORT" == "443" ]
    then
        str9=`printf "$str9" "https://${UA_SERVER_HOST}/idmadmin"`
    else
        str9=`printf "$str9" "https://${UA_SERVER_HOST}:${UA_SERVER_SSL_PORT}/idmadmin"`
    fi
    echo "$str9"

    str9=`gettext install "Self Service Password Reset url : %s"`
    if [ "$SSPR_SERVER_SSL_PORT" == "443" ]
    then
        str9=`printf "$str9" "https://${SSPR_SERVER_HOST}/sspr"`
    else
        str9=`printf "$str9" "https://${SSPR_SERVER_HOST}:${SSPR_SERVER_SSL_PORT}/sspr"`
    fi
    echo "$str9"
}

show_install_info()
{
    if [ -f "${INFO_FILENAME}" ]
    then
        echo "" >> "${INFO_FILENAME}"
        echo "###############################################################" >>  "${INFO_FILENAME}"
        #echo "" >>  "${INFO_FILENAME}"
        str1=`gettext install "Identity Manager documentation links"`
        echo "$str1" >>  "${INFO_FILENAME}"
        echo "" >>  "${INFO_FILENAME}"
        
        str2=`gettext install "Release Notes : %s"`
        str2=`printf "$str2" "${README}"`
        echo "$str2" >>  "${INFO_FILENAME}"

        str3=`gettext install "Documentation : %s"`
        str3=`printf "$str3" "${DOC}"`
        echo "$str3" >>  "${INFO_FILENAME}"
        
        #echo "" >>  "${INFO_FILENAME}"
        echo "###############################################################" >>  "${INFO_FILENAME}"
        echo_sameline "${txtgrn}"
        while read line
        do
            write_and_log "${line}"
        done < "${INFO_FILENAME}"
        echo_sameline "${txtrst}"

        rm "${INFO_FILENAME}"
    fi
}

show_rptpatchinstall_info()
{
    if [ -z $INFO_FILENAME ]
    then
        INFO_FILENAME=/etc/opt/netiq/idm/configure/install-info.txt
    fi
    if [ -z $LOG_FILE_NAME ]
    then
        LOG_FILE_NAME=/var/opt/netiq/idm/log/idmupgrade.log
        set_log_file "${LOG_FILE_NAME}"
    fi
    if [ -f /opt/netiq/idm/apps/tomcat-jre8/webapps/IDMRPT.war ]
    then
        echo "" > "${INFO_FILENAME}"
        echo "###############################################################" >>  "${INFO_FILENAME}"
        add_rptpatch_info >>  "${INFO_FILENAME}"
        echo "###############################################################" >>  "${INFO_FILENAME}"
        echo "${txtgrn}"
        while read line
        do
            write_and_log "${line}"
        done < "${INFO_FILENAME}"
        echo "${txtrst}"

        rm "${INFO_FILENAME}"
    fi
}
