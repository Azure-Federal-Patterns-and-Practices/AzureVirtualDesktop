targetScope = 'subscription' 

param Location string
param ResourceGroupManagement string
param Timestamp string
param UserAssignedIdentityClientId string
param VirtualMachineName string

module removeManagementVirtualMachine 'removeVirtualMachine.bicep' = {
  scope: resourceGroup(ResourceGroupManagement)
  name: 'RemoveManagementVirtualMachine_${Timestamp}'
  params: {
    Location: Location
    UserAssignedIdentityClientId: UserAssignedIdentityClientId
    VirtualMachineName: VirtualMachineName
  }
}
