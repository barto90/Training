# Debug Logic App Payload and Test Workflow
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$LogicAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName
)

Write-Host "🔍 Debugging Logic App Payload..." -ForegroundColor Green

# Get Logic App details
$logicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $LogicAppName
$triggerUri = $logicApp.Triggers["manual"].Callback.Value

Write-Host "📍 Logic App Trigger URL:" -ForegroundColor Yellow
Write-Host $triggerUri -ForegroundColor Gray

# Get recent Logic App runs
Write-Host "`n📊 Recent Logic App Runs:" -ForegroundColor Green
$runs = Get-AzLogicAppRunHistory -ResourceGroupName $ResourceGroupName -Name $LogicAppName -Top 5

if ($runs) {
    $runs | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.Status) at $($_.StartTime)" -ForegroundColor White
    }
    
    # Get details of the most recent run
    $latestRun = $runs[0]
    Write-Host "`n🔍 Latest Run Details:" -ForegroundColor Green
    Write-Host "  Status: $($latestRun.Status)" -ForegroundColor White
    Write-Host "  Start: $($latestRun.StartTime)" -ForegroundColor White
    Write-Host "  End: $($latestRun.EndTime)" -ForegroundColor White
    
    # Get run actions
    $actions = Get-AzLogicAppRunAction -ResourceGroupName $ResourceGroupName -Name $LogicAppName -RunName $latestRun.Name
    
    Write-Host "`n📋 Run Actions:" -ForegroundColor Green
    $actions | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.Status)" -ForegroundColor White
        
        # Show Parse_Activity_Log_Data output if available
        if ($_.Name -eq "Parse_Activity_Log_Data" -and $_.Outputs) {
            Write-Host "    Output: $($_.Outputs | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
        }
        
        # Show Get_App_Service_Tags output if available  
        if ($_.Name -eq "Get_App_Service_Tags" -and $_.Outputs) {
            Write-Host "    Output: $($_.Outputs | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  No runs found yet." -ForegroundColor Yellow
}

Write-Host "`n🧪 Test Steps:" -ForegroundColor Cyan
Write-Host "1. Stop your App Service manually" -ForegroundColor White
Write-Host "2. Wait 2-3 minutes for Activity Log Alert to trigger" -ForegroundColor White
Write-Host "3. Run this script again to see the payload" -ForegroundColor White
Write-Host "4. Check Logic App run history in portal" -ForegroundColor White

Write-Host "`n📚 Useful Links:" -ForegroundColor Cyan
Write-Host "• Logic App Runs: https://portal.azure.com/#@/resource$($logicApp.Id)/overview" -ForegroundColor Gray
Write-Host "• Activity Log: https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/activityLog" -ForegroundColor Gray

# Test App Service access
Write-Host "`n🔑 Testing Logic App Permissions..." -ForegroundColor Green
try {
    $appService = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    Write-Host "✅ App Service found: $($appService.Name)" -ForegroundColor Green
    Write-Host "  Tags: $($appService.Tags | ConvertTo-Json -Compress)" -ForegroundColor White
    Write-Host "  State: $($appService.State)" -ForegroundColor White
} catch {
    Write-Host "❌ Error accessing App Service: $($_.Exception.Message)" -ForegroundColor Red
}

# Check if Logic App has Managed Identity
if ($logicApp.Identity -and $logicApp.Identity.Type -eq "SystemAssigned") {
    Write-Host "✅ Logic App has System Assigned Managed Identity" -ForegroundColor Green
    Write-Host "  Principal ID: $($logicApp.Identity.PrincipalId)" -ForegroundColor White
} else {
    Write-Host "❌ Logic App does not have Managed Identity enabled" -ForegroundColor Red
}

Write-Host "`n💡 Next: If Logic App runs but gets permission errors, you need to assign 'Website Contributor' role manually!" -ForegroundColor Yellow 