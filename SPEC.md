# Especificação Técnica: BANCA

## 1. Visão Geral
A **Banca** é o gerador e portal estático de apresentação de todos os projetos autorais do ecossistema mantido por Lumen Pink.

## 2. Requisitos Arquiteturais
- **Linguagem / Stack:** Shell POSIX puro (`sh` / `dash` / `bash`) e `jq`.
- **Motor Gráfico:** `navalha poster` para renderização visual.
- **Formato de Saída:** Single-file HTML estático com CSS e JavaScript progressivo embutidos, sem dependências de CDN externa.
- **Fonte de Dados:** `data/projects.json` estruturado com suporte a metadados estendidos e agrupamento.
- **Norma Técnica:** GOST v1.1.0 (perfil `profiles/lumen.md`, tipologia Shell/Web).
- **Publicação:** Cloudflare Workers Static Assets (`banca.2lp.in`) e Codeberg Pages.

## 3. A Pratilera: Loja e Repositório F-Droid / Droid-ify Soberano

A **Pratilera** é o repositório centralizado de distribuição de aplicativos Android do ecossistema 2lp (`in.twolp.*`), compatível nativamente com Droid-ify, Neo Store, F-Droid e Obtainium.

### 3.1 Topologia de Rotas e Aliases
- **Rota Canônica:** `https://banca.2lp.in/pratilera/`
- **Aliases com Redirecionamento 301:**
  - `https://banca.2lp.in/patilera` $\rightarrow$ `/pratilera/` (tolerância a digitação abreviada)
  - `https://banca.2lp.in/prateleira` $\rightarrow$ `/pratilera/` (tolerância a norma culta)
  - `https://banca.2lp.in/repo` $\rightarrow$ `/pratilera/` (compatibilidade com convenção clássica F-Droid)
- **Deep Link Droid-ify:** `fdroidrepos://banca.2lp.in/pratilera`

### 3.2 Estrutura de Arquivos (`site/pratilera/`)
```
site/pratilera/
├── index-v1.jar          # Índice assinado criptograficamente com a chave in_twolp via jarsigner
├── index-v1.json         # Manifesto canônico de pacotes, versões, tamanhos e hashes SHA256
├── entry.json            # Ponto de entrada do protocolo Index-v2 moderno
├── index-v2.json         # Payload estruturado Index-v2
├── icons/                # Ícones dos aplicativos em alta resolução
└── *.apk                 # Binários Android de produção assinados (lacraia-app.apk, etc.)
```

### 3.3 Chave e Assinatura Criptográfica
- Todos os pacotes são identificados sob o domínio `in.twolp.*`.
- O arquivo `index-v1.jar` é assinado utilizando a chave soberana `in_twolp` oriunda de `~/.android/in_twolp_release.keystore`.
- A impressão digital SHA256 da chave garante integridade e confiança unificada em um único repositório no smartphone do usuário.

### 3.4 Versionamento CCCP, Pré-Releases e UX HTTPS Canônica
- **Sincronização de Versão**:
  - `versionName`: Reflete 100% a versão SemVer 2.0.0 gerada pelo CCCP (`VERSION` ou `cccp version`), contendo sufixos de desenvolvimento e commit hash (ex: `0.2.0-dev.68+20261013.f409263`).
  - `versionCode`: Inteiro positivo monotonicamente crescente exigido pelo instalador do Android (derivado de timestamp `YYYYMMDDHH` ou contagem de commits).
- **Gestão de Pré-Releases (Canal Único com `suggestedVersionCode`)**:
  - Builds contendo identificadores de pré-lançamento (`-dev`, `-alpha`, `-beta`, `-rc`) são disponibilizadas no catálogo sob o array de versões, mas não promovem o campo `suggestedVersionCode` da aplicação, assegurando que usuários gerais permaneçam na versão estável enquanto testadores podem instalar versões experimentais manualmente no Droid-ify.
- **Interface e Aderência ao Formulário do Droid-ify**:
  - Como formulários de clientes F-Droid (notadamente Droid-ify) rejeitam esquemas não-HTTP com a mensagem "endereço inválido", a vitrine web prioriza a URL canônica `https://banca.2lp.in/pratilera` e botão de 1-toque com cópia para o clipboard, que é detectado automaticamente pelo aplicativo.

## 4. Curadoria da Vitrine, Padronização PT-BR e Safe Zone 4:3 dos Cartazes

- **Catálogo de Projetos Autorais (`data/projects.json`)**:
  - Curadoria estrita de 20 projetos ativos mantidos pelo ecossistema Lumen Pink.
  - Exclusão de componentes de infraestrutura pura ou rascunhos descontinuados (`aura`, `ListaDeFármacos`, `baquara-infra`, `baquara-install`, `install_i3`, `garden_infra`, `scripts`).
  - Nomenclatura canônica e grafia corrigida de `ishcondidim` com `sh` (slug `lumenpink/ishcondidim`).
- **Padronização Linguística em Português do Brasil (PT-BR)**:
  - Eliminação de resíduos em inglês ou termos corporativos desnecessários em descrições de projetos (`lacraia`, `whostyles`, `whostyles-wordpress`, `svyaz`, `mayak`, `kvant`, `indieinabox`).
  - Preservação da voz autoral, ácida e autônoma sem formatação quebrada.
- **Safe Zone 4:3 e Integridade Visual das Margens**:
  - Padrão KokoroSim: Área útil essencial contida em 720×500 px dentro de 1200×630 px com respiro lateral de 240 px.
  - No CSS da vitrine, o container `.zine-media` adota `aspect-ratio: 1200 / 630; width: 100%; height: auto; object-fit: contain;` eliminando qualquer corte ou achatamento de imagens nas bordas.
- **Aceite de Rotas & Dica da Calçada**:
  - Acolhimento de rotas alternativas com humor e tolerância explícita a "erros para mais e para menos" (`/patilera`, `/prateleira`, `/repo`).
