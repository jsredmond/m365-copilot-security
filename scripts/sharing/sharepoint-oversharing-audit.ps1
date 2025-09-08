# Comprehensive SharePoint Permission Audit
# Requires: SharePoint Online Management Shell & PnP PowerShell
# Author: Security Architecture Team
# Version: 2.0

#Requires -Version 7.0
#Requires -Module Microsoft.Online.SharePoint.PowerShell
#Requires -Module PnP.PowerShell

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\CopilotSecurityAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

# Create output directory
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Connect to SharePoint Online
Connect-SPOService -Url $TenantUrl

# Connect to PnP for detailed permissions
$adminUrl = $TenantUrl.Replace(".sharepoint.com", "-admin.sharepoint.com")
Connect-PnPOnline -Url $adminUrl -Interactive

Write-Host "Starting comprehensive SharePoint audit..." -ForegroundColor Green

# 1. Audit External Sharing Capabilities
Write-Host "Auditing external sharing settings..." -ForegroundColor Yellow
$externalSharingReport = Get-SPOSite -Limit All | ForEach-Object {
    $site = $_
    $siteDetails = Get-SPOSite -Identity $site.Url -Detailed
    
    [PSCustomObject]@{
        SiteUrl = $site.Url
        Title = $site.Title
        SharingCapability = $site.SharingCapability
        DefaultSharingLinkType = $siteDetails.DefaultSharingLinkType
        DefaultLinkPermission = $siteDetails.DefaultLinkPermission
        RequireAnonymousLinksExpireInDays = $siteDetails.AnonymousLinkExpirationInDays
        ExternalUserCount = (Get-SPOExternalUser -SiteUrl $site.Url -ShowOnlyUsersWithAcceptedInvitations).Count
        LastModified = $site.LastContentModifiedDate
        StorageUsed = [math]::Round($site.StorageUsageCurrent / 1024, 2)
        Template = $site.Template
    }
}

$externalSharingReport | Export-Csv -Path "$OutputPath\ExternalSharingAudit.csv" -NoTypeInformation

# 2. Identify Sites with "Everyone" or "Everyone except external users" permissions
Write-Host "Identifying overshared sites..." -ForegroundColor Yellow
$oversharedSites = @()

Get-SPOSite -Limit All | ForEach-Object {
    $siteUrl = $_.Url
    Connect-PnPOnline -Url $siteUrl -Interactive -ErrorAction SilentlyContinue
    
    if ($?) {
        $web = Get-PnPWeb -Includes RoleAssignments, AllProperties
        
        foreach ($roleAssignment in $web.RoleAssignments) {
            $member = Get-PnPProperty -ClientObject $roleAssignment -Property Member
            
            if ($member.LoginName -match "spo-grid-all-users|Everyone except external users|Everyone") {
                $oversharedSites += [PSCustomObject]@{
                    SiteUrl = $siteUrl
                    PermissionLevel = ($roleAssignment.RoleDefinitionBindings | Select-Object -First 1).Name
                    GrantedTo = $member.Title
                    LoginName = $member.LoginName
                    DiscoveredDate = Get-Date
                }
            }
        }
    }
}

$oversharedSites | Export-Csv -Path "$OutputPath\OversharedSites.csv" -NoTypeInformation

# 3. Guest User Access Audit
Write-Host "Auditing guest user access..." -ForegroundColor Yellow
$guestAccess = Get-SPOExternalUser -ShowOnlyUsersWithAcceptedInvitations | ForEach-Object {
    [PSCustomObject]@{
        DisplayName = $_.DisplayName
        Email = $_.Email
        AcceptedAs = $_.AcceptedAs
        WhenCreated = $_.WhenCreated
        InvitedBy = $_.InvitedBy
        Sites = ($_.SiteUrl -join "; ")
    }
}

$guestAccess | Export-Csv -Path "$OutputPath\GuestUserAccess.csv" -NoTypeInformation

# 4. Identify Stale Sites (No activity in 90+ days)
Write-Host "Identifying stale sites..." -ForegroundColor Yellow
$staleSites = Get-SPOSite -Limit All | Where-Object {
    $_.LastContentModifiedDate -lt (Get-Date).AddDays(-90)
} | Select-Object Url, Title, LastContentModifiedDate, StorageUsageCurrent, Owner

$staleSites | Export-Csv -Path "$OutputPath\StaleSites.csv" -NoTypeInformation

# 5. OneDrive Sharing Analysis
Write-Host "Analyzing OneDrive sharing..." -ForegroundColor Yellow
$oneDriveSharing = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '*-my.sharepoint.com/personal*'" | 
    Where-Object { $_.SharingCapability -ne 'Disabled' } |
    Select-Object Url, Owner, SharingCapability, StorageUsageCurrent

$oneDriveSharing | Export-Csv -Path "$OutputPath\OneDriveSharing.csv" -NoTypeInformation

# Generate Summary Report
$summary = @"
COPILOT SECURITY READINESS AUDIT SUMMARY
========================================
Generated: $(Get-Date)
Tenant: $TenantUrl

HIGH RISK FINDINGS:
- Sites with External Sharing Enabled: $(($externalSharingReport | Where-Object {$_.SharingCapability -ne 'Disabled'}).Count)
- Sites with 'Everyone' Permissions: $($oversharedSites.Count)
- Active Guest Users: $($guestAccess.Count)
- Stale Sites (90+ days inactive): $($staleSites.Count)
- OneDrive with External Sharing: $($oneDriveSharing.Count)

RECOMMENDED ACTIONS BEFORE COPILOT DEPLOYMENT:
1. Review and restrict external sharing on $(($externalSharingReport | Where-Object {$_.SharingCapability -eq 'ExternalUserAndGuestSharing'}).Count) sites
2. Remove 'Everyone' permissions from $($oversharedSites.Count) sites
3. Review access for $($guestAccess.Count) guest users
4. Archive or delete $($staleSites.Count) stale sites
5. Apply sensitivity labels to unclassified content

Detailed reports saved to: $OutputPath
"@

$summary | Out-File -FilePath "$OutputPath\AuditSummary.txt"
Write-Host $summary -ForegroundColor Cyan

Disconnect-SPOService
Disconnect-PnPOnline