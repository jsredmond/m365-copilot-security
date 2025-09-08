# Financial Services Compliance Configuration
# SOC 2 Type II and PCI DSS Requirements
# Version: 2.0

function Configure-CopilotForFinancial {
    # PCI DSS specific controls
    $pciDssControls = @{
        # Requirement 3: Protect stored cardholder data
        CardholderDataProtection = @{
            DLPRules = @(
                @{Name="PAN-Primary"; Type="Credit Card Number"; Action="Block"},
                @{Name="PAN-Tokenized"; Pattern="TOK[0-9]{13,19}"; Action="Warn"}
            )
            Labels = @("Cardholder-Data", "PCI-Restricted")
            Encryption = "Required"
            RetentionDays = 90  # PCI DSS 3.1
        }
        
        # Requirement 7: Restrict access by business need-to-know
        AccessControl = @{
            RestrictedSearch = $true
            ConditionalAccess = @{
                RequireMFA = $true
                RequireCompliantDevice = $true
                BlockLegacyAuth = $true
            }
        }
        
        # Requirement 10: Track and monitor all access
        Logging = @{
            AuditLogRetention = 365  # 1 year minimum
            AlertOnSensitiveAccess = $true
            SIEMIntegration = "Sentinel"
        }
    }
    
    # Implement controls
    foreach ($control in $pciDssControls.GetEnumerator()) {
        Write-Host "Implementing: $($control.Key)" -ForegroundColor Yellow
        
        switch ($control.Key) {
            "CardholderDataProtection" {
                foreach ($rule in $control.Value.DLPRules) {
                    New-DlpComplianceRule -Policy "PCI-DSS-Copilot" @rule
                }
            }
            "AccessControl" {
                if ($control.Value.RestrictedSearch) {
                    Set-SPOTenant -RestrictedAccessControlType 2
                }
            }
            "Logging" {
                Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
                Set-AdminAuditLogConfig -AuditLogAgeLimit $control.Value.AuditLogRetention
            }
        }
    }
    
    Write-Host "Financial services compliance configuration completed" -ForegroundColor Green
}