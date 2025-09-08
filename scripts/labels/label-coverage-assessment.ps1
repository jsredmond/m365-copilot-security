# Sensitivity Label Coverage Assessment
# Requires: Exchange Online PowerShell & Security & Compliance PowerShell
# Version: 2.0

#Requires -Module ExchangeOnlineManagement
#Requires -Module Microsoft.Graph

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantDomain
)

# Connect to Security & Compliance Center
Connect-IPPSSession -UserPrincipalName admin@$TenantDomain

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "InformationProtectionPolicy.Read.All", "Files.Read.All", "Sites.Read.All"

Write-Host "Analyzing sensitivity label coverage..." -ForegroundColor Green

# Get all configured labels
$labels = Get-Label | Select-Object DisplayName, Name, Guid, Priority, ParentId

# Analyze label usage in SharePoint
$labelUsage = @()
$sites = Get-MgSite -All

foreach ($site in $sites) {
    $siteFiles = Get-MgSiteDriveItem -SiteId $site.Id -All
    
    $labeledCount = ($siteFiles | Where-Object { $_.SensitivityLabel }).Count
    $totalCount = $siteFiles.Count
    
    $labelUsage += [PSCustomObject]@{
        SiteName = $site.DisplayName
        SiteUrl = $site.WebUrl
        TotalFiles = $totalCount
        LabeledFiles = $labeledCount
        CoveragePercent = if ($totalCount -gt 0) { [math]::Round(($labeledCount / $totalCount) * 100, 2) } else { 0 }
        UnlabeledFiles = $totalCount - $labeledCount
    }
}

# Generate recommendations
$recommendations = @()

if (($labelUsage | Where-Object { $_.CoveragePercent -lt 50 }).Count -gt 0) {
    $recommendations += "CRITICAL: Multiple sites have less than 50% label coverage"
}

if ($labels.Count -lt 4) {
    $recommendations += "WARNING: Consider implementing a complete label taxonomy (Public, Internal, Confidential, Highly Confidential)"
}

# Output results
$labelUsage | Export-Csv -Path ".\LabelCoverageAssessment.csv" -NoTypeInformation

Write-Host "`nLabel Coverage Summary:" -ForegroundColor Cyan
Write-Host "Total Sites Analyzed: $($sites.Count)"
Write-Host "Average Label Coverage: $([math]::Round(($labelUsage.CoveragePercent | Measure-Object -Average).Average, 2))%"
Write-Host "Sites with <50% Coverage: $(($labelUsage | Where-Object { $_.CoveragePercent -lt 50 }).Count)"
Write-Host "`nRecommendations:" -ForegroundColor Yellow
$recommendations | ForEach-Object { Write-Host "  - $_" }

Disconnect-MgGraph
Disconnect-ExchangeOnline -Confirm:$false