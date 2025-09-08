# Enable Restricted SharePoint Search for Copilot
# Version: 2.0
# Based on Microsoft documentation MC696169

#Requires -Module Microsoft.Online.SharePoint.PowerShell

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Enable", "Disable", "Status")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$AllowedSitesCSV = ".\AllowedSites.csv"
)

# Connect to SharePoint Online
$adminUrl = $TenantUrl.Replace(".sharepoint.com", "-admin.sharepoint.com")
Connect-SPOService -Url $adminUrl

switch ($Action) {
    "Enable" {
        Write-Host "Enabling Restricted SharePoint Search..." -ForegroundColor Green
        
        # Enable Restricted Tenant Search Mode
        Set-SPOTenant -RestrictedAccessControlType 2
        
        # Configure allowed sites list
        if (Test-Path $AllowedSitesCSV) {
            $sites = Import-Csv $AllowedSitesCSV
            Add-SPOTenantRestrictedSearchAllowedList -SitesListFileUrl $AllowedSitesCSV -ContainsHeader $true
            Write-Host "Added $($sites.Count) sites to allowed list" -ForegroundColor Green
        } else {
            # Add critical sites individually
            $criticalSites = @(
                "https://contoso.sharepoint.com/sites/HRPolicies",
                "https://contoso.sharepoint.com/sites/CompanyNews",
                "https://contoso.sharepoint.com/sites/ITResources"
            )
            
            Add-SPOTenantRestrictedSearchAllowedList -SitesList $criticalSites
            Write-Host "Added $($criticalSites.Count) critical sites to allowed list" -ForegroundColor Green
        }
        
        Write-Host "Restricted SharePoint Search enabled successfully" -ForegroundColor Green
        Write-Host "Note: Changes may take up to 24 hours to fully propagate" -ForegroundColor Yellow
    }
    
    "Disable" {
        Write-Host "Disabling Restricted SharePoint Search..." -ForegroundColor Yellow
        Set-SPOTenant -RestrictedAccessControlType 0
        Write-Host "Restricted SharePoint Search disabled" -ForegroundColor Green
    }
    
    "Status" {
        $currentStatus = Get-SPOTenant | Select-Object RestrictedAccessControlType
        $allowedList = Get-SPOTenantRestrictedSearchAllowedList
        
        Write-Host "`nRestricted Search Status:" -ForegroundColor Cyan
        Write-Host "Mode: $(if ($currentStatus.RestrictedAccessControlType -eq 2) { 'Enabled' } else { 'Disabled' })"
        Write-Host "Sites in Allowed List: $($allowedList.Count)"
        
        if ($allowedList.Count -gt 0 -and $allowedList.Count -le 10) {
            Write-Host "`nAllowed Sites:" -ForegroundColor Gray
            $allowedList | ForEach-Object { Write-Host "  - $_" }
        }
    }
}

# Additional Configuration for Restricted Content Discovery
Write-Host "`nConfiguring Restricted Content Discovery per site..." -ForegroundColor Yellow

# Sites that should be excluded from Copilot discovery
$restrictedSites = @(
    "https://contoso.sharepoint.com/sites/ExecutiveConfidential",
    "https://contoso.sharepoint.com/sites/M&A",
    "https://contoso.sharepoint.com/sites/LegalPrivileged"
)

foreach ($site in $restrictedSites) {
    try {
        Set-SPOSite -Identity $site -RestrictContentOrgWideSearch $true
        Write-Host "Restricted discovery for: $site" -ForegroundColor Green
    } catch {
        Write-Host "Failed to restrict: $site - $_" -ForegroundColor Red
    }
}

Disconnect-SPOService