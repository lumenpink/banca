# Especificação Técnica — Satélites do Joaju no Catálogo da Banca (#37)

## 1. Contexto e Objetivo
O ecossistema **Joaju** é a infraestrutura soberana de publicação acadêmica, diagramação técnica e modelagem clínica do ecossistema 2LP.
Para além do compilador principal (`joaju`), o ecossistema é composto por 6 módulos satélites especializados.
Esta especificação formaliza a integração desses 6 projetos ao catálogo público da vitrine estática da Banca (`data/projects.json`).

## 2. Mapeamento dos Satélites

| Projeto | Categoria | Licença | Tópicos Principais |
| :--- | :--- | :--- | :--- |
| **`joaju-obsidian`** | `apps` | GPL-3.0 | `obsidian`, `plugin`, `academic`, `typst`, `healthcare`, `pedigree` |
| **`joaju-pedigree`** | `pesquisa` | Apache-2.0 | `rust`, `genetics`, `pedigree`, `healthcare`, `acmg`, `typst` |
| **`joaju-table`** | `editorial` | Apache-2.0 | `rust`, `typst`, `tables`, `abnt`, `academic` |
| **`joaju-csv`** | `pesquisa` | Apache-2.0 | `rust`, `csv`, `data`, `parser`, `typst` |
| **`joaju-unfurl`** | `editorial` | Apache-2.0 | `rust`, `opengraph`, `ssrf-defense`, `metadata`, `typst` |
| **`joaju-web`** | `pesquisa` | Apache-2.0 | `rust`, `axum`, `http`, `compiler`, `playground` |

## 3. Requisitos Visuais e Banners
- Cada satélite deve possuir um banner oficial Safe Zone de proporção exata 1200x630 (8-bit RGB).
- Os arquivos residem em `assets/banners/<slug>-banner.png` e são espelhados em `site/assets/banners/<slug>-banner.png`.
- A estética adota o design gráfico acadêmico-clínico do ecossistema Joaju.

## 4. Critérios de Aceite
1. Execução de `./build.sh` compila e renderiza os 6 novos cartões em `site/index.html` (total de 37 projetos).
2. Validação automatizada via `tests/test-catalog-joaju-satellites.sh` cobrindo existência, categorias, licenças, dimensões de banner e testes de mutação.
3. Auditoria estrita 100% aprovada pelo `cccp check --strict`.
