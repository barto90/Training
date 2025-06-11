# 🔐 Azure Function with Managed Identity & Microsoft Graph

This template deploys a secure Azure Function App with **PowerShell runtime**, **system-assigned managed identity**, and **Microsoft Graph integration** capabilities.

## 🚀 Quick Deploy

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbarto90%2FTraining%2Fmain%2FDeployments%2F14.%20Managed%20Idenitty%20And%20GRAPH%2Fazuredeploy.json)

## 📋 Overview

This deployment creates a comprehensive Azure Function environment optimized for Microsoft Graph API integration:

### Key Features

- **🔐 System-Assigned Managed Identity**: Eliminates the need for stored credentials
- **⚡ PowerShell 7.2 Runtime**: Full PowerShell scripting capabilities with Graph module support
- **📊 Microsoft Graph Ready**: Pre-configured for seamless Graph API integration
- **🏆 Premium Hosting**: P1V2 plan ensures consistent performance and no cold starts
- **🔒 Security Hardened**: HTTPS-only, TLS 1.2, and comprehensive security features
- **📈 Application Insights**: Built-in monitoring and telemetry
- **🌐 Sample Function**: Includes a working Graph API authentication example

## 🏗️ Architecture

The deployment creates the following Azure resources:

1. **Function App** with system-assigned managed identity
2. **App Service Plan** (Premium V2 for optimal performance)
3. **Storage Account** (secure configuration)
4. **Application Insights** (monitoring and logging)
5. **Sample PowerShell Function** (Graph API demonstration)

## 📦 What Gets Deployed

### Azure Resources

| Resource Type | Purpose | Configuration |
|---------------|---------|---------------|
| Function App | PowerShell runtime with managed identity | Premium V2, HTTPS-only, TLS 1.2 |
| Storage Account | Function app storage | Standard_LRS, HTTPS-only, secure defaults |
| App Service Plan | Hosting infrastructure | P1V2 Premium for consistent performance |
| Application Insights | Monitoring and telemetry | Web application type |
| Sample Function | Graph API demonstration | HTTP trigger with anonymous auth |

### Function Structure

The deployment includes a properly structured Azure Function:

```
GraphAPITrigger/
├── function.json    # Function configuration and bindings
└── run.ps1         # Clean PowerShell code without escape characters
```

### Security Features

- ✅ **No stored credentials** - Uses managed identity for authentication
- ✅ **HTTPS enforced** - All communication encrypted
- ✅ **TLS 1.2 minimum** - Modern encryption standards
- ✅ **FTPS disabled** - Secure file transfer only
- ✅ **Storage security** - Advanced threat protection and secure defaults
- ✅ **Identity-based access** - Azure AD integration
- ✅ **Audit logging** - Complete activity tracking

## 🔧 Deployment Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `functionAppName` | Name of the Function App | - | ✅ |
| `storageAccountName` | Storage account name (globally unique) | - | ✅ |
| `appServicePlanSku` | App Service Plan tier | `P1V2` | ❌ |
| `deploySampleFunction` | Deploy sample Graph function | `true` | ❌ |

### SKU Options

- **Y1**: Consumption plan (serverless)
- **B1**: Basic plan (shared infrastructure)
- **S1**: Standard plan (dedicated)
- **P1V2**: Premium V2 (recommended - no cold starts)
- **P1V3**: Premium V3 (enhanced performance)

## 🛠️ Deployment Methods

### Azure Portal

Click the **Deploy to Azure** button above and fill in the required parameters.

### Azure CLI

```bash
# Create resource group
az group create --name "rg-graph-functions" --location "East US"

# Deploy template
az deployment group create \
  --resource-group "rg-graph-functions" \
  --template-uri "https://raw.githubusercontent.com/barto90/Training/main/Deployments/14.%20Managed%20Idenitty%20And%20GRAPH/azuredeploy.json" \
  --parameters functionAppName="my-graph-function" \
               storageAccountName="mygraphfuncstorage" \
               appServicePlanSku="P1V2"
```

### PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "rg-graph-functions" -Location "East US"

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-graph-functions" `
  -TemplateUri "https://raw.githubusercontent.com/barto90/Training/main/Deployments/14.%20Managed%20Idenitty%20And%20GRAPH/azuredeploy.json" `
  -functionAppName "my-graph-function" `
  -storageAccountName "mygraphfuncstorage" `
  -appServicePlanSku "P1V2"
```

### Bicep

```bicep
// Use the main.bicep file in this directory
az deployment group create \
  --resource-group "rg-graph-functions" \
  --template-file "main.bicep" \
  --parameters @parameters.json
```

### PowerShell Deployment Script (Recommended)

Use the included PowerShell script for the easiest deployment:

```powershell
# Run the deployment script
.\deploy.ps1 -ResourceGroupName "rg-graph-functions" `
             -FunctionAppName "my-graph-function" `
             -StorageAccountName "mygraphfuncstorage" `
             -AppServicePlanSku "P1V2"
```

This script:
- ✅ Validates prerequisites (Azure CLI, login status)
- ✅ Creates resource group if needed
- ✅ Deploys using Bicep template with external PowerShell files
- ✅ Displays deployment outputs including Principal ID
- ✅ Provides next steps for permission setup
- ✅ Optionally tests the deployed function

## 🔑 Post-Deployment Setup

### 1. Grant Microsoft Graph Permissions

After deployment, you need to grant Graph API permissions to the managed identity:

#### Get the Principal ID

The deployment outputs include the managed identity's Principal ID. You can also get it using:

```bash
# Get the managed identity Principal ID
PRINCIPAL_ID=$(az functionapp show \
  --name "your-function-app-name" \
  --resource-group "your-resource-group" \
  --query "identity.principalId" \
  --output tsv)

echo "Principal ID: $PRINCIPAL_ID"
```

#### Grant Permissions via Azure CLI

```bash
# Example: Grant User.Read permission
az ad app permission grant \
  --id $PRINCIPAL_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --scope "User.Read"

# Example: Grant Directory.Read.All permission
az ad app permission grant \
  --id $PRINCIPAL_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --scope "Directory.Read.All"
```

#### Common Graph API Permissions

| Permission | Description | Use Case |
|------------|-------------|----------|
| `User.Read` | Read user profile | Basic user info |
| `User.ReadWrite.All` | Read/write all users | User management |
| `Group.Read.All` | Read all groups | Group information |
| `Mail.Read` | Read user mail | Email processing |
| `Calendars.Read` | Read user calendars | Calendar integration |
| `Files.Read.All` | Read all files | Document access |
| `Directory.Read.All` | Read directory data | Organizational data |
| `Team.ReadBasic.All` | Read Teams info | Teams integration |

### 2. Test the Sample Function

The deployment includes a sample function that demonstrates Graph API authentication:

```bash
# Test the sample function
curl "https://your-function-app.azurewebsites.net/api/GraphAPITrigger"
```

Expected response:
```json
{
  "status": "success",
  "message": "Managed Identity authentication successful",
  "tokenObtained": true
}
```

## 📊 Sample Function Code

The deployed function demonstrates how to:

1. **Obtain access tokens** using managed identity
2. **Authenticate with Microsoft Graph**
3. **Handle errors gracefully**
4. **Return structured responses**

### PowerShell Function Example

```powershell
# Get managed identity token for Microsoft Graph
$resourceURI = "https://graph.microsoft.com/"
$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"=$env:IDENTITY_HEADER} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

# Make Graph API call
$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type' = 'application/json'
}

# Example: Get current user information
$userInfo = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Headers $headers
```

## 🎯 Use Cases

This template is perfect for scenarios involving:

### Microsoft 365 Integration
- **📧 Email automation** - Send emails via Graph API
- **📅 Calendar management** - Create/manage calendar events
- **📁 File operations** - Access SharePoint and OneDrive files
- **👥 User management** - Provision and manage Azure AD users

### Teams Integration
- **💬 Teams messaging** - Send messages to Teams channels
- **🤖 Bot development** - Create Teams bots and applications
- **📊 Teams analytics** - Gather Teams usage data
- **🔔 Webhook processing** - Handle Teams webhooks

### Enterprise Workflows
- **🔄 User provisioning** - Automated user lifecycle management
- **📈 Reporting** - Generate Microsoft 365 usage reports
- **🔐 Security automation** - Automated security assessments
- **📋 Compliance** - Data governance and compliance workflows

## 🔍 Monitoring and Troubleshooting

### Application Insights

The function app includes Application Insights for comprehensive monitoring:

- **📊 Performance metrics** - Response times, throughput
- **🐛 Error tracking** - Exception details and stack traces
- **📝 Custom logging** - Function execution logs
- **🔍 Dependency tracking** - External API calls

### Common Issues

#### Authentication Failures

```powershell
# Check if managed identity is properly configured
Write-Host "Identity Endpoint: $env:IDENTITY_ENDPOINT"
Write-Host "Identity Header: $env:IDENTITY_HEADER"
```

#### Insufficient Permissions

```bash
# Verify Graph API permissions
az ad app permission list \
  --id $PRINCIPAL_ID \
  --output table
```

#### Function Errors

```bash
# Check function logs
az functionapp log tail \
  --name "your-function-app" \
  --resource-group "your-resource-group"
```

## 🔄 Advanced Configuration

### Add More Functions

```powershell
# Template for additional Graph API functions
param($Request, $TriggerMetadata)

# Get managed identity token
$resourceURI = "https://graph.microsoft.com/"
$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"=$env:IDENTITY_HEADER} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

# Your Graph API logic here
$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type' = 'application/json'
}

# Example: List users
$users = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users" -Headers $headers
```

### Environment-Specific Configuration

```json
{
  "development": {
    "appServicePlanSku": "B1",
    "deploySampleFunction": true
  },
  "production": {
    "appServicePlanSku": "P1V2",
    "deploySampleFunction": false
  }
}
```

## 📚 Additional Resources

### Documentation
- [Azure Functions PowerShell Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)
- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/)
- [Azure Managed Identity Documentation](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)

### Graph API Endpoints
- **Users**: `https://graph.microsoft.com/v1.0/users`
- **Groups**: `https://graph.microsoft.com/v1.0/groups`
- **Mail**: `https://graph.microsoft.com/v1.0/me/messages`
- **Calendar**: `https://graph.microsoft.com/v1.0/me/calendar`
- **Teams**: `https://graph.microsoft.com/v1.0/teams`
- **Files**: `https://graph.microsoft.com/v1.0/me/drive`

### PowerShell Modules
- **Microsoft.Graph**: Official PowerShell SDK for Graph API
- **Az.Accounts**: Azure PowerShell authentication
- **Az.Functions**: Azure Functions management

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

🎉 **Ready to build secure, scalable Microsoft Graph integrations with Azure Functions!** 