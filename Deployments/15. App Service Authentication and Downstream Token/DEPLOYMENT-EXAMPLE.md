# Deployment Example

## Quick Deploy with Zip Packages

You now have two deployment options:

### Option 1: PowerShell Script (Recommended)
```powershell
# Deploy everything at once (infrastructure + webapp + API)
.\deploy-with-zip.ps1 `
    -ResourceGroupName "[resource group name]" `
    -AppServiceName "[webapp]" `
    -StorageAccountName "[storage account name]" `
    -ClientId "your-client-id-here" `
    -ClientSecret "your-client-secret-here"
```

### Option 2: Manual Steps

#### Step 1: Deploy Infrastructure
```bash
az deployment group create \
    --resource-group [resource group name] \
    --template-file azuredeploy.json \
    --parameters \
        appServiceName=[webapp] \
        storageAccountName=[storage] \
        clientId=your-client-id-here \
        clientSecret=your-client-secret-here
```

#### Step 2: Deploy WebApp
```bash
az webapp deploy --resource-group [resource group name] --name [webapp] --src-path webapp.zip --type zip
```

#### Step 3: Deploy API
```bash
az webapp deploy --resource-group [resource group name] --name [webapp]-api --src-path api.zip --type zip
```

## What Gets Deployed

### Infrastructure (azuredeploy.json creates):
- ✅ App Service Plan
- ✅ Web App Service (`webapp`)
- ✅ API App Service (`[webapp]-api`)
- ✅ Application Insights (both apps)
- ✅ Storage Account
- ✅ Azure AD Authentication configuration
- ✅ All necessary app settings

### Code (zip packages deploy):
- ✅ **webapp.zip** → Production-ready HTML/JS frontend
- ✅ **api.zip** → Node.js API with authentication

## URLs After Deployment

- **Web App**: https://[webapp].azurewebsites.net
- **API**: https://[webapp]-api.azurewebsites.net
- **API Welcome**: https://[webapp]-api.azurewebsites.net/api/welcome
- **Auth Login**: https://[webapp].azurewebsites.net/.auth/login/aad
- **Auth Info**: https://[webapp].azurewebsites.net/.auth/me

## Required Azure AD Configuration

After deployment, add these redirect URIs to your Azure AD App Registration:
- `https://[webapp].azurewebsites.net/.auth/login/aad/callback`
- `https://[webapp]-api.azurewebsites.net/.auth/login/aad/callback`

## Files Included

- `azuredeploy.json` - ARM template for infrastructure
- `webapp.zip` - Frontend application package
- `api.zip` - Backend API package  
- `deploy-with-zip.ps1` - Automated deployment script

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │
│   (webapp       │────│   (api)    │
│   HTML/JS       │    │   Node.js       │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┘
                 │
         ┌─────────────────┐
         │  Azure AD       │
         │  Authentication │
         └─────────────────┘
```

Both applications are protected by Azure AD Easy Auth and can exchange tokens securely. 