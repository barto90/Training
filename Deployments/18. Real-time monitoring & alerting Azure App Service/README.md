# 🔍 Real-time Monitoring & Alerting Azure App Service

This solution provides comprehensive real-time monitoring and alerting for Azure App Services using ServiceBus, Logic Apps, and PowerShell Functions. It demonstrates a complete monitoring pipeline with automated health checks, alert processing, and notification delivery.

## 🏗️ Architecture

```
🏠 Azure App Service (Monitored)
    ↓ (Health Checks)
⏱️ HealthCheckFunction (Timer Trigger)
    ↓ (Alerts)
🚌 ServiceBus Queue (monitoring-alerts)
    ↓ (Message Processing)
🚨 AlertProcessorFunction (ServiceBus Trigger)
    ↓ (Notifications)
🚌 ServiceBus Queue (alert-notifications)
    ↓ (Email Processing)
🔄 Logic App (Email/Teams Notifications)
    ↓
📧 Email/Teams Alerts
```

## 🚀 What Gets Deployed

### Core Infrastructure
- **Azure App Service** - The monitored web application with health endpoints
- **Azure Function App** - PowerShell 7.4 runtime hosting monitoring functions
- **ServiceBus Namespace** - Message queues for alert processing
- **Logic App** - Automated alert notification workflows
- **Application Insights** - Monitoring and telemetry collection
- **Log Analytics Workspace** - Centralized logging and analytics

### Monitoring Components
- **HealthCheckFunction** - Timer-triggered function that monitors app service health
- **AlertProcessorFunction** - ServiceBus-triggered function that processes and enriches alerts
- **ServiceBus Queues**:
  - `monitoring-alerts` - Raw health check alerts
  - `alert-notifications` - Processed notifications for Logic App

### Sample Web Application
- **index.html** - Main application page with monitoring dashboard
- **health.html** - Health check endpoint with real-time metrics
- **API endpoints** - Monitored API status endpoints

## 📋 Prerequisites

- Azure subscription with appropriate permissions
- PowerShell 5.1 or later
- Azure CLI (for deployment scripts)
- Email account for receiving alerts

## 🛠️ Deployment

### Option 1: Deploy via Azure Portal
Use the deployment template directly:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template)

### Option 2: Deploy via Azure CLI
```bash
# Create resource group
az group create --name rg-monitoring-demo --location "East US"

# Deploy infrastructure
az deployment group create \
  --resource-group rg-monitoring-demo \
  --template-file azuredeploy.json \
  --parameters @parameters.json
```

### Option 3: Deploy via Azure PowerShell
```powershell
# Create resource group
New-AzResourceGroup -Name "rg-monitoring-demo" -Location "East US"

# Deploy infrastructure
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-monitoring-demo" `
  -TemplateFile "azuredeploy.json" `
  -TemplateParameterFile "parameters.json"
```

## ⚙️ Post-Deployment Setup

### 1. Deploy Function Code

After infrastructure deployment, deploy the monitoring functions:

```powershell
# Deploy functions using the provided script
.\Deploy-MonitoringFunctions.ps1 -FunctionAppName "monitoring-functions-demo"
```

### 2. Configure Logic App Connections

1. Go to **Logic App** in Azure Portal
2. Navigate to **API connections**
3. Configure the following connections:
   - **ServiceBus Connection**: Authenticate with your ServiceBus namespace
   - **Office365 Connection**: Authenticate with email account for notifications

### 3. Update Parameters

Edit `parameters.json` with your specific values:
```json
{
  "appServiceName": { "value": "your-app-service-name" },
  "functionAppName": { "value": "your-function-app-name" },
  "serviceBusNamespaceName": { "value": "your-servicebus-namespace" },
  "storageAccountName": { "value": "yourstorageaccount123" },
  "alertEmail": { "value": "your-email@domain.com" },
  "monitoringIntervalMinutes": { "value": 5 }
}
```

## 🔧 Configuration

### Health Check Endpoints

The HealthCheckFunction monitors these endpoints by default:
- **Home Page**: `https://your-app.azurewebsites.net/`
- **Health Check**: `https://your-app.azurewebsites.net/health`
- **API Status**: `https://your-app.azurewebsites.net/api/status`

### Alert Levels

| Level | Description | Response Time Threshold | Notification |
|-------|-------------|------------------------|--------------|
| **INFO** | Informational updates | N/A | Business hours only |
| **WARNING** | Performance degradation | > 5 seconds | Always |
| **CRITICAL** | Service unavailable | Any timeout | Immediate |

### Monitoring Intervals

- **Health Checks**: Every 5 minutes (configurable)
- **Alert Processing**: Real-time (ServiceBus trigger)
- **Heartbeat**: Every 10th health check cycle

## 📊 Monitoring and Alerting

### Real-time Metrics

Monitor your application through:

1. **Application Insights Dashboard**
   - Response times and availability
   - Custom telemetry from monitoring functions
   - Performance counters and dependencies

2. **ServiceBus Metrics**
   - Message throughput and queue depth
   - Processing latency and error rates
   - Dead letter queue monitoring

3. **Function App Metrics**
   - Execution count and duration
   - Success/failure rates
   - Resource consumption

### Alert Scenarios

The system automatically detects and alerts on:

- **Service Outages**: HTTP 5xx errors, timeouts, connectivity issues
- **Performance Degradation**: Response times exceeding thresholds
- **Dependency Failures**: Database, API, or external service failures
- **Resource Constraints**: High CPU, memory, or disk usage

### Notification Channels

Alerts are delivered via:
- **Email**: Formatted alerts with context and recommended actions
- **Teams** (configurable): Channel notifications for team collaboration
- **ServiceBus**: For integration with other monitoring systems
- **Application Insights**: Searchable telemetry and metrics

## 🧪 Testing the System

### Manual Testing

Test the monitoring system using the provided script:

```powershell
# Test all alert types
.\Test-MonitoringAlerts.ps1 -ServiceBusConnectionString "your-connection-string" -AlertType "ALL"

# Test only critical alerts
.\Test-MonitoringAlerts.ps1 -ServiceBusConnectionString "your-connection-string" -AlertType "CRITICAL"

# Test specific app service
.\Test-MonitoringAlerts.ps1 `
  -ServiceBusConnectionString "your-connection-string" `
  -AppServiceName "your-app-service" `
  -AppServiceUrl "https://your-app.azurewebsites.net" `
  -AlertEmail "admin@company.com"
```

### Sample Test Scenarios

The test script simulates:
1. **Complete Service Outage** (CRITICAL)
2. **Connection Timeouts** (CRITICAL)
3. **Performance Degradation** (WARNING)
4. **Server Errors** (WARNING)
5. **Heartbeat Checks** (INFO)
6. **Maintenance Notifications** (INFO)

## 📈 Monitoring Dashboard

### Key Performance Indicators

Track these KPIs in your monitoring dashboard:

- **Availability**: Percentage uptime over time periods
- **Response Time**: P50, P95, P99 percentiles
- **Error Rate**: Percentage of failed requests
- **Alert Response Time**: Time from issue to alert delivery
- **Alert Resolution Time**: Time from alert to resolution

### Custom Metrics

The solution tracks custom metrics:
- `MonitoringCheck_ResponseTime`: Health check response times
- `MonitoringCheck_Success`: Health check success rate
- `Alert_Processed`: Number of alerts processed
- `Notification_Sent`: Number of notifications delivered

## 🔒 Security & Best Practices

### Security Considerations

1. **Managed Identity**: Functions use system-assigned managed identity
2. **Connection Strings**: Stored securely in Key Vault or App Settings
3. **Network Security**: Consider VNet integration for production
4. **Access Control**: Use Azure RBAC for resource access

### Production Recommendations

1. **Monitoring**:
   - Set up Azure Monitor alerts for the monitoring system itself
   - Configure dead letter queue monitoring
   - Implement metric-based scaling for high-volume scenarios

2. **Reliability**:
   - Use Premium Function App plans for production workloads
   - Configure multiple deployment slots for zero-downtime updates
   - Implement circuit breaker patterns for external dependencies

3. **Cost Optimization**:
   - Use consumption plans for variable workloads
   - Configure appropriate message TTL and retention policies
   - Implement alert throttling to prevent notification spam

## 🛠️ Troubleshooting

### Common Issues

1. **Functions Not Triggering**
   - Check ServiceBus connection string
   - Verify queue names match configuration
   - Review function app logs in Application Insights

2. **No Email Notifications**
   - Verify Logic App connections are authorized
   - Check Logic App run history for errors
   - Confirm email addresses are correct

3. **High Alert Volume**
   - Review alert thresholds and intervals
   - Implement alert suppression rules
   - Check for underlying service issues

### Diagnostic Commands

```powershell
# Check ServiceBus queue status
az servicebus queue show --resource-group "rg-monitoring" --namespace-name "monitoring-sb" --name "monitoring-alerts"

# View function logs
az functionapp log tail --name "monitoring-functions" --resource-group "rg-monitoring"

# Test Logic App manually
az logic workflow run trigger --resource-group "rg-monitoring" --name "alert-processor-logic" --trigger-name "manual"
```

## 📚 Additional Resources

### Documentation
- [Azure Functions PowerShell Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)
- [ServiceBus Messaging Documentation](https://docs.microsoft.com/en-us/azure/service-bus-messaging/)
- [Logic Apps Documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [Application Insights Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)

### Sample Queries

**Application Insights KQL queries:**

```kql
// Monitor function execution success rate
requests
| where name contains "HealthCheckFunction"
| summarize SuccessRate = countif(success == true) * 100.0 / count() by bin(timestamp, 5m)
| render timechart

// Alert processing latency
traces
| where message contains "Alert processed successfully"
| extend ProcessingTime = datetime_diff('millisecond', timestamp, todatetime(customDimensions["alertTimestamp"]))
| summarize avg(ProcessingTime) by bin(timestamp, 1h)

// Top alert types
customEvents
| where name == "AlertProcessed"
| summarize count() by tostring(customDimensions["alertLevel"])
| render piechart
```

## 🔄 Updates and Maintenance

### Regular Maintenance Tasks

1. **Monthly**: Review alert thresholds and adjust based on baseline performance
2. **Quarterly**: Update function runtime and dependencies
3. **Bi-annually**: Review and optimize monitoring costs
4. **Annually**: Conduct disaster recovery testing

### Version History

- **v1.0** - Initial release with basic monitoring
- **v1.1** - Added Logic App integration
- **v1.2** - Enhanced error handling and diagnostics

---

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Azure Function and Logic App logs
3. Submit issues with detailed error messages and reproduction steps

**Happy Monitoring!** 🎉 