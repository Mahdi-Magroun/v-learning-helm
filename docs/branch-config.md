## Branch-specific Configuration

The Helm chart automatically configures different features based on the branch:

- **Dev Branch**: Basic Kubernetes deployment without Istio
- **Test Branch**: Full Istio service mesh with optional canary deployments
- **Main Branch**: Full Istio service mesh with optional canary deployments

## Installation

```bash
# For dev branch (no Istio)
helm install v-learning ./v-learning-helm --set global.branch=dev

# For test branch (with Istio)
helm install v-learning ./v-learning-helm --set global.branch=test

# For main branch (with Istio)
helm install v-learning ./v-learning-helm --set global.branch=main
```

## Canary Deployments

Canary deployments are supported in test and main branches:

```bash
# Enable canary deployment for the user service
helm upgrade v-learning ./v-learning-helm \
  --set global.branch=test \
  --set canary.enabled=true \
  --set canary.userService=true
```

The canary deployment uses the previous image tag (`global.previousImageTag`) for the canary version and the current image tag (`global.imageTag`) for the stable version.
