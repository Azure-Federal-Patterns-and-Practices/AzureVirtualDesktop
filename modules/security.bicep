param SecurityLogAnalyticsWorkspaceName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: SecurityLogAnalyticsWorkspaceName
}

output LogAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
