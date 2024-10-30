{{/*
==================================================================
                           OSP
==================================================================
*/}}
{{- define "identity-manager.osp.name" -}}
{{- default "osp" .Values.osp.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-manager.osp.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.osp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-manager.osp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.osp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identity-manager.osp.serviceAccountName" -}}
{{- if .Values.osp.serviceAccount.create }}
{{- default (include "identity-manager.osp.name" .) .Values.osp.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.osp.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
=============================================================================================================
OSP Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.osp.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.osp.repository }}:{{ .Values.images.osp.tag }}
{{- else }}
{{- .Values.images.osp.repository }}:{{ .Values.images.osp.tag }}
{{- end }}
{{- end }}

{{/*
==================================================================
Deploy OSP Component

Returns 'true' if:
   . OSP component is to be deployed 
==================================================================
*/}}
{{- define "identity-manager.osp.deploy" -}} 
    {{- ternary "true" "" .Values.osp.deploy }}
{{- end -}}