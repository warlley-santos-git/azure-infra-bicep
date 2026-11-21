<#
.SYNOPSIS
    Remove toda a infraestrutura do laboratório (para não gerar custo).

.DESCRIPTION
    O cofre de backup impede apagar o grupo de recursos enquanto tiver itens
    protegidos. Por isso o script, nesta ordem:
      1. Desativa a exclusão reversível (soft delete) do cofre
      2. Para o backup da VM e apaga os dados de backup
      3. Apaga o grupo de recursos inteiro

    Observação: o Key Vault fica em exclusão reversível por 7 dias após apagar.
    Em prod (proteção contra exclusão ligada), ele não pode ser purgado antes disso.

.EXAMPLE
    .\remover.ps1 -Ambiente dev
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev', 'prod')]
    [string]$Ambiente = 'dev'
)

$ErrorActionPreference = 'Stop'

$GrupoRecursos = "rg-azure-infra-$Ambiente"
$Prefixo       = if ($Ambiente -eq 'prod') { 'labprd' } else { 'labdev' }

$cofre = "$Prefixo-rsv"
$vm    = "$Prefixo-vm01"

if (-not $PSCmdlet.ShouldProcess($GrupoRecursos, 'Apagar grupo de recursos e todos os recursos')) { return }

$existeCofre = az backup vault list -g $GrupoRecursos --query "[?name=='$cofre'].name" -o tsv
if ($existeCofre) {
    Write-Host 'Desativando soft delete do cofre...'
    az backup vault backup-properties set -g $GrupoRecursos -n $cofre --soft-delete-feature-state Disable -o none

    $itens = az backup item list -g $GrupoRecursos -v $cofre --query "[].name" -o tsv
    foreach ($item in $itens) {
        Write-Host "Parando backup e apagando dados: $item"
        az backup protection disable -g $GrupoRecursos -v $cofre `
            --container-name $vm --item-name $vm `
            --backup-management-type AzureIaasVM --workload-type VM `
            --delete-backup-data true --yes -o none
    }
}

Write-Host "Apagando o grupo de recursos '$GrupoRecursos' (leva alguns minutos)..."
az group delete --name $GrupoRecursos --yes --no-wait
Write-Host 'Solicitado. Acompanhe no portal ou com: az group show -n' $GrupoRecursos
