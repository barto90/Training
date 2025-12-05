# PowerShell Service for AKS

This directory contains a sample PowerShell web service designed to run on Azure Kubernetes Service (AKS). The service uses the Pode framework to create a REST API.

## 📁 Files

- **`server.ps1`** - Main PowerShell web service using Pode framework
- **`Dockerfile`** - Container image definition
- **`deployment.yaml`** - Kubernetes deployment and service manifest
- **`hpa.yaml`** - Horizontal Pod Autoscaler configuration
- **`configmap.yaml`** - Configuration map for environment variables
- **`build-and-push.ps1`** - Script to build and push image to ACR

## 🚀 Quick Start

### Prerequisites

- Docker installed
- Azure CLI installed (`az`)
- kubectl configured for your AKS cluster
- Azure Container Registry created

### Step 1: Build and Push Image

```powershell
# Using the provided script
.\build-and-push.ps1 -AcrName "myacrdev123" -ImageName "powershell-service" -Tag "v1"

# Or manually
docker build -t myacrdev123.azurecr.io/powershell-service:v1 .
az acr login --name myacrdev123
docker push myacrdev123.azurecr.io/powershell-service:v1
```

### Step 2: Update Deployment Manifest

Edit `deployment.yaml` and replace `<ACR_NAME>` with your actual ACR name:

```yaml
image: myacrdev123.azurecr.io/powershell-service:v1
```

### Step 3: Deploy to Kubernetes

```bash
# Deploy the application
kubectl apply -f deployment.yaml

# Optionally deploy ConfigMap
kubectl apply -f configmap.yaml

# Optionally enable auto-scaling
kubectl apply -f hpa.yaml

# Check deployment status
kubectl get pods -l app=powershell-service
kubectl get service powershell-service
```

### Step 4: Test the Service

```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get service powershell-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test health endpoint
curl http://$EXTERNAL_IP/health

# Test API
curl http://$EXTERNAL_IP/api/info
```

## 📡 API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Welcome message and endpoint list |
| GET | `/health` | Health check (for liveness probe) |
| GET | `/ready` | Readiness check (for readiness probe) |
| GET | `/api/info` | Service and pod information |
| GET | `/api/routes` | List all available routes |
| POST | `/api/echo` | Echo back the request body |
| POST | `/api/process` | Process and transform data |
| GET | `/api/azure/info` | Azure integration info |

## 🧪 Testing Examples

### Test Health Endpoint

```powershell
Invoke-RestMethod -Uri "http://$EXTERNAL_IP/health"
```

### Test Info Endpoint

```powershell
Invoke-RestMethod -Uri "http://$EXTERNAL_IP/api/info"
```

### Test Echo Endpoint

```powershell
$body = @{
    message = "Hello from PowerShell"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://$EXTERNAL_IP/api/echo" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

### Test Process Endpoint

```powershell
$body = @{
    text = "Hello World from AKS"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://$EXTERNAL_IP/api/process" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

## 🔍 Monitoring and Debugging

### View Logs

```bash
# Get pod name
kubectl get pods -l app=powershell-service

# View logs
kubectl logs <pod-name>

# Follow logs in real-time
kubectl logs -f <pod-name>

# View logs from all replicas
kubectl logs -l app=powershell-service --all-containers=true
```

### Execute Commands in Pod

```bash
# Open PowerShell in the pod
kubectl exec -it <pod-name> -- pwsh

# Run a single command
kubectl exec <pod-name> -- pwsh -Command "Get-Process"
```

### Check Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods
```

## ⚙️ Configuration

### Using ConfigMap

To use the ConfigMap in your deployment:

```yaml
spec:
  containers:
  - name: powershell-service
    envFrom:
    - configMapRef:
        name: powershell-service-config
```

### Using Secrets

For sensitive data, use Kubernetes secrets:

```bash
# Create secret
kubectl create secret generic powershell-secrets \
  --from-literal=api-key=your-secret-key

# Use in deployment
envFrom:
- secretRef:
    name: powershell-secrets
```

## 📊 Scaling

### Manual Scaling

```bash
# Scale to 3 replicas
kubectl scale deployment powershell-service --replicas=3

# Verify
kubectl get pods -l app=powershell-service
```

### Auto-Scaling

The `hpa.yaml` file provides automatic scaling based on CPU and memory:

- **Min replicas:** 2
- **Max replicas:** 5
- **CPU target:** 70%
- **Memory target:** 80%

```bash
# Apply HPA
kubectl apply -f hpa.yaml

# Check HPA status
kubectl get hpa
```

## 🔄 Updating the Service

### Rolling Update

```bash
# Build and push new version
docker build -t myacrdev123.azurecr.io/powershell-service:v2 .
docker push myacrdev123.azurecr.io/powershell-service:v2

# Update deployment
kubectl set image deployment/powershell-service \
  powershell-service=myacrdev123.azurecr.io/powershell-service:v2

# Watch rollout status
kubectl rollout status deployment/powershell-service

# Rollback if needed
kubectl rollout undo deployment/powershell-service
```

## 🧹 Cleanup

```bash
# Delete deployment and service
kubectl delete -f deployment.yaml

# Delete HPA
kubectl delete -f hpa.yaml

# Delete ConfigMap
kubectl delete -f configmap.yaml
```

## 🔒 Security Best Practices

1. **Run as non-root user** - Add to Dockerfile:
   ```dockerfile
   USER 1000:1000
   ```

2. **Use specific image tags** - Avoid using `latest`

3. **Set resource limits** - Already configured in deployment.yaml

4. **Use network policies** - Restrict pod-to-pod communication

5. **Store secrets securely** - Use Azure Key Vault or Kubernetes secrets

6. **Enable pod security policies** - Restrict privileged containers

## 📚 Additional Resources

- [Pode Framework Documentation](https://badgerati.github.io/Pode/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)


