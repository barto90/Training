# Function Code Deployment Guide

## Overview

The ARM template deployment creates the **infrastructure only**:
- ✅ Azure SQL Server
- ✅ SQL Database  
- ✅ Function App (empty)
- ✅ Storage Account
- ✅ Application Insights
- ✅ Managed Identity (enabled)

The **function code** (DatabaseQuery) must be deployed separately after infrastructure deployment.

## Why Separate Deployment?

ARM templates create Azure resources but don't deploy application code. This is by design:
- Infrastructure and code have different lifecycles
- Code changes frequently without infrastructure changes
- Allows for CI/CD pipeline integration
- Enables local development and testing

## Deployment Process

### Phase 1: Infrastructure Deployment ✅

1. Deploy ARM template via Azure Portal or CLI
2. Wait for deployment to complete (~3-5 minutes)
3. Note the Function App name and resource group

### Phase 2: Database Configuration ⚠️ CRITICAL

Before deploying function code, you MUST grant database access:

```sql
-- Connect to your SQL Database (not master)
-- Run as SQL admin

CREATE USER [your-function-app-name] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [your-function-app-name];
ALTER ROLE db_datawriter ADD MEMBER [your-function-app-name];

-- Verify
SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE name = 'your-function-app-name';
```

Create sample table:

```sql
CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

INSERT INTO Users (Name, Email) VALUES 
    ('John Doe', 'john.doe@example.com'),
    ('Jane Smith', 'jane.smith@example.com'),
    ('Bob Johnson', 'bob.johnson@example.com');
```

### Phase 3: Function Code Deployment

Choose one of the following methods:

## Method 1: Azure Portal (Easiest)

**Best for:** First-time users, quick testing

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to: Resource Groups → [Your RG] → [Your Function App]
3. Click **Functions** → **Create**
4. Select **HTTP trigger**
5. Configure:
   - **Function name**: `DatabaseQuery`
   - **Authorization level**: `Function`
6. Click **Create**
7. In the function, click **Code + Test**
8. Replace the entire content with code from `DatabaseQuery/run.ps1`
9. Click **Save**
10. Click **function.json** tab
11. Replace with content from `DatabaseQuery/function.json`
12. Click **Save**
13. Test by clicking **Test/Run**

**Pros:**
- No local tools required
- Visual interface
- Immediate testing

**Cons:**
- Manual process
- Not suitable for CI/CD

## Method 2: Azure Functions Core Tools (Recommended)

**Best for:** Developers, automation, CI/CD

### Prerequisites

```bash
# Install Node.js (if not installed)
# Download from: https://nodejs.org/

# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4

# Verify installation
func --version
```

### Deployment Steps

```bash
# 1. Navigate to the project directory
cd "Deployments/32. Securing Database Access for Azure Front End Services"

# 2. Verify files exist
ls host.json
ls DatabaseQuery/

# 3. Login to Azure
az login

# 4. Deploy to Azure Function App
func azure functionapp publish <your-function-app-name>

# Example:
func azure functionapp publish myfunction-app
```

**What happens:**
- Packages your function code
- Uploads to Azure
- Installs dependencies (SqlServer module)
- Restarts function app
- Function is ready to use

**Pros:**
- Automated deployment
- Works with CI/CD
- Proper dependency management

**Cons:**
- Requires local tools
- Command-line based

## Method 3: VS Code Extension (Developer Friendly)

**Best for:** Developers using VS Code

### Prerequisites

1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install [Azure Functions extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions)
3. Install [Azure Account extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account)

### Deployment Steps

1. Open VS Code
2. Open the folder: `Deployments/32. Securing Database Access for Azure Front End Services`
3. Sign in to Azure:
   - Click Azure icon in sidebar
   - Click "Sign in to Azure"
4. Deploy:
   - Right-click on your Function App in Azure panel
   - Select **Deploy to Function App**
   - Confirm deployment
5. Wait for deployment to complete

**Pros:**
- Visual interface
- Integrated with IDE
- Easy debugging

**Cons:**
- Requires VS Code and extensions

## Method 4: PowerShell Helper Script

Use the included helper script:

```powershell
.\Deploy-FunctionCode.ps1 `
    -FunctionAppName "myfunction-app" `
    -ResourceGroupName "myResourceGroup" `
    -SqlServerName "mysqlserver"
```

This script provides:
- Verification that Function App exists
- Managed identity principal ID
- Step-by-step deployment instructions
- SQL scripts for database access
- Testing commands

## Verification

After deployment, verify function is working:

### 1. Check Function Exists

Azure Portal → Function App → Functions → Should see "DatabaseQuery"

### 2. Test Directly in Azure Portal (Recommended)

The Function App is pre-configured with CORS to allow testing from the Azure Portal:

1. Navigate to: Azure Portal → Function App → Functions → DatabaseQuery
2. Click **Test/Run** tab (or **Code + Test** → **Test/Run**)
3. Configure test:
   - **HTTP Method**: GET
   - **Query parameters**: Add `action` with value `read`
   - Click **Run**
4. Check output - should see:
```json
{
  "success": true,
  "message": "Successfully retrieved X records",
  "data": [...]
}
```

This works because the ARM template includes CORS configuration:
```json
"cors": {
  "allowedOrigins": ["https://portal.azure.com"],
  "supportCredentials": false
}
```

### 3. Get Function URL and Key (For External Testing)

```powershell
# Get function key
az functionapp keys list --name <function-app-name> --resource-group <rg> --query functionKeys.default -o tsv

# Or from Azure Portal:
# Function App → Functions → DatabaseQuery → Function Keys → default
```

### 4. Test Function Externally

```powershell
$key = "your-function-key"
$url = "https://your-function-app.azurewebsites.net/api/DatabaseQuery"

# Test read
$response = Invoke-RestMethod -Uri "$url?code=$key&action=read" -Method Get
$response | ConvertTo-Json

# Expected output:
# {
#   "success": true,
#   "message": "Successfully retrieved 3 records",
#   "data": [ ... ]
# }
```

### 5. Check Logs

Azure Portal → Function App → Functions → DatabaseQuery → Monitor

Look for:
- ✅ "Database connection established"
- ✅ "Retrieved X records"
- ✅ "Function execution completed"

## Troubleshooting

### Function Not Appearing

**Issue:** Function doesn't show up after deployment

**Solutions:**
- Wait 1-2 minutes for deployment to complete
- Refresh Azure Portal
- Check deployment logs in Azure Portal
- Restart Function App

### "Login failed for user"

**Issue:** Cannot connect to database

**Solutions:**
- Verify managed identity user was created in SQL Database
- Check user name matches Function App name exactly
- Ensure you ran SQL script in database context, not master
- Verify firewall allows Azure services

### "Could not obtain access token"

**Issue:** Managed identity token error

**Solutions:**
- Verify system-assigned managed identity is enabled
- Restart Function App
- Check Function App is running (not stopped)

### "SqlServer module not found"

**Issue:** PowerShell module missing

**Solutions:**
- Function should auto-install on first run
- Check function logs for installation progress
- May take 1-2 minutes on first execution

### Deployment Times Out

**Issue:** Deployment hangs or times out

**Solutions:**
- Check internet connection
- Verify Function App is not stopped
- Try deploying from different network
- Check Azure service health

## CI/CD Integration

### Azure DevOps Pipeline

```yaml
- task: AzureFunctionApp@1
  inputs:
    azureSubscription: 'Your-Azure-Connection'
    appType: 'functionApp'
    appName: '$(functionAppName)'
    package: '$(System.DefaultWorkingDirectory)/32. Securing Database Access for Azure Front End Services'
    deploymentMethod: 'auto'
```

### GitHub Actions

```yaml
- name: Deploy Azure Functions
  uses: Azure/functions-action@v1
  with:
    app-name: ${{ secrets.AZURE_FUNCTIONAPP_NAME }}
    package: './Deployments/32. Securing Database Access for Azure Front End Services'
```

## Best Practices

1. **Version Control**: Keep function code in Git
2. **Environments**: Use separate Function Apps for dev/test/prod
3. **Secrets**: Store sensitive data in Azure Key Vault
4. **Monitoring**: Enable Application Insights
5. **Testing**: Test locally before deploying
6. **Documentation**: Keep deployment guide updated
7. **Automation**: Use CI/CD for consistent deployments
8. **CORS Configuration**: The default CORS allows Azure Portal. For production, add your application domains:
   ```json
   "cors": {
     "allowedOrigins": [
       "https://portal.azure.com",
       "https://yourdomain.com",
       "https://app.yourdomain.com"
     ]
   }
   ```

## Local Development

To develop and test locally:

```bash
# 1. Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4

# 2. Create local settings file
# Create local.settings.json:
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "powershell",
    "SqlServerName": "your-server.database.windows.net",
    "SqlDatabaseName": "AppDatabase"
  }
}

# 3. Run locally
func start

# 4. Test locally
curl http://localhost:7071/api/DatabaseQuery?action=read
```

## Summary

The deployment process is:
1. ✅ Deploy infrastructure (ARM template)
2. ⚠️ Configure database access (SQL script) - **REQUIRED**
3. 📦 Deploy function code (one of 4 methods)
4. ✔️ Test function (verify working)
5. 📊 Monitor (Application Insights)

**Remember:** The function code does NOT deploy automatically. You must manually deploy it using one of the methods above after infrastructure deployment completes.

For questions or issues, refer to the main README.md or troubleshooting section.

