<#
.SYNOPSIS
    Valida e implanta a infraestrutura do main.bicep em um ambiente (dev ou prod).

.DESCRIPTION
    Usa a Azure CLI (az). Antes de rodar:
      1. Instale a Azure CLI e faça login: az login
      2. Gere uma chave SSH, se ainda não tiver: ssh-keygen -t ed25519
      3. Copie infra\params\<ambiente>.bicepparam para <ambiente>.local.bicepparam e preencha

    Fluxo: build + lint -> grupo de recursos -> what-if -> confirmação -> deploy.
    Use -SoValidar para parar no what-if, sem criar nada.

.EXAMPLE
    .\deploy.ps1 -Ambiente dev -SoValidar
    .\deploy.ps1 -Ambiente dev
    .\deploy.ps1 -Ambiente prod -Local eastus2
#>
[CmdletBinding()]
param(
    [ValidateSet('dev', 'prod')]
    [string]$Ambiente = 'dev',
    [string]$Local    = 'brazilsouth',
    [switch]$SoValidar
)

$ErrorActionPreference = 'Stop'

$GrupoRecursos = "rg-azure-infra-$Ambiente"
$ArquivoParam  = "$PSScriptRoot\infra\params\$Ambiente.local.bicepparam"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI não encontrada. Instale com: winget install -e --id Microsoft.AzureCLI'
}
if (-not (Test-Path $ArquivoParam)) {
    throw "Arquivo não encontrado: $ArquivoParam. Copie $Ambiente.bicepparam para $Ambiente.local.bicepparam e preencha."
}

Write-Host '1/4 Build e lint do Bicep...' -ForegroundColor Cyan
az bicep build --file "$PSScriptRoot\infra\main.bicep" --stdout | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falha no build do Bicep.' }
az bicep lint --file "$PSScriptRoot\infra\main.bicep"
if ($LASTEXITCODE -ne 0) { throw 'Falha no lint do Bicep.' }

$conta = az account show --query "{nome:name, id:id}" -o json | ConvertFrom-Json
Write-Host "Assinatura: $($conta.nome) ($($conta.id))"

Write-Host "2/4 Grupo de recursos $GrupoRecursos..." -ForegroundColor Cyan
az group create --name $GrupoRecursos --location $Local --tags projeto=azure-infra-bicep ambiente=$Ambiente -o none

Write-Host '3/4 What-if (o que será criado, alterado ou apagado)...' -ForegroundColor Cyan
az deployment group what-if --resource-group $GrupoRecursos --parameters $ArquivoParam
if ($LASTEXITCODE -ne 0) { throw 'Falha no what-if.' }

if ($SoValidar) { return }

$resposta = Read-Host 'Confirmar a implantação? (s/n)'
if ($resposta -ne 's') { Write-Host 'Cancelado.'; return }

Write-Host '4/4 Implantando...' -ForegroundColor Cyan
$saida = az deployment group create `
    --resource-group $GrupoRecursos `
    --name "$Ambiente-$(Get-Date -Format yyyyMMdd-HHmm)" `
    --parameters $ArquivoParam `
    --query properties.outputs -o json | ConvertFrom-Json

Write-Host "`nImplantação concluída." -ForegroundColor Green
Write-Host "IP público : $($saida.ipPublicoVm.value)"
Write-Host "Acesso SSH : $($saida.comandoSsh.value)"
Write-Host "Storage    : $($saida.storageAccount.value)"
Write-Host "Key Vault  : $($saida.keyVault.value)"
Write-Host "Backup     : $($saida.cofreBackup.value)"
Write-Host "`nLembrete: rode .\remover.ps1 -Ambiente $Ambiente ao terminar, para não gerar custo."
