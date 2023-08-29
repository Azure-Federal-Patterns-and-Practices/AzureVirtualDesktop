param ActiveDirectorySolution string
param CustomRdpProperty string
param DesktopApplicationGroupName string
param HostPoolName string
param HostPoolType string
param Location string
param LogAnalyticsWorkspaceResourceId string
param MaxSessionLimit int
param Monitoring bool
param ResourceGroupManagement string
param SecurityPrincipalIds array
param TagsApplicationGroup object
param TagsHostPool object
param Timestamp string = utcNow('u')
param ValidationEnvironment bool
param VmTemplate string
param WorkspaceFriendlyName string
param WorkspaceName string

var CustomRdpProperty_Complete = ActiveDirectorySolution == 'AzureActiveDirectory' || ActiveDirectorySolution == 'AzureActiveDirectoryIntuneEnrollment' ? '${CustomRdpProperty}targetisaadjoined:i:1' : CustomRdpProperty
var DesktopVirtualizationUserRoleDefinitionResourceId = resourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
var HostPoolLogs = [
  {
    category: 'Checkpoint'
    enabled: true
  }
  {
    category: 'Error'
    enabled: true
  }
  {
    category: 'Management'
    enabled: true
  }
  {
    category: 'Connection'
    enabled: true
  }
  {
    category: 'HostRegistration'
    enabled: true
  }
  {
    category: 'AgentHealthStatus'
    enabled: true
  }
]

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' = {
  name: HostPoolName
  location: Location
  tags: TagsHostPool
  properties: {
    hostPoolType: split(HostPoolType, ' ')[0]
    maxSessionLimit: MaxSessionLimit
    loadBalancerType: contains(HostPoolType, 'Pooled') ? split(HostPoolType, ' ')[1] : 'Persistent'
    validationEnvironment: ValidationEnvironment
    registrationInfo: {
      expirationTime: dateTimeAdd(Timestamp, 'PT2H')
      registrationTokenOperation: 'Update'
    }
    preferredAppGroupType: 'Desktop'
    customRdpProperty: CustomRdpProperty_Complete
    personalDesktopAssignmentType: contains(HostPoolType, 'Personal') ? split(HostPoolType, ' ')[1] : null
    startVMOnConnect: true
    vmTemplate: VmTemplate

  }
}

resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (Monitoring) {
  name: 'diag-${HostPoolName}'
  scope: hostPool
  properties: {
    logs: HostPoolLogs
    workspaceId: LogAnalyticsWorkspaceResourceId
  }
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  name: DesktopApplicationGroupName
  location: Location
  tags: TagsApplicationGroup
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
  }
}

resource appGroupAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(SecurityPrincipalIds)): {
  scope: appGroup
  name: guid(SecurityPrincipalIds[i], DesktopVirtualizationUserRoleDefinitionResourceId, DesktopApplicationGroupName)
  properties: {
    roleDefinitionId: DesktopVirtualizationUserRoleDefinitionResourceId
    principalId: SecurityPrincipalIds[i]
  }
}]

module existingWorkspace 'workspace.bicep' = {
  name: 'Workspace_Existing_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    ApplicationGroupReferences: []
    Existing: true
    FriendlyName: WorkspaceFriendlyName
    Location: Location
    LogAnalyticsWorkspaceResourceId: ''
    Monitoring: false
    Tags: {}
    WorkspaceName: WorkspaceName
  }
}

module updateWorkspace 'workspace.bicep' = {
  name: 'Workspace_Update_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    ApplicationGroupReferences: union(existingWorkspace.outputs.applicationGroupReferences, [appGroup.id])
    Existing: false
    FriendlyName: WorkspaceFriendlyName
    Location: Location
    LogAnalyticsWorkspaceResourceId: ''
    Monitoring: false
    Tags: existingWorkspace.outputs.tags
    WorkspaceName: WorkspaceName
  }
}
