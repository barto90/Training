# Azure Function App Deployment

This Bicep template deploys an Azure Function App with the following resources:

- Storage Account (for Function App storage)
- App Service Plan (Consumption by default)
- Application Insights (for monitoring)
- Function App with system-assigned managed identity
- Sample HTTP trigger function (optional)

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
| functionAppName | The name of the Function App | *Empty (required)* |
| storageAccountName | The name of the storage account | *Empty (required)* |
| functionRuntime | Runtime stack (powershell, dotnet, node, python, java) | powershell |
| functionRuntimeVersion | The version of the runtime | ~7.2 |
| appServicePlanSku | The App Service Plan SKU | Y1 (Consumption) |
| deploySampleFunction | Whether to deploy a sample HTTP trigger function | true |

Note: All resources will be deployed in the same location as the resource group.

## Sample HTTP Trigger Function

The template includes an option to deploy a sample HTTP trigger function that:

- Accepts GET or POST requests
- Uses anonymous authentication (no key required)
- Returns a greeting message with an optional name parameter

You can test the function by navigating to:
```
https://{functionAppName}.azurewebsites.net/api/HttpTrigger?name=YourName
```

To disable the sample function deployment, set the `deploySampleFunction` parameter to `false`.

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

## Security Best Practices

This deployment follows these security best practices:
- System-assigned managed identity for the Function App
- HTTPS only communication
- TLS 1.2 minimum
- FTPS disabled
- Storage account with HTTPS-only traffic
- Default OAuth authentication
- Blob public access disabled 