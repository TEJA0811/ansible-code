#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################
#set -x
#IDM_JRE_HOME=/opt/netiq/common/jre
#IDM_TEMP=/tmp/idm_install

JAVA=${IDM_JRE_HOME}/bin/java
DXCMD=com.novell.nds.dirxml.util.DxCommand

CP=${IDM_INSTALL_HOME}common/lib/dirxml_misc.jar:${IDM_INSTALL_HOME}common/lib/ldap.jar:${IDM_INSTALL_HOME}common/lib/xp.jar:${IDM_INSTALL_HOME}common/lib/nxsl.jar:${IDM_INSTALL_HOME}common/lib/jclient.jar

associate_server()
{
    ${JAVA} -cp ${CP} ${DXCMD} -v -accept 1 -host $1 -port $2 -user "$3" -password "$4" -setdriverset "$5"   >> $LOG_FILE_NAME 2>&1
}

##################
#   Returns
#       Version
#   Params
#       $1 = LDAP DN
#       $2 = xxx
#
##################
get_local_version()
{
    verstr=`${JAVA} -cp ${CP} ${DXCMD} -v -accept 1 -user "$1" -password "$2" -getversion | grep "DirXML version is"`
    version=`echo "$verstr" | awk -F "DirXML version is" '{print $2}' | xargs`
    echo "$version"
}

##################
#   Returns
#       Version
#   Params
#       $1 = IP
#       $2 = LDAPS Port
#       $3 = LDAP DN
#       $4 = xxx
#
##################
get_remote_version()
{
    verstr=`LC_ALL=en_US.utf8 ${JAVA} -cp ${CP} ${DXCMD} -v -accept 1 -host $1 -port $2 -user "$3" -password "$4" -getversion | grep "DirXML version is"`
    version=`LC_ALL=en_US.utf8 echo "$verstr" | awk -F "DirXML version is" '{print $2}' | xargs`
    echo "$version"
}

##################
#   Returns
#       0 = SE
#       1 = AE
#   Params
#       $1 = IP
#       $2 = LDAPS Port
#       $3 = LDAP DN
#       $4 = xxx
#
##################
is_advanced_edition()
{
    version=`get_remote_version $1 $2 "$3" "$4"`
    if [ ! -z "${version}" ]
    then
        echo ${version} | grep SE >> /dev/null
        RET=$?
        if [ $RET -eq 0 ]
        then
            # return SE mode
            echo 0
            return
        fi
    fi
    # return AE as default
    echo 1
}

create_ks_from_kmo()
{
    ${IDM_JRE_HOME}/bin/keytool -genkey -keyalg RSA -keysize 2048 -keystore "${IDM_TEMP}/tomcat.ks" -storetype pkcs12 -storepass "$6" -keypass "$6" -alias idm -validity 7300 -dname "cn=delete" >> $LOG_FILE_NAME 2>&1
    ${IDM_JRE_HOME}/bin/keytool -delete -alias idm -keysize 2048 -keystore "${IDM_TEMP}/tomcat.ks" -storetype pkcs12 -storepass "$6" -keypass "$6" >> $LOG_FILE_NAME 2>&1

    ${JAVA} -cp ${CP} ${DXCMD} -v -accept 1 -host $1 -port $2 -user "$3" -password "$4" -exportcerts "SSL CertificateDNS" server java "${IDM_TEMP}"  >> $LOG_FILE_NAME 2>&1
    
    ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore "${IDM_TEMP}/SSL CertificateDNS_server.ks" -destkeystore "${IDM_TEMP}/tomcat.ks" -srcstorepass "$5" -deststorepass "$6" -srcalias "SSL CertificateDNS" -srckeypass "$5" -destkeypass "$6" -deststoretype pkcs12 -noprompt >> $LOG_FILE_NAME 2>&1
    ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore "${IDM_TEMP}/SSL CertificateDNS_server.ks" -destkeystore "${IDM_TEMP}/tomcat.ks" -srcstorepass "$5" -deststorepass "$6" -srcalias "trustedcert" -destalias "trustedcert" -srckeypass "$5" -deststoretype pkcs12 -noprompt >> $LOG_FILE_NAME 2>&1
    
    rm "${IDM_TEMP}/SSL CertificateDNS_server.ks"
}

add_cert_to_cacert()
{
    local destKeystore=${IDM_JRE_HOME}/lib/security/cacerts
    local destKSPass=changeit
    ${JAVA} -cp ${CP} ${DXCMD} -v -accept 1 -host $1 -port $2 -user "$3" -password "$4" -exportcerts "SSL CertificateDNS" server java "${IDM_TEMP}"  >> $LOG_FILE_NAME 2>&1
    ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore "${IDM_TEMP}/SSL CertificateDNS_server.ks" -destkeystore "${destKeystore}" -srcstorepass "$5" -deststorepass "${destKSPass}" -srcalias "trustedcert" -destalias "SSL CertificateDNS" -srckeypass "$5" -deststoretype JKS -noprompt >> $LOG_FILE_NAME 2>&1
    if [ $? -ne 0 ]
    then
      SSLCert_notcreated=true
    else
      SSLCert_notcreated=false
    fi
    rm -f "${IDM_TEMP}/SSL CertificateDNS_server.ks"
}

add_sslcertdnls_to_idmkeystore()
{
#for now called only inside sspr standalone
  ${JAVA} -cp ${CP} ${DXCMD} -v -accept 1 -host $1 -port $2 -user "$3" -password "$4" -exportcerts "SSL CertificateDNS" server java "${IDM_TEMP}"  >> $LOG_FILE_NAME 2>&1
  ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore "${IDM_TEMP}/SSL CertificateDNS_server.ks" -destkeystore "${IDM_KEYSTORE_PATH}" -srcstorepass "$5" -deststorepass "$6" -srcalias "SSL CertificateDNS" -srckeypass "$5" -destkeypass "$6" -deststoretype pkcs12 -noprompt >> $LOG_FILE_NAME 2>&1
  ${IDM_JRE_HOME}/bin/keytool -importkeystore -srckeystore "${IDM_TEMP}/SSL CertificateDNS_server.ks" -destkeystore "${IDM_KEYSTORE_PATH}" -srcstorepass "$5" -deststorepass "$6" -srcalias "trustedcert" -destalias "trustedcert" -srckeypass "$5" -deststoretype pkcs12 -noprompt >> $LOG_FILE_NAME 2>&1
  rm "${IDM_TEMP}/SSL CertificateDNS_server.ks"
}
