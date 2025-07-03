# Test Logic App with Sample Payload
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$LogicAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

Write-Host "🧪 Testing Logic App with Sample Payload..." -ForegroundColor Green

# Get Logic App trigger URL
$logicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $LogicAppName
$triggerUri = $logicApp.Triggers["manual"].Callback.Value

Write-Host "📍 Logic App Trigger URL found" -ForegroundColor Green

# Create test payload with real resource IDs
$resourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$AppServiceName"

$testPayload = @{
    schemaId = "azureMonitorCommonAlertSchema"
    data = @{
        essentials = @{
            alertId = "/subscriptions/$SubscriptionId/providers/Microsoft.AlertsManagement/alerts/test-alert"
            alertRule = "alert-appstopped-test"
            severity = "Sev3"
            signalType = "Activity Log"
            monitorCondition = "Fired"
            monitoringService = "Activity Log - Administrative"
            alertTargetIDs = @($resourceId)
            originAlertId = "test-origin-id"
            firedDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.0000000Z")
            resolvedDateTime = ""
            description = "Alert when any App Service with AlwaysOn tag is stopped"
            essentialsVersion = "1.0"
            alertContextVersion = "1.0"
        }
        alertContext = @{
            properties = @{
                eventDataId = "test-event-id"
                eventName = @{
                    value = "Stop web app"
                    localizedValue = "Stop web app"
                }
                category = @{
                    value = "Administrative"
                    localizedValue = "Administrative"
                }
                eventTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.0000000Z")
                operationName = @{
                    value = "Microsoft.Web/sites/stop/action"
                    localizedValue = "Stop web app"
                }
                operationId = "test-operation-id"
                status = @{
                    value = "Succeeded"
                    localizedValue = "Succeeded"
                }
                subStatus = @{
                    value = ""
                    localizedValue = ""
                }
                submissionTimestamp = (Get-Date).AddSeconds(5).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.0000000Z")
                resourceId = $resourceId
                resourceGroupName = $ResourceGroupName
                resourceProviderName = @{
                    value = "Microsoft.Web"
                    localizedValue = "Microsoft.Web"
                }
                resourceType = @{
                    value = "sites"
                    localizedValue = "App Services"
                }
                caller = "test-user@domain.com"
                correlationId = "test-correlation-id"
            }
        }
    }
} | ConvertTo-Json -Depth 10

Write-Host "📤 Sending test payload to Logic App..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $triggerUri -Method POST -Body $testPayload -ContentType "application/json"
    Write-Host "✅ Successfully triggered Logic App!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor White
} catch {
    Write-Host "❌ Error triggering Logic App: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = [System.IO.StreamReader]::new($errorResponse)
        $errorContent = $reader.ReadToEnd()
        Write-Host "Error details: $errorContent" -ForegroundColor Red
    }
}

Write-Host "`n⏳ Waiting 10 seconds for Logic App to process..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check Logic App run history
Write-Host "`n📊 Checking Logic App run history..." -ForegroundColor Green
$runs = Get-AzLogicAppRunHistory -ResourceGroupName $ResourceGroupName -Name $LogicAppName -Top 3

if ($runs) {
    $latestRun = $runs[0]
    Write-Host "📋 Latest Run:" -ForegroundColor Green
    Write-Host "  Status: $($latestRun.Status)" -ForegroundColor White
    Write-Host "  Started: $($latestRun.StartTime)" -ForegroundColor White
    Write-Host "  Ended: $($latestRun.EndTime)" -ForegroundColor White
    
    if ($latestRun.Status -eq "Failed") {
        Write-Host "  ❌ Run failed - check Logic App designer for details" -ForegroundColor Red
    } elseif ($latestRun.Status -eq "Succeeded") {
        Write-Host "  ✅ Run succeeded!" -ForegroundColor Green
    }
    
    # Get run actions
    $actions = Get-AzLogicAppRunAction -ResourceGroupName $ResourceGroupName -Name $LogicAppName -RunName $latestRun.Name
    
    Write-Host "`n📋 Action Results:" -ForegroundColor Green
    $actions | ForEach-Object {
        $statusIcon = if ($_.Status -eq "Succeeded") { "✅" } elseif ($_.Status -eq "Failed") { "❌" } else { "⏳" }
        Write-Host "  $statusIcon $($_.Name): $($_.Status)" -ForegroundColor White
        
        if ($_.Name -eq "Parse_Activity_Log_Data" -and $_.Outputs) {
            Write-Host "    Parsed Data: $($_.Outputs | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }
        
        if ($_.Status -eq "Failed" -and $_.Error) {
            Write-Host "    Error: $($_.Error.message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "❌ No runs found" -ForegroundColor Red
}

Write-Host "`n📚 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Check Logic App designer in portal for detailed run history" -ForegroundColor White
Write-Host "2. If permissions failed, run: .\assign-permissions.ps1" -ForegroundColor White  
Write-Host "3. If payload parsing failed, update the trigger schema in Logic App designer" -ForegroundColor White
Write-Host "4. Test with real App Service stop event" -ForegroundColor White 