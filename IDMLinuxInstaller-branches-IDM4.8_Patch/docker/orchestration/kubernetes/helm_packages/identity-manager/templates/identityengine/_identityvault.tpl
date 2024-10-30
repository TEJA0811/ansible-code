{{/*
==================================================================
                          identityengine
==================================================================
*/}}
{{- define "identity-manager.identityengine.name" -}}
{{- default "identityengine" .Values.identityengine.nameOverride  | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.identityengine.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.identityengine.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.identityengine.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.identityengine.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the identityengine service account to use
*/}}
{{- define "identity-manager.identityengine.serviceAccountName" -}}
{{- if .Values.identityengine.serviceAccount.create }}
{{- default (include "identity-manager.identityengine.name" .) .Values.identityengine.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.identityengine.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
=============================================================================================================
identityengine Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.identityengine.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.identityengine.repository }}:{{ .Values.images.identityengine.tag }}
{{- else }}
{{- .Values.images.identityengine.repository }}:{{ .Values.images.identityengine.tag }}
{{- end }}
{{- end }}


{{/*
==================================================================
Deploy identityengine Component

Returns 'true' if:
   . Identity Engine component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.identityengine.deploy" -}} 
    {{- ternary "true" "" .Values.identityengine.deploy }}
{{- end -}}


