# Especificação Técnica: Schema Declarativo e Gerador do Catálogo Unificado (catalog.json)

- **Ticket:** [#54](https://gambi.2lp.in/lumen/banca/issues/54)
- **Status:** Proposto / Em Desenvolvimento
- **Norma:** GOST v2.0.0 / Perfil Lilya v2.0.0

---

## 1. Contexto e Motivação
A nova especificação da Banca adota a arquitetura **Produtor–Curador Desacoplado**, estabelecendo que:
- O catálogo central consolidado (`site/downloads/catalog.json`) organiza os softwares publicados em uma estrutura hierárquica por aplicação e por canais canônicos (`stable` e `dev`).
- Cada ativo entregável é tipado (`binary`, `archive`, `installer`, `package`), com formatos padronizados (`tar.gz`, `raw`, `zip`, etc.), targets explícitos (`linux-x86_64`, etc.), URLs canônicas, URLs de alias e hashes SHA-256.
- A integridade do catálogo é formalizada através de um schema declarativo JSON Schema (`catalog.schema.json`).
- Para preservar o funcionamento ininterrupto de updaters e ferramentas existentes (como Jornaleira, Mandu e CCCP), a Banca projeta e sincroniza as views de compatibilidade retroativa em `site/downloads/{app}/index.json`.

---

## 2. Contrato do Schema (`catalog.schema.json`)

O arquivo `site/downloads/catalog.schema.json` define a estrutura estrita de `catalog.json`:
- `$schema`: URI referenciando `./catalog.schema.json`.
- `updated_at`: String em formato ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ` ou com offset).
- `apps`: Dicionário indexado pelo slug da aplicação (`^[a-z0-9-]+$`).
- Cada entrada em `apps` contém:
  - `metadata`: `name` (string), `description` (string), `homepage` (URI), `repo` (URI).
  - `channels`:
    - `stable`:
      - `label`: `"Versão Recomendada"`
      - `latest_version`: string SemVer
      - `history_limit`: inteiro (5)
      - `versions`: lista de versões com `version`, `released_at`, `commit`, `assets`.
    - `dev`:
      - `label`: `"Versão Experimental"`
      - `latest_version`: string SemVer de desenvolvimento
      - `history_limit`: inteiro (10)
      - `versions`: lista de versões com `version`, `released_at`, `commit`, `assets`.
- Cada item em `assets` declara:
  - `target`: string (ex.: `linux-x86_64`, `linux-arm64`, `windows-amd64`).
  - `type`: enum `["binary", "archive", "installer", "package"]`.
  - `format`: string (ex.: `tar.gz`, `tar.xz`, `zip`, `raw`, `deb`, `rpm`, `sh`).
  - `filename`: string do arquivo físico versionado.
  - `alias`: string do alias canônico.
  - `url`: URI do binário no storage.
  - `alias_url`: URI do alias no storage.
  - `sha256`: string hexadecimal com exatamente 64 caracteres (`^[a-f0-9]{64}$`).

---

## 3. Compatibilidade Retroativa (`site/downloads/{app}/index.json`)

Para manter updaters já em campo funcionais:
- O módulo gerador mantém a geração sincronizada de `site/downloads/{app}/index.json` extraindo as versões `stable` e `dev` (mapeada para `nightlies` no formato legado).
- Seletor e views estáticas do portal web continuam consumindo os manifestos de download normalmente.
