// Conta de armazenamento: HTTPS obrigatório, TLS 1.2, sem acesso público a blobs,
// acesso de rede só pela sub-rede de dados (e, opcionalmente, pelo IP do administrador)

param prefixo string
param local string
param tags object
param subnetDadosId string
param meuIp string

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
])
param sku string

// Nome: só letras minúsculas e números, até 24 caracteres, único no Azure
var nomeConta = take('${toLower(replace(prefixo, '-', ''))}st${uniqueString(resourceGroup().id)}', 24)

resource conta 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: nomeConta
  location: local
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: sku
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetDadosId
          action: 'Allow'
        }
      ]
      ipRules: [
        {
          value: meuIp
          action: 'Allow'
        }
      ]
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: conta
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blob
  name: 'arquivos'
  properties: {
    publicAccess: 'None'
  }
}

output contaNome string = conta.name
output contaId string = conta.id
