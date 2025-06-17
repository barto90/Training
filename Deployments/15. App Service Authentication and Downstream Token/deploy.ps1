# Azure App Service with Authentication - Deployment Script
# This script deploys the Azure App Service using Bicep template with authentication enabled

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$ClientId,
    
    [Parameter(Mandatory = $false)]
    [string]$AppServicePlanSku = "B1",
    
    [Parameter(Mandatory = $false)]
    [bool]$DeploySampleApp = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "East US"
)

Write-Host "🚀 Starting deployment of Azure App Service with Authentication..." -ForegroundColor Green

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

# Validate Client ID format (should be a GUID)
if ($ClientId -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
    Write-Error "❌ Client ID must be a valid GUID format."
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

$deploymentName = "auth-app-service-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    $deployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "main.bicep" `
        --parameters appServiceName=$AppServiceName `
                     storageAccountName=$StorageAccountName `
                     appServicePlanSku=$AppServicePlanSku `
                     clientId=$ClientId `
                     deploySampleApp=$DeploySampleApp `
        --name $deploymentName `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Deployment failed."
        exit 1
    }

    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    
    # Display outputs
    Write-Host "`n📋 Deployment Outputs:" -ForegroundColor Cyan
    Write-Host "App Service Name: $($deployment.properties.outputs.appServiceName.value)" -ForegroundColor White
    Write-Host "App Service URL: $($deployment.properties.outputs.appServiceUrl.value)" -ForegroundColor White
    Write-Host "Auth Login URL: $($deployment.properties.outputs.authLoginUrl.value)" -ForegroundColor White
    Write-Host "Auth Logout URL: $($deployment.properties.outputs.authLogoutUrl.value)" -ForegroundColor White
    Write-Host "Managed Identity Principal ID: $($deployment.properties.outputs.managedIdentityPrincipalId.value)" -ForegroundColor Yellow
    
    # Save principal ID for potential future use
    $principalId = $deployment.properties.outputs.managedIdentityPrincipalId.value
    
    Write-Host "`n🔑 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Ensure your Azure AD App Registration is configured correctly:" -ForegroundColor White
    Write-Host "   Client ID: $ClientId" -ForegroundColor Yellow
    Write-Host "2. Add the following Redirect URI to your App Registration:" -ForegroundColor White
    Write-Host "   $($deployment.properties.outputs.appServiceUrl.value)/.auth/login/aad/callback" -ForegroundColor Gray
    Write-Host "3. Configure your client secret in the App Service settings" -ForegroundColor White
    Write-Host "4. Visit the app at: $($deployment.properties.outputs.appServiceUrl.value)" -ForegroundColor White
    
    # Optionally test the app
    $testApp = Read-Host "`n🧪 Would you like to open the app in your browser now? (y/n)"
    if ($testApp -eq "y" -or $testApp -eq "Y") {
        Write-Host "Opening app in browser..." -ForegroundColor Yellow
        Start-Process $deployment.properties.outputs.appServiceUrl.value
    }
    
    Write-Host "`n⚠️  Important Security Notes:" -ForegroundColor Yellow
    Write-Host "- The client secret is currently set to a placeholder value" -ForegroundColor White
    Write-Host "- You must update the MICROSOFT_PROVIDER_AUTHENTICATION_SECRET app setting" -ForegroundColor White
    Write-Host "- Use Azure Key Vault for production deployments" -ForegroundColor White
    
} catch {
    Write-Error "❌ Deployment failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "📚 For more information, see the README.md file." -ForegroundColor Cyan 