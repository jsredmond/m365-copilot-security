# Configure Labels for Copilot-Specific Restrictions
# Based on MC937930 and Microsoft documentation

# Set advanced settings to exclude from Copilot processing
$highlySensitiveLabel = Get-Label -Identity "HighlyConfidential"

# Configure label to prevent Copilot summarization
Set-Label -Identity $highlySensitiveLabel.ImmutableId `
    -AdvancedSettings @{
        "BlockCopilotSummarization" = "true"
        "RequireDownlevelVerification" = "true"
        "DisableMandatoryBeforeOpen" = "false"
    }

# Create label policy for deployment
New-LabelPolicy -Name "CopilotReadinessPolicy" `
    -Labels @("Public", "Internal", "Confidential", "HighlyConfidential") `
    -SharePointLocation All `
    -OneDriveLocation All `
    -ExchangeLocation All `
    -ModernGroupLocation All `
    -Settings @{
        "MandatoryBeforeOpen" = "true"
        "DefaultLabel" = "Internal"
        "RequireJustificationOnLabelChange" = "true"
    }

Write-Host "Labels configured for Copilot security" -ForegroundColor Green