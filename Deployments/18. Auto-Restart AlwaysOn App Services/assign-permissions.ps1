# Assign Website Contributor Role to Logic App Managed Identity
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$LogicAppName
)

Write-Host "🔑 Assigning permissions to Logic App..." -ForegroundColor Green

# Set subscription context
Set-AzContext -SubscriptionId $SubscriptionId

# Get Logic App details
$logicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $LogicAppName

if (-not $logicApp) {
    Write-Host "❌ Logic App '$LogicAppName' not found in resource group '$ResourceGroupName'" -ForegroundColor Red
    exit 1
}

# Check if Managed Identity is enabled
if (-not $logicApp.Identity -or $logicApp.Identity.Type -ne "SystemAssigned") {
    Write-Host "❌ Logic App does not have System Assigned Managed Identity enabled" -ForegroundColor Red
    Write-Host "💡 Enable it in: Portal → Logic App → Identity → System assigned → On" -ForegroundColor Yellow
    exit 1
}

$principalId = $logicApp.Identity.PrincipalId
Write-Host "✅ Found Logic App Managed Identity: $principalId" -ForegroundColor Green

# Website Contributor role definition ID
$roleDefinitionId = "de139f84-1756-47ae-9be6-808fbbe84772"
$scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"

Write-Host "🎯 Assigning 'Website Contributor' role..." -ForegroundColor Yellow
Write-Host "  Principal: $principalId" -ForegroundColor White
Write-Host "  Scope: $scope" -ForegroundColor White

try {
    # Check if assignment already exists
    $existingAssignment = Get-AzRoleAssignment -ObjectId $principalId -RoleDefinitionId $roleDefinitionId -Scope $scope -ErrorAction SilentlyContinue
    
    if ($existingAssignment) {
        Write-Host "✅ Role assignment already exists!" -ForegroundColor Green
    } else {
        # Create new role assignment
        $assignment = New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionId $roleDefinitionId -Scope $scope
        Write-Host "✅ Successfully assigned Website Contributor role!" -ForegroundColor Green
        Write-Host "  Assignment ID: $($assignment.RoleAssignmentId)" -ForegroundColor White
    }
    
    Write-Host "`n📋 Role Assignment Details:" -ForegroundColor Green
    $roleAssignments = Get-AzRoleAssignment -ObjectId $principalId
    $roleAssignments | Where-Object { $_.RoleDefinitionName -like "*Website*" } | ForEach-Object {
        Write-Host "  • Role: $($_.RoleDefinitionName)" -ForegroundColor White
        Write-Host "  • Scope: $($_.Scope)" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Failed to assign role: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 You may need higher privileges (Owner/User Access Administrator)" -ForegroundColor Yellow
}

Write-Host "`n🧪 Testing Logic App API Access..." -ForegroundColor Green

# Try to get an App Service to test permissions
$appServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName

if ($appServices) {
    Write-Host "✅ Found App Services in resource group:" -ForegroundColor Green
    $appServices | ForEach-Object {
        Write-Host "  • $($_.Name) - State: $($_.State)" -ForegroundColor White
        if ($_.Tags -and $_.Tags.AlwaysOn) {
            Write-Host "    AlwaysOn tag: $($_.Tags.AlwaysOn)" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️ No AlwaysOn tag found" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠️ No App Services found in resource group" -ForegroundColor Yellow
}

Write-Host "`n✅ Permission assignment complete!" -ForegroundColor Green
Write-Host "💡 Now test your Logic App by stopping an App Service" -ForegroundColor Cyan 