// =============================================================================
// Infraestrutura de laboratório no Azure
//   - Rede virtual + sub-rede + NSG (SSH liberado só para o seu IP)
//   - VM Linux Ubuntu pequena, com login por chave SSH
//   - Desligamento automático diário (controle de custo)
//   - Cofre de backup (Recovery Services) com política diária aplicada à VM
// =============================================================================

@description('Prefixo usado no nome de todos os recursos.')
@minLength(3)
@maxLength(10)
param prefixo string = 'lab'

@description('Região do Azure.')
param local string = resourceGroup().location

@description('Tamanho da VM. Confira na sua assinatura qual tamanho entra na cota gratuita.')
param tamanhoVm string = 'Standard_B1s'

@description('Usuário administrador da VM.')
param usuarioAdmin string = 'azureuser'

@description('Chave pública SSH (conteúdo do arquivo .pub).')
@secure()
param chavePublicaSsh string

@description('Seu IP público, para liberar o SSH só para você. Ex.: 200.100.50.25')
param meuIp string

@description('Horário do desligamento automático (HHmm).')
param horaDesligamento string = '2300'

@description('Fuso horário do desligamento automático.')
param fusoHorario string = 'E. South America Standard Time'

@description('Tags aplicadas a todos os recursos.')
param tags object = {
  projeto: 'azure-infra-bicep'
  ambiente: 'laboratorio'
  dono: 'warlley'
}

var nomeVnet = '${prefixo}-vnet'
var nomeSubrede = 'snet-servidores'
var nomeNsg = '${prefixo}-nsg'
var nomeIpPublico = '${prefixo}-pip'
var nomeNic = '${prefixo}-nic'
var nomeVm = '${prefixo}-vm01'
var nomeCofre = '${prefixo}-rsv'
var nomePolitica = 'backup-diario-7dias'

// ---------------- Rede ----------------

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nomeNsg
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

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: nomeVnet
  location: local
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: nomeSubrede
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource ipPublico 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: nomeIpPublico
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
  name: nomeNic
  location: local
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: ipPublico.id
          }
        }
      }
    ]
  }
}

// ---------------- Máquina virtual ----------------

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: nomeVm
  location: local
  tags: tags
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

// ---------------- Backup ----------------

resource cofre 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: nomeCofre
  location: local
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource politica 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  parent: cofre
  name: nomePolitica
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 2
    timeZone: fusoHorario
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2026-01-01T22:00:00Z'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2026-01-01T22:00:00Z'
        ]
        retentionDuration: {
          count: 7
          durationType: 'Days'
        }
      }
    }
  }
}

var nomeContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${nomeVm}'
var nomeItemProtegido = 'vm;iaasvmcontainerv2;${resourceGroup().name};${nomeVm}'

resource backupVm 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-04-01' = {
  name: '${nomeCofre}/Azure/${nomeContainer}/${nomeItemProtegido}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: politica.id
    sourceResourceId: vm.id
  }
}

// ---------------- Saídas ----------------

output ipPublicoVm string = ipPublico.properties.ipAddress
output comandoSsh string = 'ssh ${usuarioAdmin}@${ipPublico.properties.ipAddress}'
output cofreBackup string = cofre.name
