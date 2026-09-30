using 'main.bicep'

// Copie este arquivo para main.local.bicepparam e preencha com seus dados.
// O arquivo .local não vai para o GitHub (está no .gitignore).

param prefixo = 'lab'
param local = 'brazilsouth'
param tamanhoVm = 'Standard_B1s'
param usuarioAdmin = 'azureuser'
param chavePublicaSsh = 'COLE-AQUI-O-CONTEUDO-DO-SEU-ARQUIVO-.pub'
param meuIp = '0.0.0.0'
param horaDesligamento = '2300'
