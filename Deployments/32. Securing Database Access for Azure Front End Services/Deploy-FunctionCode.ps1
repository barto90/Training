# Deploy-FunctionCode.ps1
# Script to help deploy the function code after infrastructure is created
param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

Write-Host "🚀 Function Code Deployment Helper" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Check if Azure PowerShell is available
try {
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    
    # Check if Function App exists
    $functionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction SilentlyContinue
    
    if (-not $functionApp) {
        Write-Error "❌ Function App '$FunctionAppName' not found in resource group '$ResourceGroupName'"
        return
    }
    
    Write-Host "✅ Found Function App: $FunctionAppName" -ForegroundColor Green
    Write-Host "🌐 Function App URL: https://$FunctionAppName.azurewebsites.net" -ForegroundColor Cyan
    
    # Get managed identity principal ID
    if ($functionApp.IdentityPrincipalId) {
        Write-Host "🔑 Managed Identity Principal ID: $($functionApp.IdentityPrincipalId)" -ForegroundColor Green
    } else {
        Write-Warning "⚠️ Managed Identity not found - this is required for database access!"
    }
    
} catch {
    Write-Warning "⚠️ Azure PowerShell not available or not logged in"
}

Write-Host ""
Write-Host "⚠️ CRITICAL: GRANT DATABASE ACCESS FIRST!" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
Write-Host "Before deploying function code, you MUST grant the managed identity database access!"
Write-Host ""
Write-Host "Connect to SQL Server: $SqlServerName.database.windows.net"
Write-Host "Run this SQL script in the database (not master):"
Write-Host ""
Write-Host "-- Create user for managed identity" -ForegroundColor Yellow
Write-Host "CREATE USER [$FunctionAppName] FROM EXTERNAL PROVIDER;" -ForegroundColor Yellow
Write-Host "ALTER ROLE db_datareader ADD MEMBER [$FunctionAppName];" -ForegroundColor Yellow
Write-Host "ALTER ROLE db_datawriter ADD MEMBER [$FunctionAppName];" -ForegroundColor Yellow
Write-Host ""
Write-Host "-- Verify user was created" -ForegroundColor Yellow
Write-Host "SELECT name, type_desc, authentication_type_desc FROM sys.database_principals WHERE name = '$FunctionAppName';" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 NEXT STEPS TO DEPLOY FUNCTION CODE:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔧 METHOD 1: Azure Portal (Recommended for first-time)" -ForegroundColor Green
Write-Host "1. Go to: https://portal.azure.com"
Write-Host "2. Navigate to: Resource Groups → $ResourceGroupName → $FunctionAppName"
Write-Host "3. Click: Functions → Create"
Write-Host "4. Select: HTTP trigger"
Write-Host "5. Configure:"
Write-Host "   - Function name: DatabaseQuery"
Write-Host "   - Authorization level: Function"
Write-Host "6. Replace default code with content from: DatabaseQuery/run.ps1"
Write-Host "7. Update function.json with content from: DatabaseQuery/function.json"

Write-Host ""
Write-Host "🔧 METHOD 2: Azure Functions Core Tools" -ForegroundColor Green
Write-Host "1. Install Azure Functions Core Tools:"
Write-Host "   npm install -g azure-functions-core-tools@4"
Write-Host ""
Write-Host "2. Navigate to this directory:"
Write-Host "   cd 'Deployments/32. Securing Database Access for Azure Front End Services'"
Write-Host ""
Write-Host "3. Deploy to Azure:"
Write-Host "   func azure functionapp publish $FunctionAppName"
Write-Host ""
Write-Host "   Note: Make sure host.json and DatabaseQuery folder are in the same directory"

Write-Host ""
Write-Host "🔧 METHOD 3: VS Code Extension" -ForegroundColor Green
Write-Host "1. Install 'Azure Functions' extension in VS Code"
Write-Host "2. Open this folder in VS Code" 
Write-Host "3. Sign in to Azure"
Write-Host "4. Right-click on the Function App in Azure panel"
Write-Host "5. Select 'Deploy to Function App'"

Write-Host ""
Write-Host "📊 CREATE SAMPLE DATABASE TABLE:" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "Connect to your SQL Database and run:"
Write-Host ""
Write-Host "CREATE TABLE Users (" -ForegroundColor Yellow
Write-Host "    Id INT IDENTITY(1,1) PRIMARY KEY," -ForegroundColor Yellow
Write-Host "    Name NVARCHAR(100) NOT NULL," -ForegroundColor Yellow
Write-Host "    Email NVARCHAR(255) NOT NULL UNIQUE," -ForegroundColor Yellow
Write-Host "    CreatedDate DATETIME2 DEFAULT GETDATE()" -ForegroundColor Yellow
Write-Host ");" -ForegroundColor Yellow
Write-Host ""
Write-Host "INSERT INTO Users (Name, Email) VALUES" -ForegroundColor Yellow
Write-Host "    ('John Doe', 'john.doe@example.com')," -ForegroundColor Yellow
Write-Host "    ('Jane Smith', 'jane.smith@example.com')," -ForegroundColor Yellow
Write-Host "    ('Bob Johnson', 'bob.johnson@example.com');" -ForegroundColor Yellow

Write-Host ""
Write-Host "📤 TESTING YOUR FUNCTION:" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "After deploying the function code:"
Write-Host ""
Write-Host "1. Get the function key from Azure Portal"
Write-Host "2. Test with PowerShell:"
Write-Host ""
Write-Host "`$key = 'your-function-key'" -ForegroundColor Yellow
Write-Host "`$url = 'https://$FunctionAppName.azurewebsites.net/api/DatabaseQuery'" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Read data" -ForegroundColor Yellow
Write-Host "Invoke-RestMethod -Uri `"`$url?code=`$key&action=read`" -Method Get" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Write data" -ForegroundColor Yellow
Write-Host "`$body = @{ action='write'; name='Test User'; email='test@example.com' } | ConvertTo-Json" -ForegroundColor Yellow
Write-Host "Invoke-RestMethod -Uri `"`$url?code=`$key`" -Method Post -Body `$body -ContentType 'application/json'" -ForegroundColor Yellow

Write-Host ""
Write-Host "🎯 QUICK START PORTAL LINKS:" -ForegroundColor Cyan
if ($functionApp) {
    $functionsUrl = "https://portal.azure.com/#@/resource/subscriptions/$($functionApp.SubscriptionId)/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/functions"
    $sqlUrl = "https://portal.azure.com/#@/resource/subscriptions/$($functionApp.SubscriptionId)/resourceGroups/$ResourceGroupName/providers/Microsoft.Sql/servers/$SqlServerName/overview"
    
    Write-Host "Function App: " -NoNewline
    Write-Host $functionsUrl -ForegroundColor Blue
    Write-Host "SQL Server:   " -NoNewline
    Write-Host $sqlUrl -ForegroundColor Blue
}

Write-Host ""
Write-Host "🔒 SECURITY CHECKLIST:" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✓ Managed identity is enabled on Function App"
Write-Host "✓ Database user created for managed identity"
Write-Host "✓ db_datareader and db_datawriter roles granted"
Write-Host "✓ Sample Users table created"
Write-Host "✓ Function code deployed"
Write-Host "✓ Function tested and working"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏁 Ready to deploy your function code!" -ForegroundColor Cyan
Write-Host "💡 See README.md for detailed documentation" -ForegroundColor Cyan

