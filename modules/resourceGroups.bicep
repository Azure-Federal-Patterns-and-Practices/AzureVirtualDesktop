targetScope = 'subscription'

param LocationControlPlane string
param LocationVirtualMachines string
param ResourceGroups array
param Tags object

resource resourceGroups 'Microsoft.Resources/resourceGroups@2020-10-01' = [for i in range(0, length(ResourceGroups)): {
  name: ResourceGroups[i]
  location: contains(ResourceGroups[i], 'controlPlane') ? LocationControlPlane : LocationVirtualMachines
  tags: contains(Tags, 'Microsoft.Resources/resourceGroups') ? Tags['Microsoft.Resources/resourceGroups'] : {}
}]
