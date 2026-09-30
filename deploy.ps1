<#
.SYNOPSIS
    Cria o grupo de recursos e implanta a infraestrutura do main.bicep.

.DESCRIPTION
    Usa a Azure CLI (az). Antes de rodar:
      1. Instale a Azure CLI e faça login: az login
      2. Gere uma chave SSH, se ainda não tiver: ssh-keygen -t ed25519
      3. Copie infra\main.bicepparam para infra\main.local.bicepparam e preencha

    Use -SoValidar para ver o que seria criado (what-if) sem criar nada.

.EXAMPLE
    .\deploy.ps1 -SoValidar
    .\deploy.ps1
#>
[CmdletBinding()]
param(
    [string]$GrupoRecursos = 'rg-lab-azure',
    [string]$Local         = 'brazilsouth',
    [string]$ArquivoParam  = "$PSScriptRoot\infra\main.local.bicepparam",
    [switch]$SoValidar
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI não encontrada. Instale em https://aka.ms/installazurecli'
}
if (-not (Test-Path $ArquivoParam)) {
    throw "Arquivo de parâmetros não encontrado: $ArquivoParam. Copie main.bicepparam para main.local.bicepparam e preencha."
}

$conta = az account show --query "{nome:name, id:id}" -o json | ConvertFrom-Json
Write-Host "Assinatura: $($conta.nome) ($($conta.id))"

az group create --name $GrupoRecursos --location $Local --tags projeto=azure-infra-bicep ambiente=laboratorio -o none
Write-Host "Grupo de recursos '$GrupoRecursos' pronto."

if ($SoValidar) {
    az deployment group what-if --resource-group $GrupoRecursos --parameters $ArquivoParam
    return
}

$saida = az deployment group create `
    --resource-group $GrupoRecursos `
    --name "lab-$(Get-Date -Format yyyyMMdd-HHmm)" `
    --parameters $ArquivoParam `
    --query properties.outputs -o json | ConvertFrom-Json

Write-Host "`nImplantação concluída." -ForegroundColor Green
Write-Host "IP público : $($saida.ipPublicoVm.value)"
Write-Host "Acesso SSH : $($saida.comandoSsh.value)"
Write-Host "Cofre      : $($saida.cofreBackup.value)"
Write-Host "`nLembrete: rode .\remover.ps1 quando terminar os testes para não gerar custo."
