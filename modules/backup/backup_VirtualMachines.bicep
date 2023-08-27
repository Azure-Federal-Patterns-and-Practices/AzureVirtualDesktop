param Location string
param PolicyId string
param RecoveryServicesVaultName string
param SessionHostCount int
param SessionHostIndex int
param Tags object
param VirtualMachineNamePrefix string
param VirtualMachineResourceGroupName string

var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'

resource protectedItems_Vm 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-08-01' = [for i in range(0, SessionHostCount): {
  name: '${RecoveryServicesVaultName}/Azure/${v2VmContainer}${VirtualMachineResourceGroupName};${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}/${v2Vm}${VirtualMachineResourceGroupName};${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: PolicyId
    sourceResourceId: resourceId(VirtualMachineResourceGroupName, 'Microsoft.Compute/virtualMachines', '${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}')
  }
}]
