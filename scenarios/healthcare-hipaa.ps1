# HIPAA-Specific Copilot Configuration
# Version: 2.0

function Configure-CopilotForHIPAA {
    Connect-IPPSSession
    
    # Create HIPAA-specific labels
    $hipaaLabels = @(
        @{Name="PHI"; DisplayName="Protected Health Information"; Encryption=$true},
        @{Name="PII"; DisplayName="Personally Identifiable Information"; Encryption=$true},
        @{Name="MedicalRecords"; DisplayName="Medical Records - Restricted"; Encryption=$true}
    )
    
    foreach ($label in $hipaaLabels) {
        New-Label @label -EncryptionRightsDefinitions @{
            Users = "AuthenticatedUsers@contoso.com"
            Rights = "View", "Edit"
            ExpirationDate = (Get-Date).AddYears(7)  # HIPAA retention
        }
    }
    
    # Create HIPAA DLP policy for Copilot
    $hipaaDLP = New-DlpPolicy -Name "HIPAA-Copilot-Protection" `
        -Location "Microsoft365Copilot" `
        -Mode Enforce
    
    # Add HIPAA-specific rules
    $hippaSensitiveTypes = @(
        "U.S. Medical Record Number",
        "U.S. Medicare Beneficiary Identifier",
        "Drug Enforcement Agency (DEA) Number",
        "International Classification of Diseases (ICD-9-CM)",
        "International Classification of Diseases (ICD-10-CM)"
    )
    
    foreach ($type in $hippaSensitiveTypes) {
        New-DlpComplianceRule -Policy "HIPAA-Copilot-Protection" `
            -Name "Block-$type" `
            -ContentContainsSensitiveInformation @{Name=$type; MinCount=1} `
            -BlockAccess $true `
            -GenerateIncidentReport "hipaa-compliance@contoso.com"
    }
    
    Write-Host "HIPAA compliance configuration completed" -ForegroundColor Green
}