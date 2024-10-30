{{- define "identity-manager.common.configuration.envs" -}}

- name: DOCKER_CONTAINER
  value: "y"

- name: KUBERNETES_ORCHESTRATION
  value: "y"

- name: KUBE_NAMESPACE
  value: {{ .Release.Namespace }}

- name: UPGRADE_IDM
  value: "n"

- name: IS_COMMON_PASSWORD
  value: "n"

- name: KUBE_SUB_DOMAIN
  value: {{ .Values.KUBE_SUB_DOMAIN | quote }}

- name: IS_ADVANCED_EDITION
  value: {{ .Values.IS_ADVANCED_EDITION | quote }}

{{- end }}


{{- define "identity-manager.identityengine.configuration.envs" -}}

{{- include "identity-manager.component.configuration.envs" .Values.identityengine.configuration }}
- name: ID_VAULT_HOST
  value: {{ include "identity-manager.identityengine.name" . }}-0.{{ include "identity-manager.identityengine.name" . }}.{{ .Release.Namespace }}.svc.{{ .Values.KUBE_SUB_DOMAIN }}
- name: INSTALL_ENGINE
  value: "true"
- name: INSTALL_IDVAULT
  value: "true"
- name: ID_VAULT_VARDIR
  value: "/var/opt/novell/eDirectory"
- name: ID_VAULT_DIB
  value: "/var/opt/novell/eDirectory/data/dib"
- name: ID_VAULT_CONF
  value: "/etc/opt/novell/eDirectory/conf/nds.conf"
- name: ID_VAULT_NCP_PORT
  value: {{ .Values.identityengine.service.ports.ncpPort | quote }}
- name: ID_VAULT_LDAP_PORT
  value: {{ .Values.identityengine.service.ports.ldapPort | quote}}   
- name: ID_VAULT_LDAPS_PORT
  value: {{ .Values.identityengine.service.ports.ldapsPort | quote }}   
- name: ID_VAULT_HTTP_PORT
  value: {{ .Values.identityengine.service.ports.httpPort | quote }}
- name: ID_VAULT_HTTPS_PORT
  value: {{ .Values.identityengine.service.ports.httpsPort | quote }}
- name: ID_VAULT_HEALTH_CHECK_PORT
  value: {{ .Values.identityengine.service.ports.healthCheckPort | quote }}

{{- end -}}



{{/*
==================================================================
Get Identity Manager's configuration as env variables  

Arguments:
    . top => Specifies the top context
==================================================================
*/}}
{{- define "identity-manager.configuration.envs" -}}
{{- $top := index . "top" }}

{{- include "identity-manager.common.configuration.envs"  $top }}


- name: AZURE_POSTGRESQL_REQUIRED
  value: {{ $top.Values.AZURE_POSTGRESQL_REQUIRED | quote }}


# Ingress
- name: KUBE_INGRESS_ENABLED
  value: {{ $top.Values.ingress.enabled | quote }}

# Domain name for accessing Identity Manager web applications via Ingress controller
- name: IDM_ACCESS_VIA_SINGLE_DOMAIN
  value: {{ $top.Values.ingress.host }}


# Identity Engine Configuration
{{- if $top.Values.identityengine.deploy }}
{{- include "identity-manager.identityengine.configuration.envs"  $top }}
{{- end }}

# OSP Configuration
{{- if (include "identity-manager.osp.deploy" $top) }}

{{- include "identity-manager.component.configuration.envs" $top.Values.osp.configuration }}
- name: INSTALL_OSP
  value: "true"
- name: SSO_SERVER_HOST
  value: {{ $top.Values.osp.nameOverride }}
- name: OSP_HOST_NAME
  value: {{ $top.Values.osp.nameOverride  }}
- name: SSO_SERVER_SSL_PORT
  value:  {{ $top.Values.osp.service.ports.httpPort | quote }}
- name: TOMCAT_HTTPS_PORT
  value: {{ $top.Values.osp.service.ports.httpPort | quote }}
  
{{- end }}

# Identity Applications Configuration
{{- if (include "identity-manager.identityapplications.deploy" $top) }}

{{- include "identity-manager.component.configuration.envs" $top.Values.identityapplications.configuration }}
- name: INSTALL_UA
  value: "true"
- name: UA_SERVER_HOST
  value: {{ $top.Values.identityapplications.nameOverride }}
- name: UA_HOST_NAME
  value: {{ $top.Values.identityapplications.nameOverride }}
- name: UA_SERVER_SSL_PORT
  value: {{ $top.Values.identityapplications.service.ports.httpPort | quote }}

{{- if not $top.Values.identityapplications.configuration.UA_WFE_DB_JDBC_DRIVER_JAR }}
- name: UA_WFE_DB_JDBC_DRIVER_JAR
{{- if eq $top.Values.identityapplications.configuration.UA_WFE_DB_PLATFORM_OPTION "postgres" }}
  value: {{ include "identity-manager.jdbc.jar.posgresql" $top | quote }}
{{- end }}
{{- if eq $top.Values.identityapplications.configuration.UA_WFE_DB_PLATFORM_OPTION "oracle" }}
  value: {{ include "identity-manager.jdbc.jar.oracle" $top | quote }}
{{- end }}
{{- if eq $top.Values.identityapplications.configuration.UA_WFE_DB_PLATFORM_OPTION "mssql" }}
  value: {{ include "identity-manager.jdbc.jar.mssql" $top | quote }}
{{- end }}
{{- end }}

{{- end }}


# Form Renderer Configuration
{{- if (include "identity-manager.formrenderer.deploy" $top) }}

{{- include "identity-manager.component.configuration.envs" $top.Values.formrenderer.configuration }}
- name: FR_SERVER_HOST
  value: {{ $top.Values.formrenderer.nameOverride }}
- name: FR_HOST_NAME
  value: {{ $top.Values.formrenderer.nameOverride }}
- name: NGINX_HTTPS_PORT
  value: {{ $top.Values.formrenderer.service.ports.httpPort | quote }}

{{- end }}

 
 # ActiveMQ Configuration
{{- if (include "identity-manager.activemq.deploy" $top) }}

{{- include "identity-manager.component.configuration.envs" $top.Values.activemq.configuration }}
- name: INSTALL_ACTIVEMQ
  value: "true"
- name: ACTIVEMQ_SERVER_HOST
  value: {{ $top.Values.activemq.nameOverride }}
- name: ACTIVEMQ_HOST_NAME
  value: {{ $top.Values.activemq.nameOverride }}
- name: ACTIVEMQ_SERVER_TCP_PORT
  value: {{ $top.Values.activemq.service.ports.tcpPort | quote }}

{{- end }}

# Identity Reporting Configuration
{{- if (include "identity-manager.identityreporting.deploy" $top) }}

{{- include "identity-manager.component.configuration.envs" $top.Values.identityreporting.configuration }}
- name: INSTALL_REPORTING
  value: "true"
- name: RPT_SERVER_HOSTNAME
  value: {{ $top.Values.identityreporting.nameOverride }}
- name: RPT_HOST_NAME
  value: {{ $top.Values.identityreporting.nameOverride }}
- name: RPT_TOMCAT_HTTPS_PORT
  value: {{ $top.Values.identityreporting.service.ports.httpPort | quote }}

{{- if not $top.Values.identityreporting.configuration.RPT_DATABASE_JDBC_DRIVER_JAR }}
- name: RPT_DATABASE_JDBC_DRIVER_JAR
{{- if eq $top.Values.identityreporting.configuration.RPT_DATABASE_PLATFORM_OPTION "postgres" }}
  value: {{ include "identity-manager.jdbc.jar.posgresql" $top | quote }}
{{- end }}
{{- if eq $top.Values.identityreporting.configuration.RPT_DATABASE_PLATFORM_OPTION "oracle" }}
  value: {{ include "identity-manager.jdbc.jar.oracle" $top | quote }}
{{- end }}
{{- if eq $top.Values.identityreporting.configuration.RPT_DATABASE_PLATFORM_OPTION "mssql" }}
  value: {{ include "identity-manager.jdbc.jar.mssql" $top | quote }}
{{- end }}
{{- end }}

{{- end }}

# SSPR Configuration
{{- if (include "identity-manager.sspr.deploy" $top) }}

{{- include "identity-manager.component.configuration.envs" $top.Values.sspr.configuration }}
- name: INSTALL_SSPR
  value: "true"
- name: SSPR_HOST_NAME
  value: {{ $top.Values.sspr.nameOverride }}
- name: SSPR_SERVER_HOST
  value: {{ $top.Values.sspr.nameOverride }}
- name: SSPR_SERVER_SSL_PORT
  value: {{ $top.Values.sspr.service.ports.httpPort | quote }}

{{- end }}

# Identity Console Configuration
{{- if (include "identity-manager.identityconsole.deploy" $top) }}

{{- include "identity-manager.component.configuration.envs" $top.Values.identityconsole.configuration }}
- name: INSTALL_IDENTITY_CONSOLE
  value: "true"
- name: ID_CONSOLE_SERVER_HOST
  value: {{ $top.Values.identityconsole.nameOverride }}
- name: ID_CONSOLE_SERVER_SSL_PORT
  value: {{ $top.Values.identityconsole.service.ports.httpPort | quote }}

{{- end }}


# Adavanced configuration: 
- name: ENABLE_CUSTOM_CONTAINER_CREATION
  value: "y"
# Root container DN
- name: ROOT_CONTAINER
  value: {{ $top.Values.DATA_CONTAINERS.ROOT_CONTAINER | quote }}  
# Group Search root container DN
- name: GROUP_ROOT_CONTAINER
  value: {{ $top.Values.DATA_CONTAINERS.GROUP_ROOT_CONTAINER | quote }}    
# User search container DN
- name: USER_CONTAINER
  value: {{ $top.Values.DATA_CONTAINERS.USER_CONTAINER | quote }} 
# Admin search container DN
- name: ADMIN_CONTAINER
  value: {{ $top.Values.DATA_CONTAINERS.ADMIN_CONTAINER | quote }}
# Data container ldif
- name: DATA_CONTAINERS_LDIF
  value: |
    {{- $top.Values.DATA_CONTAINERS.DATA_CONTAINERS_LDIF | nindent 4 }}

{{- end -}}


{{/*
========================================================================================================
Get an Identity Manager component's configuration as env variables 

Arguments:
    . Identity Manager component's configuration as a map of key-value pairs

NOTE: 
========================================================================================================
*/}}
{{- define "identity-manager.component.configuration.envs" -}}
{{- $configuration := index . }}
{{- range $key, $value := $configuration }}
{{- $isSecret := include "identity-manager.configuration.isSecret" $value }}
{{- if eq $isSecret "true" }}
- name: {{ "secret___" }}{{ $key }}
  value: {{ $value.secret | quote }}
{{- else }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}



{{/*
==================================================================
Check if the value of a key is a secret  

Arguments:
    . Value of a key
==================================================================
*/}}
{{- define "identity-manager.configuration.isSecret" -}} 
{{- $value := index . }}
{{- $kind := kindOf $value }}
{{- if eq $kind "map" }}
{{- range $k, $v := $value }}
{{- if eq $k "secret" }}
{{- printf "%s" "true" }}
{{- else }}
{{- printf "%s" "false" }}
{{- end }}
{{- end }}
{{- else }}
{{- printf "%s" "false" }}
{{- end }}
{{- end }}


{{/*
==================================================================
List all secrets in a map (as a YAML array)

Arguments:
    . A configuration map
==================================================================
*/}}
{{- define "identity-manager.configuration.secrets.list" -}}
{{- $values := index . }}
{{- range $key, $value := $values }}
{{- $kind := kindOf $value }}
{{- if eq $kind "string" }}
{{- if eq $key "secret" }}
- {{ $value }}
{{- end }}
{{- else if eq $kind "map" }}
{{- include "identity-manager.configuration.secrets.list" $value }}
{{- else }}
{{- end }}
{{- end }}
{{- end }}

