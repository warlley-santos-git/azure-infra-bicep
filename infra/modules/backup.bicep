// Cofre de backup (Recovery Services) com política diária aplicada à VM

param prefixo string
param local string
param tags object
param vmId string
param vmNome string
param fusoHorario string

@description('Dias de retenção dos pontos de restauração.')
@minValue(7)
param diasRetencao int

var nomeCofre = '${prefixo}-rsv'
var nomeContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vmNome}'
var nomeItemProtegido = 'vm;iaasvmcontainerv2;${resourceGroup().name};${vmNome}'

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
  name: 'backup-diario-${diasRetencao}dias'
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
          count: diasRetencao
          durationType: 'Days'
        }
      }
    }
  }
}

resource backupVm 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-04-01' = {
  name: '${nomeCofre}/Azure/${nomeContainer}/${nomeItemProtegido}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: politica.id
    sourceResourceId: vmId
  }
}

output cofreNome string = cofre.name
