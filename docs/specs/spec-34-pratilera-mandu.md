# Especificação Técnica — Integração do Mandu na Pratilera e no Catálogo (#34)

## 1. Contexto e Objetivo
O **Mandu** (`in.twolp.mandu`) é o editor brutalista de notas e conhecimento em texto puro do ecossistema 2lp, escrito em Rust (Dioxus 0.7 no Android), com suporte a wikilinks, diagramas Joaju, compilação Typst e digitação touch ergonômica.
O objetivo desta especificação é formalizar a integração soberana do Mandu ao repositório F-Droid / Droid-ify (**A Pratilera**) e ao catálogo estático público da Banca (`data/projects.json`).

## 2. Requisitos Técnicos

### 2.1 Metadados da Pratilera (`scripts/gerar-pratilera.py`)
- Pacote Android: `in.twolp.mandu`
- Nome de exibição: `Mandu`
- Resumo (summary): `Editor Brutalista de Notas & Conhecimento`
- Descrição: `Editor brutalista de notas em texto puro com suporte a wikilinks, diagramas Joaju, compilação Typst e digitação touch ergonômica em Rust.`
- Ícone canônico: `in.twolp.mandu.png`
- Categorias F-Droid: `["Writing", "Office", "Utility"]`
- Arquivo do APK: `mandu.apk`
- Versão canônica: extraída dinamicamente de `../mandu/VERSION` (SemVer canônico CCCP)
- Resolução de APK local:
  1. `site/pratilera/mandu.apk`
  2. `.cache/apks/mandu.apk`
  3. `../mandu/dist/android/mandu.apk`
  4. Fallback remoto: `https://bucket.2lp.in/mandu.apk`
- Sanitização de ícone: garantia de profundidade estrita 8-bit RGBA nas densidades `icons-120` até `icons-640`, raiz e Fastlane (`<pkg>/<loc>/icon.png`).

### 2.2 Entrada no Catálogo da Banca (`data/projects.json`)
- Nome: `mandu`
- Slug: `lumenpink/mandu`
- Forge: `codeberg`
- Grupo: `2lp`
- Categoria: `apps`
- Banner: `assets/banners/mandu-banner.png` (dimensões estritas 1200x630, Safe Zone)
- Tópicos: `["rust", "dioxus", "markdown", "editor", "typst", "android"]`

### 2.3 Critérios de Aceite
1. Execução de `scripts/gerar-pratilera.py` inclui `in.twolp.mandu` em `site/pratilera/index-v1.json` e `site/index-v1.json`.
2. O arquivo `mandu.apk` é copiado e indexado com hash SHA-256 e tamanho exatos.
3. Os ícones Fastlane e de densidade para `in.twolp.mandu` são gerados em 8-bit RGBA.
4. O build da Banca (`./build.sh`) renderiza o cartão do Mandu com banner funcional em `site/index.html`.
5. Validação com `./tests/test-pratilera-mandu.sh` e conformidade completa com `./tests/test-pratilera.sh`.
