param ArtifactsLocation string
param File string
param Location string
param Parameters string
param Tags object
param Timestamp string = utcNow('yyyyMMddhhmmss')
param UserAssignedIdentityClientId string
param VirtualMachineName string

var CommandToExecute = 'powershell -ExecutionPolicy Unrestricted -File ${File} ${Parameters}'
var FileUri = '${ArtifactsLocation}${File}'

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: VirtualMachineName
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: Timestamp
    }
    protectedSettings: contains(File, environment().suffixes.storage) ? {
      commandToExecute: CommandToExecute
      fileUris: [
        FileUri
      ]
      managedIdentity: {
        clientId: UserAssignedIdentityClientId
      }
    } : {
      commandToExecute: CommandToExecute
      fileUris: [
        FileUri
      ]
    }
  }
}

output value object = json(filter(customScriptExtension.properties.instanceView.substatuses, item => item.code == 'ComponentStatus/StdOut/succeeded')[0].message)
