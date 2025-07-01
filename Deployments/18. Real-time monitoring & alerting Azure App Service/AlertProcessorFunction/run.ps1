# Azure Function Alert Processor
# This function processes alerts from the monitoring queue and forwards notifications

using namespace System.Net

param($AlertMessage, $TriggerMetadata)

# Write an information log with the current time
Write-Host "🚨 Alert Processor started at: $(Get-Date)"

try {
    # Parse the incoming alert message
    $alert = $AlertMessage | ConvertFrom-Json
    
    Write-Host "📨 Processing alert from: $($alert.appServiceName)"
    Write-Host "🚨 Alert Level: $($alert.alertLevel)"
    Write-Host "📍 Endpoint: $($alert.endpointName)"
    Write-Host "💬 Message: $($alert.message)"
    
    # Add processing metadata
    $processedAlert = [ordered]@{
        originalAlert = $alert
        processedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        processingId = [System.Guid]::NewGuid().ToString()
        severity = switch ($alert.alertLevel) {
            "CRITICAL" { "High" }
            "WARNING" { "Medium" }
            "INFO" { "Low" }
            default { "Medium" }
        }
        requiresImmedateAction = ($alert.alertLevel -eq "CRITICAL")
        alertCategory = if ($alert.endpointName -eq "Heartbeat") { "Heartbeat" } else { "ServiceHealth" }
    }
    
    # Enhanced alert message for notifications
    $enhancedMessage = @{
        alertLevel = $alert.alertLevel
        severity = $processedAlert.severity
        appServiceName = $alert.appServiceName
        endpointName = $alert.endpointName
        url = $alert.url
        message = $alert.message
        statusCode = $alert.statusCode
        responseTime = $alert.responseTime
        timestamp = $alert.timestamp
        processedAt = $processedAlert.processedAt
        processingId = $processedAlert.processingId
        alertEmail = $alert.alertEmail
        requiresImmedateAction = $processedAlert.requiresImmedateAction
        alertCategory = $processedAlert.alertCategory
        
        # Additional context for notifications
        alertSummary = switch ($alert.alertLevel) {
            "CRITICAL" { "🔴 CRITICAL: Service is experiencing severe issues" }
            "WARNING" { "🟡 WARNING: Service is experiencing degraded performance" }
            "INFO" { "🟢 INFO: Service status update" }
            default { "⚪ UNKNOWN: Alert level not recognized" }
        }
        
        recommendedAction = switch ($alert.alertLevel) {
            "CRITICAL" { "Immediate investigation required. Check service logs and consider scaling or restarting the service." }
            "WARNING" { "Monitor closely. Consider investigating if issues persist." }
            "INFO" { "No action required. This is an informational message." }
            default { "Review alert details and determine appropriate action." }
        }
        
        # Azure Portal links for quick access
        portalLinks = @{
            appService = "https://portal.azure.com/#@/resource/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Web/sites/$($alert.appServiceName)"
            applicationInsights = "https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/resourceType/microsoft.insights%2Fcomponents"
            serviceHealth = "https://portal.azure.com/#blade/Microsoft_Azure_Health/AzureHealthBrowseBlade/serviceIssues"
        }
    }
    
    # Log processing details
    Write-Host "🔧 Processing Details:"
    Write-Host "   📋 Processing ID: $($processedAlert.processingId)"
    Write-Host "   ⚖️ Severity: $($processedAlert.severity)"
    Write-Host "   🚨 Immediate Action Required: $($processedAlert.requiresImmedateAction)"
    Write-Host "   📂 Category: $($processedAlert.alertCategory)"
    
    # Apply alert filtering and throttling logic
    $shouldSendNotification = $true
    
    # Skip heartbeat notifications unless it's a special case
    if ($alert.alertLevel -eq "INFO" -and $alert.endpointName -eq "Heartbeat") {
        # Only send heartbeat notifications during business hours (9 AM - 5 PM UTC)
        $currentHour = (Get-Date).ToUniversalTime().Hour
        if ($currentHour -lt 9 -or $currentHour -gt 17) {
            $shouldSendNotification = $false
            Write-Host "⏰ Skipping heartbeat notification outside business hours"
        }
    }
    
    # Rate limiting: Don't send too many critical alerts in a short time
    # (This would typically use external storage to track, but for demo we'll proceed)
    
    if ($shouldSendNotification) {
        # Convert to JSON for ServiceBus message
        $notificationJson = $enhancedMessage | ConvertTo-Json -Depth 10 -Compress
        
        # Send to notification queue for Logic App processing
        Push-OutputBinding -Name NotificationMessage -Value $notificationJson
        
        Write-Host "📤 Notification sent to Logic App queue"
        Write-Host "📊 Message size: $($notificationJson.Length) bytes"
        
        # Log successful processing
        Write-Host "✅ Alert processed successfully"
    }
    else {
        Write-Host "🚫 Notification skipped due to filtering rules"
    }
    
    # Additional logging for Application Insights
    $telemetryData = @{
        alertLevel = $alert.alertLevel
        appServiceName = $alert.appServiceName
        endpointName = $alert.endpointName
        responseTime = $alert.responseTime
        statusCode = $alert.statusCode
        processingId = $processedAlert.processingId
        notificationSent = $shouldSendNotification
        severity = $processedAlert.severity
    }
    
    Write-Host "📊 Telemetry: $(($telemetryData | ConvertTo-Json -Compress))"
    
}
catch {
    Write-Host "💥 Error processing alert: $($_.Exception.Message)"
    Write-Host "📍 Error at: $($_.ScriptStackTrace)"
    
    # Send error notification
    $errorAlert = @{
        alertLevel = "CRITICAL"
        severity = "High"
        appServiceName = "Alert Processor"
        endpointName = "AlertProcessorFunction"
        url = "N/A"
        message = "Failed to process monitoring alert: $($_.Exception.Message)"
        statusCode = 500
        responseTime = 0
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        processedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        processingId = [System.Guid]::NewGuid().ToString()
        alertEmail = $env:AlertEmail
        requiresImmedateAction = $true
        alertCategory = "SystemError"
        alertSummary = "🔴 CRITICAL: Alert processing system failure"
        recommendedAction = "Check Azure Function logs and ensure ServiceBus connectivity."
        originalAlertData = $AlertMessage
        errorDetails = $_.Exception.ToString()
    }
    
    $errorJson = $errorAlert | ConvertTo-Json -Depth 10 -Compress
    Push-OutputBinding -Name NotificationMessage -Value $errorJson
    
    # Re-throw to ensure function fails and alert goes to dead letter queue
    throw
}

Write-Host "🚨 Alert Processor completed at: $(Get-Date)" 