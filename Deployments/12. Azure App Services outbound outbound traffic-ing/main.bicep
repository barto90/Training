@description('The name of the function app that you wish to create.')
param functionAppName string = ''

@description('The name of the storage account that will be used by the Function App')
param storageAccountName string = ''

@description('The runtime stack of the Function App')
@allowed([
  'dotnet'
  'node'
  'python'
  'java'
  'powershell'
])
param functionRuntime string = 'powershell'

@description('The version of the selected runtime stack')
param functionRuntimeVersion string = '~7.2'

@description('The SKU of the App Service Plan')
@allowed([
  'Y1' // Consumption
  'B1' // Basic
  'S1' // Standard
  'P1V2' // Premium V2
  'P1V3' // Premium V3
])
param appServicePlanSku string = 'Y1'

@description('Deploy a sample HTTP trigger function')
param deploySampleFunction bool = true

var hostingPlanName = 'plan-${functionAppName}'
var applicationInsightsName = 'ai-${functionAppName}'
var functionWorkerRuntime = functionRuntime
var location = resourceGroup().location

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
  }
}

// App Service Plan (consumption for Azure Functions)
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: appServicePlanSku
  }
  properties: {}
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Function App
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
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: functionRuntimeVersion
        }
      ]
    }
  }
}

// Deploy sample HTTP trigger function if enabled
resource httpTriggerFunction 'Microsoft.Web/sites/functions@2022-03-01' = if (deploySampleFunction) {
  parent: functionApp
  name: 'HttpTrigger'
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
      'run.ps1': loadTextContent('HttpTriggerFunction/run.ps1')
    }
  }
}

// Outputs
output functionAppName string = functionApp.name
output functionAppHostName string = functionApp.properties.defaultHostName
output functionAppIdentityPrincipalId string = functionApp.identity.principalId
output httpTriggerUrl string = deploySampleFunction ? 'https://${functionApp.properties.defaultHostName}/api/HttpTrigger' : ''
