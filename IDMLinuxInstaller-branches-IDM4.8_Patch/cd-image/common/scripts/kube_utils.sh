#!/bin/bash

configureKubeIngress()
{
    if [ ! -z ${SILENT_INSTALL_FILE} ]
    then
      source ${SILENT_INSTALL_FILE}
    fi

    if [ ! -z ${KUBERNETES_ORCHESTRATION} ] && [ "${KUBERNETES_ORCHESTRATION}" == "y" ] && [ "${KUBE_INGRESS_ENABLED}" == "true" ]; then

        local component="$1"

        ###########################################################################################
        # Update the internal URLs with the external domain name url in the configuration file(s) #
        ###########################################################################################
        local osp_internal_url="https://${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}"
        local ua_internal_url="https://${UA_SERVER_HOST}:${UA_SERVER_SSL_PORT}"
        local fr_internal_url="https://${FR_SERVER_HOST}:${NGINX_HTTPS_PORT}"
        local rpt_internal_url="https://${RPT_SERVER_HOSTNAME}:${RPT_TOMCAT_HTTPS_PORT}"
        local sspr_internal_url="https://${SSPR_SERVER_HOST}:${SSPR_SERVER_SSL_PORT}"

        local external_url="https://${IDM_ACCESS_VIA_SINGLE_DOMAIN}"

        case "$component" in
        "fr")
           sed -i "s#$osp_internal_url#$external_url#g" /opt/netiq/idm/apps/sites/config.ini
           sed -i "s#$ua_internal_url#$external_url#g" /opt/netiq/idm/apps/sites/config.ini
           sed -i "s#$fr_internal_url#$external_url#g" /opt/netiq/idm/apps/sites/config.ini
           ;;
        "osp" | "ua" | "rpt")
           sed -i "s#$osp_internal_url#$external_url#g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
           sed -i "s#$ua_internal_url#$external_url#g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
           sed -i "s#$fr_internal_url#$external_url#g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
           sed -i "s#$rpt_internal_url#$external_url#g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
           sed -i "s#$sspr_internal_url#$external_url#g" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
           ;;
        *)
           echo ""
           ;;
        esac

        ##########################################################################
        # Workaround for the Nginx redirection issue when reverse proxy is used  #
        ##########################################################################
        case "$component" in
        "fr")
           grep -Fq "proxy_intercept_errors on" /opt/netiq/common/nginx/nginx.conf || sed -i.bak "s#index index.html;#index index.html;\n\t\tproxy_intercept_errors on;\n\t\terror_page 301 302 307 = /forms/;#g" /opt/netiq/common/nginx/nginx.conf
           ;;
        *)
           echo ""
           ;;
        esac
        
        
        ###################################################################
        # Import Ingress SSL Certifiacte and Key to tomcat.ks and idm.jks #
        ###################################################################
        case "$component" in
        "osp" | "ua" | "rpt")
		
           local CERT_ALIAS=osp
		   
           openssl pkcs12 -inkey /config/certificates/tls.key -in /config/certificates/tls.crt -export -out /tmp/tls.pfx -password pass:"${COMMON_KEYSTORE_PWD}" -name $CERT_ALIAS
		   
           /opt/netiq/common/jre/bin/keytool -importkeystore -deststoretype PKCS12 -deststorepass "${COMMON_KEYSTORE_PWD}"  -destkeypass "${COMMON_KEYSTORE_PWD}" -destkeystore /tmp/tomcat.ks -srckeystore /tmp/tls.pfx -srcstoretype PKCS12 -srcstorepass "${COMMON_KEYSTORE_PWD}"
		   
           cp -rpf /tmp/tomcat.ks /opt/netiq/idm/apps/tomcat/conf/
		   
		   /opt/netiq/common/jre/bin/keytool -delete -noprompt -alias $CERT_ALIAS -keystore /opt/netiq/idm/apps/tomcat/conf/idm.jks -storepass "${COMMON_KEYSTORE_PWD}"
		   
           /opt/netiq/common/jre/bin/keytool -importkeystore -srckeystore /opt/netiq/idm/apps/tomcat/conf/tomcat.ks -srcstorepass "${COMMON_KEYSTORE_PWD}" -destkeystore /opt/netiq/idm/apps/tomcat/conf/idm.jks -deststorepass "${COMMON_KEYSTORE_PWD}"
           
           rm -f /tmp/tls.pfx /tmp/tomcat.ks /config/certificates/tls.key /config/certificates/tls.crt 
           ;;
        *)
           echo ""
           ;;
        esac
    fi
}


