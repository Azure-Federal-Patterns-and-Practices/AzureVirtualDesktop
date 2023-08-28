param SecurityLogAnalyticsWorkspaceResourceId string

var Name = empty(SecurityLogAnalyticsWorkspaceResourceId) ? '' : split(SecurityLogAnalyticsWorkspaceResourceId, '/')[8]
var ResourceGroupName = empty(SecurityLogAnalyticsWorkspaceResourceId) ? resourceGroup().name : split(SecurityLogAnalyticsWorkspaceResourceId, '/')[4]
var SubscriptionId = empty(SecurityLogAnalyticsWorkspaceResourceId) ? subscription().subscriptionId : split(SecurityLogAnalyticsWorkspaceResourceId, '/')[8]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: Name
  scope: resourceGroup(SubscriptionId, ResourceGroupName)
}

output LogAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
