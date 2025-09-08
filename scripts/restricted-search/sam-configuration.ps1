# SharePoint Advanced Management Configuration for Copilot
# Requires: SharePoint Advanced Management license
# Version: 2.0

#Requires -Module Microsoft.Online.SharePoint.PowerShell
#Requires -Module PnP.PowerShell

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl
)

Connect-SPOService -Url "$TenantUrl-admin"

# Enable Data Access Governance
Set-SPOTenant -EnableDataAccessGovernance $true

# Configure Restricted Access Control (RAC) policies
Write-Host "Configuring Restricted Access Control policies..." -ForegroundColor Green

# Create RAC policy for highly sensitive sites
$racPolicy = @{
    Name = "HighlySensitiveDataPolicy"
    Description = "Restricts access to highly sensitive data sites"
    RestrictedGroups = @("HighlySensitiveDataReaders@contoso.com")
    AppliesTo = "Sites"
    Enabled = $true
}

# Note: RAC policy creation requires Graph API or SharePoint Admin Center UI
# This is a representation of the configuration

# Enable Default Sensitivity Labeling for Document Libraries
Set-SPOTenant -DisableDocumentLibraryDefaultLabeling $false

Write-Host "SharePoint Advanced Management configured for Copilot readiness" -ForegroundColor Green