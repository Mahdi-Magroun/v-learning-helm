{{/* Helper for Istio enablement - returns the istio.enabled value */}}
{{- define "v-learning.istioEnabled" -}}
{{- if .Values.istio.enabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
