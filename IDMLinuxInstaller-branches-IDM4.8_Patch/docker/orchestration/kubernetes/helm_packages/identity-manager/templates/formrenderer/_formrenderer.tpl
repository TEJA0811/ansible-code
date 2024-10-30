{{/*
==================================================================
                        Form Renderer
==================================================================
*/}}
{{- define "identity-manager.formrenderer.name" -}}
{{- default "formrenderer" .Values.formrenderer.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.formrenderer.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.formrenderer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.formrenderer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.formrenderer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identity-manager.formrenderer.serviceAccountName" -}}
{{- if .Values.formrenderer.serviceAccount.create }}
{{- default (include "identity-manager.formrenderer.name" .) .Values.formrenderer.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.formrenderer.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
=============================================================================================================
Form Renderer Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.formrenderer.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.formrenderer.repository }}:{{ .Values.images.formrenderer.tag }}
{{- else }}
{{- .Values.images.formrenderer.repository }}:{{ .Values.images.formrenderer.tag }}
{{- end }}
{{- end }}


{{/*
==================================================================
Deploy Form Renderer Component

Returns'true' if:
   . Identity Manager edition is 'Advanced'
   . And, Identity Applications component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.formrenderer.deploy" -}} 
    {{- ternary "true" "" (and .Values.IS_ADVANCED_EDITION .Values.identityapplications.deploy) }}
{{- end -}}