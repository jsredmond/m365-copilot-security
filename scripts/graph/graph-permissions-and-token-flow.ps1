# Analyze Copilot Graph API Permissions
# Version: 2.0

function Get-CopilotGraphPermissions {
    Connect-MgGraph -Scopes "Application.Read.All", "DelegatedPermissionGrant.Read.All"
    
    # Get Copilot service principal
    $copilotSP = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft 365 Copilot'"
    
    # Get OAuth2 permission grants (delegated permissions)
    $delegatedPermissions = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $copilotSP.Id
    
    # Get app role assignments (application permissions)
    $appPermissions = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $copilotSP.Id
    
    # Analyze and document permissions
    $permissionAnalysis = @{
        DelegatedScopes = $delegatedPermissions | ForEach-Object {
            [PSCustomObject]@{
                Scope = $_.Scope
                ConsentType = $_.ConsentType
                PrincipalId = $_.PrincipalId
                ResourceId = $_.ResourceId
            }
        }
        
        ApplicationPermissions = $appPermissions | ForEach-Object {
            $resource = Get-MgServicePrincipal -ServicePrincipalId $_.ResourceId
            [PSCustomObject]@{
                Permission = $_.AppRoleId
                ResourceName = $resource.DisplayName
                PrincipalType = $_.PrincipalType
            }
        }
    }
    
    return $permissionAnalysis
}

# Monitor token usage and validate scopes
function Monitor-CopilotTokenUsage {
    # Parse JWT token claims
    function Parse-JWTtoken {
        param([string]$token)
        
        $tokenPayload = $token.Split(".")[1]
        $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
        $tokenArray = [System.Text.Encoding]::UTF8.GetString($tokenByteArray)
        $tokenObject = ConvertFrom-Json $tokenArray
        
        return $tokenObject
    }
    
    # Get current session token (requires admin consent)
    $context = Get-MgContext
    $token = $context.AuthContext.AccessToken
    
    $claims = Parse-JWTtoken -token $token
    
    return [PSCustomObject]@{
        Audience = $claims.aud
        Scopes = $claims.scp -split " "
        AppId = $claims.appid
        TenantId = $claims.tid
        ExpirationTime = [datetime]::new(1970,1,1,0,0,0,[DateTimeKind]::Utc).AddSeconds($claims.exp)
    }
}