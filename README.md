# V-Learning Platform Helm Chart

A comprehensive Helm chart for deploying the V-Learning microservices-based learning management system on Kubernetes with Istio service mesh support.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Branch-Based Deployment Strategy](#branch-based-deployment-strategy)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Global Configuration](#global-configuration)
  - [Istio Configuration](#istio-configuration)
  - [Canary Deployment Configuration](#canary-deployment-configuration)
  - [Resource Configuration](#resource-configuration)
- [Microservices](#microservices)
- [Istio Service Mesh Features](#istio-service-mesh-features)
  - [Traffic Management](#traffic-management)
  - [mTLS Security](#mtls-security)
  - [Canary Deployments](#canary-deployments)
  - [Ingress Gateway](#ingress-gateway)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

## Overview

V-Learning is a modern learning management system built with a microservices architecture, featuring:

- **Frontend**: Angular-based user interface
- **API Gateway**: Spring Boot Gateway for routing and load balancing  
- **Service Discovery**: Eureka Server for microservice registration
- **Database**: PostgreSQL for data persistence
- **Microservices**: 
  - Course Service: Course catalog and management
  - Content Service: Learning materials and content delivery
  - Enrollment Service: Student enrollment and progress tracking
  - Certificate Service: Certificate generation and verification

## Architecture

The V-Learning platform follows a modern microservices architecture:

```ascii
                                   ┌─────────────────┐
                                   │                 │
                                   │    Frontend     │
                                   │                 │
                                   └────────┬────────┘
                                            │
                                            ▼
┌─────────────────┐              ┌─────────────────┐              ┌─────────────────┐
│                 │              │                 │              │                 │
│  Istio Ingress  │─────────────▶│  API Gateway    │─────────────▶│  Eureka Server  │
│    Gateway      │              │                 │              │                 │
└─────────────────┘              └────────┬────────┘              └─────────────────┘
                                          │
                 ┌─────────────────┬──────┴─────┬─────────────────┬─────────────────┐
                 │                 │            │                 │                 │
                 ▼                 ▼            ▼                 ▼                 ▼
        ┌─────────────────┐┌─────────────────┐┌─────────────────┐┌─────────────────┐┌─────────────────┐
        │                 ││                 ││                 ││                 ││                 │
        │  User Service   ││ Course Service  ││ Content Service ││Enrollment Service││Certificate Service│
        │                 ││                 ││                 ││                 ││                 │
        └────────┬────────┘└────────┬────────┘└────────┬────────┘└────────┬────────┘└────────┬────────┘
                 │                  │                  │                  │                  │
                 └──────────────────┴──────────┬───────┴──────────────────┴──────────────────┘
                                               │
                                               ▼
                                    ┌─────────────────┐
                                    │                 │
                                    │   PostgreSQL    │
                                    │                 │
                                    └─────────────────┘
```

## Features

- **Kubernetes Native**: Deployments, Services, ConfigMaps, and Volumes
- **Horizontal Pod Autoscaling**: Scale based on CPU/Memory utilization
- **Istio Service Mesh**: For test and main branches only, including:
  - Traffic Management with intelligent routing
  - mTLS encryption for secure service-to-service communication
  - Canary Deployments for safer releases
  - Ingress Gateway for external access
- **Environment-specific Configuration**: Different settings for dev, test, and main environments
- **Resource Management**: Configurable CPU and memory limits for all services

## Branch-Based Deployment Strategy

The Helm chart implements a branch-based deployment strategy that automatically applies different configurations based on the branch:

| Branch | Istio Enabled | Description |
|--------|---------------|-------------|
| dev    | No            | Basic Kubernetes deployment without Istio overhead, suitable for development |
| test   | Yes           | Full Istio service mesh with canary capability for testing environments |
| main   | Yes           | Full Istio service mesh with canary capability for production |

This approach ensures:

- Faster local development without unnecessary complexity
- Comprehensive testing with full service mesh capabilities
- Production-ready deployment with all security and reliability features

## Installation

### Prerequisites

- Kubernetes cluster (1.19+)
- Helm (3.0+)
- Istio installed in the cluster (for test and main branches)

### Basic Installation

```bash
# Clone the repository
git clone https://github.com/Mahdi-Magroun/v-learning-helm.git
cd v-learning-helm

# Install for development (no Istio)
helm install v-learning . --set global.branch=dev --namespace v-learning --create-namespace

# Install for testing (with Istio)
helm install v-learning . --set global.branch=test --namespace v-learning --create-namespace

# Install for production (with Istio)
helm install v-learning . --set global.branch=main --namespace v-learning --create-namespace
```

### Installation with Custom Values

```bash
# Using a custom values file
helm install v-learning . -f my-values.yaml --namespace v-learning --create-namespace

# Overriding specific values
helm install v-learning . \
  --set global.branch=test \
  --set global.imageTag=v1.2.3 \
  --set global.previousImageTag=v1.2.2 \
  --namespace v-learning \
  --create-namespace
```

## Configuration

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace for all resources | `v-learning` |
| `global.imageTag` | Current image tag for all services | `test-2` |
| `global.previousImageTag` | Previous image tag for canary deployments | `test-1` |
| `global.branch` | Current branch for configuration | `test` |

### Istio Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `istio.mtls.enabled` | Enable mTLS for service-to-service communication | `true` |
| `istio.mtls.mode` | mTLS mode (STRICT, PERMISSIVE) | `PERMISSIVE` |
| `istio.ingressGateway.enabled` | Enable Istio ingress gateway | `true` |
| `istio.ingressGateway.host` | Hostname for ingress gateway | `v-learning.local` |
| `istio.ingressGateway.port` | HTTP port for ingress gateway | `80` |

### Canary Deployment Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `canary.enabled` | Master switch for canary deployments | `false` |
| `canary.currentWeight` | Percentage of traffic to current version | `90` |
| `canary.previousWeight` | Percentage of traffic to previous version | `10` |
| `canary.userService` | Enable canary for user service | `false` |
| `canary.courseService` | Enable canary for course service | `false` |
| `canary.contentService` | Enable canary for content service | `false` |
| `canary.enrollmentService` | Enable canary for enrollment service | `false` |
| `canary.certificateService` | Enable canary for certificate service | `false` |

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.userService.requests.cpu` | CPU request for user service | `100m` |
| `resources.userService.requests.memory` | Memory request for user service | `256Mi` |
| `resources.userService.limits.cpu` | CPU limit for user service | `500m` |
| `resources.userService.limits.memory` | Memory limit for user service | `512Mi` |

For a complete list of configuration options, see the [values.yaml](values.yaml) file.

## Microservices

### User Service (Port 8081)

- User registration and authentication
- Profile management
- Role-based access control

### Course Service (Port 8082)

- Course catalog and management
- Curriculum organization
- Course metadata

### Content Service (Port 8083)

- Learning materials management
- Content delivery
- Media storage and retrieval

### Enrollment Service (Port 8084)

- Student enrollment
- Progress tracking
- Course completion

### Certificate Service (Port 8085)

- Certificate generation
- Certificate verification
- Achievement tracking

## Istio Service Mesh Features

> **Note:** Istio integration is now manual and not automatically managed by the Helm chart. Follow the setup instructions below.

### Manual Istio Setup

The V-Learning Helm chart now requires manual setup of Istio. Follow these steps to enable Istio:

1. **Install Istio** on your cluster if not already installed:
   ```bash
   # Download Istio
   curl -L https://istio.io/downloadIstio | sh -

   # Move to the Istio package directory
   cd istio-*

   # Add istioctl to your path
   export PATH=$PWD/bin:$PATH

   # Install Istio with demo profile (includes defaults for mTLS)
   istioctl install --set profile=demo -y
   ```

2. **Enable Istio for the v-learning namespace** using one of these methods:
   
   a. Enable Istio injection via namespace label (recommended):
   ```bash
   kubectl label namespace v-learning istio-injection=enabled
   ```
   
   b. Or manually inject Istio into your Kubernetes manifests:
   ```bash
   # Generate manifests with Helm template
   helm template v-learning . -n v-learning > v-learning-manifests.yaml
   
   # Inject Istio sidecars
   istioctl kube-inject -f v-learning-manifests.yaml > v-learning-istio.yaml
   
   # Apply the modified manifests
   kubectl apply -f v-learning-istio.yaml
   ```

3. **Apply Istio resources** for traffic management, mTLS, and other features:
   ```bash
   # Apply Istio Gateway
   kubectl apply -f istio-gateway.yaml
   
   # Apply VirtualService for routing
   kubectl apply -f istio-virtualservice.yaml
   
   # Apply DestinationRules for mTLS
   kubectl apply -f istio-destination-rules.yaml
   ```

   Example Istio configuration files are provided in the `examples/` directory.

### Traffic Management

The Istio configuration includes a VirtualService that routes traffic to the appropriate microservices based on URI paths:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: v-learning-vs
spec:
  hosts:
  - v-learning.local
  gateways:
  - v-learning-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: frontend
  - match:
    - uri:
        prefix: /api/
    route:
    - destination:
        host: api-gateway
```

### mTLS Security

Mutual TLS authentication is enabled between services for secure communication:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: PERMISSIVE  # Can be STRICT for production
```

### Canary Deployments

The chart supports canary deployments for safe rollouts of new versions:

```yaml
# Enable canary for user service
canary:
  enabled: true
  currentWeight: 90   # 90% traffic to current version
  previousWeight: 10  # 10% traffic to previous version
  userService: true   # Only enable for user service
```

The canary deployment creates two versions of a service:

- Current version (using `global.imageTag`)
- Previous version (using `global.previousImageTag`)

Traffic is split between the versions according to the configured weights.

### Ingress Gateway

The Istio ingress gateway provides external access to the platform:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: v-learning-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - v-learning.local
```

## Usage Examples

### Basic Development Setup

```bash
# Install for development without Istio
helm install v-learning . --set global.branch=dev --namespace v-learning --create-namespace
```

### Testing with Canary Deployments

```bash
# Install for testing with canary deployment for user service
helm install v-learning . \
  --set global.branch=test \
  --set canary.enabled=true \
  --set canary.userService=true \
  --namespace v-learning \
  --create-namespace
```

### Production Deployment

```bash
# Install for production with strict mTLS
helm install v-learning . \
  --set global.branch=main \
  --set istio.mtls.mode=STRICT \
  --namespace v-learning \
  --create-namespace
```

### Updating Image Versions

```bash
# Update to a new version with canary deployment
helm upgrade v-learning . \
  --set global.imageTag=v1.3.0 \
  --set global.previousImageTag=v1.2.0 \
  --set canary.enabled=true \
  --set canary.userService=true \
  --set canary.courseService=true \
  --namespace v-learning
```

## Troubleshooting

### Common Issues

#### Istio Features Not Working in Dev Branch

Istio features are intentionally disabled in the dev branch. To use Istio, change to the test or main branch:

```bash
helm upgrade v-learning . --set global.branch=test
```

#### Canary Deployments Not Appearing

Ensure that:

1. You're using the test or main branch (`global.branch=test` or `global.branch=main`)
2. Canary is enabled globally (`canary.enabled=true`)
3. Canary is enabled for the specific service (`canary.userService=true`)

#### Services Not Communicating

If services can't communicate:

1. Check if mTLS is configured correctly
2. Verify service names and ports
3. Check Istio sidecar injection

For debugging:

```bash
# Check if pods have Istio sidecar
kubectl get pods -n v-learning

# View Istio configuration
kubectl get virtualservices,destinationrules,gateways -n v-learning
```

### Getting Help

For more information or assistance:

- File an issue on the GitHub repository
- Check the Istio documentation for advanced troubleshooting

---

## License

This Helm chart is licensed under the MIT License.

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
