using namespace System.Net

param([string] $mySbMsg, $TriggerMetadata)

Write-Host "🚌 ServiceBus Message Received!"
Write-Host "📅 Timestamp: $(Get-Date)"
Write-Host "🆔 Message ID: $($TriggerMetadata.MessageId)"
Write-Host "📋 Message Content: $mySbMsg"
Write-Host "📊 Delivery Count: $($TriggerMetadata.DeliveryCount)"
Write-Host "⏰ Enqueued Time: $($TriggerMetadata.EnqueuedTimeUtc)"

try {

    if ($mySbMsg -match '^[\{\[].*[\}\]]$') {
        $messageObject = $mySbMsg | ConvertFrom-Json
        Write-Host "✅ Successfully parsed JSON message:"
        $messageObject | ConvertTo-Json -Depth 3 | Write-Host
    } else {
        Write-Host "📝 Plain text message: $mySbMsg"
    }
    Write-Host "📄 Message Properties:"
    if ($TriggerMetadata.UserProperties) {
        $TriggerMetadata.UserProperties | ConvertTo-Json -Depth 2 | Write-Host
    }
  
    Write-Host "⚙️ Processing message..."
    Start-Sleep -Seconds 2
    Write-Host "✅ Message processed successfully!"
    
} catch {
    Write-Error "❌ Error processing message: $($_.Exception.Message)"
    Write-Error "Stack Trace: $($_.Exception.StackTrace)"
    throw
}

Write-Host "🏁 Message processing completed."
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 