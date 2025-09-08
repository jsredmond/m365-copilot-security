# Service Account and App Permission Audit
# Identifies over-privileged service accounts and applications
# Version: 2.0

#Requires -Module Microsoft.Graph

Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All", "AuditLog.Read.All"

# Audit Service Principals with high-risk permissions
$riskyPermissions = @(
    "Directory.ReadWrite.All",
    "User.ReadWrite.All",
    "Group.ReadWrite.All",
    "RoleManagement.ReadWrite.Directory",
    "Application.ReadWrite.All"
)

$riskyApps = Get-MgServicePrincipal -All | ForEach-Object {
    $sp = $_
    $appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id
    
    $highRiskRoles = $appRoles | Where-Object {
        $_.AppRoleId -in $riskyPermissions
    }
    
    if ($highRiskRoles) {
        [PSCustomObject]@{
            ApplicationName = $sp.DisplayName
            ApplicationId = $sp.AppId
            ServicePrincipalId = $sp.Id
            RiskyPermissions = ($highRiskRoles.AppRoleId -join ", ")
            CreatedDateTime = $sp.CreatedDateTime
            AccountEnabled = $sp.AccountEnabled
        }
    }
}

$riskyApps | Export-Csv -Path ".\RiskyApplicationPermissions.csv" -NoTypeInformation

Write-Host "Found $($riskyApps.Count) applications with high-risk permissions" -ForegroundColor Red