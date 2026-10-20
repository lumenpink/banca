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

## 9. Conformidade Estrita com Decodificadores Android e Droid-ify (Ticket #22)

- **Profundidade de Cor 8-bit RGBA Obrigatória**:
  - Todos os ícones PNG para a Pratilera e Banca devem possuir profundidade estrita de 8 bits por canal (`Bit depth: 8, Color type: 6` no cabeçalho IHDR).
  - O decodificador `BitmapFactory` / `SkCodec` do Android e a engine de imagens Coil 3 não suportam PNGs de 16 bits por canal (64-bit RGBA), falhando na alocação de memória e na decodificação. O script `scripts/gerar-pratilera.py` converte automaticamente qualquer imagem de entrada para 8-bit RGBA usando PIL.
- **Tipagem de `suggestedVersionCode` como String no `index-v1.json`**:
  - O parser de streaming Jackson do Droid-ify (`IndexV1Parser.kt`) valida o token `key.string("suggestedVersionCode")` (`JsonToken.VALUE_STRING`).
  - O modelo serializável `AppV1.kt` declara `suggestedVersionCode: String?`.
  - O gerador emite o valor explicitamente como string (ex: `"1"`), alinhado ao padrão de repositórios como IzzyOnDroid e F-Droid.
- **Identidade do Repositório (`repo.icon = "icon.png"`) e Espelhamento Físico Sem Redirecionamentos**:
  - Padronização de `repo.icon` como `"icon.png"`.
  - Espelhamento físico direto das árvores de ícones (`icons/`, `icons-<dpi>/`, `<pkg>/`) em `site/` e `site/pratilera/`, eliminando a dependência de redirecionamentos 301 para requisições de imagens em clientes Android.
## 10. Resiliência de Build no CI e Sanitização Idempotente de Ícones (Ticket #23)

- **Dependência do Ambiente de CI**:
  - O container do runner de CI deve prover o pacote `python3-pil` no job de testes e validação da vitrine estática para garantir a normalização de imagens para 8 bits RGBA.
- **Idempotência e Segurança em `sanitize_icon_8bit`**:
  - Na função de sanitização de ícones, caso a importação de `PIL` falhe ou ocorra qualquer exceção na conversão, a rotina de fallback de cópia só deve invocar `shutil.copy2(src, dst)` quando `src_path.resolve() != dst_path.resolve()`.
  - Se a origem e o destino coincidirem no sistema de arquivos, a operação é um no-op seguro, prevenindo exceções do tipo `shutil.SameFileError`.

## 11. Extração Dinâmica de Metadados de APKs e Integridade do Droid-ify (Ticket #24)

- **Extração Dinâmica via `aapt dump badging`**:
  - O gerador da Pratilera (`scripts/gerar-pratilera.py`) não deve depender de metadados estáticos ou hardcoded de `version_code` e `version_name`.
  - Para cada APK existente em `site/pratilera/`, o gerador executa `aapt dump badging` para extrair os valores reais de:
    - `versionCode` (inteiro positivo).
    - `versionName` (string semântica do build Android).
    - `minSdkVersion` (inteiro de API level).
    - `targetSdkVersion` (inteiro de API level).
  - Caso `aapt` não esteja disponível ou ocorra falha de leitura, o gerador utiliza os valores de contingência declarados em `APPS_METADATA`.
- **Integridade do Catálogo F-Droid e Verificação de Pacotes no Droid-ify**:
  - O Droid-ify valida a igualdade estrita entre o `versionCode` presente no cabeçalho do APK baixado e o `versionCode` declarado no array de pacotes em `index-v1.json` (`IndexV1Parser.kt` e `PackageInstaller.kt`).
  - Declarar `versionCode` divergente do binário resulta no erro crítico `Metadado inválido` no cliente Android.
  - O campo `suggestedVersionCode` deve refletir como string (`"suggestedVersionCode": "<code_str>"`) o código de versão compatível para instalação direta.

## 12. Soberania do SemVer Canônico CCCP em `versionName` (Ticket #25)

- **Autoridade Estrita do Arquivo `VERSION` (CCCP)**:
  - Conforme as diretrizes GOST e do ecossistema CCCP, a versão canônica exibida aos usuários no catálogo (`versionName`) provém estritamente do arquivo `VERSION` na raiz do projeto irmão (ex: `lauda/VERSION`, `lacraia/VERSION`), gerenciado via `cccp version` / `cccp tag`.
  - O `versionName` NÃO deve ser sobrescrito por strings de build interno de empacotadores Android (ex: `*-nightly.*`), garantindo consistência com o restante do ecossistema Sovereign Software.
- **Convivência Harmônica com o `versionCode` do Android**:
  - O `versionCode` (inteiro) é extraído fielmente do APK via `aapt dump badging` para satisfazer a checagem de integridade do Android PackageManager e do Droid-ify.
  - O `versionName` (string de exibição) reflete a versão SemVer canônica do CCCP.

## 13. Eliminação de Regras Conflitantes de Redirecionamento de Ícones (Ticket #26)

- **Serviço Estático Direto (HTTP 200) Sem Interceptação de `_redirects`**:
  - No Cloudflare Pages, regras definidas em `_redirects` são avaliadas antes da resolução de arquivos estáticos no disco.
  - Regras genéricas para pastas físicas (como `/icons/*`, `/icons-120/*` até `/icons-640/*`) interceptavam arquivos estáticos reais espelhados na raiz, retornando `HTTP 301 Moved Permanently` para o cliente Android.
  - O decodificador de imagens Coil 3 e o cliente OkHttp no Android falham ou descartam respostas quando recebem redirecionamentos durante o carregamento de ícones de repositório e de produtos.
  - A regra corrompida `/in.twolp.*  /pratilera/:splat  301` cortava o prefixo `in.twolp.` de requisições de metadados Fastlane (ex: `/in.twolp.lacraia.app/pt-BR/icon.png`), gerando redirecionamento para caminhos inexistentes e resultando em `HTTP 404 Not Found`.
- **Escopo Estrito de `site/_redirects`**:
  - O arquivo `site/_redirects` deve conter única e exclusivamente apelidos e aliases de rotas sem representação física em disco (`/patilera`, `/prateleira`, `/repo`).
  - Caminhos que possuem espelhamento físico em disco (`site/icons/`, `site/icons-<dpi>/`, `site/in.twolp.*/`) NUNCA devem figurar no arquivo de redirecionamentos, assegurando entrega direta com `HTTP 200 OK` e `Cache-Control` padrão da Cloudflare.

## 14. Instalação Obrigatória de `aapt` no Runner de CI (Ticket #27)

- **Completude de Ferramentas no Pipeline de CI**:
  - O step de provisionamento de dependências em `.forgejo/workflows/ci.yml` deve instalar explicitamente o pacote `aapt` (Android Asset Packaging Tool), juntamente com `openjdk-17-jdk-headless` e `python3-pil`.
  - A ferramenta `aapt` é indispensável para extrair dinamicamente `versionCode`, `versionName` e SDK targets dos APKs físicos da Pratilera. Sua ausência no runner causa falha no teste de integridade 22 e impede a execução do job dependente `Deploy Documentation Site` (Cloudflare Pages).
- **Validação de Conformidade do CI**:
  - A suíte de testes deve auditar que `.forgejo/workflows/ci.yml` declara a instalação obrigatória do pacote `aapt`.

## 15. Hermeticidade e Execução em Sub-Imagem Atômica `gost-ci-banca` (Ticket #28)

- **Conformidade Estrita com a Seção 13.6 do GOST (Zero Volatilidade de Rede)**:
  - O pipeline de CI da Banca não deve realizar downloads ou instalações em tempo de execução via gerenciadores de pacotes (`apt-get install`), prevenindo falhas intermitentes por instabilidade de espelhos do sistema operacional hospedeiro.
  - O job de teste e validação `test` roda encapsulado na sub-imagem atômica oficial `codeberg.org/lumenpink/gost-ci-banca:latest`, hospedada no registry de containers da Codeberg e mantida no repositório irmão `gost-ci`.
- **Composição da Sub-Imagem `gost-ci-banca`**:
  - Base Debian Bookworm com Node 24 (`node:24-bookworm-slim`).
  - `openjdk-17-jdk-headless` pré-instalado (jarsigner para assinatura de pacotes e repositório).
  - `python3-pil` pré-instalado (conversão canônica de ícones para 8-bit RGBA).
  - `aapt` pré-instalado (inspeção e extração de metadados dos APKs).
  - Utilitários de base: `bash`, `git`, `file`, `curl`, `ca-certificates` e `jq`.

## 16. Identidade Visual Vetorial de Alta Resolução da Pratilera, Lacraia e Simbiótyka (Ticket #26)

- **Redesign do Ícone Oficial da Pratilera (`pratilera.png` / `icon.png`)**:
  - Substitui o modelo legado baseado em compactação do card completo (toldo, placa, múltiplos zines e equalizador) por uma estante modular minimalista em 3 níveis industriais.
  - Composição geométrica com caixas/encomendas maciças em blocos sólidos (fúcsia `#ff0055`, amarelo veneno `#d4ff00`, grafite e kraft) com fitas de embrulho em "X".
  - Ausência total de micro-textos, garantindo silhueta e reconhecimento imediato mesmo quando reduzido a 32x32 e 48x48 nos cards de repositório do Droid-ify.
- **Ícones Canônicos das Aplicações**:
  - **Lacraia (`in.twolp.lacraia.app`)**: Chassi escuro grafite (`#151618`), antenas elétricas com respiro confortável (~75px) das bordas arredondadas, forcípulas peçonhentas em fúcsia e ocelos sensoriais fluorescentes.
  - **Simbiótyka (`in.twolp.lacraia.simbiotyka`)**: Base da Lacraia customizada com os óculos do Kamina sem armação aparente em vermelho escarlate (`#f50f26`) e flash estelar de anime de 4 pontas na lente direita.
- **Sincronização e Formato**:
  - Renderização via supersampling 2x (1024x1024 -> 512x512) com antialiasing LANCZOS e gravação estrita em 8-bit RGBA.
  - Sincronização em todas as densidades (`icons-120` até `icons-640`), na raiz física do site (`site/icons/`, `site/pratilera/icons/`) e nos metadados Fastlane (`site/pratilera/<pkg>/<locale>/icon.png`).

## 17. Sincronização dos Ícones Oficiais do Lauda em 8-Bit RGBA na Pratilera (Ticket #27)

- **Identidade Visual Canônica do Lauda (`in.twolp.lauda`)**:
  - Padrão Trash Polka Postal (Proposta C2): envelope brutalista branco com vincos pretos expressivos e sombra dura vetorial.
  - Carimbo postal cancelador reforçado (anel externo ultra-pesado de 10.5px e barras de 5px em carmim `#dc143c`) com a tipografia `" S M O L "` posicionada 100% sobre a área branca do envelope para máxima legibilidade.
  - Lacre central em bloco maciço preto puro sem letras e ausência de tarja inferior de texto.
- **Distribuição Multi-Densidade no Catálogo F-Droid / Droid-ify**:
  - O script `scripts/gerar-pratilera.py` importa `site/lauda-logo.png` do repositório irmão `lauda` e aplica sanitização vetorial estrita em 8-bit RGBA.
  - Espelhamento em todas as 6 pastas de densidade da Pratilera: `icons-120`, `icons-160`, `icons-240`, `icons-320`, `icons-480` e `icons-640`.
  - Atualização dos metadados Fastlane estruturados: `site/pratilera/in.twolp.lauda/pt-BR/icon.png` e `en-US/icon.png`.
  - Re-assinatura do índice oficial `index-v1.jar` com a chave release soberana `in_twolp`.

## 18. Distribuição Externa via Cloudflare R2 e Resiliência de Metadados da Pratilera (Ticket #31)

- **Distribuição Canônica no Bucket R2 (`https://bucket.2lp.in`)**:
  - O catálogo da Pratilera declara `repo.address = "https://bucket.2lp.in"`.
  - Os clientes Android (Droid-ify / F-Droid) resolvem o download dos binários diretamente contra a URL do bucket R2 soberano (`https://bucket.2lp.in/<app>.apk`), desonerando os Workers de streaming pesado.
- **Proteção Contra Limite de Assets do Cloudflare Workers (25 MB)**:
  - O diretório `site/` publicado via Cloudflare Workers Static Assets não deve conter arquivos `.apk` pesados (evitando rejeição de deploy por limite de 25 MB por asset).
  - O script gerador e o workflow de deploy garantem a limpeza de quaisquer APKs temporários em `site/pratilera/` antes da publicação.
- **Resiliência de Metadados e Inspeção Hermética**:
  - Na ausência do arquivo APK no disco do runner de CI, `scripts/gerar-pratilera.py` faz download temporário em diretório cache fora de `site/` a partir de `https://bucket.2lp.in/<apk>` para aferir hash SHA-256 real, tamanho em bytes e metadados via `aapt dump badging`.
  - Em modo offline ou falha de conectividade, o gerador preserva os metadados verídicos já consolidados no `index-v1.json` versionado no git, proibindo estritamente a emissão de valores dummy (tamanho <= 1024 ou hashes zeradas).
- **Gatilho Remoto de Atualização Automática via CI**:
  - O arquivo `.forgejo/workflows/ci.yml` habilita o evento `workflow_dispatch`, permitindo que pipelines de CI dos projetos de aplicativos disparem a re-geração do índice e deploy na produção assim que um novo APK for publicado no R2.

## 19. Infraestrutura de Downloads Multi-Arquitetura e Canais do Updater (Tickets #35 & #32)

- **Distribuição Multi-Arquitetura Hermética**:
  - A Banca consolida a vitrine web e endpoints de entrega direta em `https://banca.2lp.in/downloads/` com suporte a `linux-amd64` (x86_64), `linux-arm64` (AArch64) e `windows-amd64` (x86_64).
  - Aliases canônicos atômicos apontando para as versões mais recentes (`stable-latest` e `nightly-latest`) tanto com sufixo de arquitetura quanto com fallback padrão para `linux-amd64`.
- **Manifestos Atômicos `index.json` por Aplicação**:
  - Cada software catalogado disponibiliza `https://banca.2lp.in/downloads/<app>/index.json`, servindo de fonte canônica para updaters de terminal (como `mandu update`, `cccp`, `lauda`, etc.).
  - Os manifestos declaram artefatos segregados por arquitetura (`linux-amd64`, `linux-arm64`, `windows-amd64`) contendo `url`, `binary_url` e `sha256`.
  - Retenção estrita de até 5 versões estáveis e até 10 nightlies via `scripts/rotate-downloads.py`.
- **Resolução de Rotas em `site/_redirects`**:
  - Regra específica `/downloads/:app  /downloads/index.html  200` que previne interceptação indevida de arquivos estáticos, manifestos `.json`, tarballs e executáveis binários.
- **Vitrine Web com Detecção e PowerShell**:
  - Seletor tátil de arquiteturas na interface com detecção inteligente no navegador (`navigator.userAgentData` / `navigator.userAgent`).
  - Emissão de comando PowerShell nativo (`Invoke-WebRequest`) para usuários Windows e `curl -sSL` para usuários Linux.
  - Atualização do Mandu como editor soberano brutalista de notas em texto puro, Markdown e Joaju.

