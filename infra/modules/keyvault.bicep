// Key Vault com autorização por RBAC (sem access policies), soft delete
// e acesso de rede só pela sub-rede de dados e pelo IP do administrador.
// A identidade gerenciada da VM recebe permissão de leitura de segredos.

param prefixo string
param local string
param tags object
param subnetDadosId string
param meuIp string

@description('Object ID da identidade que lê segredos (ex.: identidade da VM).')
param principalIdLeitor string

@description('Proteção contra exclusão definitiva. Em prod, ligue; não dá para desligar depois.')
param protecaoExclusao bool

var nomeCofre = take('${prefixo}-kv-${uniqueString(resourceGroup().id)}', 24)

// Função interna do Azure: "Key Vault Secrets User"
var funcaoLeitorSegredos = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: nomeCofre
  location: local
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: protecaoExclusao ? true : null
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetDadosId
        }
      ]
      ipRules: [
        {
          value: meuIp
        }
      ]
    }
  }
}

resource leitorVm 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, principalIdLeitor, funcaoLeitorSegredos)
  scope: kv
  properties: {
    roleDefinitionId: funcaoLeitorSegredos
    principalId: principalIdLeitor
    principalType: 'ServicePrincipal'
  }
}

output kvNome string = kv.name
output kvUri string = kv.properties.vaultUri
