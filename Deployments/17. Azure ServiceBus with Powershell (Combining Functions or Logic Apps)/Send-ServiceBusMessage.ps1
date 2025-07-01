# Send-ServiceBusMessage.ps1
# PowerShell script to send messages to Azure ServiceBus Queue (for training purposes)
param(
    [Parameter(Mandatory=$true)]
    [string]$ConnectionString,
    
    [Parameter(Mandatory=$true)]
    [string]$QueueName,
    
    [Parameter(Mandatory=$false)]
    [string]$MessageContent = "Hello from PowerShell!",
    
    [Parameter(Mandatory=$false)]
    [int]$MessageCount = 1,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$UserProperties = @{}
)

Write-Host "🚌 Azure ServiceBus Message Publisher" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

try {   
    Write-Host "📦 Using REST API approach for ServiceBus messaging..." -ForegroundColor Yellow
    $connectionParams = @{}
    $ConnectionString -split ';' | ForEach-Object {
        if ($_ -match '(.+)=(.+)') {
            $connectionParams[$matches[1]] = $matches[2]
        }
    }
    
    $endpoint = $connectionParams['Endpoint']
    $sharedAccessKeyName = $connectionParams['SharedAccessKeyName']
    $sharedAccessKey = $connectionParams['SharedAccessKey']
    
    if (-not $endpoint -or -not $sharedAccessKeyName -or -not $sharedAccessKey) {
        throw "Invalid connection string format"
    }    
    
    # Remove sb:// or https:// and trailing /
    $namespace = $endpoint -replace '^sb://', '' -replace '^https://', '' -replace '/$', ''
    
    Write-Host "🔍 Debug Info:" -ForegroundColor Magenta
    Write-Host "   Endpoint: $endpoint" -ForegroundColor Gray
    Write-Host "   Namespace: $namespace" -ForegroundColor Gray
    Write-Host "   Key Name: $sharedAccessKeyName" -ForegroundColor Gray
    
    function New-SASToken {
        param($uri, $keyName, $key)
        
        $expiry = [DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()
        $stringToSign = [System.Web.HttpUtility]::UrlEncode($uri) + "`n" + $expiry
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($key)
        $signature = [Convert]::ToBase64String($hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign)))
        $signature = [System.Web.HttpUtility]::UrlEncode($signature)
        
        return "SharedAccessSignature sr=" + [System.Web.HttpUtility]::UrlEncode($uri) + "&sig=" + $signature + "&se=" + $expiry + "&skn=" + $keyName
    }
    
    for ($i = 1; $i -le $MessageCount; $i++) {
        try {            
            $currentMessage = if ($MessageCount -gt 1) { "$MessageContent (Message $i of $MessageCount)" } else { $MessageContent }
            
            $messageBody = @{
                message = $currentMessage
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                source = "PowerShell Publisher"
                messageNumber = $i
            }
            
            if ($UserProperties.Count -gt 0) {
                $messageBody.userProperties = $UserProperties
            }
            
            $jsonBody = $messageBody | ConvertTo-Json -Depth 3
            $uri = "https://$namespace/$QueueName/messages"
            $sasToken = New-SASToken -uri "https://$namespace/$QueueName" -keyName $sharedAccessKeyName -key $sharedAccessKey
            
            $headers = @{
                'Authorization' = $sasToken
                'Content-Type' = 'application/json'
                'BrokerProperties' = (@{
                    MessageId = [Guid]::NewGuid().ToString()
                    TimeToLive = 3600
                } | ConvertTo-Json -Compress)
            }            
         
            if ($UserProperties.Count -gt 0) {
                foreach ($prop in $UserProperties.GetEnumerator()) {
                    $headers["UserProperty.$($prop.Key)"] = $prop.Value
                }
            }
            
            Write-Host "📤 Sending message $i to queue: $QueueName" -ForegroundColor Green
            Write-Host "📋 Message content: $currentMessage" -ForegroundColor White
            
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
            
            Write-Host "✅ Message $i sent successfully!" -ForegroundColor Green
            Write-Host "🆔 Message ID: $($headers.BrokerProperties | ConvertFrom-Json | Select-Object -ExpandProperty MessageId)" -ForegroundColor Cyan
            
            if ($MessageCount -gt 1 -and $i -lt $MessageCount) {
                Start-Sleep -Milliseconds 500 
            }
            
        } catch {
            Write-Error "❌ Failed to send message $i`: $($_.Exception.Message)"
        }
    }
    
} catch {
    Write-Error "❌ Failed to initialize ServiceBus client: $($_.Exception.Message)"
    Write-Host "💡 Make sure you have the correct connection string and queue name." -ForegroundColor Yellow
    Write-Host "💡 Connection string format: Endpoint=sb://namespace.servicebus.windows.net/;SharedAccessKeyName=name;SharedAccessKey=key" -ForegroundColor Yellow
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏁 Message publishing completed!" -ForegroundColor Cyan

# Usage examples:
<#
# Send a simple message
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent "Hello World!"

# Send multiple messages
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent "Test Message" -MessageCount 5

# Send message with user properties
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent "Custom Message" -UserProperties @{ "priority" = "high"; "source" = "test" }

# Send JSON message
$jsonMessage = @{ name = "John Doe"; age = 30; city = "New York" } | ConvertTo-Json
.\Send-ServiceBusMessage.ps1 -ConnectionString "your-connection-string" -QueueName "messagequeue" -MessageContent $jsonMessage
#> 