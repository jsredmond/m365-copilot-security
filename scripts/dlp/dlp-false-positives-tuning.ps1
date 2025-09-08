# DLP False Positive Analysis and Tuning
# Version: 2.0

function Analyze-DLPFalsePositives {
    param(
        [string]$PolicyName,
        [int]$Days = 7
    )
    
    Connect-IPPSSession
    
    # Get DLP incidents
    $incidents = Get-DlpDetailReport -StartDate (Get-Date).AddDays(-$Days) -EndDate (Get-Date) |
        Where-Object { $_.PolicyName -eq $PolicyName }
    
    # Analyze patterns
    $falsePositivePatterns = $incidents | Group-Object RuleName | ForEach-Object {
        $rule = $_.Name
        $items = $_.Group
        
        # Check for common false positive indicators
        $potentialFP = $items | Where-Object {
            $_.FileType -in @('.log', '.csv', '.tmp') -or
            $_.FilePath -match 'test|temp|draft|template' -or
            $_.Justification -match 'false positive|not sensitive|test data'
        }
        
        [PSCustomObject]@{
            Rule = $rule
            TotalMatches = $items.Count
            PotentialFalsePositives = $potentialFP.Count
            FPRate = [math]::Round(($potentialFP.Count / $items.Count) * 100, 2)
            RecommendedAction = if (($potentialFP.Count / $items.Count) -gt 0.3) {
                "Consider adding exclusions or adjusting confidence levels"
            } else {
                "Rule performing as expected"
            }
        }
    }
    
    return $falsePositivePatterns
}

# Implement exclusions based on analysis
function Add-DLPExclusions {
    param(
        [string]$PolicyName,
        [string[]]$ExcludePaths,
        [string[]]$ExcludeLabels
    )
    
    $policy = Get-DlpCompliancePolicy -Identity $PolicyName
    
    foreach ($rule in (Get-DlpComplianceRule -Policy $PolicyName)) {
        # Add path exclusions
        if ($ExcludePaths) {
            Set-DlpComplianceRule -Identity $rule.Name `
                -ExceptIfDocumentIsInPath $ExcludePaths
        }
        
        # Add label exclusions
        if ($ExcludeLabels) {
            Set-DlpComplianceRule -Identity $rule.Name `
                -ExceptIfContentContainsSensitivityLabel $ExcludeLabels
        }
    }
    
    Write-Host "Exclusions added to policy: $PolicyName" -ForegroundColor Green
}