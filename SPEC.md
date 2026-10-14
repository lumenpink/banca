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
├── icons/                # Ícones dos aplicativos em alta resolução (fallback)
├── icons-120/            # Ícones de densidade ldpi (120 dpi) para Droid-ify / F-Droid
├── icons-160/            # Ícones de densidade mdpi (160 dpi) para Droid-ify / F-Droid
├── icons-240/            # Ícones de densidade hdpi (240 dpi) para Droid-ify / F-Droid
├── icons-320/            # Ícones de densidade xhdpi (320 dpi) para Droid-ify / F-Droid
├── icons-480/            # Ícones de densidade xxhdpi (480 dpi) para Droid-ify / F-Droid
├── icons-640/            # Ícones de densidade xxxhdpi (640 dpi) para Droid-ify / F-Droid
├── icon.png, pratilera.png, *.png # Ícones replicados na raiz para resolução direta
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

## 5. Expansão para 27 Projetos Autorais e Taxonomia Semântica

- **Adição dos 7 Projetos Autorais Estratégicos**:
  - `lauda`: Cliente de correio soberano ultraleve (Rust, Dioxus, Android/Desktop).
  - `ayvu`: Compilador declarativo de tirinhas e fanzines em quadrinhos (Rust, SVG).
  - `muiraquita`: Suíte social soberana para a IndieWeb e ecossistema IndieInABox (Rust, Dioxus).
  - `tuitata`: Cliente TUI para IA em Rust com streaming, estética Boitatá e exportação Obsidian.
  - `urupema`: Utilitário post-queue em Rust para dissecação de MIME e triagem para Markdown.
  - `tatupeba`: Extrator e sincronizador contínuo do acervo Zotero para o cofre Obsidian.
  - `baquara-rs`: Motor nativo de IA local, RAG semântico híbrido e servidor MCP em Rust.
- **Taxonomia Semântica em 6 Categorias (`data/projects.json`)**:
  1. `apps`: 📱 Aplicativos & Som (Pratilera)
  2. `terminal`: ⚡ Terminal, CLI & Sistemas
  3. `indieweb`: 🌐 IndieWeb & Fediverse
  4. `editorial`: ✂ Editorial, Arte & Zines
  5. `pesquisa`: 📚 Conhecimento, Saúde & Ciência
  6. `governance`: ☭ Normas Técnicas & Gosplan (CCCP Comrades)
- **Interface e Navegação Reativa**:
  - Filtros no `controls-panel` por categoria (`apps`, `terminal`, `indieweb`, `editorial`, `pesquisa`, `governance`, `all`).
  - Badges visuais de categoria estampados nos cartazes de cada zine/projeto.
- **Renderização e Pôsteres Exclusivos (Safe Zone 4:3)**:
  - Produção determinística via `navalha poster` com presets gráficos personalizados para os 7 novos projetos.

## 6. Identidade Visual Unificada: Ícone Oficial da Pratilera & Banca (Droid-ify / F-Droid)

- **Ícone Canônico 512×512 (A Pratilera & Banca)**:
  - Estética brutalista de banca de calçada, zines e ecossistema 2lp.
  - Paleta: Fundo preto de calçada (`#151618`), fúcsia/magenta (`#e60050` / `#ff0055`) e veneno/limão (`#d4ff00`).
  - Geometria protegida com respiro interno de 10% (sem cortes em cantos arredondados ou máscaras circulares do Android).
- **Matriz de Resolução de Caminhos (Droid-ify, Neo Store e F-Droid)**:
  - `site/pratilera/icons/icon.png`: Endereço estrito utilizado pelo `RepositoriesAdapter` do Droid-ify (`${address}/icons/icon.png`).
  - `site/pratilera/icons/pratilera.png`: Resolução relativa da conversão `RepoV1` para `RepoV2` via campo `"icon": "pratilera.png"` do índice v1.
  - `site/pratilera/icon.png` e `site/pratilera/pratilera.png`: Fallbacks clássicos servidos na raiz do repositório.
- **Unificação com a Vitrine da Banca**:
  - `site/assets/icon.png` e `site/favicon.svg`: O mesmo ícone oficial é adotado como marca e favicon da Banca, unificando a experiência da vitrine web com a loja de aplicativos.
- **Ícones Reais dos Pacotes**:
  - Substituição dos mocks 1x1 por ícones em alta resolução para os aplicativos distribuídos (`in.twolp.lacraia.app.png`, `in.twolp.lacraia.simbiotyka.png`, `in.twolp.lauda.png`).

## 7. Distribuição de Binários Reais e Integridade Criptográfica dos APKs

- **Binários Nativos Soberanos**:
  - `site/pratilera/lacraia-app.apk`: Binário de produção do Cockpit Brutalista de Som & Jukebox (~4,9 MB), compilado a partir do módulo `:app` sob o namespace canônico `in.twolp.lacraia.app`.
  - `site/pratilera/simbiotyka.apk`: Binário de produção do HUD Flutuante de Letras Sincronizadas (~4,9 MB), compilado a partir do módulo `:simbiotyka` sob o namespace `in.twolp.lacraia.simbiotyka`.
  - `site/pratilera/lauda-latest.apk`: Binário de produção do Cliente de Correio Soberano (~21,8 MB).
- **Integridade Criptográfica e Manifestos F-Droid**:
  - O gerador `scripts/gerar-pratilera.py` afere o tamanho exato em bytes e computa a hash SHA-256 de cada arquivo físico.
  - O arquivo `site/pratilera/index-v1.jar` empacota o manifesto e é assinado via `jarsigner` com a chave `in_twolp`.
  - Elimina quaisquer fallbacks nominais de 1024 bytes ou hashes nulas no catálogo da Pratilera.

## 8. Metadados Fastlane Localized e Resolução Universal de Ícones (Droid-ify / F-Droid)

- **Estrutura Localized no `index-v1.json`**:
  - O cliente Droid-ify converte o modelo `AppV1` para Room DB via `localized?.localizedIcon(...)` (`IndexConverter.kt`). Se `app.localized` for nulo/ausente, a entidade `localized_app_icon` não é persistida no banco local, impedindo a exibição de ícones na lista de aplicativos.
  - A Pratilera passa a emitir o dicionário `"localized"` contendo metadados completos (`name`, `summary`, `description`, `icon`) para os locales `pt-BR` e `en-US`.
- **Estrutura Física de Diretórios Fastlane**:
  - Replicação determinística dos ícones em `site/pratilera/<packageName>/<locale>/icon.png` para cada aplicativo do catálogo.
- **Resolução de Ícones do Repositório e Redirecionamentos Transparentes**:
  - Replicação de `icon.png` e `pratilera.png` tanto em `site/pratilera/icons/` quanto na raiz do domínio `site/icons/`.
  - Configuração de regras no `site/_redirects` cobrindo `/icons/*` e `/in.twolp.*` para garantir que o cliente Android carregue os ativos independentemente de ter cadastrado a URL com ou sem o sufixo `/pratilera`.


