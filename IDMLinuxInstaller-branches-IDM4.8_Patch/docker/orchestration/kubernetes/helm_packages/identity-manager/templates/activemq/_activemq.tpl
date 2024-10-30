{{/*
==================================================================
                          ActiveMQ
==================================================================
*/}}
{{- define "identity-manager.activemq.name" -}}
{{- default "activemq" .Values.activemq.nameOverride  | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.activemq.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.activemq.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.activemq.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.activemq.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the ActiveMQ service account to use
*/}}
{{- define "identity-manager.activemq.serviceAccountName" -}}
{{- if .Values.activemq.serviceAccount.create }}
{{- default (include "identity-manager.activemq.name" .) .Values.activemq.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.activemq.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
=============================================================================================================
ActiveMQ Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.activemq.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.activemq.repository }}:{{ .Values.images.activemq.tag }}
{{- else }}
{{- .Values.images.activemq.repository }}:{{ .Values.images.activemq.tag }}
{{- end }}
{{- end }}


{{/*
==================================================================
Deploy ActiveMQ Component

Returns 'true' if:
   . Identity Manager edition is 'Advanced'
   . And, Identity Applications component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.activemq.deploy" -}} 
    {{- ternary "true" "" (and .Values.IS_ADVANCED_EDITION .Values.identityapplications.deploy) }}
{{- end -}}


