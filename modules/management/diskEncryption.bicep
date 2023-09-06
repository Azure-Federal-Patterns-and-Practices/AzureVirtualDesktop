param DiskEncryptionKeyExpirationInDays int = 30
param DiskEncryptionSetName string
param Environment string
param KeyVaultName string
param Location string
param TagsDiskEncryptionSet object
param TagsKeyVault object
param Timestamp string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: KeyVaultName
  location: Location
  tags: TagsKeyVault
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: Environment == 'd' || Environment == 't' ? 7 : 90
    tenantId: subscription().tenantId
  }
}

resource key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: 'DiskEncryptionKey'
  tags: TagsKeyVault
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${string(DiskEncryptionKeyExpirationInDays)}D'
      }
      lifetimeActions: [
        {
          action: {
            type: 'notify'
          }
          trigger: {
            timeBeforeExpiry: 'P10D'
          }
        }
        {
          action: {
            type: 'rotate'
          }
          trigger: {
            timeAfterCreate: 'P${string(DiskEncryptionKeyExpirationInDays - 7)}D'
          }
        }
      ]
    }
  }
}

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-07-02' = {
  name: DiskEncryptionSetName
  location: Location
  tags: TagsDiskEncryptionSet
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    activeKey: {
      sourceVault: {
        id: vault.id
      }
      keyUrl: key.properties.keyUriWithVersion
    }
    encryptionType: 'EncryptionAtRestWithPlatformAndCustomerKeys'
    rotationToLatestKeyVersionEnabled: true
  }
}

module roleAssignment '../roleAssignment.bicep' = {
  name: 'RoleAssignment_${Timestamp}'
  params: {
    PrincipalId: diskEncryptionSet.identity.principalId
    PrincipalType: 'ServicePrincipal'
    RoleDefinitionId: 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet.id
