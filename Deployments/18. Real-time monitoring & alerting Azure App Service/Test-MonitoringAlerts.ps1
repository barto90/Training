# Test Monitoring Alerts Script
# This script tests the monitoring system by sending various types of test alerts

param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceBusConnectionString,
    
    [Parameter(Mandatory = $false)]
    [string]$AlertQueueName = "monitoring-alerts",
    
    [Parameter(Mandatory = $false)]
    [string]$AppServiceName = "monitored-webapp-demo",
    
    [Parameter(Mandatory = $false)]
    [string]$AppServiceUrl = "https://monitored-webapp-demo.azurewebsites.net",
    
    [Parameter(Mandatory = $false)]
    [string]$AlertEmail = "admin@example.com",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("CRITICAL", "WARNING", "INFO", "ALL")]
    [string]$AlertType = "ALL"
)

Write-Host "🧪 Testing Monitoring & Alerting System" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "📧 Alert Email: $AlertEmail" -ForegroundColor Yellow
Write-Host "🎯 App Service: $AppServiceName" -ForegroundColor Yellow
Write-Host "🌐 URL: $AppServiceUrl" -ForegroundColor Yellow
Write-Host "📊 Queue: $AlertQueueName" -ForegroundColor Yellow
Write-Host ""

# Install Azure Service Bus module if not present
if (-not (Get-Module -ListAvailable -Name Azure.Messaging.ServiceBus)) {
    Write-Host "📦 Installing Azure ServiceBus module..." -ForegroundColor Yellow
    try {
        Install-Module -Name Azure.Messaging.ServiceBus -Force -Scope CurrentUser
        Write-Host "✅ Module installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install module. Using REST API instead." -ForegroundColor Red
    }
}

# Function to send message to ServiceBus
function Send-ServiceBusMessage {
    param(
        [string]$ConnectionString,
        [string]$QueueName,
        [string]$MessageBody
    )
    
    try {
        # Parse connection string
        $connectionParts = @{}
        $ConnectionString -split ';' | ForEach-Object {
            if ($_ -match '(.+?)=(.+)') {
                $connectionParts[$matches[1]] = $matches[2]
            }
        }
        
        $namespace = $connectionParts['Endpoint'] -replace 'sb://', '' -replace '.servicebus.windows.net/', ''
        $sasKeyName = $connectionParts['SharedAccessKeyName']
        $sasKey = $connectionParts['SharedAccessKey']
        
        # Create SAS token
        $uri = "https://$namespace.servicebus.windows.net/$QueueName"
        $expiry = [DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()
        $stringToSign = [System.Web.HttpUtility]::UrlEncode($uri) + "`n" + $expiry
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key = [Text.Encoding]::UTF8.GetBytes($sasKey)
        $signature = [Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign)))
        $sasToken = "SharedAccessSignature sr=" + [System.Web.HttpUtility]::UrlEncode($uri) + "&sig=" + [System.Web.HttpUtility]::UrlEncode($signature) + "&se=" + $expiry + "&skn=" + $sasKeyName
        
        # Send message via REST API
        $headers = @{
            'Authorization' = $sasToken
            'Content-Type' = 'application/json'
        }
        
        $body = @{
            Body = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($MessageBody))
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$uri/messages" -Method Post -Headers $headers -Body $body -ContentType "application/json"
        return $true
    }
    catch {
        Write-Host "❌ Failed to send message: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test alert scenarios
$testAlerts = @()

if ($AlertType -eq "ALL" -or $AlertType -eq "CRITICAL") {
    $testAlerts += @{
        alertLevel = "CRITICAL"
        appServiceName = $AppServiceName
        endpointName = "Home Page"
        url = $AppServiceUrl
        message = "Service is completely unavailable - returning 503 Service Unavailable"
        statusCode = 503
        responseTime = 30000
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        alertEmail = $AlertEmail
        testScenario = "Complete Service Outage"
    }
    
    $testAlerts += @{
        alertLevel = "CRITICAL"
        appServiceName = $AppServiceName
        endpointName = "API Status"
        url = "$AppServiceUrl/api/status"
        message = "Connection timeout - no response from server"
        statusCode = 0
        responseTime = 60000
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        alertEmail = $AlertEmail
        testScenario = "Connection Timeout"
    }
}

if ($AlertType -eq "ALL" -or $AlertType -eq "WARNING") {
    $testAlerts += @{
        alertLevel = "WARNING"
        appServiceName = $AppServiceName
        endpointName = "Health Check"
        url = "$AppServiceUrl/health"
        message = "High response time: 8500ms (threshold: 5000ms)"
        statusCode = 200
        responseTime = 8500
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        alertEmail = $AlertEmail
        testScenario = "Performance Degradation"
    }
    
    $testAlerts += @{
        alertLevel = "WARNING"
        appServiceName = $AppServiceName
        endpointName = "API Status"
        url = "$AppServiceUrl/api/status"
        message = "Unexpected status code: 500, expected: 200"
        statusCode = 500
        responseTime = 2500
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        alertEmail = $AlertEmail
        testScenario = "Server Error Response"
    }
}

if ($AlertType -eq "ALL" -or $AlertType -eq "INFO") {
    $testAlerts += @{
        alertLevel = "INFO"
        appServiceName = $AppServiceName
        endpointName = "Heartbeat"
        url = $AppServiceUrl
        message = "Health monitoring is active - all systems healthy"
        statusCode = 200
        responseTime = 150
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        alertEmail = $AlertEmail
        testScenario = "Heartbeat Check"
    }
    
    $testAlerts += @{
        alertLevel = "INFO"
        appServiceName = $AppServiceName
        endpointName = "System Status"
        url = "$AppServiceUrl/status"
        message = "System maintenance completed successfully"
        statusCode = 200
        responseTime = 95
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        alertEmail = $AlertEmail
        testScenario = "Maintenance Notification"
    }
}

Write-Host "🚀 Starting test alert scenarios..." -ForegroundColor Green
Write-Host "📝 Total alerts to send: $($testAlerts.Count)" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failureCount = 0

foreach ($alert in $testAlerts) {
    Write-Host "📤 Sending $($alert.alertLevel) alert: $($alert.testScenario)" -ForegroundColor Cyan
    Write-Host "   📍 Endpoint: $($alert.endpointName)" -ForegroundColor Gray
    Write-Host "   💬 Message: $($alert.message)" -ForegroundColor Gray
    Write-Host "   ⏱️  Response Time: $($alert.responseTime)ms" -ForegroundColor Gray
    Write-Host "   📊 Status Code: $($alert.statusCode)" -ForegroundColor Gray
    
    $alertJson = $alert | ConvertTo-Json -Compress
    
    if (Send-ServiceBusMessage -ConnectionString $ServiceBusConnectionString -QueueName $AlertQueueName -MessageBody $alertJson) {
        Write-Host "   ✅ Alert sent successfully" -ForegroundColor Green
        $successCount++
    }
    else {
        Write-Host "   ❌ Failed to send alert" -ForegroundColor Red
        $failureCount++
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
}

Write-Host "🏁 Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "✅ Successful: $successCount" -ForegroundColor Green
Write-Host "❌ Failed: $failureCount" -ForegroundColor Red
Write-Host "📊 Total: $($testAlerts.Count)" -ForegroundColor Yellow

if ($successCount -gt 0) {
    Write-Host ""
    Write-Host "🔍 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Check Azure Function logs for HealthCheckFunction" -ForegroundColor White
    Write-Host "2. Monitor AlertProcessorFunction for message processing" -ForegroundColor White
    Write-Host "3. Verify Logic App receives notifications" -ForegroundColor White
    Write-Host "4. Check email for alert notifications" -ForegroundColor White
    Write-Host "5. Review Application Insights for telemetry data" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Azure Portal Resources:" -ForegroundColor Yellow
    Write-Host "• ServiceBus: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.ServiceBus%2Fnamespaces" -ForegroundColor White
    Write-Host "• Function App: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Web%2Fsites" -ForegroundColor White
    Write-Host "• Logic Apps: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Logic%2Fworkflows" -ForegroundColor White
    Write-Host "• App Insights: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/microsoft.insights%2Fcomponents" -ForegroundColor White
}

Write-Host ""
Write-Host "🧪 Test completed at: $(Get-Date)" -ForegroundColor Cyan 