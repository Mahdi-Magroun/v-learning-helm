# Horizontal Pod Autoscaler (HPA) Configuration

This directory contains Horizontal Pod Autoscaler configurations for all services in the V-Learning platform.

## Files Structure

```
templates/hpa/
├── user-service-hpa.yaml          # HPA for User Service
├── course-service-hpa.yaml        # HPA for Course Service
├── content-service-hpa.yaml       # HPA for Content Service
├── enrollment-service-hpa.yaml    # HPA for Enrollment Service
├── certificate-service-hpa.yaml   # HPA for Certificate Service
└── postgresql-ha-hpa.yaml         # HPA for PostgreSQL HA PgPool
```

## PostgreSQL HA Integration

The PostgreSQL HA HPA configuration scales the PgPool connection pooler based on:
- CPU utilization (default: 75%)
- Memory utilization (default: 80%)
- Min replicas: 2 (for high availability)
- Max replicas: 5 (to prevent resource exhaustion)

## Usage Examples

### Deploy with PostgreSQL HA (Production)
```bash
helm upgrade --install v-learning . \
  --namespace v-learning \
  --set postgres.enabled=false \
  --set postgresHA.enabled=true
```

### Deploy with simple PostgreSQL (Development)
```bash
helm upgrade --install v-learning . \
  --namespace v-learning \
  --set postgres.enabled=true \
  --set postgresHA.enabled=false
```

### Monitor PostgreSQL HA
```bash
# Check PostgreSQL HA pods
kubectl get pods -n v-learning -l app.kubernetes.io/name=postgresql-ha

# Check HPA status
kubectl get hpa postgresql-ha-pgpool-hpa -n v-learning

# Check database connectivity
kubectl exec -it -n v-learning $(kubectl get pods -n v-learning -l app.kubernetes.io/component=pgpool -o jsonpath='{.items[0].metadata.name}') -- psql -U pfe_user -d pfe_learning -c "SELECT version();"
```
