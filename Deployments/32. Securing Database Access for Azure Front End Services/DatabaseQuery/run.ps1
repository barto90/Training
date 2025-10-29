using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "🔒 Database Query Function Started"
Write-Host "📅 Timestamp: $(Get-Date)"
Write-Host "🆔 Invocation ID: $($TriggerMetadata.InvocationId)"

# Get configuration from environment variables
$sqlServerName = $env:SqlServerName
$sqlDatabaseName = $env:SqlDatabaseName

Write-Host "🗄️ SQL Server: $sqlServerName"
Write-Host "💾 Database: $sqlDatabaseName"

$body = @{
    success = $false
    message = ""
    data = $null
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

try {
    # Install SqlServer module if not already installed
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Host "📦 Installing SqlServer module..."
        Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
    }
    
    Import-Module SqlServer -ErrorAction Stop
    Write-Host "✅ SqlServer module loaded"

    # Get managed identity access token for Azure SQL Database
    Write-Host "🔑 Requesting Azure AD access token for SQL Database..."
    
    $resourceURI = "https://database.windows.net/"
    $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
    $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"=$env:IDENTITY_HEADER} -Uri $tokenAuthURI
    $accessToken = $tokenResponse.access_token
    
    if ($accessToken) {
        Write-Host "✅ Access token obtained successfully"
    } else {
        throw "Failed to obtain access token from managed identity"
    }

    # Parse query parameters or body
    $action = $Request.Query.action
    if (-not $action) {
        $action = $Request.Body.action
    }
    if (-not $action) {
        $action = "read"  # Default to read operation
    }

    Write-Host "⚙️ Action: $action"

    # Build connection string (no password needed with token auth)
    $connectionString = "Server=$sqlServerName; Database=$sqlDatabaseName; Encrypt=True; TrustServerCertificate=False; Connection Timeout=30;"
    
    Write-Host "🔌 Connecting to database using managed identity..."
    
    # Create SQL connection
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.AccessToken = $accessToken
    
    $connection.Open()
    Write-Host "✅ Database connection established"

    # Execute query based on action
    $command = $connection.CreateCommand()
    
    switch ($action.ToLower()) {
        "read" {
            Write-Host "📖 Executing SELECT query..."
            $command.CommandText = "SELECT TOP 10 Id, Name, Email, CreatedDate FROM Users ORDER BY CreatedDate DESC"
            
            $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
            $dataSet = New-Object System.Data.DataSet
            $adapter.Fill($dataSet) | Out-Null
            
            $results = @()
            foreach ($row in $dataSet.Tables[0].Rows) {
                $results += @{
                    Id = $row["Id"]
                    Name = $row["Name"]
                    Email = $row["Email"]
                    CreatedDate = $row["CreatedDate"].ToString("yyyy-MM-dd HH:mm:ss")
                }
            }
            
            $body.data = $results
            $body.message = "Successfully retrieved $($results.Count) records"
            Write-Host "✅ Retrieved $($results.Count) records"
        }
        
        "write" {
            # Get data from request
            $name = $Request.Query.name
            $email = $Request.Query.email
            if (-not $name) { $name = $Request.Body.name }
            if (-not $email) { $email = $Request.Body.email }
            
            if (-not $name -or -not $email) {
                throw "Name and email are required for write operation"
            }
            
            Write-Host "✍️ Executing INSERT query..."
            Write-Host "  Name: $name"
            Write-Host "  Email: $email"
            
            $command.CommandText = "INSERT INTO Users (Name, Email) VALUES (@Name, @Email); SELECT SCOPE_IDENTITY() AS NewId"
            $command.Parameters.AddWithValue("@Name", $name) | Out-Null
            $command.Parameters.AddWithValue("@Email", $email) | Out-Null
            
            $newId = $command.ExecuteScalar()
            
            $body.data = @{
                Id = [int]$newId
                Name = $name
                Email = $email
            }
            $body.message = "Successfully inserted new record with ID: $newId"
            Write-Host "✅ Inserted new record with ID: $newId"
        }
        
        "update" {
            # Get data from request
            $id = $Request.Query.id
            $name = $Request.Query.name
            $email = $Request.Query.email
            if (-not $id) { $id = $Request.Body.id }
            if (-not $name) { $name = $Request.Body.name }
            if (-not $email) { $email = $Request.Body.email }
            
            if (-not $id) {
                throw "ID is required for update operation"
            }
            
            Write-Host "🔄 Executing UPDATE query..."
            Write-Host "  ID: $id"
            
            $updateParts = @()
            if ($name) { 
                $updateParts += "Name = @Name"
                $command.Parameters.AddWithValue("@Name", $name) | Out-Null
            }
            if ($email) { 
                $updateParts += "Email = @Email"
                $command.Parameters.AddWithValue("@Email", $email) | Out-Null
            }
            
            if ($updateParts.Count -eq 0) {
                throw "At least one field (name or email) must be provided for update"
            }
            
            $command.CommandText = "UPDATE Users SET $($updateParts -join ', ') WHERE Id = @Id"
            $command.Parameters.AddWithValue("@Id", [int]$id) | Out-Null
            
            $rowsAffected = $command.ExecuteNonQuery()
            
            $body.data = @{
                Id = [int]$id
                RowsAffected = $rowsAffected
            }
            $body.message = "Successfully updated $rowsAffected record(s)"
            Write-Host "✅ Updated $rowsAffected record(s)"
        }
        
        "count" {
            Write-Host "📊 Executing COUNT query..."
            $command.CommandText = "SELECT COUNT(*) as TotalUsers FROM Users"
            
            $count = $command.ExecuteScalar()
            
            $body.data = @{
                TotalUsers = [int]$count
            }
            $body.message = "Successfully retrieved count"
            Write-Host "✅ Total users: $count"
        }
        
        default {
            throw "Invalid action: $action. Supported actions: read, write, update, count"
        }
    }
    
    $connection.Close()
    Write-Host "🔌 Database connection closed"
    
    $body.success = $true
    $statusCode = [HttpStatusCode]::OK

} catch {
    Write-Error "❌ Error occurred: $($_.Exception.Message)"
    Write-Error "Stack Trace: $($_.Exception.StackTrace)"
    
    $body.success = $false
    $body.message = "Error: $($_.Exception.Message)"
    $body.error = @{
        type = $_.Exception.GetType().FullName
        message = $_.Exception.Message
        stackTrace = $_.Exception.StackTrace
    }
    $statusCode = [HttpStatusCode]::InternalServerError
}

Write-Host "🏁 Function execution completed"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Return response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = $body | ConvertTo-Json -Depth 10
    Headers = @{
        "Content-Type" = "application/json"
    }
})

