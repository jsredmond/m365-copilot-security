<#
.SYNOPSIS
Reports SharePoint sites with permissive or external sharing enabled.

.OUTPUTS
- Console table
- CSV at ./out/site-sharing-audit.csv

.NOTES
Requires SharePoint Online Management Shell.
#>

param(
  [Parameter(Mandatory=$true)][string]$AdminUrl
)

$OUT = "out"
$CSV = Join-Path $OUT "site-sharing-audit.csv"
New-Item -ItemType Directory -Path $OUT -ErrorAction SilentlyContinue | Out-Null

Connect-SPOService -Url $AdminUrl

$sites = Get-SPOSite -Limit All |
  Select Url, Owner, Template, SharingCapability, SharingDomainRestrictionMode, DefaultLinkPermission, DefaultSharingLinkType, LockState

$sites | Tee-Object -Variable data | Format-Table -Auto
$data | Export-Csv -NoTypeInformation -Path $CSV
Write-Host "Exported: $CSV" -ForegroundColor Green
