@description('The name of the function app that you wish to create.')
param functionAppName string = 'func-${uniqueString(resourceGroup().id)}'

@description('The name of the storage account that will be used by the Function App')
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'

@description('The runtime stack of the Function App')
@allowed([
  'dotnet'
  'node'
  'python'
  'java'
  'powershell'
])
param functionRuntime string = 'dotnet'

@description('The version of the selected runtime stack')
param functionRuntimeVersion string = '6'

@description('The SKU of the App Service Plan (Y1 = Consumption Plan)')
@allowed([
  'Y1'
  'B1'
  'S1'
  'P1V2'
  'P1V3'
])
param appServicePlanSku string = 'Y1'

@description('Deploy a sample HTTP trigger function')
param deploySampleFunction bool = true

var hostingPlanName = 'plan-${functionAppName}'
var functionWorkerRuntime = functionRuntime
var location = resourceGroup().location
var applicationInsightsName = 'ai-${functionAppName}'

var httpTriggerCSharpCode = '''using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Function
{
    public static class HttpTrigger
    {
        [FunctionName("HttpTrigger")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string name = req.Query["name"];

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            name = name ?? data?.name;

            string responseMessage = string.IsNullOrEmpty(name)
                ? "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."
                : $"Hello, {name}. This HTTP triggered function executed successfully.";

            return new OkObjectResult(responseMessage);
        }
    }
}'''

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
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
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
          value: functionWorkerRuntime
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: functionRuntime == 'node' ? '~18' : functionRuntimeVersion
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

// Sample HTTP Trigger Function (conditional)
resource httpTriggerFunction 'Microsoft.Web/sites/functions@2022-03-01' = if (deploySampleFunction) {
  name: 'HttpTrigger'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          authLevel: 'anonymous'
          type: 'httpTrigger'
          direction: 'in'
          name: 'req'
          methods: [
            'get'
            'post'
          ]
        }
        {
          type: 'http'
          direction: 'out'
          name: '$return'
        }
      ]
    }
    files: {
      'run.csx': httpTriggerCSharpCode
    }
  }
}

// Outputs
output functionAppName string = functionAppName
output functionAppUrl string = 'https://${functionAppName}.azurewebsites.net'
output httpTriggerUrl string = 'https://${functionAppName}.azurewebsites.net/api/HttpTrigger' 
