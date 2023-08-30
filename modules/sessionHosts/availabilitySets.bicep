param AvailabilitySetNamePrefix string
param AvailabilitySetsCount int
param AvailabilitySetsIndex int
param Location string
param TagsAvailabilitySets object

resource availabilitySets 'Microsoft.Compute/availabilitySets@2019-07-01' = [for i in range(0, AvailabilitySetsCount): {
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
