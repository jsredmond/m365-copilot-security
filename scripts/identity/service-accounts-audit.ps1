<#
.SYNOPSIS
Finds potential over-privileged service accounts and app registrations.

.DESCRIPTION
- Enumerates critical directory roles and members
- Lists service principals with powerful Graph scopes like Sites.FullControl.All
- Requires Microsoft Graph PowerShell (Connect-MgGraph with Directory.Read.All, AppRoleAssignment.Read.All)

.NOTES
Use results to drive least-privilege remediation and PIM enrollment.
#>

$OUT = "out"
New-Item -ItemType Directory -Path $OUT -ErrorAction SilentlyContinue | Out-Null

# Critical roles to review
$roleNames = @(
  "Global Administrator",
  "SharePoint Administrator",
  "Compliance Administrator",
  "Privileged Role Administrator",
  "Security Administrator"
)

$roleReport = @()

foreach ($rn in $roleNames) {
  $role = Get-MgDirectoryRole -Filter "displayName eq '$rn'"
  if ($role) {
    $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All
    foreach ($m in $members) {
      $roleReport += [pscustomobject]@{
        RoleName = $rn
        MemberId = $m.Id
      }
    }
  }
}

$roleCsv = Join-Path $OUT "directory-role-members.csv"
$roleReport | Export-Csv -NoTypeInformation -Path $roleCsv
Write-Host "Exported: $roleCsv" -ForegroundColor Green

# Find service principals with Sites.FullControl.All or similar powerful scopes
$spFindings = @()
$allSps = Get-MgServicePrincipal -All -Property Id,DisplayName,AppId

foreach ($sp in $allSps) {
  try {
    $assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All -ErrorAction Stop
    foreach ($a in $assignments) {
      if ($a.AppRoleDisplayName -match "Sites\.FullControl\.All|Files\.ReadWrite\.All|Directory\.ReadWrite\.All") {
        $spFindings += [pscustomobject]@{
          ServicePrincipal = $sp.DisplayName
          AppId            = $sp.AppId
          AppRole          = $a.AppRoleDisplayName
          Resource         = $a.ResourceDisplayName
        }
      }
    }
  } catch {
    # ignore noisy SPs without assignments
  }
}

$spCsv = Join-Path $OUT "service-principals-privileged.csv"
$spFindings | Export-Csv -NoTypeInformation -Path $spCsv
Write-Host "Exported: $spCsv" -ForegroundColor Green
