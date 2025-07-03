# 🔄 Auto-Restart AlwaysOn App Services

A simple and reliable Azure solution that automatically restarts App Services tagged with `AlwaysOn: "true"` when they are stopped.

## 🎯 **What This Solution Does**

1. **🏷️ Tags App Service** with `AlwaysOn: "true"`
2. **👁️ Monitors** for App Service stop events
3. **🔍 Checks** if stopped app has the `AlwaysOn` tag
4. **🚀 Automatically restarts** the app if tagged
5. **📧 Sends Slack notification** about the restart (optional)

## 🏗️ **Architecture**

```
App Service Stop Event → Activity Log Alert → Action Group → Logic App
                                                              ↓
                                          Check AlwaysOn Tag → Restart App → Email
```

## 🛠️ **Components**

| Component | Purpose |
|-----------|---------|
| **App Service** | Web app with `AlwaysOn: "true"` tag |
| **Activity Log Alert** | Detects `Microsoft.Web/sites/stop/action` events |
| **Action Group** | Routes alerts to Logic App |
| **Logic App** | Smart restart logic with tag checking |
| **Role Assignment** | Grants Logic App permission to restart apps |

## 🚀 **Deployment**

### **Prerequisites**
- Azure CLI or PowerShell
- Resource Group created
- Unique App Service name (globally unique)

### **Step 1: Slack Integration (Pre-configured)**
✅ **Slack webhook is already configured** in `parameters.json`  
✅ **Test your webhook**: Run `.\test-slack-webhook.ps1` to verify it works  
✅ **Customize if needed**: Update the webhook URL in `parameters.json`

### **Step 2: Update Parameters**
Edit `parameters.json`:
```json
{
  "appServiceName": {"value": "your-unique-app-name"},
  "logicAppName": {"value": "your-logic-app-name"},
  "alertEmail": {"value": "your-email@company.com"}
}
```
**Note**: Slack webhook is already configured with your URL!

### **Step 2: Deploy**
```bash
# Azure CLI
az deployment group create \
  --resource-group YOUR-RESOURCE-GROUP \
  --template-file azuredeploy.json \
  --parameters @parameters.json
```

```powershell
# PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName "YOUR-RESOURCE-GROUP" `
  -TemplateFile "azuredeploy.json" `
  -TemplateParameterFile "parameters.json"
```

## 🧪 **Testing**

### **Test Slack Integration First**
```powershell
.\test-slack-webhook.ps1
```
This will send a test message to your Slack channel to verify the webhook works.

### **Test the Auto-Restart**
1. **✅ Verify Deployment**: Check that all resources are deployed
2. **🛑 Stop the App**: Go to Azure Portal → App Service → Stop
3. **⏰ Wait 2-3 minutes**: Activity log alert has a small delay
4. **🔍 Check Logic App**: Go to Logic App → Runs history
5. **📱 Check Slack**: You should receive restart notification in your Slack channel
6. **✅ Verify App**: App Service should be running again

### **Test Tag Dependency**
1. **🏷️ Remove Tag**: Set `AlwaysOn` tag to `"false"` or remove it
2. **🛑 Stop App**: Stop the App Service
3. **❌ No Restart**: Logic App should log "No action taken"
4. **🏷️ Add Tag Back**: Set `AlwaysOn: "true"`

## 📊 **Monitoring**

### **Logic App Runs**
- Go to **Logic App** → **Runs history**
- Check successful vs failed runs
- View detailed execution steps

### **Activity Log**
- Go to **Activity Log** → Filter by "Stop web app"
- See who stopped apps and when

### **Slack Notifications**
Example Slack message:
```
🔄 App Service Auto-Restarted: myapp-alwayson-001

✅ Auto-Restart Successful

Your App Service 'myapp-alwayson-001' was automatically stopped but has been restarted because it has the 'AlwaysOn' tag set to 'true'.

📋 Details:
• App Name: myapp-alwayson-001
• Stopped At: 2024-01-15T14:30:00Z
• Stopped By: user@company.com
• Restarted At: 2024-01-15T14:32:00Z
• Action Taken: Automatically restarted

✅ Your app is now running again!
```

## 🎛️ **Configuration**

### **Adding More Apps**
To protect additional App Services:
1. **Add the tag**: `AlwaysOn: "true"` to any App Service
2. **No redeployment needed**: The solution monitors all apps in the Resource Group

### **Excluding Apps**
To stop auto-restart for an app:
1. **Remove the tag**: Delete the `AlwaysOn` tag
2. **Or set to false**: `AlwaysOn: "false"`

### **Change Slack Webhook**
To update the Slack notifications:
1. **Update Logic App parameter**: Go to Logic App → Parameters
2. **Or redeploy**: Update `parameters.json` and redeploy
3. **Disable notifications**: Set `slackWebhookUrl` to empty string `""`

## 🔧 **Customization**

### **Different Actions**
You can modify the Logic App to:
- Send Teams notifications
- Create ServiceNow tickets
- Log to custom systems
- Add delays before restart
- Send different notifications based on who stopped the app

### **Advanced Filtering**
The Activity Log Alert can be configured to:
- Monitor specific Resource Groups
- Filter by specific users
- Different time windows
- Additional conditions

## ❌ **Troubleshooting**

### **Activity Log Not Appearing in Log Analytics**
**Problem**: Can't query Activity Log with KQL in Log Analytics workspace

**Root Cause**: Activity Log diagnostic settings require subscription-level permissions

**Solutions**:
1. **Check Diagnostic Settings**: Go to **Subscriptions** → **Monitor** → **Activity Log** → **Diagnostic Settings**
   - Look for `SendActivityLogToLogAnalytics`
   - If missing, the ARM template couldn't create it

2. **Manual Setup**: Run the included PowerShell script:
   ```powershell
   .\setup-activity-log-diagnostics.ps1 -SubscriptionId "your-sub-id" -ResourceGroupName "your-rg" -LogAnalyticsWorkspaceName "law-your-app-name"
   ```

3. **Alternative Queries**: Use Azure Portal instead:
   - **Portal**: **Monitor** → **Activity Log** → Filter by `Microsoft.Web/sites/stop/action`
   - **PowerShell**: `Get-AzActivityLog` (see README for examples)

**Note**: The auto-restart functionality works regardless of Log Analytics - it uses Activity Log Alerts directly!

### **Logic App Not Triggering**
1. **Check Activity Log Alert**: Ensure it's enabled
2. **Check Action Group**: Verify webhook URL is correct
3. **Check Permissions**: Logic App needs Website Contributor role

### **Restart Failing**
1. **Check App Service State**: Ensure it's stopped, not in error state
2. **Check Role Assignment**: Logic App needs restart permissions
3. **Check Logs**: View Logic App run history for errors

### **No Slack Notification Received**
1. **Check Webhook URL**: Verify the Slack webhook URL is correct
2. **Check Slack Channel**: Ensure the webhook is posting to the right channel
3. **Check Logic App**: View Logic App run history for webhook errors

## 💡 **Best Practices**

1. **Test in Dev First**: Deploy to dev environment before production
2. **Monitor Logic App**: Set up alerts on Logic App failures
3. **Tag Strategy**: Use consistent tagging across environments
4. **Security**: Regularly review role assignments
5. **Documentation**: Keep track of which apps have AlwaysOn tag

## 🎯 **Why This Solution Rocks**

✅ **Simple**: Just tag your apps and deploy once  
✅ **Reliable**: Uses Azure Activity Log (very reliable)  
✅ **Secure**: Uses Managed Identity, no stored credentials  
✅ **Scalable**: Automatically monitors all tagged apps  
✅ **Transparent**: Clear logging and email notifications  
✅ **Cost-Effective**: Minimal consumption-based costs  

## 📚 **Next Steps**

After this solution is working, consider:
- Adding Teams notifications
- Creating dashboards for restart events
- Implementing restart delays for maintenance windows
- Adding automatic scaling based on restart frequency

---

**Happy auto-restarting!** 🚀 