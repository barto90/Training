@description('The name of the API app service')
param apiServiceName string

@description('The Azure AD client ID (App Registration) for authentication')
param clientId string

@description('The Azure AD client secret for authentication')
@secure()
param clientSecret string

@description('The SKU of the App Service Plan')
@allowed([
  'F1'
  'B1'
  'S1'
  'P1V2'
  'P1V3'
])
param appServicePlanSku string = 'B1'

var hostingPlanName = 'plan-${apiServiceName}'
var location = resourceGroup().location
var applicationInsightsName = 'ai-${apiServiceName}'

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
    tier: appServicePlanSku == 'F1' ? 'Free' : (appServicePlanSku == 'B1' ? 'Basic' : 'Standard')
    size: appServicePlanSku
    family: appServicePlanSku == 'F1' ? 'F' : (appServicePlanSku == 'B1' ? 'B' : 'S')
    capacity: 1
  }
  properties: {
    perSiteScaling: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

// API App Service with System Assigned Managed Identity
resource apiService 'Microsoft.Web/sites@2022-03-01' = {
  name: apiServiceName
  location: location
  kind: 'app'
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
      nodeVersion: '~18'
      defaultDocuments: [
        'server.js'
        'index.js'
        'app.js'
      ]
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
          value: clientSecret
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '0'
        }
      ]
    }
  }
}

// Configure Azure AD Authentication for API
resource apiServiceAuth 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'authsettingsV2'
  parent: apiService
  properties: {
    globalValidation: {
      requireAuthentication: false
      unauthenticatedClientAction: 'AllowAnonymous'
    }
    httpSettings: {
      requireHttps: true
      routes: {
        apiPrefix: '/.auth'
      }
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: 'https://sts.windows.net/${subscription().tenantId}/'
          clientId: clientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
        }
        validation: {
          jwtClaimChecks: {}
          allowedAudiences: [
            'api://${clientId}'
            clientId
          ]
        }
      }
    }
    login: {
      routes: {
        logoutEndpoint: '/.auth/logout'
      }
      tokenStore: {
        enabled: true
        tokenRefreshExtensionHours: 72
        fileSystem: {
          directory: '/home/data/.auth'
        }
      }
      preserveUrlFragmentsForLogins: false
      allowedExternalRedirectUrls: []
      cookieExpiration: {
        convention: 'FixedTime'
        timeToExpiration: '08:00:00'
      }
      nonce: {
        validateNonce: true
        nonceExpirationInterval: '00:05:00'
      }
    }
  }
}

// Outputs
output apiServiceName string = apiService.name
output apiServiceUrl string = 'https://${apiService.name}.azurewebsites.net'
output managedIdentityPrincipalId string = apiService.identity.principalId
output authLoginUrl string = 'https://${apiService.name}.azurewebsites.net/.auth/login/aad'
output apiWelcomeUrl string = 'https://${apiService.name}.azurewebsites.net/api/welcome' 
