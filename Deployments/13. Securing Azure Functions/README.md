# 🚀 Secure Azure Function App Deployment

This ARM template deploys a secure Azure Function App with comprehensive security features and monitoring capabilities. The template follows Azure security best practices and includes all necessary resources for a production-ready serverless application.

## 📋 Resources Deployed

- **Storage Account** - Secure storage with HTTPS-only and TLS 1.2
- **Application Insights** - Comprehensive monitoring and telemetry
- **App Service Plan** - Consumption plan (serverless) by default
- **Function App** - With system-assigned managed identity and security hardening
- **Sample HTTP Trigger Function** - Optional C# function for testing (optional)

## 🎯 Deploy to Azure Button

This template includes a "Deploy to Azure" button implementation that allows users to deploy directly from a webpage. To implement this on your website:

1. Host the `azuredeploy.json` file in a publicly accessible location (like a GitHub repository)
2. Use the HTML file `deploy-to-azure.html` as a template
3. Update the links in the HTML to point to your hosted ARM template

Example URL format for the button:
```
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR_USERNAME%2FYOUR_REPO%2Fmain%2FDeployments%2F13.%20Securing%20Azure%20Functions%2Fazuredeploy.json
```

Replace `YOUR_USERNAME` and `YOUR_REPO` with your actual GitHub username and repository name.

## ⚙️ Parameters

| Parameter Name | Description | Default Value | Allowed Values |
|----------------|-------------|---------------|----------------|
| functionAppName | The name of the Function App | func-{uniqueString} | Any valid Azure resource name |
| storageAccountName | The name of the storage account | st{uniqueString} | 3-24 characters, lowercase letters and numbers |
| functionRuntime | Runtime stack for the Function App | dotnet | dotnet, node, python, java, powershell |
| functionRuntimeVersion | The version of the runtime | 6 | Depends on runtime choice |
| appServicePlanSku | The SKU of the App Service Plan | Y1 (Consumption) | Y1, B1, S1, P1V2, P1V3 |
| deploySampleFunction | Whether to deploy a sample HTTP trigger function | true | true, false |

**Note:** All resources will be deployed in the same location as the resource group.

## 🔒 Security Features

This deployment implements comprehensive security measures:

### Identity & Access Management
- ✅ **System-assigned managed identity** for secure resource access
- ✅ **Function-level authorization** support
- ✅ **Azure Key Vault integration** ready

### Network Security
- ✅ **HTTPS-only communication** enforced
- ✅ **TLS 1.2 minimum** version enforcement
- ✅ **FTPS disabled** for secure file transfers
- ✅ **CORS configured** for controlled access
- ✅ **Network access controls** configured

### Storage Security
- ✅ **Storage account with HTTPS-only** traffic
- ✅ **Default OAuth authentication** enabled
- ✅ **Blob public access disabled**
- ✅ **TLS 1.2 minimum** for storage

### Monitoring & Compliance
- ✅ **Application Insights** for security monitoring
- ✅ **Comprehensive logging** and telemetry
- ✅ **Real-time metrics** and alerting
- ✅ **Error tracking** and diagnostics

## 📊 Monitoring & Insights

The deployment includes Application Insights for comprehensive monitoring:

### Key Metrics
- Function execution count and duration
- Success/failure rates
- Performance metrics
- Custom telemetry support

### Monitoring Features
- Real-time metrics dashboard
- Performance monitoring
- Error tracking and diagnostics
- Live metrics stream
- Custom alerts and notifications

## 💰 Cost Optimization

The default configuration uses a Consumption plan which offers:

- **Pay-per-execution** pricing model
- **Automatic scaling** based on demand (0-200 instances)
- **No charges** when functions are not running
- **1 million free executions** per month
- **Cold start optimization** for better performance

### Cost Comparison

| Plan Type | Best For | Pricing Model | Scaling |
|-----------|----------|---------------|---------|
| Consumption (Y1) | Variable workloads | Pay-per-execution | 0-200 instances |
| Premium (P1V2) | Predictable workloads | Always-on pricing | Pre-warmed instances |
| Dedicated (B1/S1) | Existing App Service | Standard App Service | Manual/auto-scale |

## 🌐 Sample HTTP Trigger Function

The template includes an optional C# HTTP trigger function that:

- Accepts GET or POST requests
- Uses anonymous authentication (no key required)
- Returns a personalized greeting based on the "name" parameter
- Demonstrates basic Azure Functions functionality

### Function Code
```csharp
[FunctionName("HttpTrigger")]
public static async Task<IActionResult> Run(
    [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req,
    ILogger log)
{
    log.LogInformation("C# HTTP trigger function processed a request.");

    string name = req.Query["name"];
    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
    dynamic data = JsonConvert.DeserializeObject(requestBody);
    name = name ?? data?.name;

    string responseMessage = string.IsNullOrEmpty(name)
        ? "This HTTP triggered function executed successfully. Pass a name parameter."
        : $"Hello, {name}. This HTTP triggered function executed successfully.";

    return new OkObjectResult(responseMessage);
}
```

### Testing the Function
You can test the function by navigating to:
```
https://{functionAppName}.azurewebsites.net/api/HttpTrigger?name=YourName
```

Or by sending a POST request with JSON body:
```json
{
  "name": "YourName"
}
```

To disable the sample function deployment, set the `deploySampleFunction` parameter to `false`.

## 🛠️ Deployment Instructions

### Using Azure CLI

1. **Login to Azure:**
   ```bash
   az login
   ```

2. **Set your subscription:**
   ```bash
   az account set --subscription <subscription-id>
   ```

3. **Create a resource group (if needed):**
   ```bash
   az group create --name <resource-group-name> --location <location>
   ```

4. **Deploy the template:**
   ```bash
   az deployment group create \
     --resource-group <resource-group-name> \
     --template-file azuredeploy.json \
     --parameters parameters.json
   ```

### Using Azure PowerShell

1. **Login to Azure:**
   ```powershell
   Connect-AzAccount
   ```

2. **Set your subscription:**
   ```powershell
   Set-AzContext -Subscription "<subscription-id>"
   ```

3. **Create a resource group (if needed):**
   ```powershell
   New-AzResourceGroup -Name <resource-group-name> -Location <location>
   ```

4. **Deploy the template:**
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName <resource-group-name> `
     -TemplateFile azuredeploy.json `
     -TemplateParameterFile parameters.json
   ```

### Using Azure Portal

1. Click the "Deploy to Azure" button in the `deploy-to-azure.html` file
2. Fill in the required parameters
3. Review and create the deployment

## 🔧 Post-Deployment Configuration

After deployment, consider these additional security configurations:

### 1. Function Authorization
- Configure function keys for production workloads
- Implement Azure AD authentication for enterprise scenarios
- Set up API Management for advanced security features

### 2. Network Security
- Configure Virtual Network integration for private connectivity
- Set up Private Endpoints for storage account access
- Implement IP restrictions if needed

### 3. Monitoring & Alerting
- Set up custom alerts in Application Insights
- Configure log analytics workspace integration
- Implement security monitoring dashboards

### 4. Key Management
- Integrate with Azure Key Vault for secrets management
- Configure managed identity access to Key Vault
- Implement certificate-based authentication

## 🚨 Security Best Practices

### Development
- Use managed identities instead of connection strings
- Store secrets in Azure Key Vault
- Implement proper error handling and logging
- Use HTTPS for all external communications

### Production
- Enable Application Insights for monitoring
- Configure proper CORS settings
- Implement rate limiting and throttling
- Regular security assessments and updates

### Compliance
- Enable audit logging
- Implement data encryption at rest and in transit
- Configure backup and disaster recovery
- Document security procedures

## 📚 Additional Resources

- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure Functions Security](https://docs.microsoft.com/en-us/azure/azure-functions/security-concepts)
- [Application Insights for Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-monitoring)
- [Azure Functions Best Practices](https://docs.microsoft.com/en-us/azure/azure-functions/functions-best-practices)

## 🤝 Contributing

Feel free to submit issues and enhancement requests. Contributions are welcome!

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 