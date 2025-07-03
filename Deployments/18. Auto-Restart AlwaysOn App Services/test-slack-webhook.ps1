# Test Slack Webhook Integration
# This script helps you test your Slack webhook before deploying the full solution

param(
    [Parameter(Mandatory=$false)]
    [string]$SlackWebhookUrl = "https://hooks.slack.com/services/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",
    
    [Parameter(Mandatory=$false)]
    [string]$TestMessage = "🧪 Test message from Azure Auto-Restart solution"
)

Write-Host "🧪 Testing Slack Webhook Integration..." -ForegroundColor Cyan
Write-Host ""

# Validate webhook URL
if ($SlackWebhookUrl -notmatch "^https://hooks\.slack\.com/services/") {
    Write-Host "❌ Invalid Slack webhook URL format!" -ForegroundColor Red
    Write-Host "   Expected format: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX" -ForegroundColor Yellow
    exit 1
}

# Test payload using the same format as the Logic App
$testPayload = @{
    text = "🔄 App Service Auto-Restarted: Test-App-Service"
    attachments = @(
        @{
            color = "good"
            title = "✅ Auto-Restart Successful"
            text = "Your App Service 'Test-App-Service' was automatically stopped but has been restarted because it has the 'AlwaysOn' tag set to 'true'.\n\n📋 Details:\n• App Name: Test-App-Service\n• Stopped At: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")\n• Stopped By: test-user@company.com\n• Restarted At: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")\n• Action Taken: Automatically restarted\n\n✅ Your app is now running again!"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    Write-Host "📤 Sending test message to Slack..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri $SlackWebhookUrl -Method POST -Body $testPayload -ContentType "application/json"
    
    if ($response -eq "ok") {
        Write-Host "✅ Slack webhook test successful!" -ForegroundColor Green
        Write-Host "   Check your Slack channel for the test message." -ForegroundColor Cyan
    } else {
        Write-Host "❌ Slack webhook test failed!" -ForegroundColor Red
        Write-Host "   Response: $($response | ConvertTo-Json)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Error testing Slack webhook:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "   HTTP Status: $statusCode" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. If the test was successful, update your parameters.json with this webhook URL" -ForegroundColor White
Write-Host "   2. Deploy the solution using: .\deploy.ps1" -ForegroundColor White
Write-Host "   3. Test the full auto-restart functionality" -ForegroundColor White 