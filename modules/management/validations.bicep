param ArtifactsLocation string
param Availability string
param Location string
param SessionHostCount int
param Tags object
param Timestamp string
param UserAssignedIdentityClientId string
param VirtualMachineName string
param VirtualMachineSize string
param WorkspaceName string

module cpuQuota 'customScriptExtensions.bicep' = {
  name: 'CSE_ValidateCpuQuota_${Timestamp}'
  params: {
    ArtifactsLocation: ArtifactsLocation
    File: ''
    Location: Location
    Arguments: '-Location ${Location} -SessionHostCount ${SessionHostCount} -VmSize ${VirtualMachineSize}'
    Script: 'param([string]$Location,[int]$SessionHostCount,[string]$VmSize); $ErrorActionPreference = "Stop"; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; $vCPUs = [int]($Sku.capabilities | Where-Object {$_.name -eq "vCPUs"}).value; $RequestedCores = $vCPUs * $SessionHostCount; $Family = (Get-AzComputeResourceSku -Location $Location | Where-Object {$_.Name -eq $VmSize}).Family; $CpuData = Get-AzVMUsage -Location $Location | Where-Object {$_.Name.Value -eq $Family}; $AvailableCores = $CpuData.Limit - $CpuData.CurrentValue; $RequestedCores = $vCPUs * $SessionHostCount; if($RequestedCores -gt $AvailableCores){Write-Error -Exception "INSUFFICIENT CORE QUOTA: The selected VM size, $VmSize, does not have adequate core quota in the selected location."}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["requestedCores"] = $RequestedCores; $DeploymentScriptOutputs["availableCores"] = $AvailableCores'
    Tags: Tags
    UserAssignedIdentityClientId: UserAssignedIdentityClientId
    VirtualMachineName: VirtualMachineName
  }
  dependsOn: [
    cpuCount
  ]
}

module workspace 'customScriptExtensions.bicep' = {
  name: 'CSE_ValidateWorkspace_${Timestamp}'
  params: {
    ArtifactsLocation: ArtifactsLocation
    File: ''
    Location: Location
    Arguments: '-ResourceGroupName ${resourceGroup().name} -ResourceName ${WorkspaceName}'
    Script: 'param([string]$ResourceGroupName,[string]$ResourceName); $ErrorActionPreference = "Stop"; $Value = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName; $Output = if($Value){"true"}else{"false"}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["existing"] = $Output'
    Tags: Tags
    UserAssignedIdentityClientId: UserAssignedIdentityClientId
    VirtualMachineName: VirtualMachineName
  }
  dependsOn: [
    cpuQuota
  ]
}

output acceleratedNetworking string = acceleratedNetworking.outputs.value
output anfActiveDirectory string = azureNetAppFiles.outputs.value
output anfDnsServers string = azureNetAppFiles.outputs.value
output anfSubnetId string = azureNetAppFiles.outputs.value
output availabilityZones array = Availability == 'AvailabilityZones' ? json(availabilityZones.outputs.value) : [ '1' ]
output existingWorkspace string = workspace.outputs.value
output trustedLaunch string = trustedLaunch.outputs.value
