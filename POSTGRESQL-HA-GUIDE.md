# PostgreSQL HA Integration Guide

This guide explains how to integrate and use PostgreSQL High Availability with your V-Learning platform.

## 🎯 Overview

The integration provides:
- **High Availability**: Multiple PostgreSQL instances with automatic failover
- **Load Balancing**: PgPool for connection pooling and load distribution  
- **Horizontal Scaling**: HPA for PgPool based on CPU/Memory usage
- **Backward Compatibility**: Existing microservices continue to work without changes
- **ArgoCD Ready**: Automatic deployment via GitOps

## 📁 Structure

```
v-learning-helm/
├── Chart.yaml                                    # Updated with PostgreSQL HA dependency
├── values.yaml                                   # Updated with PostgreSQL HA config
├── values-postgres-override.yaml                 # Quick configuration switching
├── migrate-to-postgres-ha.sh                     # Migration script
├── templates/
│   ├── infrastructure/
│   │   ├── postgres.yaml                         # Old PostgreSQL (disabled)
│   │   └── postgres-ha-compatibility.yaml        # Compatibility service
│   └── hpa/
│       └── postgresql-ha-hpa.yaml                # HPA for PgPool
```

## 🚀 Quick Start

### 1. Switch to PostgreSQL HA

**Option A: Update values.yaml directly**
```yaml
postgres:
  enabled: false  # Disable old PostgreSQL

postgresHA:
  enabled: true   # Enable PostgreSQL HA
```

**Option B: Use override values**
```bash
helm upgrade --install v-learning . \
  --namespace v-learning \
  --values values-postgres-override.yaml
```

### 2. Deploy

```bash
# Update dependencies first
helm dependency update

# Deploy with PostgreSQL HA
helm upgrade --install v-learning . \
  --namespace v-learning \
  --set postgres.enabled=false \
  --set postgresHA.enabled=true
```

## 🔧 Configuration

### Database Credentials
The same credentials are used for backward compatibility:
- **Database**: `pfe_learning`
- **Username**: `pfe_user`  
- **Password**: `123456`

### PostgreSQL HA Settings
```yaml
postgresHA:
  enabled: true
  postgresql:
    replicaCount: 3           # 3 PostgreSQL instances
    auth:
      postgresPassword: "123456"
      username: "pfe_user"
      password: "123456"
      database: "pfe_learning"
    primary:
      persistence:
        size: 8Gi             # Primary storage size
    readReplicas:
      persistence:
        size: 8Gi             # Replica storage size
  pgpool:
    replicaCount: 2           # 2 PgPool instances
    adminUsername: "admin"
    adminPassword: "adminpassword123"
```

### HPA Configuration
```yaml
hpa:
  postgresHA:
    enabled: true
    pgpool:
      minReplicas: 2          # Minimum PgPool instances
      maxReplicas: 5          # Maximum PgPool instances
      targetCPUUtilizationPercentage: 75
      targetMemoryUtilizationPercentage: 80
```

## 🔄 Migration Process

### Automated Migration
```bash
# Run the migration script
./migrate-to-postgres-ha.sh v-learning v-learning

# The script will:
# 1. Backup existing database
# 2. Update dependencies
# 3. Deploy PostgreSQL HA
# 4. Wait for readiness
# 5. Verify connection
# 6. Optionally clean up old resources
```

### Manual Migration
```bash
# 1. Backup existing data (if needed)
kubectl exec -n v-learning $(kubectl get pods -n v-learning -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- pg_dump -U pfe_user pfe_learning > backup.sql

# 2. Update dependencies
helm dependency update

# 3. Deploy PostgreSQL HA
helm upgrade --install v-learning . \
  --namespace v-learning \
  --set postgres.enabled=false \
  --set postgresHA.enabled=true

# 4. Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql-ha -n v-learning --timeout=600s

# 5. Test connection
kubectl exec -it -n v-learning $(kubectl get pods -n v-learning -l app.kubernetes.io/component=pgpool -o jsonpath='{.items[0].metadata.name}') -- psql -U pfe_user -d pfe_learning -c "SELECT version();"
```

## 📊 Monitoring

### Check Status
```bash
# PostgreSQL HA pods
kubectl get pods -n v-learning -l app.kubernetes.io/name=postgresql-ha

# HPA status  
kubectl get hpa -n v-learning

# Services
kubectl get svc -n v-learning | grep postgres

# PVCs
kubectl get pvc -n v-learning -l app.kubernetes.io/name=postgresql-ha
```

### Database Connection
```bash
# Connect via PgPool (recommended)
kubectl exec -it -n v-learning $(kubectl get pods -n v-learning -l app.kubernetes.io/component=pgpool -o jsonpath='{.items[0].metadata.name}') -- psql -U pfe_user -d pfe_learning

# Connect directly to primary
kubectl exec -it -n v-learning $(kubectl get pods -n v-learning -l app.kubernetes.io/component=postgresql,role=primary -o jsonpath='{.items[0].metadata.name}') -- psql -U pfe_user -d pfe_learning
```

### Logs
```bash
# PgPool logs
kubectl logs -n v-learning -l app.kubernetes.io/component=pgpool -f

# PostgreSQL primary logs
kubectl logs -n v-learning -l app.kubernetes.io/component=postgresql,role=primary -f

# PostgreSQL replica logs
kubectl logs -n v-learning -l app.kubernetes.io/component=postgresql,role=read -f
```

## 🔄 ArgoCD Integration

### Application Manifest
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: v-learning
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/v-learning-k8s
    targetRevision: HEAD
    path: v-learning-helm
    helm:
      values: |
        postgres:
          enabled: false
        postgresHA:
          enabled: true
  destination:
    server: https://kubernetes.default.svc
    namespace: v-learning
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## 🔧 Troubleshooting

### Common Issues

**1. Old PostgreSQL still running**
```bash
# Check if old resources exist
kubectl get deployment,service,configmap,secret -n v-learning | grep postgres

# Clean up if needed
kubectl delete deployment postgres -n v-learning
kubectl delete service postgres -n v-learning  
kubectl delete configmap postgres-config -n v-learning
kubectl delete secret postgres-secret -n v-learning
```

**2. Connection issues**
```bash
# Check service endpoints
kubectl get endpoints -n v-learning postgres

# Test connection
kubectl run postgres-client --rm -it --image postgres:15-alpine --namespace v-learning -- psql -h postgres -U pfe_user -d pfe_learning
```

**3. HPA not scaling**
```bash
# Check HPA events
kubectl describe hpa postgresql-ha-pgpool-hpa -n v-learning

# Check metrics
kubectl top pods -n v-learning -l app.kubernetes.io/component=pgpool
```

## 🗑️ Rollback

To rollback to single PostgreSQL:
```bash
helm upgrade --install v-learning . \
  --namespace v-learning \
  --set postgres.enabled=true \
  --set postgresHA.enabled=false
```

## ⚙️ Advanced Configuration

### Custom Storage Classes
```yaml
postgresHA:
  postgresql:
    primary:
      persistence:
        storageClass: "fast-ssd"
    readReplicas:
      persistence:
        storageClass: "standard"
```

### Resource Limits
```yaml
postgresHA:
  postgresql:
    primary:
      resources:
        requests:
          memory: "1Gi"
          cpu: "500m"
        limits:
          memory: "2Gi" 
          cpu: "1000m"
```

### Backup Configuration
```yaml
postgresHA:
  postgresql:
    primary:
      extraVolumeMounts:
      - name: backup-storage
        mountPath: /backup
      extraVolumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: postgres-backup-pvc
```
