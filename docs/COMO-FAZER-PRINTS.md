# Como fazer os prints do README

Tempo estimado: 30 a 40 minutos. Custo: centavos, se você apagar tudo no mesmo dia (passo 6).

Salve cada imagem em `docs/img/` com o nome indicado. Use a ferramenta de Captura do Windows (`Win + Shift + S`) e salve como PNG.

> Os caminhos de menu do portal podem mudar um pouco. Se algum item não estiver onde descrevi, use a barra de busca no topo do portal.

## 0. Antes de começar: assinatura do Azure

Você precisa de uma assinatura ativa. Se ainda não tem, crie a conta gratuita em https://azure.microsoft.com/free. O cartão é pedido só para verificação, e o cadastro é feito por você.

## 1. Preparar (PowerShell 7, na pasta do repositório)

**Qual PowerShell abrir:** use o **PowerShell 7** (no menu Iniciar, procure "PowerShell 7" ou rode `pwsh`). Para saber qual está aberto, olhe a primeira linha da janela ou rode `$PSVersionTable.PSVersion`:
- `PowerShell 7.x.x`: certo.
- `Windows PowerShell` ou versão `5.1`: é o antigo. Os scripts até rodam nele, mas os acentos das mensagens aparecem quebrados. Prefira o 7.

Abra um **terminal novo** (o `az` só é reconhecido depois de reabrir o terminal) e rode:

```powershell
cd D:\azure-infra-bicep
az version
```

Se o `az version` ainda não for reconhecido, reinicie o computador ou feche e abra o VS Code.

**Chave SSH:**

```powershell
ssh-keygen -t ed25519
```

- `Enter file in which to save the key`: só aperte **Enter**. A chave vai para o caminho padrão `C:\Users\<você>\.ssh\id_ed25519`.
- `Enter passphrase`: aperte **Enter** duas vezes para ficar sem senha (ou defina uma, se preferir).
- Se aparecer `Overwrite (y/n)?`: responda **n**. Você já tem uma chave; use a que existe.

**Login no Azure:**

```powershell
az login
az account show -o table
```

O navegador abre para você entrar. Se aparecer **"No subscriptions found"**, a conta ainda não tem assinatura: volte ao passo 0, crie a conta gratuita e rode `az login` e `az account show -o table` de novo. A tabela deve mostrar a assinatura com `State` = `Enabled`.

**Parâmetros:**

```powershell
Copy-Item infra\params\dev.bicepparam infra\params\dev.local.bicepparam
```

Abra `infra\params\dev.local.bicepparam` e preencha:
- `chavePublicaSsh`: o conteúdo de `C:\Users\<você>\.ssh\id_ed25519.pub` (`Get-Content $HOME\.ssh\id_ed25519.pub`)
- `meuIp`: seu IP público (`(Invoke-RestMethod https://api.ipify.org)`)

Esse arquivo não vai para o GitHub (`*.local.bicepparam` está no `.gitignore`).

## 2. What-if e deploy

```powershell
.\deploy.ps1 -Ambiente dev -SoValidar
```

**Print `01-what-if.png`:** a lista verde com `+ Create` de cada recurso. Corte para caber a lista e o resumo final ("Resource changes: X to create").

```powershell
.\deploy.ps1 -Ambiente dev
```

Responda `s` na confirmação. Leva de 5 a 10 minutos.

**Print `02-saida-deploy.png`:** as linhas finais "Implantação concluída", com IP público, Storage e Key Vault. Se quiser esconder o IP, borre-o no editor de imagem.

## 3. Prints no portal (portal.azure.com)

| Arquivo | Onde clicar | O que deve aparecer |
| --- | --- | --- |
| `03-grupo-recursos.png` | Busca → **Grupos de recursos** → `rg-azure-infra-dev` | Lista com VNet, 2 NSGs, VM, disco, NIC, IP público, Storage, Key Vault e o agendamento de desligamento. Ative a coluna **Tags** em "Gerenciar exibição" se der |
| `04-vnet-subredes.png` | Clique em `labdev-vnet` → menu **Sub-redes** | `snet-servidores` e `snet-dados`, cada uma com seu NSG |
| `05-vm.png` | Clique em `labdev-vm01` → **Visão geral**; depois **Desligamento automático** no menu da esquerda | Ubuntu 24.04, tamanho B1s, IP público. Opcional: um segundo print do desligamento às 23:00 |
| `06-storage-rede.png` | Clique na Storage (`labdevst...`) → **Segurança + rede** → **Rede** | "Habilitado de redes virtuais e endereços IP selecionados", com `snet-dados` e seu IP |
| `07-keyvault-rbac.png` | Clique no Key Vault (`labdev-kv-...`) → **Controle de acesso (IAM)** → **Atribuições de função** | `labdev-vm01` com a função **Key Vault Secrets User** |

## 4. Print do backup (opcional, só existe em prod)

O backup fica desligado em dev para economizar. Para o print `08-backup.png`, você tem duas opções:
- Fazer o deploy de prod (`Copy-Item` do `prod.bicepparam`, preencher e rodar `.\deploy.ps1 -Ambiente prod`). Custa mais e o Key Vault de prod fica 7 dias em exclusão reversível depois de apagado.
- Ou mudar `habilitarBackup = true` só no seu `dev.local.bicepparam` e rodar o deploy de dev de novo.

Onde clicar: cofre `labdev-rsv` (ou `labprd-rsv`) → **Itens de backup** → **Máquina Virtual do Azure**. Deve aparecer a VM com a política `backup-diario-...`.

## 5. Ativar as imagens no README

No `README.md`, seção **Prints**, apague o `<!--` e o `-->` das linhas das imagens que você salvou.

## 6. Apagar tudo (não pule)

```powershell
.\remover.ps1 -Ambiente dev
```

Se fez prod também: `.\remover.ps1 -Ambiente prod`. Confira depois:

```powershell
az group list -o table
```

O grupo `rg-azure-infra-dev` não deve mais aparecer (pode levar alguns minutos).
