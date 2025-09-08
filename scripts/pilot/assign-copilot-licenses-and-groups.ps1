# Assign Copilot licenses to pilot group
$pilotGroup = Get-MgGroup -Filter "displayName eq 'Copilot-Pilot-Users'"
$copilotSku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "Microsoft_365_Copilot" }

foreach ($user in (Get-MgGroupMember -GroupId $pilotGroup.Id)) {
    Set-MgUserLicense -UserId $user.Id -AddLicenses @{SkuId = $copilotSku.SkuId}
    Write-Host "Licensed: $($user.DisplayName)" -ForegroundColor Green
}