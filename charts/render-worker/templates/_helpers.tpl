{{- define "render-worker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "render-worker.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "render-worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "render-worker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "render-worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "render-worker.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "render-worker.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.workerEnv" -}}
{{- $env := dict -}}
{{- if eq .Values.adapters.queue.type "sqs" -}}
{{- $_ := set $env .Values.adapters.queue.envName .Values.adapters.queue.sqs.queueURL -}}
{{- $_ := set $env "AWS_REGION" .Values.adapters.queue.sqs.awsRegion -}}
{{- else if eq .Values.adapters.queue.type "mock" -}}
{{- $_ := set $env .Values.adapters.queue.envName .Values.adapters.queue.mock.queueName -}}
{{- end -}}
{{- if eq .Values.adapters.storage.type "s3" -}}
{{- $_ := set $env .Values.adapters.storage.assetEnvName .Values.adapters.storage.s3.assetBucket -}}
{{- $_ := set $env .Values.adapters.storage.outputEnvName .Values.adapters.storage.s3.outputBucket -}}
{{- $_ := set $env "AWS_REGION" .Values.adapters.storage.s3.awsRegion -}}
{{- else if eq .Values.adapters.storage.type "local" -}}
{{- $_ := set $env .Values.adapters.storage.assetEnvName .Values.adapters.storage.local.assetPath -}}
{{- $_ := set $env .Values.adapters.storage.outputEnvName .Values.adapters.storage.local.outputPath -}}
{{- else if eq .Values.adapters.storage.type "minio" -}}
{{- $_ := set $env .Values.adapters.storage.assetEnvName .Values.adapters.storage.minio.assetBucket -}}
{{- $_ := set $env .Values.adapters.storage.outputEnvName .Values.adapters.storage.minio.outputBucket -}}
{{- $_ := set $env "STORAGE_ENDPOINT" .Values.adapters.storage.minio.endpoint -}}
{{- $_ := set $env "AWS_REGION" .Values.adapters.storage.minio.region -}}
{{- end -}}
{{- range $name, $value := .Values.worker.env -}}
{{- $_ := set $env $name $value -}}
{{- end -}}
{{- range $name := keys $env | sortAlpha }}
- name: {{ $name }}
  value: {{ get $env $name | quote }}
{{- end -}}
{{- end -}}

{{- define "render-worker.workdirMountPath" -}}
{{- default "/work" .Values.worker.env.RENDER_TMP_DIR -}}
{{- end -}}

{{- define "render-worker.serviceAccountAnnotations" -}}
{{- $annotations := dict -}}
{{- if and (eq .Values.adapters.identity.type "irsa") .Values.adapters.identity.irsa.roleArn -}}
{{- $_ := set $annotations .Values.adapters.identity.irsa.annotationKey .Values.adapters.identity.irsa.roleArn -}}
{{- end -}}
{{- range $key, $value := .Values.serviceAccount.annotations -}}
{{- $_ := set $annotations $key $value -}}
{{- end -}}
{{- if gt (len $annotations) 0 -}}
{{- toYaml $annotations -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.existingSecretName" -}}
{{- if and (eq .Values.adapters.identity.type "existingSecret") .Values.adapters.identity.existingSecret.name -}}
{{- .Values.adapters.identity.existingSecret.name -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.kedaTriggerType" -}}
{{- if eq .Values.adapters.queue.type "sqs" -}}
aws-sqs-queue
{{- else -}}
{{- .Values.keda.trigger.type -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.kedaQueueURLFromEnv" -}}
{{- if eq .Values.adapters.queue.type "sqs" -}}
{{- .Values.adapters.queue.envName -}}
{{- else -}}
{{- .Values.keda.trigger.queueURLFromEnv -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.kedaQueueLength" -}}
{{- if eq .Values.adapters.queue.type "sqs" -}}
{{- .Values.adapters.queue.sqs.queueLength -}}
{{- else -}}
{{- .Values.keda.queueLength -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.kedaAWSRegion" -}}
{{- if eq .Values.adapters.queue.type "sqs" -}}
{{- .Values.adapters.queue.sqs.awsRegion -}}
{{- else -}}
{{- .Values.keda.trigger.awsRegion -}}
{{- end -}}
{{- end -}}

{{- define "render-worker.kedaPodIdentityProvider" -}}
{{- if eq .Values.adapters.identity.type "podIdentity" -}}
{{- .Values.adapters.identity.podIdentity.provider -}}
{{- else -}}
{{- .Values.keda.authentication.podIdentity.provider -}}
{{- end -}}
{{- end -}}
