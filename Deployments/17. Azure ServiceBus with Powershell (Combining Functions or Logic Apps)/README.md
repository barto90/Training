# 🚌 Azure ServiceBus with PowerShell Functions

This solution deploys a complete Azure ServiceBus messaging system with PowerShell Azure Functions for automatic message processing.

## 🏗️ Architecture

```
📤 Message Publisher (PowerShell Script)
    ↓
🚌 Azure ServiceBus Queue
    ↓
⚡ Azure Function (PowerShell)
    ↓
📋 Console Output (Application Insights)
```

## 🚀 What Gets Deployed

- **Azure ServiceBus Namespace** - Standard tier messaging service
- **ServiceBus Queue** - Message storage with configurable properties
- **Azure Function App** - PowerShell 7.4 runtime on consumption plan
- **Storage Account** - Backend storage for Functions runtime
- **Application Insights** - Monitoring and logging for function execution

## 📋 Prerequisites

- Azure subscription
- PowerShell 5.1 or later for the message publisher script
- Azure CLI or Azure PowerShell (optional, for deployment)

## 🛠️ Deployment

### Option 1: Deploy via Azure Portal
Click the deploy button in `deploy-to-azure.html` or use this direct link:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbarto90%2FTraining%2Fmain%2FDeployments%2F17.%20Azure%20ServiceBus%20with%20Powershell%20(Combining%20Functions%20or%20Logic%20Apps)%2Fazuredeploy.json)

### Option 2: Deploy via Azure CLI
```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azuredeploy.json \
  --parameters serviceBusNamespaceName=myservicebus-ns \
               functionAppName=myfunction-app \
               storageAccountName=mystorageaccount123
```

### Option 3: Deploy via Azure PowerShell
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "myResourceGroup" `
  -TemplateFile "azuredeploy.json" `
  -serviceBusNamespaceName "myservicebus-ns" `
  -functionAppName "myfunction-app" `
  -storageAccountName "mystorageaccount123"
```

## ⚙️ Post-Deployment Setup

### 1. Deploy the Function Code

After infrastructure deployment, you need to deploy the function code:

#### Method A: Via Azure Portal
1. Go to your Function App in Azure Portal
2. Navigate to **Functions** → **Create**
3. Choose **ServiceBus Queue trigger**
4. Configure:
   - **Function name**: `ServiceBusQueueProcessor`
   - **Connection**: `ServiceBusConnection`
   - **Queue name**: `messagequeue`
5. Replace the default code with the content from `ServiceBusQueueProcessor/run.ps1`
6. Update `function.json` with the content from `ServiceBusQueueProcessor/function.json`

#### Method B: Via Azure Functions Core Tools
```bash
# Install Azure Functions Core Tools if not already installed
npm install -g azure-functions-core-tools@4

# Navigate to your project directory and deploy
func azure functionapp publish <your-function-app-name>
```

### 2. Get Connection String

Retrieve your ServiceBus connection string:

```powershell
# Via Azure PowerShell
$resourceGroup = "your-resource-group"
$namespaceName = "your-servicebus-namespace"

$connectionString = (Get-AzServiceBusKey -ResourceGroup $resourceGroup -Namespace $namespaceName -Name RootManageSharedAccessKey).PrimaryConnectionString
Write-Host "Connection String: $connectionString"
```

Or from Azure Portal:
1. Go to **ServiceBus Namespace** → **Shared access policies**
2. Click **RootManageSharedAccessKey**
3. Copy the **Primary Connection String**

## 📤 Sending Messages

Use the included PowerShell script to send test messages:

### Basic Usage
```powershell
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent "Hello World!"
```

### Send Multiple Messages
```powershell
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent "Test Message" -MessageCount 5
```

### Send JSON Message
```powershell
$jsonMessage = @{ 
    name = "John Doe"
    age = 30
    city = "New York"
    timestamp = (Get-Date)
} | ConvertTo-Json

.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent $jsonMessage
```

### Send Message with Custom Properties
```powershell
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent "Priority Message" -UserProperties @{ 
    "priority" = "high"
    "source" = "production"
    "category" = "alert"
}
```

## 📊 Monitoring and Logging

### Function Logs
Monitor function execution in real-time:
1. **Azure Portal**: Function App → Functions → ServiceBusQueueProcessor → Monitor
2. **Application Insights**: Search for function execution logs
3. **Live Metrics**: Real-time monitoring of function performance

### ServiceBus Metrics
Monitor queue activity:
1. **Azure Portal**: ServiceBus Namespace → Queues → messagequeue → Metrics
2. Key metrics to watch:
   - **Active Messages**: Current queue depth
   - **Incoming Messages**: Message arrival rate
   - **Outgoing Messages**: Message processing rate
   - **Dead Letter Messages**: Failed message count

### Sample Log Output
When a message is processed, you'll see output like this in the function logs:
```
🚌 ServiceBus Message Received!
📅 Timestamp: 2024-01-15 10:30:45
🆔 Message ID: 12345678-1234-5678-9abc-123456789abc
📋 Message Content: Hello World!
📊 Delivery Count: 1
⏰ Enqueued Time: 2024-01-15 10:30:44
📝 Plain text message: Hello World!
⚙️ Processing message...
✅ Message processed successfully!
🏁 Message processing completed.
```

## 🔧 Configuration

### Function Configuration
The function is configured via `function.json`:
- **Trigger**: ServiceBus Queue
- **Connection**: Uses `ServiceBusConnection` app setting
- **Queue Name**: Uses `ServiceBusQueueName` app setting

### Queue Configuration
Default queue settings (configurable in ARM template):
- **Lock Duration**: 1 minute
- **Max Size**: 1 GB
- **Message TTL**: 14 days
- **Max Delivery Count**: 10
- **Batched Operations**: Enabled

## 🔒 Security Best Practices

1. **Use Managed Identity**: In production, configure the function to use managed identity instead of connection strings
2. **Least Privilege**: Use specific access policies instead of RootManageSharedAccessKey
3. **Network Security**: Configure virtual network integration for enhanced security
4. **Key Rotation**: Regularly rotate ServiceBus access keys

### Managed Identity Configuration
```json
{
  "type": "serviceBusTrigger",
  "connection": "ServiceBusConnection__fullyQualifiedNamespace",
  "queueName": "messagequeue"
}
```

## 🚨 Troubleshooting

### Common Issues

1. **Function Not Triggering**
   - Verify ServiceBus connection string is correct
   - Check if queue name matches the configuration
   - Ensure function app has started successfully

2. **Messages in Dead Letter Queue**
   - Check function logs for processing errors
   - Verify message format is compatible with function code
   - Review max delivery count settings

3. **High Latency**
   - Monitor Application Insights for performance metrics
   - Consider scaling up the function app plan
   - Check ServiceBus namespace throttling limits

### Debug Commands
```powershell
# Check queue status
Get-AzServiceBusQueue -ResourceGroup "your-rg" -NamespaceName "your-namespace" -QueueName "messagequeue"

# View function app logs
Get-AzWebAppSlotLog -ResourceGroupName "your-rg" -Name "your-function-app"

# Test connectivity
Test-NetConnection your-namespace.servicebus.windows.net -Port 443
```

## 💰 Cost Optimization

- **Consumption Plan**: Pay only for function executions
- **Standard ServiceBus**: Balanced features and cost
- **Standard_LRS Storage**: Cost-effective storage option
- **Application Insights**: Free tier includes 1GB monthly data

## 📚 Additional Resources

- [Azure ServiceBus Documentation](https://docs.microsoft.com/azure/service-bus-messaging/)
- [Azure Functions PowerShell Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-powershell)
- [ServiceBus Triggers for Azure Functions](https://docs.microsoft.com/azure/azure-functions/functions-bindings-service-bus)
- [Application Insights for Azure Functions](https://docs.microsoft.com/azure/azure-functions/functions-monitoring)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 