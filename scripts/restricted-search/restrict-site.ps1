<#
.SYNOPSIS
Toggles the RestrictContentOrgWideSearch flag for a SharePoint site.

.EXAMPLE
./restrict-site.ps1 -AdminUrl https://contoso-admin.sharepoint.com -SiteUrl https://contoso.sharepoint.com/sites/SecretProject -Restrict $true
#>

param(
  [Parameter(Mandatory=$true)][string]$AdminUrl,
  [Parameter(Mandatory=$true)][string]$SiteUrl,
  [Parameter(Mandatory=$true)][bool]$Restrict
)

Connect-SPOService -Url $AdminUrl
Set-SPOSite -Identity $SiteUrl -RestrictContentOrgWideSearch $Restrict
Get-SPOSite -Identity $SiteUrl | Select Url, RestrictContentOrgWideSearch | Format-Table -Auto
