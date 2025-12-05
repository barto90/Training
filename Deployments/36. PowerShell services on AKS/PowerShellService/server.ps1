# PowerShell Web Service using Pode Framework
# This service demonstrates a simple REST API running on AKS

Import-Module Pode

# Start the Pode server
Start-PodeServer {
    # Add HTTP endpoint on port 8080
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Http
    
    # Enable logging
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging
    
    # Health check endpoint (required for Kubernetes probes)
    Add-PodeRoute -Method Get -Path '/health' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            status = "healthy"
            timestamp = (Get-Date).ToString("o")
            version = "1.0.0"
            service = "PowerShell-AKS-Service"
        }
    }
    
    # Readiness check endpoint
    Add-PodeRoute -Method Get -Path '/ready' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            ready = $true
            timestamp = (Get-Date).ToString("o")
        }
    }
    
    # API info endpoint
    Add-PodeRoute -Method Get -Path '/api/info' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            message = "Hello from PowerShell on AKS!"
            hostname = $env:HOSTNAME
            platform = $PSVersionTable.Platform
            psVersion = $PSVersionTable.PSVersion.ToString()
            os = $PSVersionTable.OS
            timestamp = (Get-Date).ToString("o")
            podName = $env:HOSTNAME
            podIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
        }
    }
    
    # Echo endpoint - returns what you send
    Add-PodeRoute -Method Post -Path '/api/echo' -ScriptBlock {
        $data = $WebEvent.Data
        
        Write-PodeJsonResponse -Value @{
            received = $data
            echo = "Message received successfully"
            timestamp = (Get-Date).ToString("o")
            contentType = $WebEvent.ContentType
        }
    }
    
    # Process data endpoint - example data transformation
    Add-PodeRoute -Method Post -Path '/api/process' -ScriptBlock {
        $data = $WebEvent.Data
        
        # Example: Transform the data
        $processed = @{
            original = $data
            uppercase = if ($data.text) { $data.text.ToUpper() } else { $null }
            wordCount = if ($data.text) { ($data.text -split '\s+').Count } else { 0 }
            timestamp = (Get-Date).ToString("o")
            processedBy = $env:HOSTNAME
        }
        
        Write-PodeJsonResponse -Value $processed
    }
    
    # Azure resource info endpoint (requires managed identity)
    Add-PodeRoute -Method Get -Path '/api/azure/info' -ScriptBlock {
        try {
            # This would work if managed identity is configured
            # Connect-AzAccount -Identity -ErrorAction Stop
            
            Write-PodeJsonResponse -Value @{
                message = "Azure integration endpoint"
                note = "Configure managed identity to enable Azure resource access"
                timestamp = (Get-Date).ToString("o")
            }
        }
        catch {
            Write-PodeJsonResponse -Value @{
                error = $_.Exception.Message
                timestamp = (Get-Date).ToString("o")
            } -StatusCode 500
        }
    }
    
    # List all available routes
    Add-PodeRoute -Method Get -Path '/api/routes' -ScriptBlock {
        $routes = @(
            @{ method = "GET"; path = "/health"; description = "Health check endpoint" }
            @{ method = "GET"; path = "/ready"; description = "Readiness check endpoint" }
            @{ method = "GET"; path = "/api/info"; description = "Service information" }
            @{ method = "POST"; path = "/api/echo"; description = "Echo back the request body" }
            @{ method = "POST"; path = "/api/process"; description = "Process and transform data" }
            @{ method = "GET"; path = "/api/azure/info"; description = "Azure integration info" }
            @{ method = "GET"; path = "/api/routes"; description = "List all routes" }
        )
        
        Write-PodeJsonResponse -Value @{
            service = "PowerShell-AKS-Service"
            routes = $routes
            timestamp = (Get-Date).ToString("o")
        }
    }
    
    # Error handling example
    Add-PodeRoute -Method Get -Path '/api/error' -ScriptBlock {
        throw "This is a test error"
    }
    
    # Root endpoint
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            message = "Welcome to PowerShell on AKS!"
            version = "1.0.0"
            endpoints = @{
                health = "/health"
                info = "/api/info"
                routes = "/api/routes"
            }
            timestamp = (Get-Date).ToString("o")
        }
    }
}

Write-Host "PowerShell web service stopped" -ForegroundColor Red




