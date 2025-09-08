# Create Comprehensive Sensitivity Label Taxonomy
# Version: 2.0

#Requires -Module ExchangeOnlineManagement

Connect-IPPSSession

# Define label taxonomy based on Microsoft best practices
$labelTaxonomy = @(
    @{
        Name = "Public"
        DisplayName = "Public"
        Priority = 0
        Tooltip = "Content that can be shared publicly without restrictions"
        Color = "Green"
    },
    @{
        Name = "Internal"
        DisplayName = "Internal Use Only"
        Priority = 1
        Tooltip = "Default label for internal business content"
        Color = "Blue"
        DefaultLabel = $true
    },
    @{
        Name = "Confidential"
        DisplayName = "Confidential"
        Priority = 2
        Tooltip = "Sensitive business information requiring protection"
        Color = "Orange"
        EncryptionEnabled = $true
        ContentMarkingEnabled = $true
    },
    @{
        Name = "HighlyConfidential"
        DisplayName = "Highly Confidential - Restricted"
        Priority = 3
        Tooltip = "Highly sensitive data with restricted access"
        Color = "Red"
        EncryptionEnabled = $true
        ContentMarkingEnabled = $true
        ExcludeFromCopilot = $true
    }
)

foreach ($label in $labelTaxonomy) {
    $params = @{
        DisplayName = $label.DisplayName
        Name = $label.Name
        Priority = $label.Priority
        Tooltip = $label.Tooltip
    }
    
    # Create base label
    $createdLabel = New-Label @params
    
    # Configure encryption if specified
    if ($label.EncryptionEnabled) {
        Set-Label -Identity $label.Name -EncryptionEnabled $true `
            -EncryptionProtectionType Template `
            -EncryptionPromptUser $true `
            -EncryptionContentExpiredOnDateInDaysOrNever Never
    }
    
    # Configure content marking
    if ($label.ContentMarkingEnabled) {
        Set-Label -Identity $label.Name `
            -ApplyContentMarkingHeaderEnabled $true `
            -ApplyContentMarkingHeaderText "$(label.DisplayName) - Do Not Share" `
            -ApplyContentMarkingHeaderFontSize 10 `
            -ApplyContentMarkingHeaderFontColor Red `
            -ApplyContentMarkingFooterEnabled $true `
            -ApplyContentMarkingFooterText "Classification: $(label.DisplayName)"
    }
    
    Write-Host "Created label: $($label.DisplayName)" -ForegroundColor Green
}

# Create auto-labeling policies
Write-Host "`nCreating auto-labeling policies..." -ForegroundColor Yellow

# Auto-label for financial data
New-AutoSensitivityLabelPolicy -Name "AutoLabel-Financial" `
    -ApplySensitivityLabel "Confidential" `
    -ExchangeLocation All `
    -SharePointLocation All `
    -OneDriveLocation All `
    -Mode TestWithoutNotifications

New-AutoSensitivityLabelRule -Policy "AutoLabel-Financial" `
    -Name "FinancialDataRule" `
    -ContentContainsSensitiveInformation @{Name="Credit Card Number"; MinCount=1} `
    -DocumentIsPasswordProtected $false

Write-Host "Auto-labeling policies created and set to test mode" -ForegroundColor Green