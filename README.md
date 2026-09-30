# Infraestrutura no Azure com Bicep

Infraestrutura como código (IaC): um único comando cria uma rede, uma máquina virtual Linux protegida e um cofre de backup no Azure. Outro comando apaga tudo. Nada é criado clicando no portal.

## O que é criado

```
Grupo de recursos: rg-lab-azure
│
├── Rede virtual lab-vnet (10.10.0.0/16)
│   └── Sub-rede snet-servidores (10.10.1.0/24)
│       └── NSG lab-nsg ── SSH (22) liberado só para o meu IP
│
├── VM lab-vm01 (Ubuntu 24.04, login só por chave SSH)
│   ├── IP público estático
│   └── Desligamento automático todo dia às 23h
│
└── Cofre de backup lab-rsv
    └── Política diária, retenção de 7 dias, aplicada à VM
```

## Decisões de segurança e custo

| Decisão | Motivo |
| --- | --- |
| SSH só por chave, senha desativada | Evita ataques de força bruta |
| NSG libera a porta 22 só para um IP | A VM não fica exposta para a internet |
| Desligamento automático diário | VM esquecida ligada é a principal causa de custo em laboratório |
| VM pequena e disco padrão (HDD) | Custo mínimo |
| Tags em todos os recursos | Facilita rastrear custo por projeto |
| Script de remoção | Apaga tudo, inclusive o backup, que costuma travar a exclusão |

## Pré-requisitos

- Conta no Azure (a conta gratuita serve; confira qual tamanho de VM entra na cota)
- [Azure CLI](https://aka.ms/installazurecli) instalada
- PowerShell 7 (ou Windows PowerShell)
- Chave SSH: `ssh-keygen -t ed25519`

## Como usar

```powershell
# 1. Login
az login

# 2. Parâmetros: copie o modelo e preencha seu IP e sua chave pública
Copy-Item infra\main.bicepparam infra\main.local.bicepparam

# 3. Ver o que seria criado, sem criar nada
.\deploy.ps1 -SoValidar

# 4. Criar
.\deploy.ps1

# 5. Acessar a VM
ssh azureuser@<ip-publico>

# 6. Apagar tudo ao terminar
.\remover.ps1
```

Descubra seu IP público em qualquer site como "qual é meu IP".

## Estrutura

```
azure-infra-bicep/
├── infra/
│   ├── main.bicep          # toda a infraestrutura
│   └── main.bicepparam     # modelo de parâmetros
├── deploy.ps1              # cria o grupo de recursos e implanta
└── remover.ps1             # para o backup e apaga tudo
```

## O que pratiquei

Bicep (IaC), redes virtuais e NSG, VM Linux com autenticação por chave, Azure Backup (cofre, política e proteção de VM), controle de custos, Azure CLI e automação com PowerShell. São temas cobrados na certificação AZ-104.

---

Autor: **Warlley Santos** · [LinkedIn](https://linkedin.com/in/warlley-santos)
