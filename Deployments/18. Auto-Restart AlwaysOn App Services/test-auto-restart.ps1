# Test Auto-Restart Functionality
# This script helps test the AlwaysOn auto-restart solution

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory = $true)]
    [string]$LogicAppName
)

Write-Host "🧪 Testing Auto-Restart Functionality" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Step 1: Check if App Service exists and has AlwaysOn tag
Write-Host "1️⃣ Checking App Service configuration..." -ForegroundColor Yellow
try {
    $appService = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    $alwaysOnTag = $appService.Tags["AlwaysOn"]
    
    if ($alwaysOnTag -eq "true") {
        Write-Host "✅ App Service '$AppServiceName' has AlwaysOn tag set to 'true'" -ForegroundColor Green
    } else {
        Write-Host "❌ App Service '$AppServiceName' does not have AlwaysOn tag set to 'true'" -ForegroundColor Red
        Write-Host "   Current tag value: '$alwaysOnTag'" -ForegroundColor Red
        Write-Host "   Setting AlwaysOn tag to 'true'..." -ForegroundColor Yellow
        
        # Add the tag
        $appService.Tags["AlwaysOn"] = "true"
        Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Tag $appService.Tags
        Write-Host "✅ AlwaysOn tag has been set to 'true'" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error checking App Service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check current App Service state
Write-Host "`n2️⃣ Checking current App Service state..." -ForegroundColor Yellow
$currentState = $appService.State
Write-Host "   Current state: $currentState" -ForegroundColor Cyan

if ($currentState -eq "Stopped") {
    Write-Host "   App Service is already stopped. Starting it first..." -ForegroundColor Yellow
    Start-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    Write-Host "✅ App Service started" -ForegroundColor Green
    Start-Sleep -Seconds 10
}

# Step 3: Stop the App Service to trigger the alert
Write-Host "`n3️⃣ Stopping App Service to trigger auto-restart..." -ForegroundColor Yellow
try {
    Stop-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    Write-Host "✅ App Service stopped successfully" -ForegroundColor Green
    $stopTime = Get-Date
    Write-Host "   Stopped at: $stopTime" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error stopping App Service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Wait and monitor for restart
Write-Host "`n4️⃣ Monitoring for auto-restart..." -ForegroundColor Yellow
Write-Host "   Waiting for Activity Log Alert to trigger (this may take 2-3 minutes)..." -ForegroundColor Cyan

$maxWaitTime = 300  # 5 minutes
$waitInterval = 30  # Check every 30 seconds
$elapsed = 0

while ($elapsed -lt $maxWaitTime) {
    Start-Sleep -Seconds $waitInterval
    $elapsed += $waitInterval
    
    try {
        $appService = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
        $currentState = $appService.State
        
        Write-Host "   ⏰ $elapsed seconds elapsed - Current state: $currentState" -ForegroundColor Cyan
        
        if ($currentState -eq "Running") {
            $restartTime = Get-Date
            $timeDiff = $restartTime - $stopTime
            Write-Host "`n🎉 SUCCESS! App Service has been automatically restarted!" -ForegroundColor Green
            Write-Host "   ⏱️  Time to restart: $($timeDiff.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "   ⚠️  Error checking App Service state: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if ($elapsed -ge $maxWaitTime) {
    Write-Host "`n❌ TIMEOUT: App Service was not restarted within $($maxWaitTime/60) minutes" -ForegroundColor Red
    Write-Host "   This might indicate an issue with the auto-restart logic" -ForegroundColor Red
}

# Step 5: Check Logic App runs
Write-Host "`n5️⃣ Checking Logic App execution history..." -ForegroundColor Yellow
try {
    # Get recent Logic App runs
    $logicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $LogicAppName
    Write-Host "✅ Logic App found: $($logicApp.Name)" -ForegroundColor Green
    
    # Note: Detailed run history requires additional permissions
    Write-Host "   💡 To check detailed run history:" -ForegroundColor Cyan
    Write-Host "      1. Go to Azure Portal" -ForegroundColor Cyan
    Write-Host "      2. Navigate to Logic App '$LogicAppName'" -ForegroundColor Cyan
    Write-Host "      3. Click 'Runs history'" -ForegroundColor Cyan
    Write-Host "      4. Look for recent successful runs" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error checking Logic App: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Summary
Write-Host "`n📋 Test Summary" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "App Service: $AppServiceName" -ForegroundColor White
Write-Host "Logic App: $LogicAppName" -ForegroundColor White
Write-Host "Test completed at: $(Get-Date)" -ForegroundColor White

Write-Host "`n✅ Next Steps:" -ForegroundColor Green
Write-Host "1. Check your email for restart notification" -ForegroundColor White
Write-Host "2. Verify Logic App run history in Azure Portal" -ForegroundColor White
Write-Host "3. Check Activity Log for the stop/start events" -ForegroundColor White

Write-Host "`n🎯 Test completed!" -ForegroundColor Cyan 