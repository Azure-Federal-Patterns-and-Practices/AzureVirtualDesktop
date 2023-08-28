param SecurityLogAnalyticsWorkspaceResourceId string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: split(SecurityLogAnalyticsWorkspaceResourceId, '/')[8]
  scope: resourceGroup(split(SecurityLogAnalyticsWorkspaceResourceId, '/')[2], split(SecurityLogAnalyticsWorkspaceResourceId, '/')[4])

}

output LogAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
