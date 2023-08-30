targetScope = 'subscription'

param ActiveDirectorySolution string
param DiskSku string
param DomainName string
param FileShareNames object
param FslogixSolution string
param FslogixStorage string
param HostPoolType string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param Locations object
param LocationVirtualMachines string
param ResourceGroupControlPlane string
param ResourceGroupHosts string
param ResourceGroupManagement string
param ResourceGroupStorage string
param SecurityPrincipalObjectIds array
param SecurityPrincipalNames array
param SessionHostCount int
param SessionHostIndex int
param VirtualMachineNamePrefix string
param VirtualMachineSize string

//  BATCH SESSION HOSTS
// The following variables are used to determine the batches to deploy any number of AVD session hosts.
var MaxResourcesPerTemplateDeployment = 79 // This is the max number of session hosts that can be deployed from the sessionHosts.bicep file in each batch / for loop. Math: (800 - <Number of Static Resources>) / <Number of Looped Resources> 
var DivisionValue = SessionHostCount / MaxResourcesPerTemplateDeployment // This determines if any full batches are required.
var DivisionRemainderValue = SessionHostCount % MaxResourcesPerTemplateDeployment // This determines if any partial batches are required.
var SessionHostBatchCount = DivisionRemainderValue > 0 ? DivisionValue + 1 : DivisionValue // This determines the total number of batches needed, whether full and / or partial.

//  BATCH AVAILABILITY SETS
// The following variables are used to determine the number of availability sets.
var MaxAvSetMembers = 200 // This is the max number of session hosts that can be deployed in an availability set.
var BeginAvSetRange = SessionHostIndex / MaxAvSetMembers // This determines the availability set to start with.
var EndAvSetRange = (SessionHostCount + SessionHostIndex) / MaxAvSetMembers // This determines the availability set to end with.
var AvailabilitySetsCount = length(range(BeginAvSetRange, (EndAvSetRange - BeginAvSetRange) + 1))

// OTHER LOGIC & COMPUTED VALUES
var FileShares = FileShareNames[FslogixSolution]
var Fslogix = FslogixStorage == 'None' || !contains(ActiveDirectorySolution, 'DomainServices') ? false : true
var Netbios = split(DomainName, '.')[0]
var PooledHostPool = split(HostPoolType, ' ')[0] == 'Pooled' ? true : false
var PrivateEndpoint = contains(FslogixStorage, 'PrivateEndpoint') ? true : false
var ResourceGroups = Fslogix ? [
  ResourceGroupControlPlane
  ResourceGroupHosts
  ResourceGroupManagement
  ResourceGroupStorage
] : [
  ResourceGroupControlPlane
  ResourceGroupHosts
  ResourceGroupManagement
]
var RoleDefinitions = {
  DesktopVirtualizationPowerOnContributor: '489581de-a3bd-480d-9518-53dea7416b33'
  DesktopVirtualizationUser: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  VirtualMachineUserLogin: 'fb879df8-f326-4884-b1cf-06f3ad86be52'
}
var SecurityPrincipalIdsCount = length(SecurityPrincipalObjectIds)
var SecurityPrincipalNamesCount = length(SecurityPrincipalNames)
var SmbServerLocation = Locations[LocationVirtualMachines].acronym
var StorageSku = FslogixStorage == 'None' ? 'None' : split(FslogixStorage, ' ')[1]
var StorageSolution = split(FslogixStorage, ' ')[0]
var StorageSuffix = environment().suffixes.storage
var TimeDifference = Locations[LocationVirtualMachines].timeDifference
var TimeZone = Locations[LocationVirtualMachines].timeZone
var VmTemplate = '{"domain":"${DomainName}","galleryImageOffer":"${ImageOffer}","galleryImagePublisher":"${ImagePublisher}","galleryImageSKU":"${ImageSku}","imageType":"Gallery","imageUri":null,"customImageId":null,"namePrefix":"${VirtualMachineNamePrefix}","osDiskType":"${DiskSku}","useManagedDisks":true,"VirtualMachineSize":{"id":"${VirtualMachineSize}","cores":null,"ram":null},"galleryItemId":"${ImagePublisher}.${ImageOffer}${ImageSku}"}'

output AvailabilitySetsCount int = AvailabilitySetsCount
output BeginAvSetRange int = BeginAvSetRange
output DivisionRemainderValue int = DivisionRemainderValue
output FileShares array = FileShares
output Fslogix bool = Fslogix
output MaxResourcesPerTemplateDeployment int = MaxResourcesPerTemplateDeployment
output Netbios string = Netbios
output PooledHostPool bool = PooledHostPool
output PrivateEndpoint bool = PrivateEndpoint
output ResourceGroups array = ResourceGroups
output RoleDefinitions object = RoleDefinitions
output SessionHostBatchCount int = SessionHostBatchCount
output SecurityPrincipalIdsCount int = SecurityPrincipalIdsCount
output SecurityPrincipalNamesCount int = SecurityPrincipalNamesCount
output SmbServerLocation string = SmbServerLocation
output StorageSku string = StorageSku
output StorageSolution string = StorageSolution
output StorageSuffix string = StorageSuffix
output TimeDifference string = TimeDifference
output TimeZone string = TimeZone
output VmTemplate string = VmTemplate
