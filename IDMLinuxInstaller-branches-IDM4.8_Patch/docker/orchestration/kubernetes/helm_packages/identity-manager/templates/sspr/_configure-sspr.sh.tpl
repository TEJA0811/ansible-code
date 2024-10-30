{{- define "identity-manager.sspr.configure.script" -}}
#!/bin/bash

silentPropertiesFile="$1"
tlsCertificateFile="$2"

LOG_FILE="/config/logs/sspr-configure.log"
SSPR_CONFIGURATION_XML="/config/SSPRConfiguration.xml"


Log()
{
  echo $(date): $1 >> $LOG_FILE
}

GetOAuthServerCertificates() 
{
  no_of_certs=0
  linetostart=1
  
  no_of_certs=$(sed -ne "/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p" $tlsCertificateFile  | sed -r "/-----BEGIN CERTIFICATE-----/{:a;N;/-----END CERTIFICATE-----/!ba;s/^[^\n]*\n(.*)\n.*/\1/;s/\n//g}" | wc -l)
  
  while [ $no_of_certs -gt 0 ]
  do
	certline=$(sed -ne "/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p" $tlsCertificateFile | sed -r "/-----BEGIN CERTIFICATE-----/{:a;N;/-----END CERTIFICATE-----/!ba;s/^[^\n]*\n(.*)\n.*/\1/;s/\n//g}" | sed -n ${linetostart}p)
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
  echo OAUTH_IDSERVER_SERVERCERTS=$(GetOAuthServerCertificates) >> $silentPropertiesFile 

  Log "CMD => /app/command.sh ImportPropertyConfig $silentPropertiesFile"
  Log "Waiting for command.sh to generate SSPRConfiguration.xml..."
  /app/command.sh ImportPropertyConfig $silentPropertiesFile
  WaitForSSPRConfigurationXmlCreation

}

UpdateURLs()
{
   
  source $silentPropertiesFile 
  
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

AllowRoamingSourceNetworkAddress()
{
   
  grep -Fq "network.allowMultiIPSession" $SSPR_CONFIGURATION_XML || sed -i "s#  </settings>#    <setting key=\"network.allowMultiIPSession\" syntax=\"BOOLEAN\" syntaxVersion=\"0\">\n      <label>Allow Roaming Source Network Address</label>\n      <value>true</value>\n    </setting>\n  </settings>#g" $SSPR_CONFIGURATION_XML 
  
}

Main()
{
  if [ ! -f $SSPR_CONFIGURATION_XML ] 
  then
	  Log "Starting SSPR Configuration"
	  GenerateSSPRConfigurationXml
	  UpdateURLs
	  AllowRoamingSourceNetworkAddress
	  Log "Completed Configuration of SSPR"
  fi

  rm $silentPropertiesFile
  rm $tlsCertificateFile

}

Main

{{- end -}}
