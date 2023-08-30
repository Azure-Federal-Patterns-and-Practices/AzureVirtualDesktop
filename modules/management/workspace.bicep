param ApplicationGroupReferences array
param Existing bool
param FriendlyName string
param Location string
param LogAnalyticsWorkspaceResourceId string = ''
param Monitoring bool = false
param Tags object = {}
param WorkspaceName string

resource existingWorkspace 'Microsoft.DesktopVirtualization/workspaces@2021-03-09-preview' existing = if (Existing) {
  name: WorkspaceName
}

resource newWorkspace 'Microsoft.DesktopVirtualization/workspaces@2021-03-09-preview' = if (!Existing) {
  name: WorkspaceName
  location: Location
  tags: Tags
  properties: {
    applicationGroupReferences: ApplicationGroupReferences
    friendlyName: '${FriendlyName} (${Location})'
  }
}

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!Existing && Monitoring) {
  name: 'diag-${WorkspaceName}'
  scope: newWorkspace
  properties: {
    logs: [
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
        category: 'Feed'
        enabled: true
      }
    ]
    workspaceId: LogAnalyticsWorkspaceResourceId
  }
}

output applicationGroupReferences array = Existing ? existingWorkspace.properties.applicationGroupReferences : []
output tags object = Existing ? existingWorkspace.tags : Tags
