# Testing Istio in V-Learning Platform

This guide provides step-by-step instructions for testing your Istio service mesh implementation for the V-Learning platform.

## Prerequisites

1. Ensure you have installed Istio in your Kubernetes cluster
2. Make sure the V-Learning Helm chart is deployed
3. Confirm that the namespace has Istio injection enabled: `kubectl get namespace v-learning --show-labels`
4. Install `curl` and `jq` (optional, for formatting JSON responses)

## 1. Get Istio Ingress Gateway IP/Port

First, you need to get the external IP or port for the Istio ingress gateway:

```bash
# Get the Istio ingress gateway service details
kubectl get svc istio-ingressgateway -n istio-system
```

You'll see output similar to:

```
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                         AGE
istio-ingressgateway   LoadBalancer   10.43.16.125    X.X.X.X         15021:30729/TCP,80:30637/TCP    1d
```

Take note of:
- The EXTERNAL-IP if using a LoadBalancer
- The NodePort (e.g., 30637) if you're using NodePort

## 2. Configure Host Resolution

Since the gateway is configured for the hostname `v-learning.local`, you need to either:

### A. Update your hosts file (recommended for testing)

```bash
# Replace X.X.X.X with your ingress gateway IP
sudo sh -c "echo 'X.X.X.X v-learning.local' >> /etc/hosts"
```

### B. Use the `-H` header with curl

```bash
# Use this if you don't want to modify your hosts file
INGRESS_IP=X.X.X.X  # Replace with your ingress gateway IP or hostname
curl -H "Host: v-learning.local" http://$INGRESS_IP/api/users
```

## 3. Test API Endpoints

Now you can test each service through the Istio gateway:

### User Service

```bash
# Test user service API
curl -v http://v-learning.local/api/users | jq .

# Authentication endpoint (if available)
curl -X POST http://v-learning.local/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test@example.com","password":"password"}'
```

### Course Service

```bash
# Test course service API
curl -v http://v-learning.local/api/courses | jq .

# Get specific course (if available)
curl -v http://v-learning.local/api/courses/1 | jq .
```

### Content Service

```bash
# Test content service API
curl -v http://v-learning.local/api/content | jq .
```

### Enrollment Service

```bash
# Test enrollment service API
curl -v http://v-learning.local/api/enrollments | jq .
```

### Certificate Service

```bash
# Test certificate service API
curl -v http://v-learning.local/api/certificates | jq .
```

## 4. Verify Istio Metrics and Tracing

### Check Prometheus Metrics

If you've deployed Prometheus for Istio:

```bash
# Port-forward to Prometheus
kubectl -n istio-system port-forward $(kubectl -n istio-system get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090

# Access in browser: http://localhost:9090
# Try queries like:
# - istio_requests_total
# - istio_request_duration_milliseconds
```

### Check Kiali Dashboard

If you've deployed Kiali:

```bash
# Port-forward to Kiali
kubectl -n istio-system port-forward $(kubectl -n istio-system get pods -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001

# Access in browser: http://localhost:20001
```

### Check Jaeger Tracing

If you've deployed Jaeger:

```bash
# Port-forward to Jaeger
kubectl -n istio-system port-forward $(kubectl -n istio-system get pods -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686

# Access in browser: http://localhost:16686
```

## 5. Verify mTLS Enforcement

You can verify that mTLS is enforced between services:

```bash
# Get pods
kubectl get pods -n v-learning

# Check if traffic is encrypted
istioctl x describe pod <pod-name> -n v-learning
```

Look for "PERMISSIVE" or "STRICT" mode in the output.

## 6. Test Canary Deployments

To test canary deployments (if enabled), make multiple requests to a service with both versions deployed:

```bash
# Make multiple requests to see traffic distribution between versions
for i in {1..20}; do curl -s http://v-learning.local/api/users | grep -o "version"; done | sort | uniq -c
```

This should show a distribution between the current and previous versions according to your weight settings in values.yaml.

## Troubleshooting

### Check Istio Proxy Logs

```bash
# Check logs for the Istio proxy (sidecar) in a specific pod
kubectl logs <pod-name> -c istio-proxy -n v-learning
```

### Check Istio Gateway Logs

```bash
# Find the ingress gateway pod
GATEWAY_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')

# Check logs
kubectl logs $GATEWAY_POD -n istio-system
```

### Verify VirtualService and Gateway Configuration

```bash
# Check if VirtualService is properly configured
istioctl x describe vs v-learning-vs -n v-learning

# Check if Gateway is properly configured
istioctl x describe gateway v-learning-gateway -n v-learning
```

### Check for Auth Policies

```bash
# List all authentication policies
kubectl get peerauthentication -n v-learning
kubectl get authorizationpolicy -n v-learning
```
