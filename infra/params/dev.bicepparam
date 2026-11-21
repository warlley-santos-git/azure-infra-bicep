using '../main.bicep'

// Ambiente de desenvolvimento: custo mínimo, sem backup.
// Copie para dev.local.bicepparam e preencha seu IP e sua chave pública.
// Arquivos *.local.bicepparam não vão para o GitHub (estão no .gitignore).

param ambiente = 'dev'
param prefixo = 'labdev'
param local = 'brazilsouth'
param espacoEnderecos = '10.10.0.0/16'
param prefixoServidores = '10.10.1.0/24'
param prefixoDados = '10.10.2.0/24'
param tamanhoVm = 'Standard_B1s'
param chavePublicaSsh = 'COLE-AQUI-O-CONTEUDO-DO-SEU-ARQUIVO-.pub'
param meuIp = '203.0.113.10'
param skuStorage = 'Standard_LRS'
param habilitarBackup = false
param protecaoExclusaoKv = false
