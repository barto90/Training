# 📁 Project Structure

This deployment uses a clean, maintainable structure with separate files for web application code:

## 📂 File Organization

```
15. App Service Authentication and Downstream Token/
├── 📄 azuredeploy.json              # ARM template (generated from Bicep)
├── 📄 main.bicep                    # Main Bicep template (uses loadTextContent)
├── 📄 parameters.json               # Sample deployment parameters
├── 📄 deploy.ps1                    # PowerShell deployment script
├── 📄 deploy-to-azure.html          # Web deployment interface
├── 📄 azuredeploy.visualizer.html   # Architecture visualization
├── 📄 README.md                     # Comprehensive documentation
├── 📄 STRUCTURE.md                  # This file
└── 📁 WebApp/                       # Web application folder
    ├── 📄 index.html                # Authentication demo web page
    └── 📄 web.config                # IIS configuration
```

## 🚀 Improvements Made

### ✅ Before (Inline Content)
- HTML content was embedded in ARM/Bicep templates
- Escape characters made content hard to read
- Difficult to maintain and style
- No proper web development experience

### ✅ After (Separate Files)
- Clean HTML/CSS/JavaScript files with proper formatting
- No escape characters needed
- Easy to edit and maintain with proper IDE support
- Full web development syntax highlighting
- Proper debugging capabilities for web content

## 🔧 Technical Implementation

### Bicep Template Changes
```bicep
// Load web application files from external files
var indexHtmlContent = loadTextContent('WebApp/index.html')
var webConfigContent = loadTextContent('WebApp/web.config')

// Use in App Service deployment (simplified - actual deployment uses source control)
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  // ... other properties ...
}
```

### Web Application Structure
- **index.html**: Contains the authentication demo interface with JavaScript
- **web.config**: Contains IIS configuration for proper routing and security headers

## 🎯 Benefits

1. **🔍 Readability**: Web code is clean and easy to read
2. **🛠️ Maintainability**: Separate files are easier to modify
3. **🧪 Testing**: Can test web application independently
4. **📝 Debugging**: Better debugging experience with proper file structure
5. **🔄 Reusability**: Web application can be reused across deployments
6. **👥 Collaboration**: Easier for teams to work on different components
7. **🎨 Styling**: Full CSS and JavaScript development experience

## 📚 Usage Examples

### Deploy with Script
```powershell
.\deploy.ps1 -ResourceGroupName "rg-auth-demo" -AppServiceName "my-auth-app" -StorageAccountName "myauthstorage123" -ClientId "your-client-id"
```

### Edit Web Application
Simply edit `WebApp/index.html` with your favorite editor and redeploy.

### Add New Web Pages
1. Create new HTML files in `WebApp/` folder
2. Update routing in `web.config` if needed
3. Redeploy the application

### Customize Authentication Flow
1. Modify the JavaScript in `index.html`
2. Add new endpoints or API calls
3. Update styling and user experience

## 🔗 Authentication Features

### Built-in Endpoints
- `/.auth/login/aad` - Azure AD login
- `/.auth/logout` - Logout
- `/.auth/me` - User claims and token information
- `/.auth/refresh` - Token refresh

### Token Management
- Automatic token storage and refresh
- Secure token access for downstream APIs
- User claims and profile information
- Session management

## 🛡️ Security Configuration

### IIS Security Headers (web.config)
```xml
<httpProtocol>
  <customHeaders>
    <add name="X-Content-Type-Options" value="nosniff" />
    <add name="X-Frame-Options" value="DENY" />
    <add name="X-XSS-Protection" value="1; mode=block" />
  </customHeaders>
</httpProtocol>
```

### Azure AD Authentication (Bicep)
```bicep
resource appServiceAuth 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'authsettingsV2'
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'RedirectToLoginPage'
    }
    // ... additional auth configuration
  }
}
```

## 🔗 Related Files

- **README.md**: Complete deployment and usage guide
- **deploy.ps1**: Automated deployment script
- **main.bicep**: Infrastructure as Code template
- **parameters.json**: Configuration parameters 