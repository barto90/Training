# 📁 Project Structure

This deployment uses a clean, maintainable structure with separate files for PowerShell code:

## 📂 File Organization

```
14. Managed Idenitty And GRAPH/
├── 📄 azuredeploy.json              # ARM template (generated from Bicep)
├── 📄 main.bicep                    # Main Bicep template (uses loadTextContent)
├── 📄 parameters.json               # Sample deployment parameters
├── 📄 deploy.ps1                    # PowerShell deployment script
├── 📄 deploy-to-azure.html          # Web deployment interface
├── 📄 azuredeploy.visualizer.html   # Architecture visualization
├── 📄 README.md                     # Comprehensive documentation
├── 📄 STRUCTURE.md                  # This file
└── 📁 GraphAPITrigger/              # Function folder
    ├── 📄 function.json             # Function bindings configuration
    └── 📄 run.ps1                   # Clean PowerShell code
```

## 🚀 Improvements Made

### ✅ Before (Embedded Code)
- PowerShell code was embedded in ARM/Bicep templates
- Escape characters made code hard to read: `Write-Host \\\"Hello\\\"`
- Difficult to maintain and debug
- No syntax highlighting in templates

### ✅ After (Separate Files)
- Clean PowerShell files with proper formatting
- No escape characters: `Write-Host "Hello"`
- Easy to edit and maintain
- Full PowerShell syntax highlighting
- Proper debugging capabilities

## 🔧 Technical Implementation

### Bicep Template Changes
```bicep
// Load PowerShell code from external file
var httpTriggerGraphCode = loadTextContent('GraphAPITrigger/run.ps1')
var functionConfig = loadTextContent('GraphAPITrigger/function.json')

// Use in function resource
resource graphAPITrigger 'Microsoft.Web/sites/functions@2022-03-01' = {
  properties: {
    config: json(functionConfig)
    files: {
      'run.ps1': httpTriggerGraphCode
    }
  }
}
```

### Function Structure
- **function.json**: Contains bindings and trigger configuration
- **run.ps1**: Contains the actual PowerShell function logic

## 🎯 Benefits

1. **🔍 Readability**: PowerShell code is clean and easy to read
2. **🛠️ Maintainability**: Separate files are easier to modify
3. **🧪 Testing**: Can test PowerShell code independently
4. **📝 Debugging**: Better debugging experience with proper file structure
5. **🔄 Reusability**: Function code can be reused across deployments
6. **👥 Collaboration**: Easier for teams to work on different components

## 📚 Usage Examples

### Deploy with Script
```powershell
.\deploy.ps1 -ResourceGroupName "rg-test" -FunctionAppName "test-func" -StorageAccountName "teststorage123"
```

### Edit Function Code
Simply edit `GraphAPITrigger/run.ps1` with your favorite editor and redeploy.

### Add New Functions
1. Create new folder: `MyNewFunction/`
2. Add `function.json` and `run.ps1`
3. Update Bicep template to include the new function

## 🔗 Related Files

- **README.md**: Complete deployment and usage guide
- **deploy.ps1**: Automated deployment script
- **main.bicep**: Infrastructure as Code template 