# Deploy Monitoring Functions Script
# This script deploys the function code to Azure Function App

param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseZipDeploy = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild = $false
)

Write-Host "🚀 Azure Functions Deployment Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "📱 Function App: $FunctionAppName" -ForegroundColor Yellow
if ($ResourceGroupName) {
    Write-Host "📦 Resource Group: $ResourceGroupName" -ForegroundColor Yellow
}
if ($SubscriptionId) {
    Write-Host "🆔 Subscription: $SubscriptionId" -ForegroundColor Yellow
}
Write-Host ""

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json 2>$null | ConvertFrom-Json
    Write-Host "✅ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
    Write-Host "   Download: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in to Azure
try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
    Write-Host "👤 Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "🆔 Current subscription: $($account.name) ($($account.id))" -ForegroundColor Green
}
catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "🔄 Setting subscription to: $SubscriptionId" -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to set subscription" -ForegroundColor Red
        exit 1
    }
}

# Get function app details
Write-Host "🔍 Getting function app details..." -ForegroundColor Yellow
try {
    $functionApp = az functionapp show --name $FunctionAppName --output json 2>$null | ConvertFrom-Json
    
    if (-not $functionApp) {
        Write-Host "❌ Function app '$FunctionAppName' not found." -ForegroundColor Red
        Write-Host "   Make sure the function app exists and you have access to it." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Function app found:" -ForegroundColor Green
    Write-Host "   📍 Location: $($functionApp.location)" -ForegroundColor Gray
    Write-Host "   📦 Resource Group: $($functionApp.resourceGroup)" -ForegroundColor Gray
    Write-Host "   🏷️  Runtime: $($functionApp.siteConfig.powerShellVersion)" -ForegroundColor Gray
    Write-Host "   🔧 State: $($functionApp.state)" -ForegroundColor Gray
    
    $ResourceGroupName = $functionApp.resourceGroup
}
catch {
    Write-Host "❌ Error getting function app details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create deployment package
Write-Host ""
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow

$tempDir = Join-Path $env:TEMP "monitoring-functions-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$zipPath = "$tempDir.zip"

try {
    # Create temporary directory structure
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy host.json
    Copy-Item -Path "host.json" -Destination $tempDir -Force
    Write-Host "   ✅ Copied host.json" -ForegroundColor Green
    
    # Copy HealthCheckFunction
    $healthCheckDir = Join-Path $tempDir "HealthCheckFunction"
    New-Item -ItemType Directory -Path $healthCheckDir -Force | Out-Null
    Copy-Item -Path "HealthCheckFunction\*" -Destination $healthCheckDir -Force
    Write-Host "   ✅ Copied HealthCheckFunction" -ForegroundColor Green
    
    # Copy AlertProcessorFunction
    $alertProcessorDir = Join-Path $tempDir "AlertProcessorFunction"
    New-Item -ItemType Directory -Path $alertProcessorDir -Force | Out-Null
    Copy-Item -Path "AlertProcessorFunction\*" -Destination $alertProcessorDir -Force
    Write-Host "   ✅ Copied AlertProcessorFunction" -ForegroundColor Green
    
    # Create requirements.psd1 if it doesn't exist
    $requirementsPath = Join-Path $tempDir "requirements.psd1"
    if (-not (Test-Path $requirementsPath)) {
        @"
# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'.
    # To use the Az module in your function app, please uncomment the line below.
    # 'Az' = '9.*'
}
"@ | Out-File -FilePath $requirementsPath -Encoding UTF8
        Write-Host "   ✅ Created requirements.psd1" -ForegroundColor Green
    }
    
    # Create ZIP package
    Write-Host "🗜️  Creating ZIP package..." -ForegroundColor Yellow
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
    $zipSize = (Get-Item $zipPath).Length / 1KB
    Write-Host "   ✅ Package created: $zipPath ($([math]::Round($zipSize, 2)) KB)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error creating deployment package: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Deploy to Azure
Write-Host ""
Write-Host "🚀 Deploying to Azure Functions..." -ForegroundColor Yellow

try {
    if ($UseZipDeploy) {
        Write-Host "📤 Using ZIP deployment..." -ForegroundColor Yellow
        az functionapp deployment source config-zip --name $FunctionAppName --resource-group $ResourceGroupName --src $zipPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deployment successful!" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Deployment failed!" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "📤 Using source deployment..." -ForegroundColor Yellow
        # Alternative: Use Azure Functions Core Tools if available
        if (Get-Command func -ErrorAction SilentlyContinue) {
            func azure functionapp publish $FunctionAppName --powershell
        }
        else {
            Write-Host "❌ Azure Functions Core Tools not found. Using ZIP deployment instead..." -ForegroundColor Red
            az functionapp deployment source config-zip --name $FunctionAppName --resource-group $ResourceGroupName --src $zipPath
        }
    }
}
catch {
    Write-Host "❌ Deployment error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify deployment
Write-Host ""
Write-Host "🔍 Verifying deployment..." -ForegroundColor Yellow

try {
    $functions = az functionapp function list --name $FunctionAppName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
    
    $expectedFunctions = @("HealthCheckFunction", "AlertProcessorFunction")
    $deployedFunctions = $functions | Where-Object { $_.name -in $expectedFunctions }
    
    Write-Host "📊 Deployment verification:" -ForegroundColor Green
    foreach ($expectedFunction in $expectedFunctions) {
        $deployed = $deployedFunctions | Where-Object { $_.name -eq $expectedFunction }
        if ($deployed) {
            Write-Host "   ✅ $expectedFunction: Deployed" -ForegroundColor Green
        }
        else {
            Write-Host "   ❌ $expectedFunction: Not found" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "⚠️  Could not verify deployment: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Cleanup
Write-Host ""
Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
try {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ Temporary files cleaned up" -ForegroundColor Green
}
catch {
    Write-Host "   ⚠️  Could not clean up temporary files" -ForegroundColor Yellow
}

# Final instructions
Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the functions manually in Azure Portal" -ForegroundColor White
Write-Host "2. Run Test-MonitoringAlerts.ps1 to test the monitoring system" -ForegroundColor White
Write-Host "3. Configure Logic App connections for email notifications" -ForegroundColor White
Write-Host "4. Monitor function logs in Application Insights" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Useful Links:" -ForegroundColor Yellow
$functionAppUrl = "https://portal.azure.com/#@/resource/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/sites/{2}" -f $account.id, $ResourceGroupName, $FunctionAppName
$monitorUrl = "https://portal.azure.com/#@/resource/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/sites/{2}/monitor" -f $account.id, $ResourceGroupName, $FunctionAppName
Write-Host "• Function App: $functionAppUrl" -ForegroundColor White
Write-Host "• Monitor Logs: $monitorUrl" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Test Command:" -ForegroundColor Yellow
Write-Host ".\Test-MonitoringAlerts.ps1 -ServiceBusConnectionString `"<connection-string>`" -AppServiceName `"$FunctionAppName`"" -ForegroundColor White 