# Generate Copilot Readiness Metrics Dashboard
# Version: 2.0

function Get-CopilotReadinessMetrics {
    param(
        [datetime]$StartDate,
        [datetime]$EndDate
    )
    
    $metrics = [PSCustomObject]@{
        # Security Metrics
        ExternalSharingReduction = (Get-SPOSite -Limit All | Where-Object {
            $_.SharingCapability -eq 'Disabled'
        }).Count
        
        # Label Adoption
        LabelCoverage = (Get-MgDriveItem -All | Where-Object {
            $_.SensitivityLabel
        }).Count / (Get-MgDriveItem -All).Count * 100
        
        # DLP Effectiveness
        DLPBlockedAttempts = (Get-DlpDetailReport -StartDate $StartDate -EndDate $EndDate |
            Where-Object { $_.Action -eq 'Blocked' }).Count
        
        # User Adoption
        ActiveCopilotUsers = (Get-MgAuditLogSignIn -Filter "appId eq 'copilot-app-id'" |
            Select-Object -Unique UserId).Count
        
        # Compliance Score
        PurviewComplianceScore = (Get-ComplianceScore).Score
    }
    
    return $metrics
}

# Generate weekly reports
$weeklyMetrics = Get-CopilotReadinessMetrics -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
$weeklyMetrics | Export-Csv -Path ".\WeeklyCopilotMetrics_$(Get-Date -Format 'yyyyMMdd').csv"