{{/*
==================================================================
                     Identity Console
==================================================================
*/}}
{{- define "identity-manager.identityconsole.name" -}}
{{- default "identityconsole" .Values.identityconsole.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.identityconsole.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.identityconsole.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.identityconsole.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.identityconsole.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identity-manager.identityconsole.serviceAccountName" -}}
{{- if .Values.identityconsole.serviceAccount.create }}
{{- default (include "identity-manager.identityconsole.name" .) .Values.identityconsole.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.identityconsole.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
=============================================================================================================
Identity Console Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.identityconsole.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.identityconsole.repository }}:{{ .Values.images.identityconsole.tag }}
{{- else }}
{{- .Values.images.identityconsole.repository }}:{{ .Values.images.identityconsole.tag }}
{{- end }}
{{- end }}


{{/*
==================================================================
Deploy Identity Console Component

Returns 'true' if:
   . Identity Console component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.identityconsole.deploy" -}} 
    {{- ternary "true" "" .Values.identityconsole.deploy }}
{{- end -}}