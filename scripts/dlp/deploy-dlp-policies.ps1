# Create and Deploy DLP Policies for Copilot
# Version: 2.0

#Requires -Module ExchangeOnlineManagement

Connect-IPPSSession

# Create DLP policy for Copilot location
$dlpPolicy = New-DlpPolicy -Name "Copilot-Protection-Policy" `
    -Mode TestWithoutNotifications `
    -Priority 1

# Add Copilot location to policy
Set-DlpPolicy -Identity "Copilot-Protection-Policy" `
    -Location "Microsoft365Copilot"

# Create rules for the policy
# Rule 1: Block Highly Confidential
New-DlpComplianceRule -Policy "Copilot-Protection-Policy" `
    -Name "Block-HighlyConfidential" `
    -ContentContainsSensitivityLabel @("HighlyConfidential") `
    -BlockAccess $true `
    -NotifyUser Owner `
    -NotifyUserType NotSet `
    -Priority 1

# Rule 2: Block Personal Information
New-DlpComplianceRule -Policy "Copilot-Protection-Policy" `
    -Name "Block-PersonalData" `
    -ContentContainsSensitiveInformation @{
        Name = "U.S. Social Security Number (SSN)"
        MinCount = 1
        ConfidenceLevel = 85
    } `
    -BlockAccess $true `
    -GenerateAlert $true `
    -Priority 2

# Test the policy first
Write-Host "DLP Policy created in TEST mode" -ForegroundColor Yellow
Write-Host "Monitor for 48 hours before enforcing" -ForegroundColor Yellow

# Schedule enforcement after testing
$enforcementDate = (Get-Date).AddDays(2)
Write-Host "Policy will be enforced on: $enforcementDate" -ForegroundColor Cyan