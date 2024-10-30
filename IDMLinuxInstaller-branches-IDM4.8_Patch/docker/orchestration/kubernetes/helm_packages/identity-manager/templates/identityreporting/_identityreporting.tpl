{{/*
==================================================================
                     Identity Reporting
==================================================================
*/}}
{{- define "identity-manager.identityreporting.name" -}}
{{- default "reporting" .Values.identityreporting.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.identityreporting.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.identityreporting.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.identityreporting.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.identityreporting.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identity-manager.identityreporting.serviceAccountName" -}}
{{- if .Values.identityreporting.serviceAccount.create }}
{{- default (include "identity-manager.identityreporting.name" .) .Values.identityreporting.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.identityreporting.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
=============================================================================================================
Identity Reporting Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.identityreporting.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.identityreporting.repository }}:{{ .Values.images.identityreporting.tag }}
{{- else }}
{{- .Values.images.identityreporting.repository }}:{{ .Values.images.identityreporting.tag }}
{{- end }}
{{- end }}

{{/*
==================================================================
Deploy Identity Reporting Component

Returns 'true' if:
   . Identity Reporting component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.identityreporting.deploy" -}} 
    {{- ternary "true" "" .Values.identityreporting.deploy }}
{{- end -}}
