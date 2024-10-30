
{{/*
==================================================================
List of eDirAPI configuration setting                     
==================================================================
*/}}
{{- define "identity-manager.identityconsole.edirapi.conf" -}}
- listen = ":__ID_CONSOLE_SERVER_SSL_PORT__"
- pfxpassword = "__IDM_KEYSTORE_PWD__"
- ospmode = "false"
- bcert = "/etc/opt/novell/eDirAPI/conf/ssl/trustedcert/"
- loglevel = "error"
- check-origin = "true"
- origin = "__ORIGIN__"
{{- end }}


{{/*
=======================================================================
List of eDirAPI configuration setting when OSP is used as a login method
=======================================================================
*/}}
{{- define "identity-manager.identityconsole.edirapi-osp.conf" -}}
- listen = ":__ID_CONSOLE_SERVER_SSL_PORT__"
- ldapserver = "__ID_VAULT_HOST__:__ID_VAULT_LDAPS_PORT__"
- ldapuser = "__ID_VAULT_ADMIN_LDAP__"
- ldappassword = "__ID_VAULT_PASSWORD__"
- pfxpassword = "__IDM_KEYSTORE_PWD__"
- ospmode = "true"
- osp-token-endpoint = "https://__SSO_SERVER_HOST__:__SSO_SERVER_SSL_PORT__/osp/a/idm/auth/oauth2/getattributes"
- osp-authorize-url = "https://__SSO_SERVER_HOST__:__SSO_SERVER_SSL_PORT__/osp/a/idm/auth/oauth2/grant"
- osp-logout-url = "https://__SSO_SERVER_HOST__:__SSO_SERVER_SSL_PORT__/osp/a/idm/auth/app/logout"
- osp-redirect-url = "https://__ID_CONSOLE_SERVER_HOST__:__ID_CONSOLE_SERVER_SSL_PORT__/eDirAPI/v1/__ID_VAULT_TREENAME__/authcoderedirect"
- osp-client-id = "identityconsole"
- ospclientpass = "__SSO_SERVICE_PWD__"
- ospcert = "/etc/opt/novell/eDirAPI/conf/ssl/private/cert.pem"
- bcert = "/etc/opt/novell/eDirAPI/conf/ssl/trustedcert/"
- loglevel = "error"
- check-origin = "false"
- origin = "https://10.10.10.10:9000,https://192.168.1.1:8543"
{{- end }}


{{/*
===========================================================================================
Command for generating eDirAPI configuration file.

Arguments:
    . top => The top context
    . eDirAPIConfPath => The path for the eDirAPI configuration file that will be generated
===========================================================================================
*/}}
{{- define "identity-manager.identityconsole.generate-edirapi-conf.command" -}}
{{- $top := index . "top" }}
{{- $eDirAPIConfPath := index . "edirAPIConfPath" }}
printf '
{{- if eq $top.Values.identityconsole.configuration.ID_CONSOLE_USE_OSP "y" }}
{{- $settings := include "identity-manager.identityconsole.edirapi-osp.conf" $top }}
{{- range $settings | fromYamlArray }}
{{ . | replace "%" "%%" | replace "\\" "\\\\" | replace "'" "'\"'\"'" }}\n
{{- end -}}
{{- else }}
{{- $settings := include "identity-manager.identityconsole.edirapi.conf" $top }}
{{- range $settings | fromYamlArray }}
{{ . | replace "%" "%%" | replace "\\" "\\\\" | replace "'" "'\"'\"'" }}\n
{{- end -}}
{{- end }}
'> "{{ $eDirAPIConfPath }}";
{{- end }}

