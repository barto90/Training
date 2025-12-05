# 🚀 Deployment Guide - PowerShell Services on AKS

This guide walks you through deploying the AKS cluster and PowerShell services step-by-step.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Azure subscription with sufficient permissions
- [ ] Azure CLI installed (`az --version`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] Docker installed (`docker --version`)
- [ ] PowerShell 7.x installed (`pwsh --version`)
- [ ] Resource names planned (must be globally unique)

## 🎯 Phase 1: Deploy Infrastructure

### Step 1: Login to Azure

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "Your Subscription Name"

# Verify current subscription
az account show
```

### Step 2: Create Resource Group

```bash
# Create resource group
az group create \
  --name myResourceGroup \
  --location eastus
```

### Step 3: Deploy AKS Cluster

**Option A: Using Azure CLI**

```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azuredeploy.json \
  --parameters parameters.json
```

**Option B: Using PowerShell**

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "myResourceGroup" `
  -TemplateFile "azuredeploy.json" `
  -TemplateParameterFile "parameters.json"
```

**Option C: Using Azure Portal**

1. Open `deploy-to-azure.html` in browser
2. Click "Deploy to Azure" button
3. Fill in parameters
4. Review and create

### Step 4: Wait for Deployment

Deployment takes approximately **10-15 minutes**. Monitor progress:

```bash
# Check deployment status
az deployment group show \
  --resource-group myResourceGroup \
  --name azuredeploy \
  --query "properties.provisioningState"
```

### Step 5: Capture Deployment Outputs

```bash
# Get all outputs
az deployment group show \
  --resource-group myResourceGroup \
  --name azuredeploy \
  --query "properties.outputs"

# Save key values
AKS_NAME=$(az deployment group show --resource-group myResourceGroup --name azuredeploy --query "properties.outputs.clusterName.value" -o tsv)
ACR_NAME=$(az deployment group show --resource-group myResourceGroup --name azuredeploy --query "properties.outputs.containerRegistryName.value" -o tsv)

echo "AKS Cluster: $AKS_NAME"
echo "ACR Name: $ACR_NAME"
```

## 🔗 Phase 2: Configure AKS and ACR Integration

### Step 6: Attach ACR to AKS

This allows AKS to pull images from ACR without credentials:

```bash
az aks update \
  --resource-group myResourceGroup \
  --name $AKS_NAME \
  --attach-acr $ACR_NAME
```

Verify attachment:

```bash
az aks show \
  --resource-group myResourceGroup \
  --name $AKS_NAME \
  --query "identityProfile"
```

### Step 7: Get AKS Credentials

Configure kubectl to connect to your cluster:

```bash
az aks get-credentials \
  --resource-group myResourceGroup \
  --name $AKS_NAME \
  --overwrite-existing
```

Verify connection:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
```

## 🐳 Phase 3: Build and Deploy PowerShell Service

### Step 8: Navigate to Service Directory

```bash
cd "PowerShellService"
```

### Step 9: Build Container Image

```bash
# Build image
docker build -t $ACR_NAME.azurecr.io/powershell-service:v1 .

# Verify image
docker images | grep powershell-service
```

### Step 10: Push to ACR

```bash
# Login to ACR
az acr login --name $ACR_NAME

# Push image
docker push $ACR_NAME.azurecr.io/powershell-service:v1

# Verify in ACR
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository powershell-service --output table
```

### Step 11: Update Deployment Manifest

Edit `deployment.yaml` and replace `<ACR_NAME>`:

```bash
# Using sed (Linux/macOS)
sed -i "s/<ACR_NAME>/$ACR_NAME/g" deployment.yaml

# Using PowerShell (Windows)
(Get-Content deployment.yaml) -replace '<ACR_NAME>', $ACR_NAME | Set-Content deployment.yaml
```

Or manually update line:

```yaml
image: myacrdev123.azurecr.io/powershell-service:v1
```

### Step 12: Deploy to Kubernetes

```bash
# Apply deployment
kubectl apply -f deployment.yaml

# Watch deployment progress
kubectl get pods -l app=powershell-service -w
```

Wait until pods show `Running` status (typically 1-2 minutes).

### Step 13: Get Service External IP

```bash
# Get service details
kubectl get service powershell-service

# Wait for EXTERNAL-IP (may take 2-5 minutes)
kubectl get service powershell-service -w
```

Save the external IP:

```bash
EXTERNAL_IP=$(kubectl get service powershell-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Service URL: http://$EXTERNAL_IP"
```

## 🧪 Phase 4: Test Your Service

### Step 14: Test Health Endpoint

```bash
curl http://$EXTERNAL_IP/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "service": "PowerShell-AKS-Service"
}
```

### Step 15: Test API Endpoints

```bash
# Get service info
curl http://$EXTERNAL_IP/api/info

# Get all routes
curl http://$EXTERNAL_IP/api/routes

# Test echo endpoint
curl -X POST http://$EXTERNAL_IP/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello from AKS"}'

# Test process endpoint
curl -X POST http://$EXTERNAL_IP/api/process \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello World from AKS"}'
```

### Step 16: Test with PowerShell

```powershell
# Set service URL
$serviceUrl = "http://$EXTERNAL_IP"

# Test health
Invoke-RestMethod -Uri "$serviceUrl/health"

# Test info
Invoke-RestMethod -Uri "$serviceUrl/api/info"

# Test echo
$body = @{
    message = "Hello from PowerShell"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json

Invoke-RestMethod -Uri "$serviceUrl/api/echo" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

## 📊 Phase 5: Monitoring and Validation

### Step 17: View Pod Logs

```bash
# Get pod names
kubectl get pods -l app=powershell-service

# View logs from first pod
POD_NAME=$(kubectl get pods -l app=powershell-service -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME

# Follow logs in real-time
kubectl logs -f $POD_NAME

# View logs from all replicas
kubectl logs -l app=powershell-service --all-containers=true --tail=50
```

### Step 18: Check Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -l app=powershell-service
```

### Step 19: View in Azure Portal

1. Navigate to **Azure Portal** → **Resource Groups** → **myResourceGroup**
2. Click on **AKS Cluster** → **Workloads** → **Deployments**
3. View **powershell-service** deployment
4. Click **Monitoring** → **Insights** for detailed metrics

### Step 20: Query Logs in Log Analytics

```bash
# Get workspace ID
WORKSPACE_ID=$(az deployment group show --resource-group myResourceGroup --name azuredeploy --query "properties.outputs.logAnalyticsWorkspaceId.value" -o tsv)

echo "Log Analytics Workspace: $WORKSPACE_ID"
```

In Azure Portal → Log Analytics → Query:

```kql
// View container logs
ContainerLog
| where TimeGenerated > ago(1h)
| where Name contains "powershell-service"
| project TimeGenerated, LogEntry, Name
| order by TimeGenerated desc

// View error logs
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error" or LogEntry contains "exception"
| project TimeGenerated, LogEntry, Name
```

## ⚙️ Optional Configurations

### Enable Auto-Scaling (HPA)

```bash
cd PowerShellService
kubectl apply -f hpa.yaml

# Check HPA status
kubectl get hpa
kubectl describe hpa powershell-service-hpa
```

### Apply ConfigMap

```bash
kubectl apply -f configmap.yaml

# Update deployment to use ConfigMap
kubectl edit deployment powershell-service
```

Add under `spec.containers`:

```yaml
envFrom:
- configMapRef:
    name: powershell-service-config
```

### Scale Manually

```bash
# Scale to 3 replicas
kubectl scale deployment powershell-service --replicas=3

# Verify
kubectl get pods -l app=powershell-service
```

## 🔄 Phase 6: Update and Rollout

### Update Service Code

```bash
# Make changes to server.ps1
# Rebuild image with new tag
docker build -t $ACR_NAME.azurecr.io/powershell-service:v2 .
docker push $ACR_NAME.azurecr.io/powershell-service:v2

# Update deployment
kubectl set image deployment/powershell-service \
  powershell-service=$ACR_NAME.azurecr.io/powershell-service:v2

# Watch rollout
kubectl rollout status deployment/powershell-service

# View rollout history
kubectl rollout history deployment/powershell-service
```

### Rollback if Needed

```bash
# Rollback to previous version
kubectl rollout undo deployment/powershell-service

# Rollback to specific revision
kubectl rollout undo deployment/powershell-service --to-revision=1
```

## 🧹 Cleanup

### Remove Service (Keep Cluster)

```bash
kubectl delete -f deployment.yaml
kubectl delete -f hpa.yaml
kubectl delete -f configmap.yaml
```

### Delete Entire Infrastructure

```bash
# Delete resource group (deletes everything)
az group delete --name myResourceGroup --yes --no-wait
```

Or delete resources individually:

```bash
# Delete AKS cluster
az aks delete --resource-group myResourceGroup --name $AKS_NAME --yes --no-wait

# Delete ACR
az acr delete --resource-group myResourceGroup --name $ACR_NAME --yes

# Delete Log Analytics workspace
az monitor log-analytics workspace delete --resource-group myResourceGroup --workspace-name logs-$AKS_NAME --yes
```

## 🚨 Troubleshooting

### Issue: Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node resources
kubectl describe nodes
```

### Issue: Cannot pull image from ACR

```bash
# Verify ACR attachment
az aks show --resource-group myResourceGroup --name $AKS_NAME --query "identityProfile"

# Re-attach ACR
az aks update --resource-group myResourceGroup --name $AKS_NAME --attach-acr $ACR_NAME

# Manually test ACR access
az acr login --name $ACR_NAME
docker pull $ACR_NAME.azurecr.io/powershell-service:v1
```

### Issue: LoadBalancer not getting external IP

```bash
# Check service status
kubectl describe service powershell-service

# Check for pending events
kubectl get events --field-selector involvedObject.name=powershell-service

# Verify Azure Load Balancer
az network lb list --resource-group MC_myResourceGroup_${AKS_NAME}_eastus --output table
```

### Issue: High memory/CPU usage

```bash
# Check resource usage
kubectl top pods

# Adjust resource limits in deployment.yaml
kubectl edit deployment powershell-service
```

## ✅ Deployment Checklist

After completing all steps, verify:

- [ ] AKS cluster is running
- [ ] ACR is accessible
- [ ] kubectl can connect to cluster
- [ ] Pods are in Running state
- [ ] Service has external IP
- [ ] Health endpoint returns 200 OK
- [ ] API endpoints respond correctly
- [ ] Logs are visible in kubectl and Azure Portal
- [ ] Container Insights shows metrics

## 📞 Next Steps

1. **Customize the Service**: Modify `server.ps1` to add your business logic
2. **Add Authentication**: Implement API key or OAuth authentication
3. **Integrate with Azure**: Use Managed Identity to access Azure resources
4. **Set up CI/CD**: Automate builds and deployments with GitHub Actions or Azure DevOps
5. **Enable Monitoring**: Set up alerts in Azure Monitor
6. **Implement Secrets**: Use Azure Key Vault for sensitive data
7. **Add Custom Domain**: Configure ingress with SSL/TLS

## 📚 Additional Resources

- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Pode Framework](https://badgerati.github.io/Pode/)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)

---

**Congratulations! You've successfully deployed PowerShell services on AKS!** 🎉




