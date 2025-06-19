# V-Learning Platform Helm Chart

A comprehensive Helm chart for deploying the V-Learning microservices-based learning management system on Kubernetes.

## Overview

V-Learning is a modern learning management system built with microservices architecture, featuring:

- **Frontend**: Angular-based user interface
- **API Gateway**: Spring Boot Gateway for routing and load balancing  
- **Service Discovery**: Eureka Server for microservice registration
- **Database**: PostgreSQL for data persistence
- **Microservices**: 
  - User Service (port 8081)
  - Course Service (port 8082) 
  - Content Service (port 8083)
  - Enrollment Service (port 8084)
  - Certificate Service (port 8085)

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Frontend  │    │ API Gateway │    │   Eureka    │
│   :30420    │───▶│   :30080    │───▶│   Server    │
└─────────────┘    └─────────────┘    │   :8761     │
                          │            └─────────────┘
                          │                   │
                          ▼                   │
                   ┌─────────────┐            │
                   │ Microservices│            │
                   │ User :8081   │◀───────────┘
                   │ Course :8082 │
                   │ Content :8083│
                   │ Enroll :8084 │
                   │ Cert :8085   │
                   └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │ PostgreSQL  │
                   │   :5432     │
                   └─────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- kubectl configured

### Installation

1. **Install the chart:**
   ```bash
   helm install v-learning .
   ```

2. **Check deployment status:**
   ```bash
   kubectl get pods -n v-learning
   ```

3. **Access the application:**
   - Frontend: http://localhost:30420
   - API Gateway: http://localhost:30080
   - Eureka Dashboard: Port-forward with `kubectl port-forward -n v-learning svc/eureka-server 8761:8761`

## Chart Structure

```
v-learning-helm/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── README.md                 # This file
└── templates/
    ├── namespace.yaml        # Namespace creation
    ├── configs/             # ConfigMaps
    │   ├── eureka-config.yaml
    │   ├── gateway-config.yaml
    │   ├── postgres-config.yaml
    │   └── services-config.yaml
    ├── deployments/         # Application deployments
    │   ├── eureka.yaml
    │   ├── gateway.yaml
    │   ├── postgres.yaml
    │   └── services.yaml
    ├── frontend/            # Frontend components
    │   └── frontend.yaml
    ├── infrastructure/      # Infrastructure components
    │   └── postgres.yaml
    ├── secrets/            # Sensitive data
    │   └── postgres-secret.yaml
    ├── services/           # Kubernetes services
    │   ├── eureka-service.yaml
    │   ├── gateway-service.yaml
    │   ├── postgres-service.yaml
    │   └── services-svc.yaml
    └── volumes/            # Persistent storage
        └── postgres-pvc.yaml
```

## Configuration

### Default Values

The chart comes with sensible defaults in `values.yaml`:

```yaml
global:
  namespace: v-learning
  imageRegistry: mahdi0188
  imageTag: dev-66

postgres:
  enabled: true
  database: pfe_learning
  username: pfe_user

# All services enabled by default
userService:
  enabled: true
  port: 8081
```

### Customization

Create a custom values file:

```yaml
# custom-values.yaml
global:
  imageTag: "latest"

# Disable specific services
certificateService:
  enabled: false

# Custom database configuration
postgres:
  database: "my_learning_db"
  username: "my_user"
```

Install with custom values:
```bash
helm install v-learning . -f custom-values.yaml
```

## Operations

### Scaling

Update replicas in values.yaml and upgrade:
```bash
helm upgrade v-learning .
```

### Updates

Update image tags:
```bash
helm upgrade v-learning . --set global.imageTag=v2.0
```

### Rollback

Rollback to previous version:
```bash
helm rollback v-learning 1
```

### Uninstall

Remove completely:
```bash
helm uninstall v-learning
kubectl delete namespace v-learning
```

## Monitoring & Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n v-learning
```

### View Logs
```bash
# API Gateway logs
kubectl logs -n v-learning deployment/api-gateway

# Database logs  
kubectl logs -n v-learning deployment/postgres

# Service logs
kubectl logs -n v-learning deployment/user-service
```

### Service Discovery
Check Eureka dashboard:
```bash
kubectl port-forward -n v-learning svc/eureka-server 8761:8761
# Visit: http://localhost:8761
```

### Database Access
Connect to PostgreSQL:
```bash
kubectl exec -it -n v-learning deployment/postgres -- psql -U pfe_user -d pfe_learning
```

### Common Issues

1. **Services in CrashLoopBackOff:**
   - Usually means waiting for database/Eureka to be ready
   - Check logs: `kubectl logs -n v-learning <pod-name>`

2. **PostgreSQL Init Issues:**
   - Delete PVC and restart: `kubectl delete pvc -n v-learning postgres-pvc`

3. **Service Discovery Issues:**
   - Verify Eureka is running: `kubectl get pods -n v-learning -l app=eureka-server`

## Security Considerations

- Database passwords should be changed from defaults
- Consider using Kubernetes secrets for sensitive data
- Implement network policies for production
- Use service accounts with minimal permissions

## Support

For issues and questions:
- Check the troubleshooting section above
- Review Kubernetes events: `kubectl get events -n v-learning`
- Examine pod logs for specific errors

## Version History

- **1.0.0**: Initial release with all core services
  - PostgreSQL database
  - Eureka service discovery  
  - API Gateway
  - 5 microservices (User, Course, Content, Enrollment, Certificate)
  - Angular frontend
