# Architecture

The V-Learning platform follows a modern microservices architecture:

```
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

# Features

- **Kubernetes Native**: Deployments, Services, ConfigMaps, and Volumes
- **Horizontal Pod Autoscaling**: Scale based on CPU/Memory utilization
- **Istio Service Mesh**: For test and main branches only, including:
  - Traffic Management with intelligent routing
  - mTLS encryption for secure service-to-service communication
  - Canary Deployments for safer releases
  - Ingress Gateway for external access
- **Environment-specific Configuration**: Different settings for dev, test, and main environments
- **Resource Management**: Configurable CPU and memory limits for all services

# Branch-Based Deployment Strategy

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

# Installation

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm (3.0+)
- Istio installed in the cluster (for test and main branches)

## Basic Installation

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

## Installation with Custom Values

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

# Configuration

## Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace for all resources | `v-learning` |
| `global.imageTag` | Current image tag for all services | `test-2` |
| `global.previousImageTag` | Previous image tag for canary deployments | `test-1` |
| `global.branch` | Current branch for configuration | `test` |

## Istio Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `istio.mtls.enabled` | Enable mTLS for service-to-service communication | `true` |
| `istio.mtls.mode` | mTLS mode (STRICT, PERMISSIVE) | `PERMISSIVE` |
| `istio.ingressGateway.enabled` | Enable Istio ingress gateway | `true` |
| `istio.ingressGateway.host` | Hostname for ingress gateway | `v-learning.local` |
| `istio.ingressGateway.port` | HTTP port for ingress gateway | `80` |

## Canary Deployment Configuration

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

## Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.userService.requests.cpu` | CPU request for user service | `100m` |
| `resources.userService.requests.memory` | Memory request for user service | `256Mi` |
| `resources.userService.limits.cpu` | CPU limit for user service | `500m` |
| `resources.userService.limits.memory` | Memory limit for user service | `512Mi` |
| `resources.courseService.*` | Resource configuration for course service | See `values.yaml` |
| `resources.contentService.*` | Resource configuration for content service | See `values.yaml` |
| `resources.enrollmentService.*` | Resource configuration for enrollment service | See `values.yaml` |
| `resources.certificateService.*` | Resource configuration for certificate service | See `values.yaml` |

For a complete list of configuration options, see the [values.yaml](values.yaml) file.

# Microservices

## User Service (Port 8081)
- User registration and authentication
- Profile management
- Role-based access control

## Course Service (Port 8082)
- Course catalog and management
- Curriculum organization
- Course metadata

## Content Service (Port 8083)
- Learning materials management
- Content delivery
- Media storage and retrieval

## Enrollment Service (Port 8084)
- Student enrollment
- Progress tracking
- Course completion

## Certificate Service (Port 8085)
- Certificate generation
- Certificate verification
- Achievement tracking

# Istio Service Mesh Features

## Traffic Management

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

## mTLS Security

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

## Canary Deployments

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

## Ingress Gateway

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

# Usage Examples

## Basic Development Setup

```bash
# Install for development without Istio
helm install v-learning . --set global.branch=dev --namespace v-learning --create-namespace
```

## Testing with Canary Deployments

```bash
# Install for testing with canary deployment for user service
helm install v-learning . \
  --set global.branch=test \
  --set canary.enabled=true \
  --set canary.userService=true \
  --namespace v-learning \
  --create-namespace
```

## Production Deployment

```bash
# Install for production with strict mTLS
helm install v-learning . \
  --set global.branch=main \
  --set istio.mtls.mode=STRICT \
  --namespace v-learning \
  --create-namespace
```

## Updating Image Versions

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

# Troubleshooting

## Common Issues

### Istio Features Not Working in Dev Branch

Istio features are intentionally disabled in the dev branch. To use Istio, change to the test or main branch:

```bash
helm upgrade v-learning . --set global.branch=test
```

### Canary Deployments Not Appearing

Ensure that:
1. You're using the test or main branch (`global.branch=test` or `global.branch=main`)
2. Canary is enabled globally (`canary.enabled=true`)
3. Canary is enabled for the specific service (`canary.userService=true`)

### Services Not Communicating

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

## Getting Help

For more information or assistance:
- File an issue on the GitHub repository
- Check the Istio documentation for advanced troubleshooting

---

## License

This Helm chart is licensed under the MIT License.
