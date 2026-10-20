# Especificação Técnica: Infraestrutura Soberana de Downloads, Multi-Arquitetura e Canais do Updater (Tickets #35 & #32)

## 1. Contexto e Motivação
A distribuição de utilitários de linha de comando (CLI) e aplicações gráficas/terminais do ecossistema 2lp/Gosplan (`cccp`, `mandu`, `lauda`, `lacraia`, `navalha`, etc.) é centralizada soberanamente na infraestrutura da Banca (`https://banca.2lp.in/downloads`).

Esta especificação unifica as necessidades do **Ticket #35** (infraestrutura pública de `/downloads/`) e do **Ticket #32** (suporte a múltiplos canais de distribuição para o módulo `updater`), estabelecendo um contrato de metadados transparente, multi-arquitetura e estritamente aderente à política de retenção da norma GOST (5 versões estáveis e 10 nightlies).

---

## 2. Matriz Canônica de Plataformas e Arquiteturas

Para garantir ampla acessibilidade sem comprometer o isolamento hermético, a distribuição suporta três plataformas principais de execução, além do canal móvel Android:

| Plataforma / Arquitetura | Identificador Canônico | Formato de Empacotamento | Binário Direto |
|---|---|---|---|
| **Linux x86_64** | `linux-amd64` | `<app>-<ver>-linux-amd64.tar.gz` | `<app>-linux-amd64` |
| **Linux AArch64** | `linux-arm64` | `<app>-<ver>-linux-arm64.tar.gz` | `<app>-linux-arm64` |
| **Windows x86_64** | `windows-amd64` | `<app>-<ver>-windows-amd64.zip` | `<app>.exe` |
| **Android AArch64** | `android-arm64` | `<app>.apk` (via A Pratilera) | N/A (APK empacotado) |

---

## 3. Contrato do Manifesto Atômico (`index.json`)

Cada aplicação catalogada disponibiliza um manifesto canônico no caminho:
`https://banca.2lp.in/downloads/<app>/index.json`

O formato estrito do documento JSON:
```json
{
  "app": "mandu",
  "name": "Mandu",
  "category": "Editor de Notas & Joaju",
  "description": "Editor brutalista de notas em texto puro com links wiki, grafos, diagramas Joaju e cofre local.",
  "repo": "https://codeberg.org/lumenpink/mandu",
  "stable_latest": "0.1.0",
  "nightly_latest": "0.1.0-dev.172+20261020.e21e439",
  "stables": [
    {
      "version": "0.1.0",
      "date": "2026-10-20",
      "artifacts": {
        "linux-amd64": {
          "url": "https://banca.2lp.in/downloads/mandu/stable/mandu-0.1.0-linux-amd64.tar.gz",
          "binary_url": "https://banca.2lp.in/downloads/mandu/stable-latest/mandu-linux-amd64",
          "sha256": "abcdef..."
        },
        "linux-arm64": {
          "url": "https://banca.2lp.in/downloads/mandu/stable/mandu-0.1.0-linux-arm64.tar.gz",
          "binary_url": "https://banca.2lp.in/downloads/mandu/stable-latest/mandu-linux-arm64",
          "sha256": "123456..."
        },
        "windows-amd64": {
          "url": "https://banca.2lp.in/downloads/mandu/stable/mandu-0.1.0-windows-amd64.zip",
          "binary_url": "https://banca.2lp.in/downloads/mandu/stable-latest/mandu.exe",
          "sha256": "fedcba..."
        }
      }
    }
  ],
  "nightlies": [
    {
      "version": "0.1.0-dev.172+20261020.e21e439",
      "date": "2026-10-20",
      "artifacts": {
        "linux-amd64": {
          "url": "https://banca.2lp.in/downloads/mandu/nightly/mandu-nightly-linux-amd64.tar.gz",
          "binary_url": "https://banca.2lp.in/downloads/mandu/nightly-latest/mandu-linux-amd64",
          "sha256": "987654..."
        }
      }
    }
  ]
}
```

---

## 4. Resolução de Rotas e Precedência em `site/_redirects`

Para prevenir que regras de rewrite do Single Page Application (SPA) capturem requisições estáticas para os manifestos e arquivos binários, a ordem de precedência no `site/_redirects` deve ser estrita:

1. Redirecionamentos da loja Pratilera (`/patilera`, `/prateleira`, etc.).
2. Redirecionamentos de compatibilidade para o bucket R2 (`/pratilera/*.apk`).
3. **Exceções de Downloads Diretos (arquivos físicos e manifestos):**
   - Requisições diretas a `/downloads/:app/index.json` não sofrem rewrite.
   - Requisições diretas a `/downloads/:app/releases/*` e `/downloads/:app/*-latest/*` são resolvidas diretamente.
4. **Rewrite do SPA da Vitrine:**
   - `/downloads    /downloads/  301`
   - Somente caminhos de visualização HTML sem extensão de arquivo sofrem rewrite para `/downloads/index.html`.

---

## 5. Regras do Módulo `updater` (Ticket #32)

O módulo de atualização cliente (`updater`) deve seguir o seguinte protocolo de resolução:

1. **Leitura de Configuração de Canal:**
   - Precedência: flag de linha de comando (`--channel`) > variável de ambiente (`MANDU_UPDATE_CHANNEL`) > arquivo de configuração (`config.toml`) > canal padrão (`stable`).
2. **Deteção de Arquitetura no Host:**
   - Detecta `os` (`linux`, `windows`, `macos`) e `arch` (`x86_64` -> `amd64`, `aarch64` -> `arm64`).
3. **Consulta ao Manifesto:**
   - Faz o download de `https://banca.2lp.in/downloads/<app>/index.json`.
   - Lê `stable_latest` ou `nightly_latest` de acordo com o canal ativo.
   - Localiza na lista de versões o objeto correspondente e extrai o artefato da arquitetura detectada.
4. **Proteção Contra Downgrade Acidental:**
   - Se a versão remota for menor que a versão instalada, a atualização é bloqueada a menos que a flag `--force` seja informada.
5. **Aplicação Atômica com Rollback:**
   - Download em arquivo temporário no mesmo sistema de arquivos (`fs::rename`), permissões `0o755`, preservação da versão anterior com sufixo `.old` e substituição atômica.

---

## 6. Interface Web da Vitrine (`site/downloads/index.html`)

1. **Seletor de Plataforma:**
   - Abas táteis ou botões segmentados com design brutalista para alternar entre `Linux x86_64`, `Linux ARM64` e `Windows x86_64`.
   - Detecção inteligente no carregamento da página com seleção padrão da plataforma do visitante.
2. **Comandos Rápidos de Instalação:**
   - **Linux:**
     ```bash
     curl -sSL https://banca.2lp.in/downloads/<app>/stable-latest/<app>-<arch> -o /usr/local/bin/<app> && chmod +x /usr/local/bin/<app>
     ```
   - **Windows (PowerShell):**
     ```powershell
     Invoke-WebRequest -Uri "https://banca.2lp.in/downloads/<app>/stable-latest/<app>-windows-amd64.zip" -OutFile "$HOME\Downloads\<app>.zip"
     ```
3. **Ficha do Mandu:**
   - Atualizada para *"Editor Soberano de Notas em Texto Puro, Markdown e Joaju"* na categoria *"Editorial & Escrita"*.
