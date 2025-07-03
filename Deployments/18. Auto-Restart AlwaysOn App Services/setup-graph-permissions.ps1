# Setup Microsoft Graph Mail.Send permission for Logic App
# Run this script to allow the Logic App to send emails

Write-Host "🔑 Setting up Microsoft Graph permissions for Logic App..." -ForegroundColor Green

# Your Logic App's Managed Identity ID
$logicAppPrincipalId = "58c1903d-ab77-44ad-b659-d4369e98c3ab"

# Microsoft Graph Service Principal ID  
$graphServicePrincipalId = "20f79b96-63cf-4c5d-b165-c57e12e3c1aa"

# Mail.Send App Role ID
$mailSendRoleId = "b633e1c5-b582-4048-a93e-9f11b44c7e96"

Write-Host "📋 Details:" -ForegroundColor Yellow
Write-Host "  Logic App ID: $logicAppPrincipalId" -ForegroundColor White
Write-Host "  Graph Service Principal: $graphServicePrincipalId" -ForegroundColor White  
Write-Host "  Mail.Send Role ID: $mailSendRoleId" -ForegroundColor White

# Create the app role assignment
Write-Host "`n🔧 Assigning Mail.Send permission..." -ForegroundColor Yellow

# Create JSON body file to avoid PowerShell escaping issues
$jsonBody = @{
    principalId = $logicAppPrincipalId
    resourceId = $graphServicePrincipalId
    appRoleId = $mailSendRoleId
} | ConvertTo-Json

$jsonBody | Out-File -FilePath "temp-permission.json" -Encoding UTF8

try {
    # Use Azure CLI to make the assignment
    $result = az rest --method post --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$logicAppPrincipalId/appRoleAssignments" --body "@temp-permission.json" | ConvertFrom-Json
    
    Write-Host "✅ Successfully assigned Mail.Send permission!" -ForegroundColor Green
    Write-Host "  Assignment ID: $($result.id)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Failed to assign permission: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 You may need Global Administrator or Privileged Role Administrator permissions" -ForegroundColor Yellow
    
    Write-Host "`n🔧 Alternative: Manual setup in Azure Portal:" -ForegroundColor Cyan
    Write-Host "1. Go to Azure AD → Enterprise applications" -ForegroundColor White
    Write-Host "2. Search for: $logicAppPrincipalId" -ForegroundColor White
    Write-Host "3. Click Permissions → Add permission → Microsoft Graph → Application permissions" -ForegroundColor White
    Write-Host "4. Select Mail.Send → Grant admin consent" -ForegroundColor White
}

# Clean up temp file
Remove-Item "temp-permission.json" -ErrorAction SilentlyContinue

Write-Host "`n🧪 Test your Logic App:" -ForegroundColor Cyan
Write-Host "1. Stop your App Service" -ForegroundColor White
Write-Host "2. Check Logic App runs for email sending" -ForegroundColor White
Write-Host "3. Check your email inbox!" -ForegroundColor White 