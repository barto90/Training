# ☸️ PowerShell Services on AKS (Azure Kubernetes Service)

This solution deploys a developer-tier Azure Kubernetes Service (AKS) cluster optimized for hosting PowerShell-based containerized services. The deployment includes Azure Container Registry (ACR) for image storage and Log Analytics for monitoring.

## 🏗️ Architecture

```
🐳 PowerShell Container
    ↓
☸️ AKS Cluster (Developer Tier)
    ↓
📦 Azure Container Registry
    ↓
📊 Log Analytics Workspace
    ↓
✅ Scalable PowerShell Services
```

## 🚀 What Gets Deployed

- **AKS Cluster (Developer Tier)** - Cost-effective Kubernetes cluster for testing
  - 1-3 nodes with B-series or D-series VMs
  - System-assigned managed identity
  - Auto-upgrade enabled for patches
  - Defender for Containers enabled
- **Azure Container Registry (Basic)** - Private Docker registry for your images
  - Admin user disabled (uses managed identity)
  - Basic tier for cost optimization
- **Log Analytics Workspace** - Centralized logging and monitoring
  - 30-day retention
  - Integrated with AKS monitoring
  - Container Insights enabled
- **HTTP Application Routing** (Optional) - Simple ingress for testing
- **Network Configuration** - Kubenet networking for cost efficiency

## 💰 Developer Tier - Cost Optimization

This deployment is optimized for **development and testing**:

| Component | Configuration | Monthly Cost (Est.) |
|-----------|--------------|---------------------|
| AKS Control Plane | Free tier | **$0** |
| 1x Node (B2s) | 2 vCPU, 4GB RAM | ~$30 |
| Container Registry | Basic tier | ~$5 |
| Log Analytics | 30-day retention, 5GB | ~$10 |
| Bandwidth | Standard egress | ~$5 |
| **Total** | | **~$50/month** |

### Cost Saving Features:
- ✅ **Free AKS control plane** (no management fee)
- ✅ **B-series burstable VMs** (cost-effective for dev/test)
- ✅ **Kubenet networking** (no additional IP costs)
- ✅ **Single node pool** (can scale to 3 if needed)
- ✅ **Basic ACR tier** (sufficient for development)
- ✅ **30GB OS disk** (smaller than default 128GB)

## 🔑 Key Features

- ✅ **Developer Tier** - Optimized for cost-effective testing
- ✅ **Managed Identity** - Secure authentication without credentials
- ✅ **Container Registry Integration** - Private image storage
- ✅ **Monitoring** - Container Insights and Log Analytics
- ✅ **Auto-Scaling** - Optional horizontal pod and node autoscaling
- ✅ **HTTP Routing** - Simple ingress for quick testing
- ✅ **Security** - Defender for Containers enabled
- ✅ **Auto-Upgrade** - Automatic patch management

## 📋 Prerequisites

- Azure subscription
- Azure CLI installed (`az` command)
- kubectl installed
- Docker installed (for building containers)
- PowerShell 7.x (for local development)

## 🛠️ Deployment

### Option 1: Deploy via Azure Portal

Open `deploy-to-azure.html` in your browser or use the direct deployment link.

### Option 2: Deploy via Azure CLI

```bash
az group create --name myResourceGroup --location eastus

az deployment group create \
  --resource-group myResourceGroup \
  --template-file azuredeploy.json \
  --parameters clusterName=myaks-dev \
               dnsPrefix=myaks-dev \
               containerRegistryName=myacrdev123 \
               nodeCount=1 \
               nodeVMSize=Standard_B2s
```

### Option 3: Deploy via Azure PowerShell

```powershell
New-AzResourceGroup -Name "myResourceGroup" -Location "eastus"

New-AzResourceGroupDeployment `
  -ResourceGroupName "myResourceGroup" `
  -TemplateFile "azuredeploy.json" `
  -clusterName "myaks-dev" `
  -dnsPrefix "myaks-dev" `
  -containerRegistryName "myacrdev123" `
  -nodeCount 1 `
  -nodeVMSize "Standard_B2s"
```

## ⚙️ Post-Deployment Setup (REQUIRED)

### Step 1: Attach ACR to AKS

Grant the AKS cluster permission to pull images from ACR:

```bash
# Get resource group and cluster name
RESOURCE_GROUP="myResourceGroup"
AKS_NAME="myaks-dev"
ACR_NAME="myacrdev123"

# Attach ACR to AKS (enables managed identity pull)
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --attach-acr $ACR_NAME
```

Or use PowerShell:

```powershell
$resourceGroup = "myResourceGroup"
$aksName = "myaks-dev"
$acrName = "myacrdev123"

az aks update `
  --resource-group $resourceGroup `
  --name $aksName `
  --attach-acr $acrName
```

### Step 2: Get AKS Credentials

Configure kubectl to connect to your cluster:

```bash
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --overwrite-existing
```

Verify connection:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### Step 3: Verify ACR Integration

```bash
# Test ACR connection
az acr login --name $ACR_NAME

# List repositories (should be empty initially)
az acr repository list --name $ACR_NAME
```

## 🐳 Building and Deploying PowerShell Containers

### Sample PowerShell Web Service

Create a simple PowerShell web service:

**1. Create `Dockerfile`:**

```dockerfile
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

WORKDIR /app

# Copy PowerShell scripts
COPY ./app /app

# Install any required modules
RUN pwsh -Command "Install-Module -Name Pode -Force -Scope AllUsers"

# Expose port
EXPOSE 8080

# Run the PowerShell service
CMD ["pwsh", "-File", "/app/server.ps1"]
```

**2. Create `app/server.ps1`:**

```powershell
# Simple PowerShell web server using Pode
Import-Module Pode

Start-PodeServer {
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Http
    
    # Health check endpoint
    Add-PodeRoute -Method Get -Path '/health' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            status = "healthy"
            timestamp = (Get-Date).ToString("o")
            version = "1.0.0"
        }
    }
    
    # API endpoint
    Add-PodeRoute -Method Get -Path '/api/info' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            message = "Hello from PowerShell on AKS!"
            hostname = $env:HOSTNAME
            platform = $PSVersionTable.Platform
            psVersion = $PSVersionTable.PSVersion.ToString()
        }
    }
    
    # Process data endpoint
    Add-PodeRoute -Method Post -Path '/api/process' -ScriptBlock {
        $data = $WebEvent.Data
        
        Write-PodeJsonResponse -Value @{
            received = $data
            processed = "Data processed successfully"
            timestamp = (Get-Date).ToString("o")
        }
    }
}
```

### Build and Push Container

```bash
# Build the container image
docker build -t $ACR_NAME.azurecr.io/powershell-service:v1 .

# Login to ACR
az acr login --name $ACR_NAME

# Push to ACR
docker push $ACR_NAME.azurecr.io/powershell-service:v1

# Verify image
az acr repository show --name $ACR_NAME --repository powershell-service
```

### Deploy to AKS

**3. Create `deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: powershell-service
  labels:
    app: powershell-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: powershell-service
  template:
    metadata:
      labels:
        app: powershell-service
    spec:
      containers:
      - name: powershell-service
        image: <ACR_NAME>.azurecr.io/powershell-service:v1
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: powershell-service
spec:
  type: LoadBalancer
  selector:
    app: powershell-service
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

**Deploy to Kubernetes:**

```bash
# Replace ACR name in yaml
sed -i "s/<ACR_NAME>/$ACR_NAME/g" deployment.yaml

# Apply deployment
kubectl apply -f deployment.yaml

# Watch deployment progress
kubectl get pods -w

# Get service external IP
kubectl get service powershell-service

# Test the service
EXTERNAL_IP=$(kubectl get service powershell-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP/health
curl http://$EXTERNAL_IP/api/info
```

## 🧪 Testing Your PowerShell Service

### Test Health Endpoint

```powershell
$serviceIP = kubectl get service powershell-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Invoke-RestMethod -Uri "http://$serviceIP/health"
```

### Test API Endpoint

```powershell
Invoke-RestMethod -Uri "http://$serviceIP/api/info"
```

### Test POST Endpoint

```powershell
$body = @{
    name = "Test Data"
    value = 123
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://$serviceIP/api/process" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

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

## 📊 Monitoring and Management

### Container Insights

View metrics in Azure Portal:
1. Navigate to: **AKS Cluster** → **Monitoring** → **Insights**
2. View:
   - Node CPU/Memory usage
   - Pod performance
   - Container logs
   - Live metrics

### Log Analytics Queries

Common queries for troubleshooting:

```kql
// All container logs
ContainerLog
| where TimeGenerated > ago(1h)
| project TimeGenerated, LogEntry, Name, PodName
| order by TimeGenerated desc

// Error logs only
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error" or LogEntry contains "exception"
| project TimeGenerated, LogEntry, Name
| order by TimeGenerated desc

// Pod restart events
KubePodInventory
| where TimeGenerated > ago(24h)
| where PodStatus == "Failed" or PodStatus == "CrashLoopBackOff"
| project TimeGenerated, Name, Namespace, PodStatus, RestartCount
```

### Kubectl Commands

```bash
# Get cluster info
kubectl cluster-info

# View all resources
kubectl get all --all-namespaces

# Describe pod (for troubleshooting)
kubectl describe pod <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- pwsh

# Port forward for local testing
kubectl port-forward service/powershell-service 8080:80

# Scale deployment
kubectl scale deployment powershell-service --replicas=3

# View resource usage
kubectl top nodes
kubectl top pods
```

## 🔄 Scaling Your Service

### Manual Scaling

```bash
# Scale to 3 replicas
kubectl scale deployment powershell-service --replicas=3

# Verify scaling
kubectl get pods -l app=powershell-service
```

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: powershell-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: powershell-service
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

Apply HPA:

```bash
kubectl apply -f hpa.yaml
kubectl get hpa
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy to AKS

on:
  push:
    branches: [ main ]

env:
  ACR_NAME: myacrdev123
  AKS_CLUSTER: myaks-dev
  AKS_RESOURCE_GROUP: myResourceGroup
  IMAGE_NAME: powershell-service

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Build and push image
      run: |
        az acr login --name ${{ env.ACR_NAME }}
        docker build -t ${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }} .
        docker push ${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }}
    
    - name: Set AKS context
      uses: azure/aks-set-context@v3
      with:
        resource-group: ${{ env.AKS_RESOURCE_GROUP }}
        cluster-name: ${{ env.AKS_CLUSTER }}
    
    - name: Deploy to AKS
      run: |
        kubectl set image deployment/powershell-service \
          powershell-service=${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }}
        kubectl rollout status deployment/powershell-service
```

## 🚨 Troubleshooting

### Issue: Pods not starting

**Check pod status:**
```bash
kubectl get pods
kubectl describe pod <pod-name>
```

**Common causes:**
- Image pull errors → Check ACR attachment
- Resource constraints → Check node capacity
- Configuration errors → Check pod logs

### Issue: Cannot pull image from ACR

**Solution:**
```bash
# Verify ACR attachment
az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "identityProfile"

# Re-attach ACR
az aks update --resource-group $RESOURCE_GROUP --name $AKS_NAME --attach-acr $ACR_NAME
```

### Issue: Service not accessible

**Check service status:**
```bash
kubectl get service powershell-service
kubectl describe service powershell-service

# Check if LoadBalancer has external IP
kubectl get svc powershell-service -o wide
```

**Solution:**
- Wait for LoadBalancer provisioning (can take 2-5 minutes)
- Check network security groups
- Verify pod is running and healthy

### Issue: High memory/CPU usage

**Check resource usage:**
```bash
kubectl top nodes
kubectl top pods

# View detailed resource metrics
kubectl describe node <node-name>
```

**Solutions:**
- Adjust resource requests/limits in deployment
- Scale horizontally (add more replicas)
- Optimize PowerShell code
- Consider upgrading VM size

## 🔒 Security Best Practices

### Production Recommendations

1. **Use Private Cluster**
   - Enable private cluster endpoint
   - Use Azure Private Link

2. **Network Policies**
   - Implement network policies to restrict pod communication
   - Use Azure CNI for advanced networking

3. **RBAC and Azure AD Integration**
```bash
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --enable-aad \
  --aad-admin-group-object-ids <AAD_GROUP_ID>
```

4. **Pod Security Standards**
```yaml
apiVersion: policy/v1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  volumes:
  - 'configMap'
  - 'secret'
  - 'persistentVolumeClaim'
```

5. **Secrets Management**
   - Use Azure Key Vault for sensitive data
   - Enable Key Vault CSI driver

6. **Image Scanning**
```bash
# Enable Defender for Containers
az security pricing create \
  --name Containers \
  --tier Standard
```

## 📚 Sample PowerShell Services

### Example 1: REST API for Azure Management

```powershell
# Azure management API
Add-PodeRoute -Method Get -Path '/api/azure/resources' -ScriptBlock {
    # Use managed identity
    Connect-AzAccount -Identity
    
    $resources = Get-AzResource | Select-Object -First 10
    
    Write-PodeJsonResponse -Value @{
        count = $resources.Count
        resources = $resources
    }
}
```

### Example 2: Data Processing Service

```powershell
# Data transformation endpoint
Add-PodeRoute -Method Post -Path '/api/transform' -ScriptBlock {
    $data = $WebEvent.Data
    
    # Process data
    $result = $data | ForEach-Object {
        [PSCustomObject]@{
            Original = $_
            Processed = $_.ToUpper()
            Timestamp = Get-Date
        }
    }
    
    Write-PodeJsonResponse -Value $result
}
```

### Example 3: Scheduled Job Service

```powershell
# Background job that runs every 5 minutes
Add-PodeSchedule -Name 'DataSync' -Cron '*/5 * * * *' -ScriptBlock {
    Write-Host "Running scheduled data sync..."
    # Your sync logic here
}
```

## 💡 Advanced Features

### ConfigMaps and Secrets

```bash
# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=log_level=debug \
  --from-literal=api_url=https://api.example.com

# Create Secret
kubectl create secret generic app-secrets \
  --from-literal=api_key=your-secret-key

# Use in deployment
# See deployment-with-config.yaml example
```

### Persistent Storage

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: powershell-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: managed-premium
```

## 📄 Additional Resources

- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [PowerShell in Containers](https://docs.microsoft.com/powershell/scripting/install/powershell-in-docker)
- [Pode Web Framework](https://badgerati.github.io/Pode/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License.




