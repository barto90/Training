# 🔒 Securing Database Access for Azure Front End Services

This solution deploys a secure Azure SQL Database with PowerShell Azure Functions using Managed Identity for passwordless authentication. No connection strings or passwords are stored in the function code - all authentication is handled through Azure AD tokens.

## 🏗️ Architecture

```
⚡ Azure Function (PowerShell)
    ↓ (Request Azure AD Token)
🔑 Managed Identity (System Assigned)
    ↓ (Token-based Authentication)
🗄️ Azure SQL Database
    ↓ (Read & Write Operations)
✅ Secure Data Access
```

## 🚀 What Gets Deployed

- **Azure SQL Server** - Managed SQL Server with TLS 1.2 minimum
- **SQL Database** - Scalable database with automatic backups
- **Azure Function App** - PowerShell 7.4 runtime on consumption plan with system-assigned managed identity
- **Storage Account** - Backend storage for Functions runtime
- **Application Insights** - Monitoring and logging for function execution
- **Firewall Rule** - Allows Azure services to access SQL Server
- **CORS Configuration** - Pre-configured to allow testing from Azure Portal (https://portal.azure.com)

## 🔑 Key Security Features

- ✅ **Managed Identity** - No credentials stored in code or configuration
- ✅ **Azure AD Authentication** - Token-based database access
- ✅ **No Connection Strings** - Passwordless authentication
- ✅ **TLS 1.2+** - All connections encrypted
- ✅ **Granular Permissions** - db_datareader and db_datawriter roles
- ✅ **Audit Trail** - All access logged with identity information
- ✅ **HTTPS Only** - Function App enforces HTTPS
- ✅ **CORS Enabled** - Pre-configured for Azure Portal testing

## 📋 Prerequisites

- Azure subscription
- Azure CLI or Azure PowerShell (for deployment)
- SQL Server Management Studio, Azure Data Studio, or Azure Portal (for SQL configuration)
- PowerShell 5.1 or later

## 🛠️ Deployment

### Option 1: Deploy via Azure Portal
Click the deploy button in `deploy-to-azure.html` or use this direct link:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbarto90%2FTraining%2Fmain%2FDeployments%2F32.%20Securing%20Database%20Access%20for%20Azure%20Front%20End%20Services%2Fazuredeploy.json)

### Option 2: Deploy via Azure CLI
```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azuredeploy.json \
  --parameters sqlServerName=mysqlserver-prod \
               sqlAdministratorLogin=sqladmin \
               sqlAdministratorPassword='YourSecurePassword123!' \
               functionAppName=myfunction-app \
               storageAccountName=mystorageaccount123
```

### Option 3: Deploy via Azure PowerShell
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "myResourceGroup" `
  -TemplateFile "azuredeploy.json" `
  -sqlServerName "mysqlserver-prod" `
  -sqlAdministratorLogin "sqladmin" `
  -sqlAdministratorPassword (ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force) `
  -functionAppName "myfunction-app" `
  -storageAccountName "mystorageaccount123"
```

## ⚙️ Post-Deployment Setup (CRITICAL)

### Step 1: Grant Managed Identity Database Access

**This is a REQUIRED step.** The function cannot access the database until you grant the managed identity permission.

#### 1a. Get the Function App Name
```powershell
# The Function App name is what you specified during deployment
$functionAppName = "myfunction-app"
```

#### 1b. Connect to Azure SQL Database
Connect using SQL Server Management Studio, Azure Data Studio, or Azure Portal Query Editor as the SQL admin user.

#### 1c. Execute SQL Script
Run this SQL script in the database context (not master):

```sql
-- Create user for the managed identity
-- IMPORTANT: Use the Function App name, not the principal ID
CREATE USER [myfunction-app] FROM EXTERNAL PROVIDER;

-- Grant read permissions
ALTER ROLE db_datareader ADD MEMBER [myfunction-app];

-- Grant write permissions
ALTER ROLE db_datawriter ADD MEMBER [myfunction-app];

-- Optional: Grant execute permissions for stored procedures
-- ALTER ROLE db_executor ADD MEMBER [myfunction-app];

-- Verify the user was created
SELECT 
    name, 
    type_desc, 
    authentication_type_desc,
    create_date
FROM sys.database_principals 
WHERE name = 'myfunction-app';
```

**Important Notes:**
- Replace `myfunction-app` with your actual Function App name
- Execute this in the **database context**, not the master database
- The user name must match the Function App name exactly
- This must be done BEFORE the function can connect to the database

### Step 2: Create Sample Database Table

Create a sample table for testing:

```sql
-- Create Users table
CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NULL
);

-- Create index for better query performance
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_CreatedDate ON Users(CreatedDate);

-- Insert sample data
INSERT INTO Users (Name, Email) VALUES 
    ('John Doe', 'john.doe@example.com'),
    ('Jane Smith', 'jane.smith@example.com'),
    ('Bob Johnson', 'bob.johnson@example.com'),
    ('Alice Williams', 'alice.williams@example.com'),
    ('Charlie Brown', 'charlie.brown@example.com');

-- Verify data
SELECT * FROM Users ORDER BY CreatedDate DESC;
```

### Step 3: Deploy Function Code

After infrastructure deployment, deploy the function code:

#### Method A: Via Azure Portal
1. Go to your Function App in Azure Portal
2. Navigate to **Functions** → **Create**
3. Choose **HTTP trigger**
4. Configure:
   - **Function name**: `DatabaseQuery`
   - **Authorization level**: `Function`
5. Replace the default code with the content from `DatabaseQuery/run.ps1`
6. Update `function.json` with the content from `DatabaseQuery/function.json`

#### Method B: Via Azure Functions Core Tools
```bash
# Install Azure Functions Core Tools if not already installed
npm install -g azure-functions-core-tools@4

# Navigate to your project directory
cd "Deployments/32. Securing Database Access for Azure Front End Services"

# Deploy to Azure
func azure functionapp publish <your-function-app-name>
```

#### Method C: Via VS Code
1. Install Azure Functions extension
2. Open the project folder
3. Right-click on the Function App in Azure panel
4. Select "Deploy to Function App"

## ⚙️ Technical Details

### Lightweight SQL Connectivity

The function uses **System.Data.SqlClient** directly (built into .NET runtime) instead of the SqlServer PowerShell module. This approach:
- ✅ **No module installation** required (saves 45MB+ download)
- ✅ **Faster cold starts** (no module import overhead)
- ✅ **Works on Consumption plan** (no disk space issues)
- ✅ **More efficient** (direct .NET API usage)

### Managed Identity Token Flow

```powershell
# 1. Request Azure AD token
$resourceURI = "https://database.windows.net/"
$tokenResponse = Invoke-RestMethod -Uri $tokenAuthURI

# 2. Create SQL connection with token
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.AccessToken = $tokenResponse.access_token

# 3. Execute queries - no credentials needed!
```

## 🧪 Testing the Solution

### Test in Azure Portal (Easiest)

The Function App is pre-configured with CORS to allow testing directly from the Azure Portal:

1. Navigate to: Azure Portal → Function App → Functions → DatabaseQuery
2. Click **Test/Run** tab
3. Select HTTP method (GET or POST)
4. For GET request:
   - Add Query parameter: `action` = `read`
   - Click **Run**
5. For POST request:
   - Add Query parameter: `action` = `write`
   - Request body:
   ```json
   {
     "name": "Test User",
     "email": "test@example.com"
   }
   ```
   - Click **Run**
6. View results in the Output section

The CORS configuration (`https://portal.azure.com`) allows the portal to call your function for testing.

### Get the Function URL

```powershell
# Get the function URL and key
$functionAppName = "myfunction-app"
$resourceGroup = "myResourceGroup"

# Get the default host key
$key = (az functionapp keys list --name $functionAppName --resource-group $resourceGroup --query functionKeys.default -o tsv)

# Get the function URL
$functionUrl = "https://$functionAppName.azurewebsites.net/api/DatabaseQuery"

Write-Host "Function URL: $functionUrl"
Write-Host "Function Key: $key"
```

### Test Read Operation (GET)

```powershell
# Read all users (default action)
$response = Invoke-RestMethod -Uri "$functionUrl?code=$key" -Method Get
$response | ConvertTo-Json -Depth 10

# Or explicitly specify action
$response = Invoke-RestMethod -Uri "$functionUrl?code=$key&action=read" -Method Get
$response | ConvertTo-Json -Depth 10
```

### Test Write Operation (POST)

```powershell
# Insert a new user
$body = @{
    action = "write"
    name = "New User"
    email = "newuser@example.com"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$functionUrl?code=$key" -Method Post -Body $body -ContentType "application/json"
$response | ConvertTo-Json -Depth 10
```

### Test Update Operation (POST)

```powershell
# Update an existing user
$body = @{
    action = "update"
    id = 1
    name = "Updated Name"
    email = "updated@example.com"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$functionUrl?code=$key" -Method Post -Body $body -ContentType "application/json"
$response | ConvertTo-Json -Depth 10
```

### Test Count Operation (GET)

```powershell
# Get total count of users
$response = Invoke-RestMethod -Uri "$functionUrl?code=$key&action=count" -Method Get
$response | ConvertTo-Json -Depth 10
```

## 📊 Function API Reference

### Supported Actions

| Action | Method | Parameters | Description |
|--------|--------|------------|-------------|
| `read` | GET/POST | None | Retrieves top 10 users ordered by created date |
| `write` | POST | name, email | Inserts a new user record |
| `update` | POST | id, name, email | Updates an existing user (name and/or email) |
| `count` | GET/POST | None | Returns total count of users |

### Request Examples

**Read (Query String):**
```
GET /api/DatabaseQuery?code={key}&action=read
```

**Write (JSON Body):**
```json
POST /api/DatabaseQuery?code={key}
Content-Type: application/json

{
  "action": "write",
  "name": "John Doe",
  "email": "john.doe@example.com"
}
```

**Update (JSON Body):**
```json
POST /api/DatabaseQuery?code={key}
Content-Type: application/json

{
  "action": "update",
  "id": 1,
  "name": "Updated Name",
  "email": "updated.email@example.com"
}
```

### Response Format

**Success Response:**
```json
{
  "success": true,
  "message": "Successfully retrieved 5 records",
  "data": [
    {
      "Id": 1,
      "Name": "John Doe",
      "Email": "john.doe@example.com",
      "CreatedDate": "2024-01-15 10:30:45"
    }
  ],
  "timestamp": "2024-01-15 11:00:00"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error: Connection timeout",
  "data": null,
  "error": {
    "type": "System.Data.SqlClient.SqlException",
    "message": "Connection timeout",
    "stackTrace": "..."
  },
  "timestamp": "2024-01-15 11:00:00"
}
```

## 🔍 How Managed Identity Works

### Authentication Flow

1. **Function Starts**: Azure Function is activated
2. **Token Request**: Function requests an Azure AD access token for SQL Database resource
3. **Identity Validation**: Azure AD validates the managed identity
4. **Token Issued**: Azure AD issues a time-limited access token
5. **Database Connection**: Function connects to SQL using the token (no password)
6. **Permission Check**: SQL Server validates token and checks database permissions
7. **Query Execution**: Function executes queries with granted permissions

### Code Implementation

The function uses managed identity with these steps:

```powershell
# 1. Get access token from managed identity
$resourceURI = "https://database.windows.net/"
$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"=$env:IDENTITY_HEADER} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

# 2. Create connection without password
$connectionString = "Server=$sqlServerName; Database=$sqlDatabaseName; Encrypt=True;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.AccessToken = $accessToken  # Use token instead of password

# 3. Open connection and execute queries
$connection.Open()
# ... execute queries ...
$connection.Close()
```

## 📊 Monitoring and Logging

### Application Insights

View function execution logs:
1. Azure Portal → Function App → Functions → DatabaseQuery → Monitor
2. Click on any invocation to see detailed logs
3. View the "Logs" tab for real-time streaming

### SQL Database Metrics

Monitor database performance:
1. Azure Portal → SQL Database → Metrics
2. Key metrics to watch:
   - **DTU Percentage** - Resource utilization
   - **Database Size** - Storage usage
   - **Connections** - Active connections
   - **Deadlocks** - Lock conflicts

### Query Performance

Enable Query Performance Insights:
1. Azure Portal → SQL Database → Query Performance Insight
2. View top resource-consuming queries
3. Identify optimization opportunities

### Audit Logging

Enable SQL auditing to track all database access:

```sql
-- Enable auditing (run as server admin)
CREATE SERVER AUDIT [FunctionAppAudit]
TO EXTERNAL_MONITOR;

ALTER SERVER AUDIT [FunctionAppAudit]
WITH (STATE = ON);

CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec]
FOR SERVER AUDIT [FunctionAppAudit]
ADD (SELECT, INSERT, UPDATE, DELETE ON DATABASE::AppDatabase BY [myfunction-app])
WITH (STATE = ON);
```

## 🚨 Troubleshooting

### Issue: Function cannot connect to database

**Symptoms:** Error "Login failed for user"

**Solutions:**
1. Verify managed identity database user was created (Step 1c)
2. Ensure user name matches Function App name exactly
3. Check SQL Server firewall allows Azure services
4. Verify function app has system-assigned managed identity enabled

```powershell
# Check if managed identity is enabled
az functionapp identity show --name <function-app-name> --resource-group <resource-group>

# Enable if not present
az functionapp identity assign --name <function-app-name> --resource-group <resource-group>
```

### Issue: "Could not obtain access token"

**Symptoms:** Error obtaining token from managed identity

**Solutions:**
1. Verify system-assigned managed identity is enabled
2. Check Function App is running (not stopped)
3. Restart the Function App
4. Verify Azure environment variables are set

```powershell
# Restart Function App
az functionapp restart --name <function-app-name> --resource-group <resource-group>
```

### Issue: Permission denied on database operations

**Symptoms:** "The SELECT permission was denied" or "The INSERT permission was denied"

**Solutions:**
1. Verify db_datareader and db_datawriter roles were granted
2. Check in the correct database (not master)

```sql
-- Verify permissions
SELECT 
    dp.name as UserName,
    dp.type_desc as UserType,
    r.name as RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'myfunction-app';
```

### Issue: Table 'Users' not found

**Symptoms:** "Invalid object name 'Users'"

**Solutions:**
1. Create the Users table (see Step 2)
2. Verify you're connected to the correct database

### Issue: "Not enough space on the disk"

**Symptoms:** Error during module installation (if using old code)

**Solutions:**
- **This has been fixed** - The latest version uses System.Data.SqlClient directly
- No module installation required (saves 45MB+ and disk space)
- Update your function code to the latest run.ps1 from the repository
- The new version has faster cold starts and works perfectly on Consumption plan

### Debug SQL Connections

Test SQL connectivity:

```powershell
# Test from local machine (requires Azure CLI and SQL cmdlets)
$token = (az account get-access-token --resource https://database.windows.net --query accessToken -o tsv)

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=mysqlserver.database.windows.net; Database=AppDatabase; Encrypt=True;"
$connection.AccessToken = $token
$connection.Open()
Write-Host "Connection successful!"
$connection.Close()
```

## 🔒 Security Best Practices

### Production Recommendations

1. **Store SQL Admin Password in Key Vault**
```powershell
# Store password in Key Vault
az keyvault secret set --vault-name mykeyvault --name sql-admin-password --value 'YourPassword'

# Reference in ARM template
"sqlAdministratorPassword": {
  "reference": {
    "keyVault": {
      "id": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/mykeyvault"
    },
    "secretName": "sql-admin-password"
  }
}
```

2. **Use Virtual Network Integration**
```json
{
  "type": "Microsoft.Web/sites/config",
  "properties": {
    "vnetName": "myvnet",
    "subnetName": "function-subnet"
  }
}
```

3. **Enable Private Endpoints**
- Use Private Endpoint for SQL Server
- Disable public network access
- Access only through private network

4. **Implement IP Restrictions**
```powershell
# Restrict Function App to specific IPs
az functionapp config access-restriction add \
  --resource-group myResourceGroup \
  --name myfunction-app \
  --rule-name AllowCorporateNetwork \
  --action Allow \
  --ip-address 203.0.113.0/24 \
  --priority 100
```

5. **Enable Advanced Threat Protection**
```powershell
# Enable Azure Defender for SQL
az security atp storage update \
  --resource-group myResourceGroup \
  --storage-account mystorageaccount \
  --is-enabled true
```

6. **Rotate Keys Regularly**
- Enable automatic key rotation in Key Vault
- Rotate SQL admin password quarterly
- Monitor access with Azure AD sign-in logs

7. **Least Privilege Principle**
- Grant only necessary database permissions
- Use separate identities for different functions
- Regular review of permissions

## 💰 Cost Optimization

### Estimated Monthly Costs (Basic Tier)

| Resource | Configuration | Estimated Cost |
|----------|--------------|----------------|
| SQL Database | Basic (5 DTU) | ~$5 |
| Function App | Consumption (1M executions) | ~$0.20 |
| Storage Account | Standard LRS (10 GB) | ~$0.20 |
| Application Insights | Basic (1 GB) | Free |
| **Total** | | **~$5.40/month** |

### Cost Reduction Tips

1. **Use Consumption Plan** - Pay only for executions
2. **Auto-pause SQL Database** - For dev/test environments
3. **Serverless SQL Database** - Automatically pause when inactive
4. **Reserved Capacity** - Save up to 80% on SQL Database
5. **Optimize Query Performance** - Reduce execution time and DTU usage

### Switch to Serverless SQL Database

```powershell
# Update to serverless tier
az sql db update \
  --resource-group myResourceGroup \
  --server mysqlserver \
  --name AppDatabase \
  --edition GeneralPurpose \
  --family Gen5 \
  --capacity 1 \
  --compute-model Serverless \
  --auto-pause-delay 60
```

## 📚 Additional Resources

- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [Managed Identities for Azure Resources](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Azure Functions PowerShell Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-powershell)
- [Azure SQL Database Security](https://docs.microsoft.com/azure/azure-sql/database/security-overview)
- [Using Azure AD Authentication with Azure SQL](https://docs.microsoft.com/azure/azure-sql/database/authentication-aad-overview)

## 🎓 Learning Resources

- [Tutorial: Use managed identity with Azure SQL](https://docs.microsoft.com/azure/app-service/tutorial-connect-msi-sql-database)
- [Secure Azure SQL Database connection from Azure Functions](https://docs.microsoft.com/azure/azure-functions/functions-identity-based-connections-tutorial-2)
- [PowerShell SqlServer Module](https://docs.microsoft.com/powershell/module/sqlserver/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

