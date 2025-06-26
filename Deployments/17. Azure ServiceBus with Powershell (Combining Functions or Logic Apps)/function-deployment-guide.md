# 🚀 Function Code Deployment Guide

The ARM template creates the **infrastructure** only. You need to deploy the **function code** separately.

## 🎯 Quick Start (Azure Portal Method)

### Step 1: Navigate to your Function App
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your Function App: **Resource Groups** → **[Your RG]** → **[Function App Name]**

### Step 2: Create the Function
1. Click **"Functions"** in the left menu
2. Click **"Create"** button
3. Select **"ServiceBus Queue trigger"**
4. Configure:
   - **Function name**: `ServiceBusQueueProcessor`
   - **Connection string setting**: `ServiceBusConnection` 
   - **Queue name**: `messagequeue`
5. Click **"Create"**

### Step 3: Update Function Code
1. Click on your newly created function
2. Go to **"Code + Test"** tab
3. **Replace** the default `run.ps1` content with:

```powershell
# PowerShell script for processing ServiceBus messages
using namespace System.Net

param($QueueItem, $TriggerMetadata)

# Log the incoming message
Write-Host "🚌 ServiceBus Message Received!"
Write-Host "📅 Timestamp: $(Get-Date)"
Write-Host "🆔 Message ID: $($TriggerMetadata.MessageId)"
Write-Host "📋 Message Content: $QueueItem"
Write-Host "📊 Delivery Count: $($TriggerMetadata.DeliveryCount)"
Write-Host "⏰ Enqueued Time: $($TriggerMetadata.EnqueuedTimeUtc)"

# Process the message content
try {
    # Convert message if it's JSON
    if ($QueueItem -match '^[\{\[].*[\}\]]$') {
        $messageObject = $QueueItem | ConvertFrom-Json
        Write-Host "✅ Successfully parsed JSON message:"
        $messageObject | ConvertTo-Json -Depth 3 | Write-Host
    } else {
        Write-Host "📝 Plain text message: $QueueItem"
    }
    
    # Log additional metadata
    Write-Host "📄 Message Properties:"
    if ($TriggerMetadata.UserProperties) {
        $TriggerMetadata.UserProperties | ConvertTo-Json -Depth 2 | Write-Host
    }
    
    # Simulate message processing
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
```

4. Click **"Save"**

### Step 4: Update function.json (if needed)
1. Click on **"function.json"** tab
2. **Replace** content with:

```json
{
  "bindings": [
    {
      "name": "QueueItem",
      "type": "serviceBusTrigger",
      "direction": "in",
      "queueName": "%ServiceBusQueueName%",
      "connection": "ServiceBusConnection"
    }
  ]
}
```

3. Click **"Save"**

## 🧪 Test Your Function

### Step 1: Get ServiceBus Connection String
1. Go to your **ServiceBus Namespace**
2. Click **"Shared access policies"**
3. Click **"RootManageSharedAccessKey"**
4. Copy the **"Primary Connection String"**

### Step 2: Send Test Message
Use the PowerShell script:

```powershell
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string-here" -QueueName "messagequeue" -MessageContent "Hello World!"
```

### Step 3: Check Function Logs
1. Go to your Function App → **Functions** → **ServiceBusQueueProcessor**
2. Click **"Monitor"** tab
3. You should see the function execution logs with your message processing output

## 🔍 Troubleshooting

### Function Not Triggering?
- ✅ Check if ServiceBus connection string is correct in Function App configuration
- ✅ Verify queue name matches (`messagequeue`)
- ✅ Ensure Function App is running (not stopped)

### Messages Going to Dead Letter Queue?
- ✅ Check function logs for errors
- ✅ Verify function code syntax is correct
- ✅ Check if there are any binding errors

### Can't See Logs?
- ✅ Check Application Insights is connected
- ✅ Try the **"Live Metrics"** view for real-time logs
- ✅ Use **"Logs"** section for detailed telemetry

## 🎉 Success!

When working correctly, you'll see logs like this:
```
🚌 ServiceBus Message Received!
📅 Timestamp: 2024-01-15 10:30:45
🆔 Message ID: 12345678-1234-5678-9abc-123456789abc
📋 Message Content: Hello World!
📊 Delivery Count: 1
⏰ Enqueued Time: 2024-01-15 10:30:44
📝 Plain text message: Hello World!
⚙️ Processing message...
✅ Message processed successfully!
🏁 Message processing completed.
``` 