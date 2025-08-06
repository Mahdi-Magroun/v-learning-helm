{{- /*
This file contains helpers for enabling Istio based on the branch
It automatically enables Istio for test and main branches only
*/ -}}

{{- /*
enableIstioForBranch determines whether to enable Istio based on the branch name
Returns true for test and main branches, false otherwise
*/ -}}
{{- define "v-learning.enableIstioForBranch" -}}
{{- if or (eq .Values.global.branch "test") (eq .Values.global.branch "main") -}}
{{- true -}}
{{- else -}}
{{- .Values.istio.enabled -}}
{{- end -}}
{{- end -}}

{{- /*
shouldEnableIstio combines the user setting with the branch check
This allows explicit enabling in values.yaml to override the branch check
*/ -}}
{{- define "v-learning.shouldEnableIstio" -}}
{{- if .Values.istio.enabled -}}
{{- true -}}
{{- else -}}
{{- include "v-learning.enableIstioForBranch" . -}}
{{- end -}}
{{- end -}}
