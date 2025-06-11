@description('The name of the function app that you wish to create.')
param functionAppName string

@description('The name of the storage account that will be used by the Function App')
param storageAccountName string

@description('The SKU of the App Service Plan (P1V2 = Premium V2)')
@allowed([
  'Y1'
  'B1'
  'S1'
  'P1V2'
  'P1V3'
])
param appServicePlanSku string = 'P1V2'

@description('Deploy a sample Microsoft Graph PowerShell function')
param deploySampleFunction bool = true

var hostingPlanName = 'plan-${functionAppName}'
var location = resourceGroup().location
var applicationInsightsName = 'ai-${functionAppName}'

// PowerShell code for the sample Graph API function
var httpTriggerGraphCode = '''using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function with Managed Identity processed a request."

# Get the managed identity token for Microsoft Graph
try {
    $resourceURI = "https://graph.microsoft.com/"
    $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
    $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"=$env:IDENTITY_HEADER} -Uri $tokenAuthURI
    $accessToken = $tokenResponse.access_token
    
    Write-Host "Successfully obtained access token for Microsoft Graph"
    
    # Example: Get current user information (requires User.Read permission)
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type' = 'application/json'
    }
    
    # You can uncomment this to test Graph API call
    # $userInfo = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Headers $headers
    
    $body = @{
        status = "success"
        message = "Managed Identity authentication successful"
        tokenObtained = $true
        # userInfo = $userInfo
    } | ConvertTo-Json
    
} catch {
    Write-Host "Error obtaining token: $($_.Exception.Message)"
    $body = @{
        status = "error"
        message = "Failed to obtain access token: $($_.Exception.Message)"
        tokenObtained = $false
    } | ConvertTo-Json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    Headers = @{
        "Content-Type" = "application/json"
    }
})'''

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// App Service Plan
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: appServicePlanSku
    tier: appServicePlanSku == 'Y1' ? 'Dynamic' : 'PremiumV2'
    size: appServicePlanSku
    family: appServicePlanSku == 'Y1' ? 'Y' : 'Pv2'
    capacity: appServicePlanSku == 'Y1' ? 0 : 1
  }
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: appServicePlanSku == 'Y1' ? 200 : 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

// Function App with System Assigned Managed Identity
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~7.2'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
      ]
    }
  }
}

// Sample Microsoft Graph Function (conditional)
resource graphAPITrigger 'Microsoft.Web/sites/functions@2022-03-01' = if (deploySampleFunction) {
  name: 'GraphAPITrigger'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          authLevel: 'anonymous'
          type: 'httpTrigger'
          direction: 'in'
          name: 'Request'
          methods: [
            'get'
            'post'
          ]
        }
        {
          type: 'http'
          direction: 'out'
          name: 'Response'
        }
      ]
    }
    files: {
      'run.ps1': httpTriggerGraphCode
    }
  }
}

// Outputs
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.name}.azurewebsites.net'
output graphAPITriggerUrl string = 'https://${functionApp.name}.azurewebsites.net/api/GraphAPITrigger'
output managedIdentityPrincipalId string = functionApp.identity.principalId 
