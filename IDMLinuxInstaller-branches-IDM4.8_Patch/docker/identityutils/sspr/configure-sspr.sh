#!/bin/bash

LOG_FILE="/config/logs/sspr-configure.log"
SSPR_CONFIGURATION_XML="/config/SSPRConfiguration.xml"
SilentPropertiesFile="/shared-volume/silent.properties"
TLSCertificateFile="/shared-volume/tls.crt"

Log()
{
  echo $(date): $1 >> $LOG_FILE
}

GetOAuthServerCertificates()
{
  no_of_certs=0
  linetostart=1
  
  no_of_certs=$(sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' ${TLSCertificateFile} | sed -r '/-----BEGIN CERTIFICATE-----/{:a;N;/-----END CERTIFICATE-----/!ba;s/^[^\n]*\n(.*)\n.*/\1/;s/\n//g}' | wc -l)
  
  while [ $no_of_certs -gt 0 ]
  do
	certline=$(sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' ${TLSCertificateFile} | sed -r '/-----BEGIN CERTIFICATE-----/{:a;N;/-----END CERTIFICATE-----/!ba;s/^[^\n]*\n(.*)\n.*/\1/;s/\n//g}' | sed -n ${linetostart}p)
	((no_of_certs--))
	((linetostart++))
	if [ -z $certs ]
	then
		certs=$(echo $certline)
	else
		certs=$(echo $certs,$certline)
	fi
  done
  
  echo $certs
}

WaitForSSPRConfigurationXmlCreation()
{
  while ! test -f $SSPR_CONFIGURATION_XML; do
	sleep 2s
  done

  while ! grep "ldap.serverCerts" $SSPR_CONFIGURATION_XML; do
	sleep 2s
  done

  sleep 2s
}

GenerateSSPRConfigurationXml()
{
  Log "Generating SSPRConfiguration.xml"

  Log "Importing oAuth Server Certificates"
  echo OAUTH_IDSERVER_SERVERCERTS=$(GetOAuthServerCertificates) >> $SilentPropertiesFile

  Log "CMD => /app/command.sh ImportPropertyConfig $SilentPropertiesFile"
  Log "Waiting for command.sh to generate SSPRConfiguration.xml..."
  /app/command.sh ImportPropertyConfig $SilentPropertiesFile
  WaitForSSPRConfigurationXmlCreation

}

UpdateURLs()
{
   
  source $SilentPropertiesFile 
  
  osp_internal_url="https://${SSO_SERVER_HOST}:${SSO_SERVER_SSL_PORT}"
  ua_internal_url="https://${UA_SERVER_HOST}:${UA_SERVER_SSL_PORT}"
  sspr_internal_url="https://${SSPR_SERVER_HOST}:${SSPR_SERVER_SSL_PORT}"
  external_url="https://${IDM_ACCESS_VIA_SINGLE_DOMAIN}"

  Log "Changing the internal URLs to the external Domain Name URL in SSPRConfiguration.xml"
  sed -i "s#$osp_internal_url#$external_url#g" $SSPR_CONFIGURATION_XML
  sed -i "s#$ua_internal_url#$external_url#g" $SSPR_CONFIGURATION_XML
  sed -i "s#$sspr_internal_url#$external_url#g" $SSPR_CONFIGURATION_XML
  sed -i "s#https%3A%2F%2F$SSPR_SERVER_HOST%3A$SSPR_SERVER_SSL_PORT#https%3A%2F%2F$IDM_ACCESS_VIA_SINGLE_DOMAIN#g" $SSPR_CONFIGURATION_XML

}

Main()
{
  if [ ! -f $SSPR_CONFIGURATION_XML ] 
  then
	Log "Starting SSPR Configuration"
	GenerateSSPRConfigurationXml
	UpdateURLs
	Log "Completed Configuration of SSPR"
  fi

   rm $SilentPropertiesFile
   rm $TLSCertificateFile

}

Main
