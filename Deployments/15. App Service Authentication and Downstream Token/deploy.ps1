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
    [string]$ClientSecret,
    
    [Parameter(Mandatory = $false)]
    [string]$AppServicePlanSku = "B1",
    
    [Parameter(Mandatory = $false)]
    [bool]$DeploySampleApp = $true,
    
    [Parameter(Mandatory = $false)]
    [bool]$DeployAPI = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$APIServiceName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "East US"
)

Write-Host "Starting deployment of Azure App Service with Authentication..." -ForegroundColor Green

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed or not accessible. Please install Azure CLI first."
    exit 1
}

# Check if logged in to Azure
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Error "Not logged in to Azure. Please run 'az login' first."
    exit 1
}

# Validate storage account name (must be globally unique and follow naming rules)
if ($StorageAccountName.Length -lt 3 -or $StorageAccountName.Length -gt 24) {
    Write-Error "Storage account name must be between 3 and 24 characters."
    exit 1
}

if ($StorageAccountName -notmatch '^[a-z0-9]+$') {
    Write-Error "Storage account name can only contain lowercase letters and numbers."
    exit 1
}

# Validate Client ID format (should be a GUID)
if ($ClientId -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
    Write-Error "Client ID must be a valid GUID format."
    exit 1
}

# If deploying API and no client secret provided, prompt for it
if ($DeployAPI -and [string]::IsNullOrEmpty($ClientSecret)) {
    $ClientSecret = Read-Host "Enter the Azure AD Client Secret for API authentication" -AsSecureString
    $ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret))
}

# Create resource group if it doesn't exist
Write-Host "Checking/creating resource group: $ResourceGroupName" -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "Creating resource group: $ResourceGroupName in $Location" -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create resource group."
        exit 1
    }
    Write-Host "Resource group created successfully." -ForegroundColor Green
} else {
    Write-Host "Resource group already exists." -ForegroundColor Green
}

# Deploy Web App using Bicep template
Write-Host "Deploying main Web App Bicep template..." -ForegroundColor Yellow

$deploymentName = "auth-app-service-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    $deployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "azuredeploy.json" `
        --parameters appServiceName=$AppServiceName `
                     storageAccountName=$StorageAccountName `
                     appServicePlanSku=$AppServicePlanSku `
                     clientId=$ClientId `
                     deploySampleApp=$DeploySampleApp `
        --name $deploymentName `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Main deployment failed."
        exit 1
    }

    Write-Host "Main deployment completed successfully!" -ForegroundColor Green
    
    # Display outputs
    Write-Host "`nMain Deployment Outputs:" -ForegroundColor Cyan
    Write-Host "App Service Name: $($deployment.properties.outputs.appServiceName.value)" -ForegroundColor White
    Write-Host "App Service URL: $($deployment.properties.outputs.appServiceUrl.value)" -ForegroundColor White
    Write-Host "Auth Login URL: $($deployment.properties.outputs.authLoginUrl.value)" -ForegroundColor White
    Write-Host "Auth Logout URL: $($deployment.properties.outputs.authLogoutUrl.value)" -ForegroundColor White
    Write-Host "Managed Identity Principal ID: $($deployment.properties.outputs.managedIdentityPrincipalId.value)" -ForegroundColor Yellow
    
    # Deploy Web App code automatically if DeploySampleApp is true
    if ($DeploySampleApp) {
        Write-Host "`nDeploying Web App code..." -ForegroundColor Yellow
        
        $webAppZipPath = "webapp-deployment.zip"
        
        # Create Web App deployment package with API URL configuration
        if (Test-Path $webAppZipPath) {
            Remove-Item $webAppZipPath -Force
        }
        
        # Update API URL in web app if API is being deployed
        if ($DeployAPI) {
            $apiUrl = "https://$APIServiceName.azurewebsites.net/api/welcome"
            $indexContent = Get-Content "WebApp\index.html" -Raw
            $indexContent = $indexContent -replace "https://your-api-name.azurewebsites.net/api/welcome", $apiUrl
            $indexContent = $indexContent -replace "\[Your API URL\]/api/welcome", "$apiUrl"
            
            # Create temporary directory for modified files
            $tempDir = "WebApp-Temp"
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force
            }
            New-Item -ItemType Directory -Path $tempDir | Out-Null
            
            # Copy files and update index.html
            Copy-Item "WebApp\*" $tempDir -Exclude "index.html"
            $indexContent | Out-File "$tempDir\index.html" -Encoding UTF8
            
            Compress-Archive -Path "$tempDir\*" -DestinationPath $webAppZipPath -Force
            
            # Clean up temp directory
            Remove-Item $tempDir -Recurse -Force
        } else {
            Compress-Archive -Path "WebApp\*" -DestinationPath $webAppZipPath -Force
        }
        
        # Deploy Web App code
        az webapp deploy --resource-group $ResourceGroupName --name $($deployment.properties.outputs.appServiceName.value) --src-path $webAppZipPath --type zip
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Web App code deployed successfully!" -ForegroundColor Green
        } else {
            Write-Warning "Web App code deployment failed, but infrastructure is ready."
        }
        
        # Clean up
        if (Test-Path $webAppZipPath) {
            Remove-Item $webAppZipPath -Force
        }
    }
    
} catch {
    Write-Error "Main deployment failed: $($_.Exception.Message)"
    exit 1
}

# Deploy API if requested
if ($DeployAPI) {
    if ([string]::IsNullOrEmpty($APIServiceName)) {
        $APIServiceName = "$AppServiceName-api"
    }
    
    Write-Host "`nDeploying API App Service..." -ForegroundColor Yellow
    
    $apiDeploymentName = "api-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    try {
        $apiDeployment = az deployment group create `
            --resource-group $ResourceGroupName `
            --template-file "api-deploy.json" `
            --parameters apiServiceName=$APIServiceName `
                         clientId=$ClientId `
                         clientSecret=$ClientSecret `
                         appServicePlanSku=$AppServicePlanSku `
            --name $apiDeploymentName `
            --output json | ConvertFrom-Json

        if ($LASTEXITCODE -ne 0) {
            Write-Error "API deployment failed."
            exit 1
        }

        Write-Host "API deployment completed successfully!" -ForegroundColor Green
        
        # Display API outputs
        Write-Host "`nAPI Deployment Outputs:" -ForegroundColor Cyan
        Write-Host "API Service Name: $($apiDeployment.properties.outputs.apiServiceName.value)" -ForegroundColor White
        Write-Host "API Service URL: $($apiDeployment.properties.outputs.apiServiceUrl.value)" -ForegroundColor White
        Write-Host "API Auth Login URL: $($apiDeployment.properties.outputs.authLoginUrl.value)" -ForegroundColor White
        Write-Host "API Welcome Endpoint: $($apiDeployment.properties.outputs.apiWelcomeUrl.value)" -ForegroundColor White
        Write-Host "API Managed Identity Principal ID: $($apiDeployment.properties.outputs.managedIdentityPrincipalId.value)" -ForegroundColor Yellow
        
        # Deploy API code automatically
        Write-Host "`nDeploying API code..." -ForegroundColor Yellow
        
        $apiZipPath = "api-deployment.zip"
        
        # Create API deployment package
        if (Test-Path $apiZipPath) {
            Remove-Item $apiZipPath -Force
        }
        
        Compress-Archive -Path "API\*" -DestinationPath $apiZipPath -Force
        
        # Deploy API code
        az webapp deploy --resource-group $ResourceGroupName --name $($apiDeployment.properties.outputs.apiServiceName.value) --src-path $apiZipPath --type zip
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "API code deployed successfully!" -ForegroundColor Green
        } else {
            Write-Warning "API code deployment failed, but infrastructure is ready."
        }
        
        # Clean up
        if (Test-Path $apiZipPath) {
            Remove-Item $apiZipPath -Force
        }
        
    } catch {
        Write-Error "API deployment failed: $($_.Exception.Message)"
    }
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Ensure your Azure AD App Registration is configured correctly:" -ForegroundColor White
Write-Host "   Client ID: $ClientId" -ForegroundColor Yellow
Write-Host "2. Add the following Redirect URI to your App Registration:" -ForegroundColor White
Write-Host "   $($deployment.properties.outputs.appServiceUrl.value)/.auth/login/aad/callback" -ForegroundColor Gray
if ($DeployAPI) {
    Write-Host "   $($apiDeployment.properties.outputs.apiServiceUrl.value)/.auth/login/aad/callback" -ForegroundColor Gray
}
Write-Host "3. Visit the web app at: $($deployment.properties.outputs.appServiceUrl.value)" -ForegroundColor White
if ($DeployAPI) {
    Write-Host "4. Test the API at: $($apiDeployment.properties.outputs.apiServiceUrl.value)" -ForegroundColor White
}

Write-Host "`nImportant Security Notes:" -ForegroundColor Yellow
if (-not $DeployAPI) {
    Write-Host "- The client secret is currently set to a placeholder value" -ForegroundColor White
    Write-Host "- You must update the MICROSOFT_PROVIDER_AUTHENTICATION_SECRET app setting" -ForegroundColor White
}
Write-Host "- Use Azure Key Vault for production deployments" -ForegroundColor White

Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
Write-Host "For more information, see the README.md file." -ForegroundColor Cyan 