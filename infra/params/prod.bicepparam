using '../main.bicep'

// Ambiente de produção (simulado): VM maior, storage com redundância entre zonas,
// backup ligado com 30 dias e proteção contra exclusão no Key Vault.
// Copie para prod.local.bicepparam e preencha seu IP e sua chave pública.

param ambiente = 'prod'
param prefixo = 'labprd'
param local = 'brazilsouth'
param espacoEnderecos = '10.20.0.0/16'
param prefixoServidores = '10.20.1.0/24'
param prefixoDados = '10.20.2.0/24'
param tamanhoVm = 'Standard_B2s'
param chavePublicaSsh = 'COLE-AQUI-O-CONTEUDO-DO-SEU-ARQUIVO-.pub'
param meuIp = '203.0.113.10'
param skuStorage = 'Standard_ZRS'
param habilitarBackup = true
param diasRetencaoBackup = 30
param protecaoExclusaoKv = true
