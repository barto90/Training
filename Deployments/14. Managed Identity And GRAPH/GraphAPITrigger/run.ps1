using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "PowerShell HTTP trigger function with Managed Identity processed a request"

$resourceURI =  "https://graph.microsoft.com/"
$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"

write-host "Using token URI: $($tokenAuthURI)";

$headers = @{
 'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER
}

$tokenResponse = Invoke-RestMethod -Method Get -Headers $headers -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

write-host "Successfully obtained access token for Microsoft Graph!"
write-host "Token is: $($accessToken)"


$graphUri = "https://graph.microsoft.com/v1.0/users"

$graphHeaders = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type'  = 'application/json'
}

    $graphResponse = Invoke-RestMethod -Method Get -Uri $graphUri -Headers $graphHeaders

    Write-Host "Successfully retrieved users from Microsoft Graph"

    # Optional: log the first few user display names
    $graphResponse.value[0..2] | ForEach-Object {
        Write-Host "User: $($_.displayName) - $($_.userPrincipalName)"
    }

    $body = @{
        status = "success"
        message = "Retrieved users"
        users = $graphResponse.value[0..4]  # Only show a few for the response
    } | ConvertTo-Json -Depth 4



