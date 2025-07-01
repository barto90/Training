# Azure Function Health Check Monitor
# This function performs health checks on the monitored App Service and sends alerts via ServiceBus

using namespace System.Net

param($Timer)

# Write an information log with the current time
Write-Host "🏥 Health Check Monitor started at: $(Get-Date)"

# Get configuration from environment variables
$monitoredAppUrl = $env:MonitoredAppServiceUrl
$appServiceName = $env:MonitoredAppServiceName
$alertEmail = $env:AlertEmail

Write-Host "🎯 Monitoring App Service: $appServiceName"
Write-Host "🌐 URL: $monitoredAppUrl"

# Health check endpoints to monitor
$healthCheckEndpoints = @(
    @{ Name = "Home Page"; Url = $monitoredAppUrl; ExpectedStatusCode = 200 },
    @{ Name = "Health Check"; Url = "$monitoredAppUrl/health"; ExpectedStatusCode = 200 },
    @{ Name = "API Status"; Url = "$monitoredAppUrl/api/status"; ExpectedStatusCode = 200 }
)

$alertsToSend = @()
$overallHealth = "Healthy"

foreach ($endpoint in $healthCheckEndpoints) {
    try {
        Write-Host "🔍 Checking endpoint: $($endpoint.Name) - $($endpoint.Url)"
        
        # Measure response time
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Make HTTP request with timeout
        $response = Invoke-WebRequest -Uri $endpoint.Url -Method GET -TimeoutSec 30 -ErrorAction Stop
        
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        Write-Host "✅ Response: $($response.StatusCode) | Time: ${responseTime}ms"
        
        # Check status code
        if ($response.StatusCode -ne $endpoint.ExpectedStatusCode) {
            $overallHealth = "Degraded"
            $alertMessage = @{
                alertLevel = "WARNING"
                appServiceName = $appServiceName
                endpointName = $endpoint.Name
                url = $endpoint.Url
                message = "Unexpected status code: $($response.StatusCode), expected: $($endpoint.ExpectedStatusCode)"
                statusCode = $response.StatusCode
                responseTime = $responseTime
                timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
                alertEmail = $alertEmail
            }
            $alertsToSend += $alertMessage
        }
        
        # Check response time (alert if > 5 seconds)
        if ($responseTime -gt 5000) {
            $overallHealth = "Degraded"
            $alertMessage = @{
                alertLevel = "WARNING"
                appServiceName = $appServiceName
                endpointName = $endpoint.Name
                url = $endpoint.Url
                message = "High response time: ${responseTime}ms (threshold: 5000ms)"
                statusCode = $response.StatusCode
                responseTime = $responseTime
                timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
                alertEmail = $alertEmail
            }
            $alertsToSend += $alertMessage
        }
        
    }
    catch [System.Net.WebException] {
        $overallHealth = "Unhealthy"
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        Write-Host "❌ Web Exception: $($_.Exception.Message)"
        
        # Determine status code from exception
        $statusCode = 0
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        $alertMessage = @{
            alertLevel = "CRITICAL"
            appServiceName = $appServiceName
            endpointName = $endpoint.Name
            url = $endpoint.Url
            message = "Endpoint unreachable: $($_.Exception.Message)"
            statusCode = $statusCode
            responseTime = $responseTime
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
            alertEmail = $alertEmail
        }
        $alertsToSend += $alertMessage
    }
    catch {
        $overallHealth = "Unhealthy"
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        Write-Host "💥 General Exception: $($_.Exception.Message)"
        
        $alertMessage = @{
            alertLevel = "CRITICAL"
            appServiceName = $appServiceName
            endpointName = $endpoint.Name
            url = $endpoint.Url
            message = "Health check failed: $($_.Exception.Message)"
            statusCode = 0
            responseTime = $responseTime
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
            alertEmail = $alertEmail
        }
        $alertsToSend += $alertMessage
    }
}

# Send alerts if any issues found
if ($alertsToSend.Count -gt 0) {
    Write-Host "🚨 Sending $($alertsToSend.Count) alert(s)"
    
    foreach ($alert in $alertsToSend) {
        $alertJson = $alert | ConvertTo-Json -Compress
        
        # Send to ServiceBus for alert processing
        Push-OutputBinding -Name AlertMessage -Value $alertJson
        
        Write-Host "📤 Alert sent: $($alert.alertLevel) - $($alert.message)"
    }
}
else {
    Write-Host "✅ All health checks passed - no alerts to send"
    
    # Send a heartbeat message periodically (every 10th run)
    $runNumber = Get-Random -Minimum 1 -Maximum 11
    if ($runNumber -eq 1) {
        $heartbeatMessage = @{
            alertLevel = "INFO"
            appServiceName = $appServiceName
            endpointName = "Heartbeat"
            url = $monitoredAppUrl
            message = "Health monitoring is active - all systems healthy"
            statusCode = 200
            responseTime = 0
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
            alertEmail = $alertEmail
        }
        
        $heartbeatJson = $heartbeatMessage | ConvertTo-Json -Compress
        Push-OutputBinding -Name AlertMessage -Value $heartbeatJson
        
        Write-Host "💓 Heartbeat message sent"
    }
}

Write-Host "🏥 Health Check Monitor completed at: $(Get-Date)"
Write-Host "📊 Overall Health Status: $overallHealth" 