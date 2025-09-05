<#
.SYNOPSIS
Audits guest users and their access context.

.DESCRIPTION
- Lists Entra ID guest users, enabled status, last sign-in (if available), and group count.
- Requires Microsoft Graph PowerShell and sufficient permissions.
- Run: Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All","AuditLog.Read.All"; Select-MgProfile beta (for signInActivity if needed)

.NOTES
Some properties like signInActivity require the beta profile and appropriate permissions.
#>

$OUT = "out"
$CSV = Join-Path $OUT "guest-access-audit.csv"
New-Item -ItemType Directory -Path $OUT -ErrorAction SilentlyContinue | Out-Null

Write-Host "Querying guest users..." -ForegroundColor Cyan
$guests = Get-MgUser -All -Filter "userType eq 'Guest'" -Property Id,DisplayName,UserPrincipalName,UserType,AccountEnabled,SignInActivity

$result = foreach ($g in $guests) {
  $groups = (Get-MgUserMemberOf -UserId $g.Id -All -ErrorAction SilentlyContinue) | Measure-Object | Select -ExpandProperty Count
  [pscustomobject]@{
    DisplayName     = $g.DisplayName
    UserPrincipalName = $g.UserPrincipalName
    Enabled         = $g.AccountEnabled
    LastSignInUtc   = $g.SignInActivity.LastSignInDateTime
    GroupCount      = $groups
    UserId          = $g.Id
  }
}

$result | Tee-Object -Variable data | Format-Table -Auto
$data | Export-Csv -NoTypeInformation -Path $CSV
Write-Host "Exported: $CSV" -ForegroundColor Green
