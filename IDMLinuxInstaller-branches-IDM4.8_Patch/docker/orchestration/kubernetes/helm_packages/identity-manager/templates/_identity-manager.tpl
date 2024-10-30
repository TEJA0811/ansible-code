{{/*
=============================================================================================================
Name of the chart.
=============================================================================================================
*/}}
{{- define "identity-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
=============================================================================================================
Fully qualified name of the chart.

NOTE: We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
=============================================================================================================
*/}}
{{- define "identity-manager.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
=============================================================================================================
Chart name and version as used by the chart label.
=============================================================================================================
*/}}
{{- define "identity-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
=============================================================================================================
Common labels
=============================================================================================================
*/}}
{{- define "identity-manager.labels" -}}
helm.sh/chart: {{ include "identity-manager.chart" . }}
{{ include "identity-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
=============================================================================================================
Selector labels
=============================================================================================================
*/}}
{{- define "identity-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
################################################################################################################################
#                                    Common Docker Images related Templates                                                    #
################################################################################################################################
*/}}

{{/*
=============================================================================================================
Docker Image Pull Policy
=============================================================================================================
*/}}
{{- define "identity-manager.imagePullPolicy" -}}
{{- .Values.images.pullPolicy }}
{{- end -}}

{{/*
=============================================================================================================
Docker Image Pull Secrets
=============================================================================================================
*/}}
{{- define "identity-manager.imagePullSecrets" -}}
{{- .Values.images.imagePullSecrets | toYaml }}
{{- end -}}

{{/*
=============================================================================================================
Identityutils Docker Image 
=============================================================================================================
*/}}
{{- define "identity-manager.identityutils.image" -}}
{{- if .Values.images.registry }}
{{- .Values.images.registry }}/{{ .Values.images.identityutils.repository }}:{{ .Values.images.identityutils.tag }}
{{- else }}
{{- .Values.images.identityutils.repository }}:{{ .Values.images.identityutils.tag }}
{{- end }}
{{- end }}



{{/*
################################################################################################################################
#                                            Volumes and VolumeMounts                                                          #
################################################################################################################################
*/}} 


{{/*
=====================================================================================================================
Identity Manager Persistent Volume which is shared between the Identity Manager Services( Access mode ReadWriteMany ).

Arguments:
    . top => Specifies the top context
======================================================================================================================
*/}} 
{{- define "identity-manager.shared-persistent.volume" -}}
{{- $top := index . "top" }}
{{- if $top.Values.persistence.shared.existingClaim }}
- name: data
  persistentVolumeClaim:
    claimName: {{ $top.Values.persistence.shared.existingClaim }}
{{- else }}
- name: data
  persistentVolumeClaim:
    claimName: {{ $top.Release.Name }}-idm-data-dynamic-pvc
{{- end }}
{{- end }}

{{/*
=============================================================================================================
Volume Mount for Identity Manager Shared Persistent Volume

Arguments:
    . mountPath => Specifies the path inside a Pod where volume will be mounted.
    . (Optional) subPath => Specifies a sub folder inside the root mountPath where the volume would be mounted
==============================================================================================================
*/}} 
{{- define "identity-manager.shared-persistent.volumeMount" -}}
{{ $mountPath := index . "mountPath" }}
{{ $subPath := ternary (index . "subPath") "" (hasKey . "subPath") }}
- name: data
  mountPath: "{{ $mountPath }}"
{{- if $subPath }}
  subPath: {{ $subPath }}
{{- end }}
{{- end }}


{{/*
=========================================================================
Volume for mounting Identity Manager Passwords and Secrets inside a Pod

Arguments:
    . top => Specifies the top context
=========================================================================
*/}}
{{- define "identity-manager.secrets.volume" -}}
{{- $top := index . "top" }}
{{- if $top.Values.secret_manager.azureKeyVault.use -}}
- name: azure-keyvault-secrets
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: "azure-keyvault-secret-provider-class"
{{- else }}
{{- $secretList := include "identity-manager.configuration.secrets.list" $top.Values }}
{{- range $secretList | fromYamlArray | uniq }}
- name: kubernetes-secrets-{{ . }}
  secret:
    secretName: {{ . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
=================================================================================================
Volume Mount for Identity Manager Passwords and Secrets inside a Pod

Arguments:
    . top => Specifies the top context
    . mountPath => Specifies the path inside a Pod where volume will be mounted.
==================================================================================================
*/}}
{{- define "identity-manager.secrets.volumeMount" -}}
{{- $top := index . "top" }}
{{- $mountPath := index . "mountPath" }}
{{- if $top.Values.secret_manager.azureKeyVault.use -}}
- name: azure-keyvault-secrets
  mountPath: "{{ $mountPath }}"
{{- else }}
{{- $secretList := include "identity-manager.configuration.secrets.list" $top.Values }}
{{- range $secretList | fromYamlArray | uniq }}
- name: kubernetes-secrets-{{ . }}
  mountPath: "{{ $mountPath }}/{{ . }}"
{{- end }}
{{- end }}
{{- end -}}


{{/*
==================================================================================================
Volume for mounting Keystore Password inside a Pod

Arguments:
    . top => Specifies the top context
==================================================================================================
*/}}
{{- define "identity-manager.key-store-pwd.volume" -}}
{{- $top := index . "top" }}
- name: key-store-pwd
  secret:
    secretName: identity-manager-key-store-pwd
{{- end -}}


{{/*
==================================================================================================
Volume Mount for Keystore Password inside a Pod

Arguments:
    . mountPath => Specifies the path inside a Pod where volume will be mounted.
==================================================================================================
*/}}
{{- define "identity-manager.key-store-pwd.volumeMount" -}}
{{- $top := index . "top" }}
{{- $mountPath := index . "mountPath" }}
- name: key-store-pwd
  mountPath: "{{ $mountPath }}"
{{- end -}}


{{/*
==================================================================================================
Volume for mounting Database SSL Root Certificate inside a Pod

Arguments:
    . secretName => Specifies the name of Kubernetes Secret containing the Root Certificate
==================================================================================================
*/}}
{{- define "identity-manager.db-root-crt.volume" -}}  
{{- $secretName := index . "secretName" }}
- name: db-root-crt
  secret:
    secretName: "{{ $secretName }}"
{{- end -}}


{{/*
==================================================================================================
Volume Mount for Database SSL Root Certificate inside a Pod

Arguments:
    . mountPath => Specifies the path inside a Pod where volume will be mounted.
==================================================================================================
*/}}
{{- define "identity-manager.db-root-crt.volumeMount" -}}
{{- $mountPath := index . "mountPath" }}
- name: db-root-crt
  mountPath: "{{ $mountPath }}"
{{- end -}}



{{/*
========================================================================================================================
Volume for Ingress TLS Certificate and Key

Arguments:
    . top => Specifies the top context
=========================================================================================================================
*/}}
{{- define "identity-manager.ingress.tls.volume" -}}
{{- $top := index . "top" }}
{{- if $top.Values.secret_manager.azureKeyVault.use }}
- name: ingress-tls
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: "azure-keyvault-ingress-tls-certificate-key-provider-class"
{{- else }}
- name: ingress-tls
  secret:
    secretName: {{ $top.Values.ingress.tls.secretName }}  
{{- end }}
{{- end -}}


{{/*
=====================================================================================================================
Volume Mount for Ingress TLS Certificate and Key

Arguments:
    . top => Specifies the top context
    . mountPath => Specifies the path inside a Pod where volume will be mounted.   
=======================================================================================================================
*/}}
{{- define "identity-manager.ingress.tls.volumeMount" -}}
{{- $top := index . "top" }}
{{- $mountPath := index . "mountPath" }}
- name: ingress-tls
  mountPath: "{{ $mountPath }}"
{{- end -}}




{{/*
==============================================================================================================
Volume which can be shared between the containers within a Pod.
It uses emptyDir volume where all containers in the Pod can share files or read and write the same files.

Arguments:
    . name => Name to be assigned to the shared volume

EXAMPLE: init-containers can generate configuration files inside the shared volume which can be subesequenly 
accessed by other containers in the pod.

===============================================================================================================
*/}}
{{- define "identity-manager.shared.volume" -}}
{{- $name := index . "name" }}
- name: {{ $name }}
  emptyDir: {}
{{- end -}}


{{/*
==============================================================================================================
Volume Mount for the Shared Volume.

Arguments:
    . volumeName => Name of the shared volume to be mounted
    . mountPath => Specifies the path inside a Pod where the shared volume will be mounted.

NOTE: Shared volume can be mounted at the same or different paths in each container

===============================================================================================================
*/}}
{{- define "identity-manager.shared.volumeMount" -}}
{{- $volumeName := index . "volumeName" }}
{{- $mountPath := index . "mountPath" }}
- name: {{ $volumeName }}
  mountPath: {{ $mountPath }}
{{- end -}}

{{/*
################################################################################################################################
#                                                   Commands                                                                   #
################################################################################################################################
*/}}


{{/*
=======================================================================================
Command for generating secret properties file

Arguments:
  . top => The top context
  . secretMountFolder => Path of the folder where secrets are mounted as files in a Pod
  . secretPropertiesPath => Path of the secret properties to be generated        
========================================================================================
*/}}
{{- define "identity-manager.generate-secret-properties.command" -}}
{{- $top := index . "top" }}
{{- $secretMountFolder := index . "secretMountFolder" }}
{{- $secretPropertiesPath := index . "secretPropertiesPath" }}
{{- if $top.Values.secret_manager.azureKeyVault.use -}}
while IFS='=' read -r name value ; do if [[ "$name" == "secret___"* ]]; then echo ${name#"secret___"}=\"$(cat {{ $secretMountFolder }}/$value)\" >> {{ $secretPropertiesPath }};fi done < <(env);
{{- else }}
while IFS='=' read -r name value ; do if [[ "$name" == "secret___"* ]]; then echo ${name#"secret___"}=\"$(cat {{ $secretMountFolder }}/$value/*)\" >> {{ $secretPropertiesPath }};fi done < <(env);
{{- end }}
{{- end -}}

{{/*
====================================================================================================
Command for adding common keystore password to secret properties file

Arguments:
  . top => The top context
  . secretMountFolder => Path of the folder where keystore password secret is mounted as file
  . secretPropertiesPath => Path of the secret properties file        
======================================================================================================
*/}}
{{- define "identity-manager.add-keystore-pwd-to-secret-properties.command" -}}
{{- $top := index . "top" }}
{{- $secretMountFolder := index . "secretMountFolder" }}
{{- $secretPropertiesPath := index . "secretPropertiesPath" }}
echo COMMON_KEYSTORE_PWD=\"$(cat {{ $secretMountFolder }}/*)\" >> {{ $secretPropertiesPath }};
{{- end -}}


{{/*
=======================================================================================
Command for splitting TLS certificate and key from a file containg both.

Arguments:
  . file => File containing both TLS certificate and key
  . tlsOutputFolder => Folder where tls.key and tls.crt will be generated  

NOTE: This is needed when Ingress TLS certificate and key are stored in Azure Key Vault.
      In that case both key and certificate are retrieved and mounted as a single file        
========================================================================================
*/}}
{{- define "identity-manager.split-tls-cert-and-key-from-file.command" -}}
{{- $file := index . "file" }}
{{- $tlsOutputFolder := index . "tlsOutputFolder" }}
[ ! -d {{ $tlsOutputFolder }} ] && mkdir -p {{ $tlsOutputFolder }};
openssl pkey -in {{ $file }} -out {{ $tlsOutputFolder }}/tls.key;
openssl crl2pkcs7 -nocrl -certfile {{ $file }} | openssl pkcs7 -print_certs -out {{ $tlsOutputFolder }}/tls.crt;
{{- end }}


{{/*
=======================================================================================
Command for copying the mounted TLS certificate to a folder(as tls.crt)

Arguments:
  . top => The top context
  . tlsMountFolder => Path of the folder where TLS certificate is mounted 
  . outputFolder => Folder where tls.crt will be copied
        
========================================================================================
*/}}
{{- define "identity-manager.setup-tls-cert.command" -}}
{{- $top := index . "top" }}
{{- $tlsMountFolder := index . "tlsMountFolder" }}
{{- $outputFolder := index . "outputFolder" }}
{{- if $top.Values.secret_manager.azureKeyVault.use }}
{{- $certificateFile := printf "%s%s%s" $tlsMountFolder "/" $top.Values.ingress.tls.azureKeyVaultCertificateName }}
{{ include "identity-manager.split-tls-cert-and-key-from-file.command" 
(dict 
  "file" $certificateFile 
  "tlsOutputFolder" "/tmp/tls"
) | nindent 16 }}
cat /tmp/tls/tls.crt > {{ $outputFolder }}/tls.crt;
{{- else }}
cat {{ $tlsMountFolder }}/tls.crt > {{ $outputFolder }}/tls.crt;
{{- end }}
{{- end -}}


{{/*
===========================================================================================
Command for copying the mounted TLS certificate and key to a folder(as tls.crt abd tls.key)

Arguments:
  . top => The top context
  . tlsMountFolder => Path of the folder where TLS certificate and key are mounted 
  . outputFolder => Folder where tls.crt and tls.key will be copied 
        
=============================================================================================
*/}}
{{- define "identity-manager.setup-tls-cert-and-key.command" -}}
{{- $top := index . "top" }}
{{- $tlsMountFolder := index . "tlsMountFolder" }}
{{- $outputFolder := index . "outputFolder" }}
{{- if $top.Values.secret_manager.azureKeyVault.use }}
{{- $certificateFile := printf "%s%s%s" $tlsMountFolder "/" $top.Values.ingress.tls.azureKeyVaultCertificateName }}
{{ include "identity-manager.split-tls-cert-and-key-from-file.command" 
(dict 
  "file" $certificateFile 
  "tlsOutputFolder" "/tmp/tls"
) | nindent 16 }}
cat /tmp/tls/tls.key > {{ $outputFolder }}/tls.key;
cat /tmp/tls/tls.crt > {{ $outputFolder }}/tls.crt;
{{- else }}
cat {{ $tlsMountFolder }}/tls.key > {{ $outputFolder }}/tls.key;
cat {{ $tlsMountFolder }}/tls.crt > {{ $outputFolder }}/tls.crt;
{{- end }}
{{- end -}}


{{/*
=======================================================================================
Execute a script

Arguments:
  . script => Specifies the script to be executed
  . (Optional) args => Arguments for the script     
========================================================================================
*/}}
{{- define "identity-manager.execute-script" -}}
{{- $script := index . "script" }}
{{ $args := ternary (index . "args") "" (hasKey . "args") }}
printf '
{{- range $line := splitList "\n" $script }}
{{ $line | replace "%" "%%" | replace "\\" "\\\\" | replace "'" "'\"'\"'" }}{{ "\n" }}
{{- end -}}
'> '/tmp/run-script.sh';
chmod 755 /tmp/run-script.sh;
{{- if $args }}
/tmp/run-script.sh {{ join " " $args }};
{{- else }}
/tmp/run-script.sh;
{{- end }}
rm /tmp/run-script.sh;
{{- end -}}



