// VM Linux Ubuntu com login só por chave SSH, IP público e desligamento automático

param prefixo string
param local string
param tags object
param subnetId string
param tamanhoVm string
param usuarioAdmin string

@secure()
param chavePublicaSsh string

@description('Horário do desligamento automático (HHmm).')
param horaDesligamento string

param fusoHorario string

var nomeVm = '${prefixo}-vm01'

resource ipPublico 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${prefixo}-pip'
  location: local
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${prefixo}-nic'
  location: local
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: ipPublico.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: nomeVm
  location: local
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: tamanhoVm
    }
    osProfile: {
      computerName: nomeVm
      adminUsername: usuarioAdmin
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${usuarioAdmin}/.ssh/authorized_keys'
              keyData: chavePublicaSsh
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 30
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Desligamento automático: evita cobrança com a VM esquecida ligada
resource desligamento 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${nomeVm}'
  location: local
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: horaDesligamento
    }
    timeZoneId: fusoHorario
    targetResourceId: vm.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

output vmId string = vm.id
output vmNome string = vm.name
output principalId string = vm.identity.principalId
output ipPublico string = ipPublico.properties.ipAddress
