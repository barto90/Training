@description('The name of the app service that you wish to create.')
param appServiceName string

@description('The name of the storage account that will be used by the App Service')
param storageAccountName string

@description('The SKU of the App Service Plan')
@allowed([
  'F1'
  'B1'
  'S1'
  'P1V2'
  'P1V3'
])
param appServicePlanSku string = 'B1'

@description('The Azure AD tenant ID for authentication')
param tenantId string = subscription().tenantId

@description('The Azure AD client ID (App Registration) for authentication')
param clientId string

@description('The Azure AD client secret for authentication')
@secure()
param clientSecret string

@description('Deploy a sample web application')
param deploySampleApp bool = true

@description('Deploy the Node.js API application')
param deployAPI bool = true

@description('The name of the API app service (optional, will default to appServiceName-api)')
param apiServiceName string = '${appServiceName}-api'

var hostingPlanName = 'plan-${appServiceName}'
var location = resourceGroup().location
var applicationInsightsName = 'ai-${appServiceName}'
var apiApplicationInsightsName = 'ai-${apiServiceName}'

// Load sample app code from external file
var indexHtmlContent = loadTextContent('WebApp/index.html')
var webConfigContent = loadTextContent('WebApp/web.config')

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

// Application Insights for Web App
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Application Insights for API
resource apiApplicationInsights 'Microsoft.Insights/components@2020-02-02' = if (deployAPI) {
  name: apiApplicationInsightsName
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

// Web App Service with System Assigned Managed Identity
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
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
      defaultDocuments: [
        'index.html'
        'Default.htm'
        'Default.html'
        'Default.asp'
        'index.htm'
        'iisstart.htm'
        'default.aspx'
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
      ]
    }
  }
}

// API App Service with System Assigned Managed Identity
resource apiService 'Microsoft.Web/sites@2022-03-01' = if (deployAPI) {
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
          value: deployAPI ? apiApplicationInsights.properties.InstrumentationKey : ''
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: deployAPI ? apiApplicationInsights.properties.ConnectionString : ''
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

// Configure Azure AD Authentication for Web App
resource appServiceAuth 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'authsettingsV2'
  parent: appService
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'azureActiveDirectory'
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
          openIdIssuer: 'https://sts.windows.net/${tenantId}/'
          clientId: clientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
        }
        login: {
          scopes: [
            'openid'
            'profile'
            'email'
            'api://${clientId}/API.Access'
          ]
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

// Configure Azure AD Authentication for API - DISABLED for testing
/*
resource apiServiceAuth 'Microsoft.Web/sites/config@2022-03-01' = if (deployAPI) {
  name: 'authsettingsV2'
  parent: apiService
  properties: {
    globalValidation: {
      requireAuthentication: false
      unauthenticatedClientAction: 'AllowAnonymous'
      excludedPaths: []
    }
    platform: {
      enabled: false
    }
    httpSettings: {
      requireHttps: true
      routes: {
        apiPrefix: '/.auth'
      }
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: false
        registration: {
          openIdIssuer: 'https://sts.windows.net/${tenantId}/'
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
*/

// Deploy sample web files (conditional)
resource webFiles 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = if (deploySampleApp) {
  name: 'web'
  parent: appService
  properties: {
    deploymentRollbackEnabled: false
    isManualIntegration: true
    isGitHubAction: false
  }
}

// Outputs
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.name}.azurewebsites.net'
output managedIdentityPrincipalId string = appService.identity.principalId
output authLoginUrl string = 'https://${appService.name}.azurewebsites.net/.auth/login/aad'
output authLogoutUrl string = 'https://${appService.name}.azurewebsites.net/.auth/logout'

// API Outputs (conditional)
output apiServiceName string = deployAPI ? apiService.name : ''
output apiServiceUrl string = deployAPI ? 'https://${apiService.name}.azurewebsites.net' : ''
output apiManagedIdentityPrincipalId string = deployAPI ? apiService.identity.principalId : ''
output apiAuthLoginUrl string = deployAPI ? 'https://${apiService.name}.azurewebsites.net/.auth/login/aad' : ''
output apiWelcomeUrl string = deployAPI ? 'https://${apiService.name}.azurewebsites.net/api/welcome' : '' 
