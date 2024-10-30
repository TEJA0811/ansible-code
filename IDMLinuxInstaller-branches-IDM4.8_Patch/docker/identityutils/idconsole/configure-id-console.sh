#!/bin/bash

source /secret.properties

openssl pkcs12 -inkey /etc/certificates/tls.key -in /etc/certificates/tls.crt -export -out /shared-volume/keys.pfx -password pass:"${IDM_KEYSTORE_PWD}" -name osp

openssl s_client -showcerts -connect ${ID_VAULT_HOST}:${ID_VAULT_LDAPS_PORT} < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="/shared-volume/SSCert.pem"; print >out}'

if [ "${ID_CONSOLE_USE_OSP}" == "y" ]; then
  cp /edirapi-osp.conf /shared-volume/edirapi.conf  
else
  cp /edirapi.conf /shared-volume
fi	
if [ "${KUBERNETES_ORCHESTRATION}" == "y" ] && [ "${KUBE_INGRESS_ENABLED}" == "true" ]; then
  sed -i "s#__SSO_SERVER_HOST__:__SSO_SERVER_SSL_PORT__#$IDM_ACCESS_VIA_SINGLE_DOMAIN#g" /shared-volume/edirapi.conf 
  sed -i "s#__ID_CONSOLE_SERVER_HOST__:__ID_CONSOLE_SERVER_SSL_PORT__#$IDM_ACCESS_VIA_SINGLE_DOMAIN#g" /shared-volume/edirapi.conf 
else
  sed -i "s#__SSO_SERVER_HOST__:__SSO_SERVER_SSL_PORT__#$SSO_SERVER_HOST:$SSO_SERVER_SSL_PORT#g" /shared-volume/edirapi.conf 
  sed -i "s#__ID_CONSOLE_SERVER_HOST__:__ID_CONSOLE_SERVER_SSL_PORT__#$ID_CONSOLE_SERVER_HOST:$ID_CONSOLE_SERVER_SSL_PORT#g" /shared-volume/edirapi.conf  
fi
sed -i "s#__ID_CONSOLE_SERVER_SSL_PORT__#$ID_CONSOLE_SERVER_SSL_PORT#g" /shared-volume/edirapi.conf
sed -i "s#__ID_VAULT_HOST__#$ID_VAULT_HOST#g" /shared-volume/edirapi.conf
sed -i "s#__ID_VAULT_LDAPS_PORT__#$ID_VAULT_LDAPS_PORT#g" /shared-volume/edirapi.conf
sed -i "s#__ID_VAULT_ADMIN_LDAP__#$ID_VAULT_ADMIN_LDAP#g" /shared-volume/edirapi.conf
sed -i "s#__ID_VAULT_PASSWORD__#$ID_VAULT_PASSWORD#g" /shared-volume/edirapi.conf
sed -i "s#__ID_VAULT_TREENAME__#$ID_VAULT_TREENAME#g" /shared-volume/edirapi.conf
sed -i "s#__IDM_KEYSTORE_PWD__#$IDM_KEYSTORE_PWD#g" /shared-volume/edirapi.conf
sed -i "s#__SSO_SERVICE_PWD__#$SSO_SERVICE_PWD#g" /shared-volume/edirapi.conf

sed -i "s#__ORIGIN__#https://$IDM_ACCESS_VIA_SINGLE_DOMAIN#g" /shared-volume/edirapi.conf


chmod -R 755 /shared-volume

