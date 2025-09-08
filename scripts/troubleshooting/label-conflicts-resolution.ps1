# Sensitivity Label Conflict Resolution
# Version: 2.0

function Resolve-LabelConflicts {
    param(
        [string]$SiteUrl
    )
    
    Connect-PnPOnline -Url $SiteUrl -Interactive
    
    # Identify files with multiple or conflicting labels
    $conflicts = Get-PnPListItem -List "Documents" -PageSize 5000 | ForEach-Object {
        $item = $_
        $labels = $item["SensitivityLabel"]
        $autoLabel = $item["AutoAppliedSensitivityLabel"]
        
        if ($labels -and $autoLabel -and $labels -ne $autoLabel) {
            [PSCustomObject]@{
                FileName = $item["FileLeafRef"]
                ManualLabel = $labels
                AutoLabel = $autoLabel
                LastModified = $item["Modified"]
                ModifiedBy = $item["Editor"].LookupValue
                Resolution = "Manual label takes precedence"
            }
        }
    }
    
    # Generate resolution report
    $conflicts | Export-Csv -Path ".\LabelConflicts_$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation
    
    # Apply resolution rules
    foreach ($conflict in $conflicts) {
        # Keep higher priority label
        $manualPriority = (Get-Label -Identity $conflict.ManualLabel).Priority
        $autoPriority = (Get-Label -Identity $conflict.AutoLabel).Priority
        
        if ($autoPriority -gt $manualPriority) {
            Write-Warning "Auto-label has higher priority for: $($conflict.FileName)"
            # Optionally update the label
        }
    }
    
    return $conflicts
}