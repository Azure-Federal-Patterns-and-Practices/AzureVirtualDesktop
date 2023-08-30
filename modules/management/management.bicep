targetScope = 'subscription'

param ActiveDirectorySolution string
param AutomationAccountName string
param Availability string
param AvdObjectId string
param LocationControlPlane string
param DeploymentScriptNamePrefix string
param DiskEncryption bool
param DiskEncryptionSetName string
param DiskSku string
param DomainName string
param DrainMode bool
param Environment string
param Fslogix bool
param FslogixSolution string
param FslogixStorage string
param HostPoolType string
param ImageSku string
param KerberosEncryption string
param KeyVaultName string
param LocationVirtualMachines string
param LogAnalyticsWorkspaceName string
param LogAnalyticsWorkspaceRetention int
param LogAnalyticsWorkspaceSku string
param Monitoring bool
param PooledHostPool bool
param RecoveryServices bool
param RecoveryServicesVaultName string
param ResourceGroupManagement string
param ResourceGroupStorage string
param RoleDefinitions object
param SecurityPrincipalIdsCount int
param SecurityPrincipalNamesCount int
param SessionHostCount int
param StorageCount int
param StorageSolution string
param SubnetResourceId string
param Tags object
param Timestamp string
param TimeZone string
param UserAssignedIdentityName string
param VirtualMachineSize string
param WorkspaceFriendlyName string
param WorkspaceName string

module userAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(ResourceGroupManagement)
  name: 'UserAssignedIdentity_${Timestamp}'
  params: {
    DiskEncryption: DiskEncryption
    DrainMode: DrainMode
    Fslogix: Fslogix
    FslogixStorage: FslogixStorage
    Location: LocationVirtualMachines
    UserAssignedIdentityName: UserAssignedIdentityName
    ResourceGroupStorage: ResourceGroupStorage
    Tags: contains(Tags, 'Microsoft.ManagedIdentity/userAssignedIdentities') ? Tags['Microsoft.ManagedIdentity/userAssignedIdentities'] : {}
    Timestamp: Timestamp
    VirtualNetworkResourceGroupName: split(SubnetResourceId, '/')[4]
  }
}

// Role Assignment for Validation
// This role assignment is required to collect validation information
resource roleAssignment_validation 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(UserAssignedIdentityName, RoleDefinitions.Reader, subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitions.Reader)
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deployment Validation
// This module validates the selected parameter values and collects required data
module validations 'validations.bicep' = {
  scope: resourceGroup(ResourceGroupManagement)
  name: 'Validations_${Timestamp}'
  params: {
    ActiveDirectorySolution: ActiveDirectorySolution
    Availability: Availability
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskSku: DiskSku
    DomainName: DomainName
    Fslogix: Fslogix
    HostPoolType: HostPoolType
    ImageSku: ImageSku
    KerberosEncryption: KerberosEncryption
    Location: LocationVirtualMachines
    SecurityPrincipalIdsCount: SecurityPrincipalIdsCount
    SecurityPrincipalNamesCount: SecurityPrincipalNamesCount
    SessionHostCount: SessionHostCount
    StorageCount: StorageCount
    StorageSolution: StorageSolution
    Tags: contains(Tags, 'Microsoft.Resources/deploymentScripts') ? Tags['Microsoft.Resources/deploymentScripts'] : {}
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.id
    VirtualMachineSize: VirtualMachineSize
    VnetName: split(SubnetResourceId, '/')[8]
    VnetResourceGroupName: split(SubnetResourceId, '/')[4]
    WorkspaceName: WorkspaceName
  }
}

// Role Assignment required for Start VM On Connect
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(AvdObjectId, RoleDefinitions.DesktopVirtualizationPowerOnContributor, subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitions.DesktopVirtualizationPowerOnContributor)
    principalId: AvdObjectId
  }
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with Windows Events & Windows Performance Counters plus diagnostic settings on the required resources 
module logAnalyticsWorkspace 'logAnalyticsWorkspace.bicep' = if (Monitoring) {
  name: 'Monitoring_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    LogAnalyticsWorkspaceRetention: LogAnalyticsWorkspaceRetention
    LogAnalyticsWorkspaceSku: LogAnalyticsWorkspaceSku
    Location: LocationVirtualMachines
    Tags: contains(Tags, 'Microsoft.OperationalInsights/workspaces') ? Tags['Microsoft.OperationalInsights/workspaces'] : {}
  }
}

// Automation Account required for the AVD Scaling Tool and the Auto Increase Premium File Share Quota solution
module automationAccount 'automationAccount.bicep' = if (PooledHostPool || contains(FslogixSolution, 'AzureStorageAccount Premium')) {
  name: 'AutomationAccount_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    AutomationAccountName: AutomationAccountName
    Location: LocationVirtualMachines
    LogAnalyticsWorkspaceResourceId: Monitoring ? logAnalyticsWorkspace.outputs.ResourceId : ''
    Monitoring: Monitoring
    Tags: contains(Tags, 'Microsoft.Automation/automationAccounts') ? Tags['Microsoft.Automation/automationAccounts'] : {}
  }
}

module diskEncryption 'diskEncryption.bicep' = if (DiskEncryption) {
  name: 'DiskEncryption_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryptionSetName: DiskEncryptionSetName
    Environment: Environment
    KeyVaultName: KeyVaultName
    Location: LocationVirtualMachines
    TagsDeploymentScripts: contains(Tags, 'Microsoft.Resources/deploymentScripts') ? Tags['Microsoft.Resources/deploymentScripts'] : {}
    TagsDiskEncryptionSet: contains(Tags, 'Microsoft.Compute/diskEncryptionSets') ? Tags['Microsoft.Compute/diskEncryptionSets'] : {}
    TagsKeyVault: contains(Tags, 'Microsoft.KeyVault/vaults') ? Tags['Microsoft.KeyVault/vaults'] : {}
    Timestamp: Timestamp
    UserAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.id
  }
}

module recoveryServicesVault 'recoveryServicesVault.bicep' = if (RecoveryServices) {
  name: 'RecoveryServicesVault_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    Fslogix: Fslogix
    Location: LocationVirtualMachines
    RecoveryServicesVaultName: RecoveryServicesVaultName
    StorageSolution: StorageSolution
    Tags: contains(Tags, 'Microsoft.RecoveryServices/vaults') ? Tags['Microsoft.RecoveryServices/vaults'] : {}
    TimeZone: TimeZone
  }
}

module workspace 'workspace.bicep' = {
  name: 'Workspace_Create_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    ApplicationGroupReferences: []
    Existing: validations.outputs.existingWorkspace == 'true' ? true : false
    FriendlyName: WorkspaceFriendlyName
    Location: LocationControlPlane
    LogAnalyticsWorkspaceResourceId: Monitoring ? logAnalyticsWorkspace.outputs.ResourceId : ''
    Monitoring: Monitoring
    Tags: contains(Tags, 'Microsoft.DesktopVirtualization/workspaces') ? Tags['Microsoft.DesktopVirtualization/workspaces'] : {}
    WorkspaceName: WorkspaceName
  }
}

output DiskEncryptionSetResourceId string = DiskEncryption ? diskEncryption.outputs.diskEncryptionSetResourceId : ''
output LogAnalyticsWorkspaceResourceId string = Monitoring ? logAnalyticsWorkspace.outputs.ResourceId : ''
output UserAssignedIdentityClientId string = userAssignedIdentity.outputs.clientId
output UserAssignedIdentityResourceId string = userAssignedIdentity.outputs.id
output ValidateAcceleratedNetworking string = validations.outputs.acceleratedNetworking
output ValidateANFfActiveDirectory string = validations.outputs.anfActiveDirectory
output ValidateANFDnsServers string = validations.outputs.anfDnsServers
output ValidateANFSubnetId string = validations.outputs.anfSubnetId
output ValidateAvailabilityZones array = validations.outputs.availabilityZones
output ValidateTrustedLaunch string = validations.outputs.trustedLaunch
