{{/*
==================================================================
                           SSPR
==================================================================
*/}}
{{- define "identity-manager.sspr.name" -}}
{{- default "sspr" .Values.sspr.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.sspr.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.sspr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.sspr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.sspr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identity-manager.sspr.serviceAccountName" -}}
{{- if .Values.sspr.serviceAccount.create }}
{{- default (include "identity-manager.sspr.name" .) .Values.sspr.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.sspr.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
=============================================================================================================
SSPR Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.sspr.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.sspr.repository }}:{{ .Values.images.sspr.tag }}
{{- else }}
{{- .Values.images.sspr.repository }}:{{ .Values.images.sspr.tag }}
{{- end }}
{{- end }}

{{/*
==================================================================
(Boolean) Deploy SSPR Component

Returns 'true' if:
   . SSPR component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.sspr.deploy" -}} 
    {{- ternary "true" "" .Values.sspr.deploy }}
{{- end -}}