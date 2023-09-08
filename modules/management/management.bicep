targetScope = 'subscription'

param ActiveDirectorySolution string
param ArtifactsLocation string
param ArtifactsStorageAccountResourceId string
param AutomationAccountName string
param Availability string
param AvdObjectId string
param AzurePowerShellAzModuleMsiLink string
param LocationControlPlane string
param DiskNamePrefix string
param DiskEncryption bool
param DiskEncryptionSetName string
param DiskSku string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DrainMode bool
param Environment string
param Fslogix bool
param FslogixSolution string
param FslogixStorage string
param HostPoolType string
param KerberosEncryption string
param KeyVaultName string
param LocationVirtualMachines string
param LogAnalyticsWorkspaceName string
param LogAnalyticsWorkspaceRetention int
param LogAnalyticsWorkspaceSku string
param Monitoring bool
param NetworkInterfaceNamePrefix string
param PooledHostPool bool
param RecoveryServices bool
param RecoveryServicesVaultName string
param ResourceGroupControlPlane string
param ResourceGroupManagement string
param ResourceGroupStorage string
param RoleDefinitions object
param SessionHostCount int
param StorageSolution string
param SubnetResourceId string
param Tags object
param Timestamp string
param TimeZone string
param UserAssignedIdentityName string
param VirtualMachineNamePrefix string
@secure()
param VirtualMachinePassword string
param VirtualMachineUsername string
param VirtualMachineSize string
param WorkspaceFriendlyName string
param WorkspaceName string

var CpuCountMax = contains(HostPoolType, 'Pooled') ? 32 : 128
var CpuCountMin = contains(HostPoolType, 'Pooled') ? 4 : 2
var VirtualNetworkName = split(SubnetResourceId, '/')[8]
var VirtualNetworkResourceGroupName = split(SubnetResourceId, '/')[4]

module userAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(ResourceGroupManagement)
  name: 'UserAssignedIdentity_${Timestamp}'
  params: {
    ArtifactsStorageAccountResourceId: ArtifactsStorageAccountResourceId
    DiskEncryption: DiskEncryption
    DrainMode: DrainMode
    Fslogix: Fslogix
    FslogixStorage: FslogixStorage
    Location: LocationVirtualMachines
    UserAssignedIdentityName: UserAssignedIdentityName
    ResourceGroupControlPlane: ResourceGroupControlPlane
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

module diskEncryption 'diskEncryption.bicep' = if (DiskEncryption) {
  name: 'DiskEncryption_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    DiskEncryptionSetName: DiskEncryptionSetName
    Environment: Environment
    KeyVaultName: KeyVaultName
    Location: LocationVirtualMachines
    TagsDiskEncryptionSet: contains(Tags, 'Microsoft.Compute/diskEncryptionSets') ? Tags['Microsoft.Compute/diskEncryptionSets'] : {}
    TagsKeyVault: contains(Tags, 'Microsoft.KeyVault/vaults') ? Tags['Microsoft.KeyVault/vaults'] : {}
    Timestamp: Timestamp
  }
}

// Management VM
// The management VM is required to validate the deployment and configure FSLogix storage.
module virtualMachine 'virtualMachine.bicep' = {
  name: 'ManagementVirtualMachine_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    ArtifactsLocation: ArtifactsLocation
    AzurePowerShellAzModuleMsiLink: AzurePowerShellAzModuleMsiLink 
    DiskEncryption: DiskEncryption
    DiskEncryptionSetResourceId: DiskEncryption ? diskEncryption.outputs.diskEncryptionSetResourceId : ''
    DiskNamePrefix: DiskNamePrefix
    DiskSku: DiskSku
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    Location: LocationVirtualMachines
    NetworkInterfaceNamePrefix: NetworkInterfaceNamePrefix
    Subnet: split(SubnetResourceId, '/')[10]
    TagsNetworkInterfaces: contains(Tags, 'Microsoft.Network/networkInterfaces') ? Tags['Microsoft.Network/networkInterfaces'] : {}
    TagsVirtualMachines: contains(Tags, 'Microsoft.Compute/virtualMachines') ? Tags['Microsoft.Compute/virtualMachines'] : {}
    UserAssignedIdentityClientId: userAssignedIdentity.outputs.clientId
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.id
    VirtualNetwork: VirtualNetworkName
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroupName
    VirtualMachineNamePrefix: VirtualMachineNamePrefix
    VirtualMachinePassword: VirtualMachinePassword
    VirtualMachineUsername: VirtualMachineUsername
  }
}

// Deployment Validations
// This module validates the selected parameter values and collects required data
module validations 'customScriptExtensions.bicep' = {
  scope: resourceGroup(ResourceGroupManagement)
  name: 'Validations_${Timestamp}'
  params: {
    ArtifactsLocation: ArtifactsLocation
    File: 'Get-Validations.ps1'
    Location: LocationVirtualMachines
    Parameters: '-ActiveDirectorySolution ${ActiveDirectorySolution} -CpuCountMax ${CpuCountMax} -CpuCountMin ${CpuCountMin} -DomainName ${DomainName} -Environment ${environment().name} -KerberosEncryption ${KerberosEncryption} -Location ${LocationVirtualMachines} -SessionHostCount ${SessionHostCount} -StorageSolution ${StorageSolution} -SubscriptionId ${subscription().subscriptionId} -TenantId ${tenant().tenantId} -UserAssignedIdentityClientId ${userAssignedIdentity.outputs.clientId} -VirtualMachineSize ${VirtualMachineSize} -VirtualNetworkName ${VirtualNetworkName} -VirtualNetworkResourceGroupName ${VirtualNetworkResourceGroupName} -WorkspaceName ${WorkspaceName} -WorkspaceResourceGroupName ${ResourceGroupManagement}'
    Tags: contains(Tags, 'Microsoft.Compute/virtualMachines') ? Tags['Microsoft.Compute/virtualMachines'] : {}
    UserAssignedIdentityClientId: userAssignedIdentity.outputs.clientId
    VirtualMachineName: virtualMachine.outputs.Name
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
    Existing: validations.outputs.value.existingWorkspace == 'true' ? true : false
    FriendlyName: WorkspaceFriendlyName
    Location: LocationControlPlane
    LogAnalyticsWorkspaceResourceId: Monitoring ? logAnalyticsWorkspace.outputs.ResourceId : ''
    Monitoring: Monitoring
    Tags: contains(Tags, 'Microsoft.DesktopVirtualization/workspaces') ? Tags['Microsoft.DesktopVirtualization/workspaces'] : {}
    Timestamp: Timestamp
    WorkspaceName: WorkspaceName
  }
}

output DiskEncryptionSetResourceId string = DiskEncryption ? diskEncryption.outputs.diskEncryptionSetResourceId : ''
output LogAnalyticsWorkspaceResourceId string = Monitoring ? logAnalyticsWorkspace.outputs.ResourceId : ''
output UserAssignedIdentityClientId string = userAssignedIdentity.outputs.clientId
output UserAssignedIdentityResourceId string = userAssignedIdentity.outputs.id
output ValidateAcceleratedNetworking string = validations.outputs.value.acceleratedNetworking
output ValidateANFfActiveDirectory string = validations.outputs.value.anfActiveDirectory
output ValidateANFDnsServers string = validations.outputs.value.anfDnsServers
output ValidateANFSubnetId string = validations.outputs.value.anfSubnetId
output ValidateAvailabilityZones array = Availability == 'AvailabilityZones' ? validations.outputs.value.availabilityZones : [ '1' ]
output ValidateTrustedLaunch string = validations.outputs.value.trustedLaunch
output VirtualMachineName string = virtualMachine.outputs.Name
