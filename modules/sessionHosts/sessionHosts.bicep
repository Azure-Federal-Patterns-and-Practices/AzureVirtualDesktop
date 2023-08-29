param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AcceleratedNetworking string
param ActiveDirectorySolution string
param AutomationAccountName string
param Availability string
param AvailabilitySetNamePrefix string
param AvailabilitySetsCount int
param AvailabilitySetsIndex int
param AvailabilityZones array
param DeploymentScriptNamePrefix string
param DiskEncryption bool
param DiskEncryptionSetResourceId string
param DiskNamePrefix string
param DiskSku string
param DivisionRemainderValue int
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DrainMode bool
param FslogixSolution string
param Fslogix bool
param HostPoolName string
param HostPoolType string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageVersionResourceId string
param Location string
param LogAnalyticsWorkspaceName string
param ManagedIdentityResourceId string
param MaxResourcesPerTemplateDeployment int
param Monitoring bool
param NetAppFileShares array
param NetworkInterfaceNamePrefix string
param OuPath string
param PooledHostPool bool
param RecoveryServices bool
param RecoveryServicesVaultName string
param ResourceGroupControlPlane string
param ResourceGroupHosts string
param ResourceGroupManagement string
param ScalingBeginPeakTime string
param ScalingEndPeakTime string
param ScalingLimitSecondsToForceLogOffUser string
param ScalingMinimumNumberOfRdsh string
param ScalingSessionThresholdPerCPU string
param ScalingTool bool
param SecurityPrincipalObjectIds array
param SecurityLogAnalyticsWorkspaceResourceId string
param SessionHostBatchCount int
param SessionHostIndex int
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageSolution string
param StorageSuffix string
param Subnet string
param TagsAutomationAccounts object
param TagsAvailabilitySets object
param TagsDeploymentScripts object
param TagsNetworkInterfaces object
param TagsRecoveryServicesVault object
param TagsVirtualMachines object
param TimeDifference string
param Timestamp string
param TimeZone string
param TrustedLaunch string
param VirtualMachineLocation string
param VirtualMachineNamePrefix string
@secure()
param VirtualMachinePassword string
param VirtualMachineSize string
param VirtualMachineUsername string
param VirtualNetwork string
param VirtualNetworkResourceGroup string

var VirtualMachineUserLoginRoleDefinitionResourceId = resourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')

resource availabilitySets 'Microsoft.Compute/availabilitySets@2019-07-01' = [for i in range(0, AvailabilitySetsCount): if (PooledHostPool && Availability == 'AvailabilitySets') {
  name: '${AvailabilitySetNamePrefix}${padLeft((i + AvailabilitySetsIndex), 2, '0')}'
  location: Location
  tags: TagsAvailabilitySets
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}]

// Role Assignment for Virtual Machine Login User
// This module deploys the role assignments to login to Azure AD joined session hosts
module roleAssignments '../roleAssignment.bicep' = [for i in range(0, length(SecurityPrincipalObjectIds)): if (!contains(ActiveDirectorySolution, 'DomainServices')) {
  name: 'RoleAssignments_${i}_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    PrincipalId: SecurityPrincipalObjectIds[i]
    PrincipalType: 'Group'
    RoleDefinitionId: VirtualMachineUserLoginRoleDefinitionResourceId
  }
}]

@batchSize(1)
module virtualMachines 'virtualMachines.bicep' = [for i in range(1, SessionHostBatchCount): {
  name: 'VirtualMachines_${i - 1}_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AcceleratedNetworking: AcceleratedNetworking
    ActiveDirectorySolution: ActiveDirectorySolution
    Availability: Availability
    AvailabilityZones: AvailabilityZones
    AvailabilitySetNamePrefix: AvailabilitySetNamePrefix
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryption: DiskEncryption
    DiskEncryptionSetResourceId: DiskEncryptionSetResourceId
    DiskNamePrefix: DiskNamePrefix
    DiskSku: DiskSku
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    DrainMode: DrainMode
    Fslogix: Fslogix
    FslogixSolution: FslogixSolution
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersionResourceId: ImageVersionResourceId
    Location: Location
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    ManagedIdentityResourceId: ManagedIdentityResourceId
    Monitoring: Monitoring
    NetAppFileShares: NetAppFileShares
    NetworkInterfaceNamePrefix: NetworkInterfaceNamePrefix
    OuPath: OuPath
    ResourceGroupControlPlane: ResourceGroupControlPlane
    ResourceGroupManagement: ResourceGroupManagement
    SecurityLogAnalyticsWorkspaceResourceId: SecurityLogAnalyticsWorkspaceResourceId
    SessionHostCount: i == SessionHostBatchCount && DivisionRemainderValue > 0 ? DivisionRemainderValue : MaxResourcesPerTemplateDeployment
    SessionHostIndex: i == 1 ? SessionHostIndex : ((i - 1) * MaxResourcesPerTemplateDeployment) + SessionHostIndex
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageSolution: StorageSolution
    StorageSuffix: StorageSuffix
    Subnet: Subnet
    TagsDeploymentScripts: TagsDeploymentScripts
    TagsNetworkInterfaces: TagsNetworkInterfaces
    TagsVirtualMachines: TagsVirtualMachines
    Timestamp: Timestamp
    TrustedLaunch: TrustedLaunch
    VirtualMachineNamePrefix: VirtualMachineNamePrefix
    VirtualMachinePassword: VirtualMachinePassword
    VirtualMachineSize: VirtualMachineSize
    VirtualMachineUsername: VirtualMachineUsername
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
  }
  dependsOn: [
    availabilitySets
  ]
}]

resource vault 'Microsoft.RecoveryServices/vaults@2022-03-01' existing = if (RecoveryServices) {
  name: RecoveryServicesVaultName
  scope: resourceGroup(ResourceGroupManagement)
}

resource backupPolicy_Vm 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' existing = if (RecoveryServices) {
  parent: vault
  name: 'AvdPolicyVm'
}

module protectedItems_Vm '../protectedItems/virtualMachines.bicep' = [for i in range(1, SessionHostBatchCount): if (RecoveryServices && !Fslogix) {
  name: 'BackupProtectedItems_VirtualMachines_${i - 1}_${Timestamp}'
  scope: resourceGroup(resourceGroup().name) // Management Resource Group
  params: {
    Location: Location
    PolicyId: backupPolicy_Vm.id
    RecoveryServicesVaultName: vault.name
    SessionHostCount: i == SessionHostBatchCount && DivisionRemainderValue > 0 ? DivisionRemainderValue : MaxResourcesPerTemplateDeployment
    SessionHostIndex: i == 1 ? SessionHostIndex : ((i - 1) * MaxResourcesPerTemplateDeployment) + SessionHostIndex
    Tags: TagsRecoveryServicesVault
    VirtualMachineNamePrefix: VirtualMachineNamePrefix
    VirtualMachineResourceGroupName: ResourceGroupHosts
  }
  dependsOn: [
    virtualMachines
  ]
}]

module scalingTool '../scalingTool.bicep' = if (ScalingTool && PooledHostPool) {
  name: 'ScalingTool_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AutomationAccountName: AutomationAccountName
    BeginPeakTime: ScalingBeginPeakTime
    EndPeakTime: ScalingEndPeakTime
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: ResourceGroupManagement
    LimitSecondsToForceLogOffUser: ScalingLimitSecondsToForceLogOffUser
    Location: VirtualMachineLocation
    MinimumNumberOfRdsh: ScalingMinimumNumberOfRdsh
    ResourceGroupHosts: ResourceGroupHosts
    ResourceGroupManagement: ResourceGroupManagement
    SessionThresholdPerCPU: ScalingSessionThresholdPerCPU
    Tags: TagsAutomationAccounts
    TimeDifference: TimeDifference
    TimeZone: TimeZone
  }
  dependsOn: [
    protectedItems_Vm
  ]
}
