param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "BPAS",
    
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName = "bpas",
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientSecret,
    
    [string]$AppServicePlanSku = "B1",
    [string]$APIClientId = "",
    [string]$APIClientSecret = "",
    [bool]$DeployAPI = $true,
    [bool]$DeploySampleApp = $true
)

Write-Host "🚀 Starting deployment to Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "📱 Web App Name: $AppServiceName" -ForegroundColor Cyan
Write-Host "🔧 API Name: $AppServiceName-api" -ForegroundColor Cyan

# Step 1: Deploy ARM template
Write-Host "`n📦 Step 1: Deploying infrastructure..." -ForegroundColor Yellow

$deploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "azuredeploy.json" `
    --parameters `
        appServiceName=$AppServiceName `
        storageAccountName=$StorageAccountName `
        clientId=$ClientId `
        clientSecret=$ClientSecret `
        appServicePlanSku=$AppServicePlanSku `
        apiClientId=$APIClientId `
        apiClientSecret=$APIClientSecret `
        deployAPI=$DeployAPI `
        deploySampleApp=$DeploySampleApp `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ ARM template deployment failed!"
    exit 1
}

$deployment = $deploymentResult | ConvertFrom-Json
Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green

# Step 2: Deploy WebApp
if ($DeploySampleApp) {
    Write-Host "`n📱 Step 2: Deploying WebApp..." -ForegroundColor Yellow
    
    if (Test-Path "webapp.zip") {
        Write-Host "Deploying webapp.zip to $AppServiceName..."
        az webapp deploy --resource-group $ResourceGroupName --name $AppServiceName --src-path "webapp.zip" --type zip
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ WebApp deployed successfully!" -ForegroundColor Green
        } else {
            Write-Error "❌ WebApp deployment failed!"
        }
    } else {
        Write-Warning "⚠️ webapp.zip not found, skipping webapp deployment"
    }
}

# Step 3: Deploy API
if ($DeployAPI) {
    Write-Host "`n🔧 Step 3: Deploying API..." -ForegroundColor Yellow
    
    $apiName = "$AppServiceName-api"
    
    if (Test-Path "api.zip") {
        Write-Host "Deploying api.zip to $apiName..."
        az webapp deploy --resource-group $ResourceGroupName --name $apiName --src-path "api.zip" --type zip
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ API deployed successfully!" -ForegroundColor Green
        } else {
            Write-Error "❌ API deployment failed!"
        }
    } else {
        Write-Warning "⚠️ api.zip not found, skipping API deployment"
    }
}

# Step 4: Display results
Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

$webAppUrl = "https://$AppServiceName.azurewebsites.net"
$apiUrl = "https://$AppServiceName-api.azurewebsites.net"

Write-Host "🌐 Web App URL: $webAppUrl" -ForegroundColor Cyan
if ($DeployAPI) {
    Write-Host "🔧 API URL: $apiUrl" -ForegroundColor Cyan
    Write-Host "🔗 API Welcome: $apiUrl/api/welcome" -ForegroundColor Cyan
}
Write-Host "🔐 Auth Login: $webAppUrl/.auth/login/aad" -ForegroundColor Cyan
Write-Host "👤 Auth Info: $webAppUrl/.auth/me" -ForegroundColor Cyan

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure your Azure AD App Registration redirect URIs:" -ForegroundColor White
Write-Host "   - Add: $webAppUrl/.auth/login/aad/callback" -ForegroundColor Gray
if ($DeployAPI) {
    Write-Host "   - Add: $apiUrl/.auth/login/aad/callback" -ForegroundColor Gray
}
Write-Host "2. Test authentication by visiting the web app URL" -ForegroundColor White
Write-Host "3. Check logs in Azure Portal if needed" -ForegroundColor White 