// =============================================================================
// Infraestrutura no Azure com Bicep (modular)
//   modules/network.bicep  - VNet, 2 sub-redes, 2 NSGs
//   modules/vm.bicep       - VM Ubuntu (chave SSH), IP público, desligamento automático
//   modules/storage.bicep  - Storage Account fechada por rede
//   modules/keyvault.bicep - Key Vault com RBAC; a VM lê segredos pela identidade gerenciada
//   modules/backup.bicep   - Cofre Recovery Services com política diária (opcional)
// Parâmetros por ambiente: params/dev.bicepparam e params/prod.bicepparam
// =============================================================================

@description('Ambiente da implantação.')
@allowed([
  'dev'
  'prod'
])
param ambiente string

@description('Prefixo do nome dos recursos.')
@minLength(3)
@maxLength(10)
param prefixo string

@description('Região do Azure.')
param local string = resourceGroup().location

@description('Espaço de endereços da VNet.')
param espacoEnderecos string

@description('Sub-rede de servidores.')
param prefixoServidores string

@description('Sub-rede de dados.')
param prefixoDados string

@description('Tamanho da VM.')
param tamanhoVm string

@description('Usuário administrador da VM.')
param usuarioAdmin string = 'azureuser'

@description('Chave pública SSH (conteúdo do arquivo .pub).')
@secure()
param chavePublicaSsh string

@description('Seu IP público. Libera SSH, Storage e Key Vault só para ele.')
param meuIp string

@description('Horário do desligamento automático (HHmm).')
param horaDesligamento string = '2300'

@description('Fuso horário do desligamento e do backup.')
param fusoHorario string = 'E. South America Standard Time'

@description('Redundância da Storage Account.')
param skuStorage string = 'Standard_LRS'

@description('Cria o cofre de backup e protege a VM.')
param habilitarBackup bool

@description('Dias de retenção do backup.')
param diasRetencaoBackup int = 7

@description('Proteção contra exclusão definitiva no Key Vault (irreversível).')
param protecaoExclusaoKv bool = false

var tags = {
  projeto: 'azure-infra-bicep'
  ambiente: ambiente
  dono: 'warlley'
  gerenciadoPor: 'bicep'
}

module rede 'modules/network.bicep' = {
  name: 'rede'
  params: {
    prefixo: prefixo
    local: local
    tags: tags
    espacoEnderecos: espacoEnderecos
    prefixoServidores: prefixoServidores
    prefixoDados: prefixoDados
    meuIp: meuIp
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vm'
  params: {
    prefixo: prefixo
    local: local
    tags: tags
    subnetId: rede.outputs.subnetServidoresId
    tamanhoVm: tamanhoVm
    usuarioAdmin: usuarioAdmin
    chavePublicaSsh: chavePublicaSsh
    horaDesligamento: horaDesligamento
    fusoHorario: fusoHorario
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    prefixo: prefixo
    local: local
    tags: tags
    subnetDadosId: rede.outputs.subnetDadosId
    meuIp: meuIp
    sku: skuStorage
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    prefixo: prefixo
    local: local
    tags: tags
    subnetDadosId: rede.outputs.subnetDadosId
    meuIp: meuIp
    principalIdLeitor: vm.outputs.principalId
    protecaoExclusao: protecaoExclusaoKv
  }
}

module backup 'modules/backup.bicep' = if (habilitarBackup) {
  name: 'backup'
  params: {
    prefixo: prefixo
    local: local
    tags: tags
    vmId: vm.outputs.vmId
    vmNome: vm.outputs.vmNome
    fusoHorario: fusoHorario
    diasRetencao: diasRetencaoBackup
  }
}

output ipPublicoVm string = vm.outputs.ipPublico
output comandoSsh string = 'ssh ${usuarioAdmin}@${vm.outputs.ipPublico}'
output storageAccount string = storage.outputs.contaNome
output keyVault string = keyVault.outputs.kvNome
output cofreBackup string = habilitarBackup ? backup!.outputs.cofreNome : 'desabilitado'
