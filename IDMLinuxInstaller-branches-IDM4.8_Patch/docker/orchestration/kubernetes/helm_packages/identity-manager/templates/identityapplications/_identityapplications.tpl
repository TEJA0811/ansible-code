{{/*
==================================================================
                     Identity Applications
==================================================================
*/}}
{{- define "identity-manager.identityapplications.name" -}}
{{- default "identityapplications" .Values.identityapplications.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.identityapplications.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.identityapplications.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.identityapplications.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.identityapplications.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identity-manager.identityapplications.serviceAccountName" -}}
{{- if .Values.identityapplications.serviceAccount.create }}
{{- default (include "identity-manager.identityapplications.name" .) .Values.identityapplications.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.identityapplications.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
=============================================================================================================
Identity Applications Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.identityapplications.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.identityapplications.repository }}:{{ .Values.images.identityapplications.tag }}
{{- else }}
{{- .Values.images.identityapplications.repository }}:{{ .Values.images.identityapplications.tag }}
{{- end }}
{{- end }}

{{/*
==================================================================
Deploy Identity Applications Component

Returns 'true' if:
   . Identity Manager edition is 'Advanced'
   . And, Identity Applications component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.identityapplications.deploy" -}} 
    {{- ternary "true" "" (and .Values.IS_ADVANCED_EDITION .Values.identityapplications.deploy) }}
{{- end -}}