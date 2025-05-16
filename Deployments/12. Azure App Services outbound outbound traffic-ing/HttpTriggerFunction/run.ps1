using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

write-host "Checking public IP";

$publicIPAddress = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip

$body = "";
if ($publicIPAddress) {
    $body = "Public IP: $publicIPAddress"
} else {
    $body = "Unable to validate public IP";
}

write-host $body;

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})

