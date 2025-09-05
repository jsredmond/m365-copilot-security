<#
.SYNOPSIS
Enables Restricted SharePoint Search tenant-wide and seeds the allowed list of sites.

.DESCRIPTION
- Turns on Restricted Search so org-wide search and Copilot index only approved sites.
- Adds a provided list of site URLs to the allowed list.
- Requires SharePoint Online Management Shell.
- Run: ./enable-restricted-search.ps1 -AdminUrl https://contoso-admin.sharepoint.com -AllowedSites @("https://contoso.sharepoint.com/sites/HR","https://contoso.sharepoint.com/sites/Finance")

.NOTES
Test in a pilot tenant first. Verify cmdlet availability with your installed SPO module version.
#>

param(
  [Parameter(Mandatory=$true)][string]$AdminUrl,
  [string[]]$AllowedSites = @()
)

Write-Host "Connecting to $AdminUrl ..." -ForegroundColor Cyan
Connect-SPOService -Url $AdminUrl

Write-Host "Enabling Restricted SharePoint Search tenant-wide..." -ForegroundColor Cyan
Set-SPOTenantRestrictedSearchMode -Mode Enabled

if ($AllowedSites.Count -gt 0) {
  Write-Host "Adding $($AllowedSites.Count) site(s) to the allowed list..." -ForegroundColor Cyan
  Add-SPOTenantRestrictedSearchAllowedList -SitesList $AllowedSites
}

Write-Host "Done. Validate behavior with a test account before broadening scope." -ForegroundColor Green
