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

// Load PowerShell code from external file
var httpTriggerGraphCode = loadTextContent('GraphAPITrigger/run.ps1')
var functionConfig = loadTextContent('GraphAPITrigger/function.json')

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
    config: json(functionConfig)
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
