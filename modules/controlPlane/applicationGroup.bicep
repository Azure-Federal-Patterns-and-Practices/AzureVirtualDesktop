param DesktopApplicationGroupName string
param HostPoolResourceId string
param Location string
param RoleDefinitions object
param SecurityPrincipalIds array
param TagsApplicationGroup object

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  name: DesktopApplicationGroupName
  location: Location
  tags: TagsApplicationGroup
  properties: {
    hostPoolArmPath: HostPoolResourceId
    applicationGroupType: 'Desktop'
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(SecurityPrincipalIds)): {
  scope: applicationGroup
  name: guid(SecurityPrincipalIds[i], RoleDefinitions.DesktopVirtualizationUser, DesktopApplicationGroupName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitions.DesktopVirtualizationUser)
    principalId: SecurityPrincipalIds[i]
  }
}]


output ApplicationGroupReference array = [
  applicationGroup.id
]
