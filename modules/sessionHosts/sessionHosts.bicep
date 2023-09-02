targetScope = 'subscription'

param AcceleratedNetworking string
param ActiveDirectorySolution string
param ArtifactsLocation string
param AutomationAccountName string
param Availability string
param AvailabilitySetNamePrefix string
param AvailabilitySetsCount int
param AvailabilitySetsIndex int
param AvailabilityZones array
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
param ManagementVMName string
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
param RoleDefinitions object
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
param TagsNetworkInterfaces object
param TagsRecoveryServicesVault object
param TagsVirtualMachines object
param TimeDifference string
param Timestamp string
param TimeZone string
param TrustedLaunch string
param UserAssignedIdentityClientId string
param VirtualMachineNamePrefix string
@secure()
param VirtualMachinePassword string
param VirtualMachineSize string
param VirtualMachineUsername string
param VirtualNetwork string
param VirtualNetworkResourceGroup string

module availabilitySets 'availabilitySets.bicep' = if (PooledHostPool && Availability == 'AvailabilitySets') {
  name: 'AvailabilitySets_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    AvailabilitySetNamePrefix: AvailabilitySetNamePrefix
    AvailabilitySetsCount: AvailabilitySetsCount
    AvailabilitySetsIndex: AvailabilitySetsIndex
    Location: Location
    TagsAvailabilitySets: TagsAvailabilitySets
  }
}

// Role Assignment for Virtual Machine Login User
// This module deploys the role assignments to login to Azure AD joined session hosts
module roleAssignments '../roleAssignment.bicep' = [for i in range(0, length(SecurityPrincipalObjectIds)): if (!contains(ActiveDirectorySolution, 'DomainServices')) {
  name: 'RoleAssignments_${i}_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    PrincipalId: SecurityPrincipalObjectIds[i]
    PrincipalType: 'Group'
    RoleDefinitionId: RoleDefinitions.VirtualMachineUserLogin
  }
}]

@batchSize(1)
module virtualMachines 'virtualMachines.bicep' = [for i in range(1, SessionHostBatchCount): {
  name: 'VirtualMachines_${i - 1}_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    AcceleratedNetworking: AcceleratedNetworking
    ActiveDirectorySolution: ActiveDirectorySolution
    ArtifactsLocation: ArtifactsLocation
    Availability: Availability
    AvailabilityZones: AvailabilityZones
    AvailabilitySetNamePrefix: AvailabilitySetNamePrefix
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
    ManagementVMName: ManagementVMName
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
    TagsNetworkInterfaces: TagsNetworkInterfaces
    TagsVirtualMachines: TagsVirtualMachines
    Timestamp: Timestamp
    TrustedLaunch: TrustedLaunch
    UserAssignedIdentityClientId: UserAssignedIdentityClientId
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

module recoveryServices 'recoveryServices.bicep' = if (RecoveryServices) {
  name: 'RecoveryServices_VirtualMachines_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    DivisionRemainderValue: DivisionRemainderValue
    Fslogix: Fslogix
    Location: Location
    MaxResourcesPerTemplateDeployment: MaxResourcesPerTemplateDeployment
    RecoveryServicesVaultName: RecoveryServicesVaultName
    ResourceGroupHosts: ResourceGroupHosts
    ResourceGroupManagement: ResourceGroupManagement
    SessionHostBatchCount: SessionHostBatchCount
    SessionHostIndex: SessionHostIndex
    TagsRecoveryServicesVault: TagsRecoveryServicesVault
    Timestamp: Timestamp
    VirtualMachineNamePrefix: VirtualMachineNamePrefix
  }
  dependsOn: [
    virtualMachines
  ]
}



module scalingTool '../management/scalingTool.bicep' = if (ScalingTool && PooledHostPool) {
  name: 'ScalingTool_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    ArtifactsLocation: ArtifactsLocation
    AutomationAccountName: AutomationAccountName
    BeginPeakTime: ScalingBeginPeakTime
    EndPeakTime: ScalingEndPeakTime
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: ResourceGroupManagement
    LimitSecondsToForceLogOffUser: ScalingLimitSecondsToForceLogOffUser
    Location: Location
    MinimumNumberOfRdsh: ScalingMinimumNumberOfRdsh
    ResourceGroupHosts: ResourceGroupHosts
    ResourceGroupManagement: ResourceGroupManagement
    SessionThresholdPerCPU: ScalingSessionThresholdPerCPU
    Tags: TagsAutomationAccounts
    TimeDifference: TimeDifference
    TimeZone: TimeZone
  }
  dependsOn: [
    recoveryServices
  ]
}
