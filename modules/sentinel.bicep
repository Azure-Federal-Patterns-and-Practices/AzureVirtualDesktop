param Sentinel bool
param SentinelLogAnalyticsWorkspaceName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: SentinelLogAnalyticsWorkspaceName
}

output sentinelWorkspaceId string = Sentinel ? logAnalyticsWorkspace.properties.customerId : 'NotApplicable'
