#ExecutionPolicy
$ExecutionPolicy = Get-ExecutionPolicy

Set-ExecutionPolicy -ExecutionPolicy Unrestricted

# Check if module exist
if (Get-Module -ListAvailable -Name Microsoft.Graph.Intune) {
Write-Host "Module exists"
}
else {
Write-Host "Module does not exist... installing"
Install-Module -Name Microsoft.Graph.Intune
}

# Connect and change schema
Import-Module -Name Microsoft.Graph.Intune
Connect-MSGraph -ForceInteractive
Update-MSGraphEnvironment -SchemaVersion beta
 
# Which AAD group do we want to check against
$groupName = Read-Host "Enter the name of the group"
$FilePath = Read-Host "Enter the path you want to save this information"
 
#$Groups = Get-AADGroup | Get-MSGraphAllPages
$Group = Get-AADGroup -Filter "displayname eq '$GroupName'"
 
#### Config Don't change
 
Write-host "AAD Group Name: $($Group.displayName)" -ForegroundColor Green
 
# Apps
$AllAssignedApps = Get-IntuneMobileApp -Filter "isAssigned eq true" -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments | Where-Object {$_.assignments -match $Group.id}
Write-host "Number of Apps found: $($AllAssignedApps.DisplayName.Count)" -ForegroundColor cyan
Foreach ($Config in $AllAssignedApps) {
 
Write-host $Config.displayName -ForegroundColor Yellow
 
}

$AllAssignedApps | Out-File -Filepath $FilePath\$Group\$groupName-Apps.txt 
 
# Device Compliance
$AllDeviceCompliance = Get-IntuneDeviceCompliancePolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments | Where-Object {$_.assignments -match $Group.id}
Write-host "Number of Device Compliance policies found: $($AllDeviceCompliance.DisplayName.Count)" -ForegroundColor cyan
Foreach ($Config in $AllDeviceCompliance) {
 
Write-host $Config.displayName -ForegroundColor Yellow

}

$AllDeviceCompliance | Out-File -Filepath $FilePath\$groupName-DeviceCompliance.txt
 
# Device Configuration
$AllDeviceConfig = Get-IntuneDeviceConfigurationPolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments | Where-Object {$_.assignments -match $Group.id}
Write-host "Number of Device Configurations found: $($AllDeviceConfig.DisplayName.Count)" -ForegroundColor cyan
Foreach ($Config in $AllDeviceConfig) {
 
Write-host $Config.displayName -ForegroundColor Yellow
 
}

$AllDeviceConfig | Out-File -Filepath $FilePath\$groupName-DeviceConfig.txt
 
# Device Configuration Powershell Scripts 
$Resource = "deviceManagement/deviceManagementScripts"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=groupAssignments"
$DMS = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllDeviceConfigScripts = $DMS.value | Where-Object {$_.groupassignments -match $Group.id}
Write-host "Number of Device Configurations Powershell Scripts found: $($AllDeviceConfigScripts.DisplayName.Count)" -ForegroundColor cyan
 
Foreach ($Config in $AllDeviceConfigScripts) {
 
Write-host $Config.displayName -ForegroundColor Yellow
 
}
 
$AllDeviceConfigScripts | Out-File -Filepath $FilePath\$groupName-DeviceConfigScripts.txt 
 
# Administrative templates
$Resource = "deviceManagement/groupPolicyConfigurations"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$ADMT = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllADMT = $ADMT.value | Where-Object {$_.assignments -match $Group.id}
Write-host "Number of Device Administrative Templates found: $($AllADMT.DisplayName.Count)" -ForegroundColor cyan
Foreach ($Config in $AllADMT) {
 
Write-host $Config.displayName -ForegroundColor Yellow

}

$AllADMT | Out-File -Filepath $FilePath\$groupName-AdminTemplates.txt

# Set to Default the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy