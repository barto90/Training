# Deploy-FunctionCode.ps1
# Script to help deploy the function code after infrastructure is created
param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
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
    
} catch {
    Write-Warning "⚠️ Azure PowerShell not available or not logged in"
}

Write-Host ""
Write-Host "📋 NEXT STEPS TO DEPLOY FUNCTION CODE:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

Write-Host ""
Write-Host "🔧 METHOD 1: Azure Portal (Recommended for first-time)" -ForegroundColor Green
Write-Host "1. Go to: https://portal.azure.com"
Write-Host "2. Navigate to: Resource Groups → $ResourceGroupName → $FunctionAppName"
Write-Host "3. Click: Functions → Create"
Write-Host "4. Select: ServiceBus Queue trigger"
Write-Host "5. Configure:"
Write-Host "   - Function name: ServiceBusQueueProcessor"
Write-Host "   - Connection: ServiceBusConnection"
Write-Host "   - Queue name: messagequeue"
Write-Host "6. Replace default code with content from: ServiceBusQueueProcessor/run.ps1"
Write-Host "7. Update function.json with content from: ServiceBusQueueProcessor/function.json"

Write-Host ""
Write-Host "🔧 METHOD 2: Azure Functions Core Tools" -ForegroundColor Green
Write-Host "1. Install Azure Functions Core Tools:"
Write-Host "   npm install -g azure-functions-core-tools@4"
Write-Host ""
Write-Host "2. Initialize local project:"
Write-Host "   func init --worker-runtime powershell"
Write-Host ""
Write-Host "3. Create function:"
Write-Host "   func new --name ServiceBusQueueProcessor --template 'ServiceBus Queue trigger'"
Write-Host ""
Write-Host "4. Replace generated files with our files:"
Write-Host "   - Copy ServiceBusQueueProcessor/run.ps1 → ServiceBusQueueProcessor/run.ps1"
Write-Host "   - Copy ServiceBusQueueProcessor/function.json → ServiceBusQueueProcessor/function.json"
Write-Host "   - Copy host.json → host.json"
Write-Host ""
Write-Host "5. Deploy to Azure:"
Write-Host "   func azure functionapp publish $FunctionAppName"

Write-Host ""
Write-Host "🔧 METHOD 3: VS Code Extension" -ForegroundColor Green
Write-Host "1. Install 'Azure Functions' extension in VS Code"
Write-Host "2. Open this folder in VS Code" 
Write-Host "3. Use Command Palette (Ctrl+Shift+P):"
Write-Host "   - 'Azure Functions: Create Function'"
Write-Host "   - Select ServiceBus Queue trigger"
Write-Host "4. Deploy using the Azure Functions extension"

Write-Host ""
Write-Host "📤 TESTING YOUR FUNCTION:" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "After deploying the function code:"
Write-Host ""
Write-Host "1. Get your ServiceBus connection string:"
Write-Host "   - Go to: ServiceBus Namespace → Shared access policies → RootManageSharedAccessKey"
Write-Host "   - Copy the Primary Connection String"
Write-Host ""
Write-Host "2. Send a test message:"
Write-Host "   .\Send-ServiceBusMessage.ps1 -ConnectionString 'your-connection-string' -QueueName 'messagequeue' -MessageContent 'Hello World!'"
Write-Host ""
Write-Host "3. Check function logs:"
Write-Host "   - Go to: Function App → Functions → ServiceBusQueueProcessor → Monitor"
Write-Host "   - Or check Application Insights for detailed logs"

Write-Host ""
Write-Host "🎯 QUICK START PORTAL LINK:" -ForegroundColor Cyan
if ($functionApp) {
    $portalUrl = "https://portal.azure.com/#@/resource/subscriptions/$($functionApp.SubscriptionId)/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/functions"
    Write-Host $portalUrl -ForegroundColor Blue
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏁 Ready to deploy your function code!" -ForegroundColor Cyan 