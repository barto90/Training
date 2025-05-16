# Azure Function App Deployment

This Bicep template deploys an Azure Function App with the following resources:

- Storage Account (for Function App storage)
- App Service Plan (Consumption by default)
- Application Insights (for monitoring)
- Function App with system-assigned managed identity
- Network configuration for outbound traffic

## Deploy to Azure Button

This template includes a "Deploy to Azure" button implementation that allows users to deploy directly from a webpage. To implement this on your website:

1. Host the `azuredeploy.json` file in a publicly accessible location (like a GitHub repository)
2. Use the HTML file `deploy-to-azure.html` as a template
3. Update the links in the HTML to point to your hosted ARM template

Example URL format for the button:
```
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR_USERNAME%2FYOUR_REPO%2Fmain%2FDeployments%2F12.%20Azure%20App%20Services%20outbound%20outbound%20traffic-ing%2Fazuredeploy.json
```

Replace `YOUR_USERNAME` and `YOUR_REPO` with your actual GitHub username and repository name.

## Parameters

| Parameter Name | Description | Default Value |
|----------------|-------------|---------------|
| functionAppName | The name of the Function App | func-[uniqueString] |
| storageAccountName | The name of the storage account | st[uniqueString] |
| location | The Azure region for deployment | Resource Group location |
| functionRuntime | Runtime stack (node, dotnet, python, java) | node |
| functionRuntimeVersion | The version of the runtime | ~18 |
| appServicePlanSku | The App Service Plan SKU | Y1 (Consumption) |

## Deployment Instructions

### Using Azure CLI

1. Login to Azure:
   ```bash
   az login
   ```

2. Set your subscription:
   ```bash
   az account set --subscription <subscription-id>
   ```

3. Create a resource group (if needed):
   ```bash
   az group create --name <resource-group-name> --location <location>
   ```

4. Deploy the Bicep template:
   ```bash
   az deployment group create \
     --resource-group <resource-group-name> \
     --template-file main.bicep \
     --parameters parameters.json
   ```

### Using Azure PowerShell

1. Login to Azure:
   ```powershell
   Connect-AzAccount
   ```

2. Set your subscription:
   ```powershell
   Set-AzContext -Subscription "<subscription-id>"
   ```

3. Create a resource group (if needed):
   ```powershell
   New-AzResourceGroup -Name <resource-group-name> -Location <location>
   ```

4. Deploy the Bicep template:
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName <resource-group-name> `
     -TemplateFile main.bicep `
     -TemplateParameterFile parameters.json
   ```

## Network Considerations for Outbound Traffic

This template includes configuration for outbound traffic from the Function App. By default, it:

- Enables HTTPS-only access
- Sets minimum TLS version to 1.2
- Configures network settings via the `virtualNetwork` resource

To integrate with a Virtual Network:
1. Create a Virtual Network and subnet
2. Update the `subnetResourceId` parameter in the `functionAppNetworkConfig` resource

## Security Best Practices

This deployment follows these security best practices:
- System-assigned managed identity for the Function App
- HTTPS only communication
- TLS 1.2 minimum
- FTPS disabled
- Storage account with HTTPS-only traffic
- Default OAuth authentication
- Blob public access disabled 