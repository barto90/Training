# Setup Activity Log Diagnostic Settings
# Run this if the ARM template failed to create subscription-level diagnostic settings

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$LogAnalyticsWorkspaceName
)

Write-Host "Setting up Activity Log diagnostic settings..." -ForegroundColor Green

# Set subscription context
Set-AzContext -SubscriptionId $SubscriptionId

# Get Log Analytics workspace resource ID
$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsWorkspaceName
$workspaceId = $workspace.ResourceId

Write-Host "Found Log Analytics workspace: $workspaceId" -ForegroundColor Yellow

# Check if diagnostic setting already exists
$existingSetting = Get-AzDiagnosticSetting -ResourceId "/subscriptions/$SubscriptionId" -Name "SendActivityLogToLogAnalytics" -ErrorAction SilentlyContinue

if ($existingSetting) {
    Write-Host "✅ Diagnostic setting already exists!" -ForegroundColor Green
    Write-Host "Current categories enabled:" -ForegroundColor Yellow
    $existingSetting.Log | ForEach-Object { Write-Host "  - $($_.Category): $($_.Enabled)" }
} else {
    Write-Host "Creating Activity Log diagnostic setting..." -ForegroundColor Yellow
    
    # Create diagnostic setting
    $logSettings = @(
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "Administrative"
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "Security"
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "ServiceHealth"
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "Alert"
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "Recommendation"
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "Policy"
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "Autoscale"
        New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "ResourceHealth"
    )
    
    try {
        New-AzDiagnosticSetting `
            -ResourceId "/subscriptions/$SubscriptionId" `
            -Name "SendActivityLogToLogAnalytics" `
            -WorkspaceId $workspaceId `
            -Log $logSettings
            
        Write-Host "✅ Successfully created Activity Log diagnostic setting!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to create diagnostic setting: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You may need to run this with higher privileges or ask your admin to configure it." -ForegroundColor Yellow
    }
}

# Test the setup by querying recent Activity Log events
Write-Host "`nTesting Log Analytics connection..." -ForegroundColor Green
try {
    $query = @"
AzureActivity
| where TimeGenerated > ago(1h)
| where CategoryValue == "Administrative"
| take 5
| project TimeGenerated, CategoryValue, OperationNameValue, ResourceId
"@

    $result = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspace.CustomerId -Query $query
    
    if ($result.Results.Count -gt 0) {
        Write-Host "✅ Activity Log data is flowing to Log Analytics!" -ForegroundColor Green
        Write-Host "Recent events:" -ForegroundColor Yellow
        $result.Results | ForEach-Object { 
            Write-Host "  - $($_.TimeGenerated): $($_.OperationNameValue)" 
        }
    } else {
        Write-Host "⏳ No recent Activity Log data found. It may take 5-15 minutes for data to appear." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⏳ Unable to query Log Analytics yet. Data may still be flowing in." -ForegroundColor Yellow
}

Write-Host "`n📍 To verify manually:" -ForegroundColor Cyan
Write-Host "1. Go to Azure Portal → Subscriptions → Monitor → Activity Log → Diagnostic Settings" -ForegroundColor White
Write-Host "2. You should see 'SendActivityLogToLogAnalytics'" -ForegroundColor White
Write-Host "3. Go to Log Analytics workspace → Logs → Run this query:" -ForegroundColor White
Write-Host "   AzureActivity | where CategoryValue == 'Administrative' | take 10" -ForegroundColor Gray

Write-Host "`n🧪 To test the auto-restart:" -ForegroundColor Cyan
Write-Host "1. Stop your App Service manually" -ForegroundColor White
Write-Host "2. Check Activity Log for stop event" -ForegroundColor White  
Write-Host "3. Wait for auto-restart (should happen within 1-2 minutes)" -ForegroundColor White 