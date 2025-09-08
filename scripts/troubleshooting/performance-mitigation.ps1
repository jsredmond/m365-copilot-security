# Performance Monitoring and Optimization
# Version: 2.0

function Monitor-CopilotPerformance {
    Connect-MgGraph -Scopes "Reports.Read.All"
    
    # Get performance metrics
    $performanceData = @{
        ResponseTime = (Get-MgReportCopilotUsage -Period 'D7' | 
            Measure-Object -Property ResponseTimeMs -Average).Average
        
        ThrottlingEvents = (Get-MgAuditLogDirectoryAudit -Filter "category eq 'Copilot' and result eq 'Throttled'" |
            Measure-Object).Count
        
        ConcurrentUsers = (Get-MgReportCopilotUsage -Period 'D1' |
            Measure-Object -Property ConcurrentUsers -Maximum).Maximum
    }
    
    # Recommendations based on metrics
    $recommendations = @()
    
    if ($performanceData.ResponseTime -gt 3000) {
        $recommendations += "Consider implementing caching for frequently accessed content"
        $recommendations += "Review and optimize search scopes"
    }
    
    if ($performanceData.ThrottlingEvents -gt 100) {
        $recommendations += "Implement request rate limiting"
        $recommendations += "Consider staggered rollout to reduce load"
    }
    
    if ($performanceData.ConcurrentUsers -gt 500) {
        $recommendations += "Monitor tenant resource utilization"
        $recommendations += "Consider peak usage scheduling"
    }
    
    return [PSCustomObject]@{
        Metrics = $performanceData
        Recommendations = $recommendations
        Timestamp = Get-Date
    }
}