// Rede: VNet com duas sub-redes e um NSG por sub-rede
//   - snet-servidores: VMs; SSH liberado só para o IP do administrador
//   - snet-dados: endpoint de serviço para Storage e Key Vault

param prefixo string
param local string
param tags object

@description('Espaço de endereços da VNet. Ex.: 10.10.0.0/16')
param espacoEnderecos string

@description('Prefixo da sub-rede de servidores. Ex.: 10.10.1.0/24')
param prefixoServidores string

@description('Prefixo da sub-rede de dados. Ex.: 10.10.2.0/24')
param prefixoDados string

@description('IP público liberado para SSH.')
param meuIp string

resource nsgServidores 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${prefixo}-nsg-servidores'
  location: local
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Permitir-SSH-Meu-IP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '${meuIp}/32'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource nsgDados 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${prefixo}-nsg-dados'
  location: local
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Negar-Internet-Entrada'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${prefixo}-vnet'
  location: local
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        espacoEnderecos
      ]
    }
    subnets: [
      {
        name: 'snet-servidores'
        properties: {
          addressPrefix: prefixoServidores
          networkSecurityGroup: {
            id: nsgServidores.id
          }
        }
      }
      {
        name: 'snet-dados'
        properties: {
          addressPrefix: prefixoDados
          networkSecurityGroup: {
            id: nsgDados.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
    ]
  }
}

output vnetNome string = vnet.name
output subnetServidoresId string = vnet.properties.subnets[0].id
output subnetDadosId string = vnet.properties.subnets[1].id
