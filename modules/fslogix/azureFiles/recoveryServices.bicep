param FileShares array
param Location string
param RecoveryServicesVaultName string
param ResourceGroupStorage string
param StorageAccountNamePrefix string
param StorageCount int
param StorageIndex int
param TagsRecoveryServicesVault object
param Timestamp string

resource vault 'Microsoft.RecoveryServices/vaults@2022-03-01' existing =  {
  name: RecoveryServicesVaultName
}

resource protectionContainers 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2022-03-01' = [for i in range(0, StorageCount): {
  name: '${vault.name}/Azure/storagecontainer;Storage;${ResourceGroupStorage};${StorageAccountNamePrefix}${padLeft(i + StorageIndex, 2, '0')}'
  properties: {
    backupManagementType: 'AzureStorage'
    containerType: 'StorageContainer'
    sourceResourceId: resourceId(ResourceGroupStorage, 'Microsoft.Storage/storageAccounts', '${StorageAccountNamePrefix}${padLeft(i + StorageIndex, 2, '0')}')
  }
}]

resource backupPolicy_Storage 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' existing = {
  parent: vault
  name: 'AvdPolicyStorage'
}

module protectedItems_FileShares 'protectedItems.bicep' = [for i in range(0, StorageCount): {
  name: 'BackupProtectedItems_FileShares_${i + StorageIndex}_${Timestamp}'
  params: {
    FileShares: FileShares
    Location: Location
    ProtectionContainerName: protectionContainers[i].name
    PolicyId: backupPolicy_Storage.id
    SourceResourceId: resourceId(ResourceGroupStorage, 'Microsoft.Storage/storageAccounts', '${StorageAccountNamePrefix}${padLeft(i + StorageIndex, 2, '0')}')
    Tags: TagsRecoveryServicesVault
  }
}]
