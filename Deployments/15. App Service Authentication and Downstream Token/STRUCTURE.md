# 📁 Project Structure

This deployment demonstrates a complete Azure App Service solution with both web application and API service, featuring clean architecture, production-ready code, and automated deployment.

## 📂 File Organization

```
15. App Service Authentication and Downstream Token/
├── 🌐 WebApp/                       # Web Application (Frontend)
│   ├── index.html                   # Production-ready web app with token inspection
│   └── web.config                   # IIS configuration with security headers
├── 🔗 API/                          # API Service (Backend)
│   ├── server.js                    # Clean Node.js API server
│   ├── package.json                 # Node.js dependencies
│   ├── package-lock.json            # Dependency lock file
│   ├── web.config                   # Node.js IIS configuration
│   └── .deployment                  # Azure deployment configuration
├── 🏗️ Infrastructure/
│   ├── main.bicep                   # Web app infrastructure template
│   ├── api-main.bicep               # API infrastructure template
│   ├── azuredeploy.json             # Generated ARM template (web app)
│   ├── api-deploy.json              # Generated ARM template (API)
│   └── parameters.json              # Deployment parameters
├── 🚀 Deployment/
│   ├── deploy.ps1                   # Complete automated deployment script
│   ├── deploy-to-azure.html         # Web deployment interface
│   └── azuredeploy.visualizer.html  # Architecture visualization
├── 📚 Documentation/
│   ├── README.md                    # Complete deployment guide
│   ├── STRUCTURE.md                 # This file
│   └── API-DEPLOYMENT-GUIDE.md      # API-specific deployment guide
```

## 🏗️ Architecture Components

### 🌐 Web Application (Frontend)
- **Technology**: HTML5, CSS3, JavaScript (ES6+)
- **Authentication**: Azure AD integration with token inspection
- **Features**: 
  - Real-time authentication status
  - Complete JWT token display
  - Claims table with all user information
  - Live API testing interface
  - Token copy functionality
- **Security**: HTTPS enforcement, security headers, CORS configuration

### 🔗 API Service (Backend)
- **Technology**: Node.js with Express framework
- **Authentication**: Bearer token validation via App Service Easy Auth
- **Features**:
  - Health check endpoints
  - Protected API endpoints
  - User claims processing
  - CORS configuration for web app communication
- **Security**: Token validation, secure headers, error handling

## 🚀 Deployment Architecture

### Infrastructure as Code
- **Bicep Templates**: Separate templates for web app and API
- **ARM Templates**: Generated from Bicep for compatibility
- **Parameters**: Configurable deployment settings
- **Resource Groups**: Organized Azure resource management

### Automated Deployment Process
1. **Infrastructure Deployment**: Creates Azure resources
2. **Code Deployment**: Automatically deploys application code
3. **Configuration**: Sets up authentication and app settings
4. **Validation**: Verifies deployment success

## 🔧 Technical Implementation

### Web App Features
```javascript
// Authentication status check
async function checkAuthStatus() {
    const response = await fetch('/.auth/me');
    const authData = await response.json();
    // Process user data and tokens
}

// API communication with Bearer token
async function callDownstreamAPI() {
    const response = await fetch('https://api-service.azurewebsites.net/api/welcome', {
        headers: {
            'Authorization': `Bearer ${idToken}`,
            'Content-Type': 'application/json'
        }
    });
}
```

### API Service Features
```javascript
// Token validation and user extraction
app.get('/api/welcome', (req, res) => {
    const clientPrincipal = req.headers['x-ms-client-principal'];
    const userInfo = JSON.parse(Buffer.from(clientPrincipal, 'base64').toString('utf-8'));
    
    res.json({
        message: "API CALL SUCCESSFUL!",
        authenticated: true,
        user: userInfo
    });
});
```

## 🛡️ Security Implementation

### Web App Security
- **Authentication**: Required for all pages
- **Token Storage**: Secure App Service token store
- **HTTPS**: Enforced for all connections
- **Headers**: Security headers via web.config

### API Security
- **Token Validation**: Bearer token validation
- **CORS**: Configured for web app communication
- **Headers**: Security headers and error handling
- **Claims Processing**: Automatic user claims extraction

## 📊 Monitoring & Observability

### Application Insights Integration
- **Web App Monitoring**: User behavior, performance, errors
- **API Monitoring**: Request/response times, error rates
- **Authentication Metrics**: Login success/failure rates
- **Custom Telemetry**: Business-specific metrics

### Health Checks
- **Web App**: Authentication status monitoring
- **API**: Service health endpoints (`/health`)
- **Infrastructure**: Azure resource health monitoring

## 🔄 Development Workflow

### Local Development
1. **Web App**: Edit HTML/CSS/JavaScript files directly
2. **API**: Standard Node.js development with `npm start`
3. **Testing**: Use development tools and debuggers
4. **Deployment**: Automated via PowerShell script

### Production Deployment
1. **Code Cleanup**: No debug statements or comments
2. **Optimization**: Minified and production-ready code
3. **Security**: All security headers and HTTPS enforcement
4. **Monitoring**: Full Application Insights integration

## 🎯 Key Improvements Made

### ✅ Code Quality
- **Removed**: All debug console.log statements
- **Removed**: Unnecessary comments and debug code
- **Cleaned**: Production-ready, optimized code
- **Organized**: Clear separation of concerns

### ✅ Deployment Process
- **Automated**: Complete infrastructure and code deployment
- **Validated**: Deployment success verification
- **Optimized**: Parallel deployment where possible
- **Documented**: Clear deployment instructions

### ✅ Architecture
- **Scalable**: Separate web app and API services
- **Secure**: Production-ready security configuration
- **Monitored**: Comprehensive monitoring and logging
- **Maintainable**: Clean, well-structured code

## 🚀 Usage Examples

### Complete Deployment
```powershell
.\deploy.ps1 -ResourceGroupName "my-rg" -AppServiceName "my-app" -APIServiceName "my-api" -StorageAccountName "mystorage123" -ClientId "client-id" -ClientSecret "client-secret"
```

### Web App Customization
```html
<!-- Edit WebApp/index.html -->
<div class="custom-feature">
    <h3>My Custom Feature</h3>
    <button onclick="myCustomFunction()">Custom Action</button>
</div>
```

### API Extension
```javascript
// Add to API/server.js
app.get('/api/custom', (req, res) => {
    res.json({ message: 'Custom endpoint' });
});
```

## 🔗 Integration Points

### Authentication Flow
1. **User Login**: Azure AD authentication via web app
2. **Token Issuance**: ID token stored in App Service token store
3. **API Calls**: Bearer token passed to API service
4. **Token Validation**: API validates token via Easy Auth headers

### Service Communication
- **Web App → API**: Bearer token authentication
- **API → Azure AD**: Token validation and user claims
- **Both → App Insights**: Telemetry and monitoring data

## 📚 Related Documentation

- **README.md**: Complete deployment and usage guide
- **API-DEPLOYMENT-GUIDE.md**: API-specific deployment instructions
- **Azure Documentation**: Official Azure App Service auth docs

This structure provides a complete, production-ready solution for Azure App Service authentication with downstream API communication! 🚀 