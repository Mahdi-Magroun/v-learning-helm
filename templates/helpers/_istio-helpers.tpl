{{/* Simple helper to enable Istio only for test and main branches */}}
{{- define "v-learning.istioEnabled" -}}
{{- if or (eq .Values.global.branch "test") (eq .Values.global.branch "main") -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
