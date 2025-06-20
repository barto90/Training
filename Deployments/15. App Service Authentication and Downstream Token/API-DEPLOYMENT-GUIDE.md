# API Deployment Guide

## Issue Resolution: "You do not have permission to view this directory or page"

This error occurred because the API was configured with mandatory authentication for ALL endpoints, including health checks. 

## Changes Made

1. **Added web.config** - Required for proper Node.js hosting on Azure App Service
2. **Updated authentication configuration** - Changed from `requireAuthentication: true` to `requireAuthentication: false`
3. **Implemented selective authentication** - Only API endpoints require authentication, health checks are public
4. **Fixed client secret handling** - Removed hardcoded placeholder value

## Deployment Steps

### Option 1: Deploy API Separately (Recommended)

1. **First, ensure you have your Azure AD App Registration ready:**
   - Client ID (GUID format)
   - Client Secret (keep this secure!)

2. **Deploy the API using PowerShell:**
   ```powershell
   .\deploy.ps1 -ResourceGroupName "your-rg" -AppServiceName "your-web-app" -StorageAccountName "yourstorageaccount" -ClientId "your-client-id" -DeployAPI $true -APIServiceName "your-api-name" -ClientSecret "your-client-secret"
   ```

3. **Deploy the Node.js code:**
   ```bash
   # Navigate to the API directory
   cd API
   
   # Create deployment package
   zip -r ../api.zip .
   
   # Deploy using Azure CLI
   az webapp deploy --resource-group "your-rg" --name "your-api-name" --src-path ../api.zip --type zip
   ```

### Option 2: Manual Deployment via Azure Portal

1. **Create the App Service** using the ARM template:
   ```bash
   az deployment group create --resource-group "your-rg" --template-file "api-deploy.json" --parameters apiServiceName="your-api" clientId="your-client-id" clientSecret="your-client-secret"
   ```

2. **Deploy code via Visual Studio Code or GitHub Actions**

## Testing the Deployment

After successful deployment, you should be able to access:

### Public Endpoints (No Authentication Required)
- `GET /` - Health check and basic info
- `GET /health` - Detailed health status  
- `GET /login` - Authentication information

### Protected Endpoints (Authentication Required)
- `GET /api/welcome` - Main API endpoint with user info
- `GET /api/auth-info` - Detailed authentication headers

## Expected Responses

### Success - Public Endpoint
```json
{
  "message": "API is running",
  "timestamp": "2024-01-20T10:30:00.000Z",
  "authenticated": false,
  "status": "healthy",
  "version": "1.0.0"
}
```

### Success - Protected Endpoint (after authentication)
```json
{
  "message": "Welcome from the API!",
  "timestamp": "2024-01-20T10:30:00.000Z",
  "authenticated": true,
  "user": {
    "userId": "user@domain.com",
    "userDetails": "John Doe",
    "identityProvider": "aad",
    "claims": [...]
  }
}
```

### Authentication Required Response
```json
{
  "error": "Authentication required",
  "message": "Please authenticate at /.auth/login/aad",
  "authUrl": "https://your-api.azurewebsites.net/.auth/login/aad"
}
```

## Troubleshooting

### Still getting permission errors?
1. **Check the web.config is deployed** - Should be in the root of your app
2. **Verify authentication settings** - Should be `requireAuthentication: false`
3. **Check App Service logs** - Use `az webapp log tail` to see real-time logs

### Authentication not working for protected endpoints?
1. **Verify Azure AD App Registration** - Must have correct redirect URIs
2. **Check client secret** - Must be valid and not expired
3. **Verify allowed audiences** - Should include both `api://your-client-id` and `your-client-id`

### Additional Azure AD Setup Required

1. **Add Redirect URIs to your App Registration:**
   - `https://your-api.azurewebsites.net/.auth/login/aad/callback`

2. **Configure API permissions if needed**

3. **Test authentication flow:**
   - Visit `https://your-api.azurewebsites.net/.auth/login/aad`
   - Should redirect to Microsoft login
   - After login, should redirect back to your API

## Security Notes

- The API now allows anonymous access to health endpoints while protecting business logic endpoints
- Always use Azure Key Vault for client secrets in production
- Monitor authentication logs for security incidents
- Consider implementing rate limiting for public endpoints 