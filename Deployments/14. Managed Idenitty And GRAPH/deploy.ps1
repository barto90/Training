# Azure Function with Managed Identity & Graph - Deployment Script
# This script deploys the Azure Function using Bicep template with external PowerShell files

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$AppServicePlanSku = "P1V2",
    
    [Parameter(Mandatory = $false)]
    [bool]$DeploySampleFunction = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "East US"
)

Write-Host "🚀 Starting deployment of Azure Function with Managed Identity & Graph..." -ForegroundColor Green

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✅ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Error "❌ Azure CLI is not installed or not accessible. Please install Azure CLI first."
    exit 1
}

# Check if logged in to Azure
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Error "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
}

# Validate storage account name (must be globally unique and follow naming rules)
if ($StorageAccountName.Length -lt 3 -or $StorageAccountName.Length -gt 24) {
    Write-Error "❌ Storage account name must be between 3 and 24 characters."
    exit 1
}

if ($StorageAccountName -notmatch '^[a-z0-9]+$') {
    Write-Error "❌ Storage account name can only contain lowercase letters and numbers."
    exit 1
}

# Create resource group if it doesn't exist
Write-Host "🏗️  Checking/creating resource group: $ResourceGroupName" -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "Creating resource group: $ResourceGroupName in $Location" -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Failed to create resource group."
        exit 1
    }
    Write-Host "✅ Resource group created successfully." -ForegroundColor Green
} else {
    Write-Host "✅ Resource group already exists." -ForegroundColor Green
}

# Deploy using Bicep template
Write-Host "📦 Deploying Bicep template..." -ForegroundColor Yellow

$deploymentName = "graph-function-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    $deployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "main.bicep" `
        --parameters functionAppName=$FunctionAppName `
                     storageAccountName=$StorageAccountName `
                     appServicePlanSku=$AppServicePlanSku `
                     deploySampleFunction=$DeploySampleFunction `
        --name $deploymentName `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Deployment failed."
        exit 1
    }

    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    
    # Display outputs
    Write-Host "`n📋 Deployment Outputs:" -ForegroundColor Cyan
    Write-Host "Function App Name: $($deployment.properties.outputs.functionAppName.value)" -ForegroundColor White
    Write-Host "Function App URL: $($deployment.properties.outputs.functionAppUrl.value)" -ForegroundColor White
    Write-Host "Graph API Trigger URL: $($deployment.properties.outputs.graphAPITriggerUrl.value)" -ForegroundColor White
    Write-Host "Managed Identity Principal ID: $($deployment.properties.outputs.managedIdentityPrincipalId.value)" -ForegroundColor Yellow
    
    # Save principal ID for permission setup
    $principalId = $deployment.properties.outputs.managedIdentityPrincipalId.value
    
    Write-Host "`n🔑 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Grant Microsoft Graph permissions to the managed identity:" -ForegroundColor White
    Write-Host "   Principal ID: $principalId" -ForegroundColor Yellow
    Write-Host "2. Use the following Azure CLI commands to grant permissions:" -ForegroundColor White
    Write-Host "   az ad app permission grant --id $principalId --api 00000003-0000-0000-c000-000000000000 --scope User.Read" -ForegroundColor Gray
    Write-Host "3. Test the function at: $($deployment.properties.outputs.graphAPITriggerUrl.value)" -ForegroundColor White
    
    # Optionally test the function
    $testFunction = Read-Host "`n🧪 Would you like to test the function now? (y/n)"
    if ($testFunction -eq "y" -or $testFunction -eq "Y") {
        Write-Host "Testing function..." -ForegroundColor Yellow
        try {
            $response = Invoke-RestMethod -Uri $deployment.properties.outputs.graphAPITriggerUrl.value -Method GET
            Write-Host "✅ Function test successful!" -ForegroundColor Green
            Write-Host "Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor White
        } catch {
            Write-Host "⚠️  Function test failed (this is expected if permissions aren't granted yet): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Error "❌ Deployment failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "📚 For more information, see the README.md file." -ForegroundColor Cyan 