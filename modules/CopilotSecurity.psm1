# CopilotSecurity.psm1
# Comprehensive PowerShell Module for Copilot Security Management
# Version: 2.0

#Requires -Version 7.0
#Requires -Module Microsoft.Graph
#Requires -Module ExchangeOnlineManagement
#Requires -Module Microsoft.Online.SharePoint.PowerShell

# Module manifest
@{
    ModuleVersion = '2.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Security Architecture Team'
    CompanyName = 'Heliobright'
    Description = 'Comprehensive Copilot Security Management Module'
    PowerShellVersion = '7.0'
    RequiredModules = @(
        'Microsoft.Graph',
        'ExchangeOnlineManagement',
        'Microsoft.Online.SharePoint.PowerShell'
    )
    FunctionsToExport = @(
        'Start-CopilotSecurityAssessment',
        'Enable-CopilotSecurityControls',
        'Test-CopilotReadiness',
        'Get-CopilotSecurityScore',
        'Export-CopilotComplianceReport'
    )
}

function Start-CopilotSecurityAssessment {
    <#
    .SYNOPSIS
    Performs comprehensive security assessment for Copilot readiness
    
    .DESCRIPTION
    Runs multiple security checks and generates detailed readiness report
    
    .PARAMETER TenantDomain
    The tenant domain to assess
    
    .PARAMETER OutputPath
    Path for assessment reports
    
    .EXAMPLE
    Start-CopilotSecurityAssessment -TenantDomain "contoso.com" -OutputPath "C:\Assessments"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantDomain,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = ".\CopilotAssessment_$(Get-Date -Format 'yyyyMMdd')"
    )
    
    Begin {
        # Initialize connections
        Write-Host "Initializing connections..." -ForegroundColor Green
        Connect-MgGraph -Scopes "Directory.Read.All", "Reports.Read.All", "AuditLog.Read.All"
        Connect-SPOService -Url "https://$TenantDomain-admin.sharepoint.com"
        Connect-IPPSSession
        
        # Create output directory
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        
        # Initialize scoring
        $securityScore = 0
        $maxScore = 100
        $findings = @()
    }
    
    Process {
        # 1. External Sharing Assessment (20 points)
        Write-Progress -Activity "Security Assessment" -Status "Checking external sharing..." -PercentComplete 10
        $externalSharing = Get-SPOSite -Limit All | Where-Object {
            $_.SharingCapability -ne 'Disabled'
        }
        
        if ($externalSharing.Count -eq 0) {
            $securityScore += 20
            $findings += [PSCustomObject]@{
                Category = "External Sharing"
                Status = "Pass"
                Score = 20
                Details = "No sites have external sharing enabled"
            }
        } else {
            $points = [Math]::Max(0, 20 - ($externalSharing.Count * 2))
            $securityScore += $points
            $findings += [PSCustomObject]@{
                Category = "External Sharing"
                Status = "Warning"
                Score = $points
                Details = "$($externalSharing.Count) sites have external sharing enabled"
                Remediation = "Review and restrict external sharing where appropriate"
            }
        }
        
        # 2. Sensitivity Label Coverage (25 points)
        Write-Progress -Activity "Security Assessment" -Status "Analyzing label coverage..." -PercentComplete 30
        $labeledContent = Get-MgDriveItem -All | Where-Object { $_.SensitivityLabel }
        $totalContent = (Get-MgDriveItem -All).Count
        $coveragePercent = if ($totalContent -gt 0) { 
            ($labeledContent.Count / $totalContent) * 100 
        } else { 0 }
        
        $labelPoints = [Math]::Round($coveragePercent / 4, 0)  # Max 25 points
        $securityScore += $labelPoints
        
        $findings += [PSCustomObject]@{
            Category = "Sensitivity Labels"
            Status = if ($coveragePercent -gt 75) { "Pass" } elseif ($coveragePercent -gt 50) { "Warning" } else { "Fail" }
            Score = $labelPoints
            Details = "$([Math]::Round($coveragePercent, 2))% of content has sensitivity labels"
            Remediation = if ($coveragePercent -lt 75) { "Increase label coverage to at least 75%" }
        }
        
        # 3. DLP Policy Configuration (20 points)
        Write-Progress -Activity "Security Assessment" -Status "Checking DLP policies..." -PercentComplete 50
        $dlpPolicies = Get-DlpCompliancePolicy | Where-Object {
            $_.Location -contains "Microsoft365Copilot"
        }
        
        if ($dlpPolicies.Count -gt 0) {
            $securityScore += 20
            $findings += [PSCustomObject]@{
                Category = "DLP Policies"
                Status = "Pass"
                Score = 20
                Details = "$($dlpPolicies.Count) DLP policies configured for Copilot"
            }
        } else {
            $findings += [PSCustomObject]@{
                Category = "DLP Policies"
                Status = "Fail"
                Score = 0
                Details = "No DLP policies configured for Copilot location"
                Remediation = "Create DLP policies targeting Microsoft365Copilot location"
            }
        }
        
        # 4. Guest Access Review (15 points)
        Write-Progress -Activity "Security Assessment" -Status "Reviewing guest access..." -PercentComplete 70
        $guestUsers = Get-MgUser -Filter "userType eq 'Guest'" -All
        
        if ($guestUsers.Count -eq 0) {
            $securityScore += 15
            $findings += [PSCustomObject]@{
                Category = "Guest Access"
                Status = "Pass"
                Score = 15
                Details = "No guest users in tenant"
            }
        } else {
            $activeGuests = $guestUsers | Where-Object {
                $_.SignInActivity.LastSignInDateTime -gt (Get-Date).AddDays(-90)
            }
            
            $guestPoints = [Math]::Max(0, 15 - ($activeGuests.Count))
            $securityScore += $guestPoints
            
            $findings += [PSCustomObject]@{
                Category = "Guest Access"
                Status = "Warning"
                Score = $guestPoints
                Details = "$($guestUsers.Count) total guests, $($activeGuests.Count) active in last 90 days"
                Remediation = "Review and remove unnecessary guest access"
            }
        }
        
        # 5. Conditional Access (20 points)
        Write-Progress -Activity "Security Assessment" -Status "Checking conditional access..." -PercentComplete 90
        $caPolicies = Get-MgConditionalAccessPolicy -All | Where-Object {
            $_.Conditions.Applications.IncludeApplications -contains "Microsoft 365 Copilot"
        }
        
        if ($caPolicies.Count -gt 0) {
            $securityScore += 20
            $findings += [PSCustomObject]@{
                Category = "Conditional Access"
                Status = "Pass"
                Score = 20
                Details = "$($caPolicies.Count) Conditional Access policies apply to Copilot"
            }
        } else {
            $findings += [PSCustomObject]@{
                Category = "Conditional Access"
                Status = "Warning"
                Score = 10
                Details = "No specific Conditional Access policies for Copilot"
                Remediation = "Consider creating Copilot-specific CA policies"
            }
            $securityScore += 10
        }
    }
    
    End {
        Write-Progress -Activity "Security Assessment" -Completed
        
        # Generate final report
        $finalScore = [Math]::Round(($securityScore / $maxScore) * 100, 2)
        
        $report = @{
            AssessmentDate = Get-Date
            TenantDomain = $TenantDomain
            OverallScore = $finalScore
            SecurityPosture = switch ($finalScore) {
                {$_ -ge 90} { "Excellent - Ready for Copilot" }
                {$_ -ge 75} { "Good - Minor improvements needed" }
                {$_ -ge 60} { "Fair - Several improvements recommended" }
                {$_ -ge 40} { "Poor - Significant work required" }
                default { "Critical - Major security gaps" }
            }
            Findings = $findings
        }
        
        # Export detailed findings
        $findings | Export-Csv -Path "$OutputPath\SecurityFindings.csv" -NoTypeInformation
        
        # Generate HTML report
        $htmlReport = ConvertTo-Html -Head @"
<style>
    body { font-family: Arial, sans-serif; }
    h1 { color: #0078d4; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #0078d4; color: white; }
    .pass { background-color: #d4edda; }
    .warning { background-color: #fff3cd; }
    .fail { background-color: #f8d7da; }
</style>
"@ -Body @"
<h1>Copilot Security Readiness Assessment</h1>
<p><strong>Date:</strong> $(Get-Date)</p>
<p><strong>Tenant:</strong> $TenantDomain</p>
<h2>Overall Score: $finalScore% - $($report.SecurityPosture)</h2>
$(
    $findings | ConvertTo-Html -Fragment | Out-String
)
"@
        
        $htmlReport | Out-File -FilePath "$OutputPath\AssessmentReport.html"
        
        # Display summary
        Write-Host "`n" -NoNewline
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║        COPILOT SECURITY READINESS ASSESSMENT COMPLETE      ║" -ForegroundColor Cyan
        Write-Host "╠═══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║ Overall Score: $finalScore%".PadRight(60) + "║" -ForegroundColor $(if ($finalScore -ge 75) { "Green" } elseif ($finalScore -ge 50) { "Yellow" } else { "Red" })
        Write-Host "║ Security Posture: $($report.SecurityPosture)".PadRight(60) + "║" -ForegroundColor White
        Write-Host "╠═══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        
        foreach ($finding in $findings) {
            $color = switch ($finding.Status) {
                "Pass" { "Green" }
                "Warning" { "Yellow" }
                "Fail" { "Red" }
            }
            Write-Host "║ $($finding.Category): $($finding.Status) (Score: $($finding.Score))".PadRight(60) + "║" -ForegroundColor $color
        }
        
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host "`nDetailed reports saved to: $OutputPath" -ForegroundColor Green
        
        # Return the report object
        return $report
    }
}

# Additional functions would follow...
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *