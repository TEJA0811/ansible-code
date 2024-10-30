{{/*
==================================================================
                     Identity Console
==================================================================
*/}}
{{- define "identity-manager.identityconsole.configure.script" -}}
#!/bin/bash

tlsCertPath="$1"
tlsKeyPath="$2"
secretPropertiesPath="$3"
edirapiConfPath="$4"
sharedVolumePath="$5"

echo "Running Identityconsole configuration script"

source $secretPropertiesPath

echo "Generating keys.pfx"
openssl pkcs12 -inkey $tlsKeyPath -in $tlsCertPath -export -out ${sharedVolumePath}/keys.pfx -password pass:"${COMMON_KEYSTORE_PWD}" -name osp

echo "Generating SSCert.pem"
until [ -f "/tmp/SSCert.pem" ]
do
  openssl s_client -showcerts -connect ${ID_VAULT_HOST}:${ID_VAULT_LDAPS_PORT} < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="/tmp/SSCert.pem"; print >out}'
  sleep 5s 
done
mv /tmp/SSCert.pem ${sharedVolumePath}

	
echo "Updating eDirAPI Configuration"
if [ "${KUBERNETES_ORCHESTRATION}" == "y" ] && [ "${KUBE_INGRESS_ENABLED}" == "true" ]; then
  sed -i "s#__SSO_SERVER_HOST__:__SSO_SERVER_SSL_PORT__#$IDM_ACCESS_VIA_SINGLE_DOMAIN#g" $edirapiConfPath 
  sed -i "s#__ID_CONSOLE_SERVER_HOST__:__ID_CONSOLE_SERVER_SSL_PORT__#$IDM_ACCESS_VIA_SINGLE_DOMAIN#g" $edirapiConfPath 
else
  sed -i "s#__SSO_SERVER_HOST__:__SSO_SERVER_SSL_PORT__#$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT#g" $edirapiConfPath 
  sed -i "s#__ID_CONSOLE_SERVER_HOST__:__ID_CONSOLE_SERVER_SSL_PORT__#$ID_CONSOLE_SERVER_HOST:$ID_CONSOLE_SERVER_SSL_PORT#g" $edirapiConfPath 
fi
sed -i "s#__ID_CONSOLE_SERVER_SSL_PORT__#$ID_CONSOLE_SERVER_SSL_PORT#g" $edirapiConfPath
sed -i "s#__ID_VAULT_HOST__#$ID_VAULT_HOST#g" $edirapiConfPath
sed -i "s#__ID_VAULT_LDAPS_PORT__#$ID_VAULT_LDAPS_PORT#g" $edirapiConfPath
sed -i "s#__ID_VAULT_ADMIN_LDAP__#$ID_VAULT_ADMIN_LDAP#g" $edirapiConfPath
sed -i "s#__ID_VAULT_PASSWORD__#$ID_VAULT_PASSWORD#g" $edirapiConfPath
sed -i "s#__ID_VAULT_TREENAME__#$ID_VAULT_TREENAME#g" $edirapiConfPath
sed -i "s#__IDM_KEYSTORE_PWD__#$COMMON_KEYSTORE_PWD#g" $edirapiConfPath
sed -i "s#__SSO_SERVICE_PWD__#$SSO_SERVICE_PWD#g" $edirapiConfPath

sed -i "s#__ORIGIN__#https://$IDM_ACCESS_VIA_SINGLE_DOMAIN#g" $edirapiConfPath

chmod -R 755 $sharedVolumePath
{{- end }}
