# Build and Push PowerShell Service to Azure Container Registry
# This script builds the Docker image and pushes it to ACR

param(
    [Parameter(Mandatory=$true)]
    [string]$AcrName,
    
    [Parameter(Mandatory=$false)]
    [string]$ImageName = "powershell-service",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "v1"
)

Write-Host "🐳 Building and Pushing PowerShell Service to ACR" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    # Verify Azure CLI is installed
    Write-Host "`n✓ Checking Azure CLI..." -ForegroundColor Yellow
    az --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI is not installed. Please install it from https://aka.ms/azure-cli"
    }
    Write-Host "  Azure CLI is installed" -ForegroundColor Green
    
    # Verify Docker is installed
    Write-Host "`n✓ Checking Docker..." -ForegroundColor Yellow
    docker --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not installed. Please install Docker Desktop"
    }
    Write-Host "  Docker is installed" -ForegroundColor Green
    
    # Build full image name
    $fullImageName = "$AcrName.azurecr.io/$ImageName`:$Tag"
    
    # Build the Docker image
    Write-Host "`n🔨 Building Docker image..." -ForegroundColor Yellow
    Write-Host "  Image: $fullImageName" -ForegroundColor Cyan
    docker build -t $fullImageName .
    
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed"
    }
    Write-Host "  ✓ Image built successfully" -ForegroundColor Green
    
    # Login to ACR
    Write-Host "`n🔐 Logging in to Azure Container Registry..." -ForegroundColor Yellow
    az acr login --name $AcrName
    
    if ($LASTEXITCODE -ne 0) {
        throw "ACR login failed"
    }
    Write-Host "  ✓ Logged in to ACR" -ForegroundColor Green
    
    # Push the image
    Write-Host "`n📤 Pushing image to ACR..." -ForegroundColor Yellow
    docker push $fullImageName
    
    if ($LASTEXITCODE -ne 0) {
        throw "Docker push failed"
    }
    Write-Host "  ✓ Image pushed successfully" -ForegroundColor Green
    
    # Verify the image
    Write-Host "`n🔍 Verifying image in ACR..." -ForegroundColor Yellow
    $repos = az acr repository show --name $AcrName --repository $ImageName --output json | ConvertFrom-Json
    
    if ($repos) {
        Write-Host "  ✓ Image verified in ACR" -ForegroundColor Green
        Write-Host "  Registry: $($repos.registry)" -ForegroundColor Cyan
        Write-Host "  Repository: $($repos.name)" -ForegroundColor Cyan
    }
    
    # List tags
    Write-Host "`n📋 Available tags:" -ForegroundColor Yellow
    $tags = az acr repository show-tags --name $AcrName --repository $ImageName --output table
    Write-Host $tags -ForegroundColor Cyan
    
    Write-Host "`n✅ SUCCESS! Image is ready to deploy" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Update deployment.yaml with the image name:" -ForegroundColor White
    Write-Host "   $fullImageName" -ForegroundColor Cyan
    Write-Host "2. Deploy to Kubernetes:" -ForegroundColor White
    Write-Host "   kubectl apply -f deployment.yaml" -ForegroundColor Cyan
    Write-Host "3. Check deployment status:" -ForegroundColor White
    Write-Host "   kubectl get pods -l app=powershell-service" -ForegroundColor Cyan
    
}
catch {
    Write-Host "`n❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}




