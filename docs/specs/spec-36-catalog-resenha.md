# Especificação Técnica — Inclusão do Resenha no Catálogo da Banca (#36)

## 1. Contexto e Objetivo
O **resenha** (`lumenpink/resenha`) é o subsistema de extração de miolo textual e sanitização tipográfica na borda em Markdown estrito, operando tanto como CLI autônomo quanto como motor editorial integrado ao Fuxico (`fuxico.lumen.pink`).
O objetivo desta especificação é formalizar a entrada do `resenha` no catálogo público da vitrine estática da Banca (`data/projects.json`).

## 2. Requisitos Técnicos

### 2.1 Entrada em `data/projects.json`
- **Nome:** `resenha`
- **Forge:** `codeberg`
- **Slug:** `lumenpink/resenha`
- **Categoria:** `editorial` (conforme taxonomia da Banca)
- **Descrição:** `Subsistema de extração de miolo textual e sanitização tipográfica na borda em Markdown estrito para o Fuxico e terminal`
- **Tópicos:** `["rust", "cli", "markdown", "readability", "editorial", "indieweb"]`
- **Licença:** `GPL-3.0`
- **Website:** `https://fuxico.lumen.pink`
- **Grupo:** `""`
- **Banner:** `assets/banners/resenha-banner.png`

### 2.2 Requisitos do Banner
- Dimensões estritas: 1200x630 (proporção Safe Zone da vitrine).
- Profundidade de cor e compatibilidade: RGB 8-bit.
- Tipografia brutalista editorial com paleta condizente ao ecossistema 2LP.
- Disponibilidade em `assets/banners/resenha-banner.png` e espelhamento em `site/assets/banners/resenha-banner.png`.

### 2.3 Critérios de Aceite
1. Execução de `./build.sh` renderiza o cartão do `resenha` em `site/index.html`.
2. Presença de banner de 1200x630 validada programaticamente.
3. Testes automatizados em `tests/test-catalog-resenha.sh` cobrindo asserções positivas e testes de mutação.
4. Auditoria estrita aprovada com 100% de conformidade pelo `cccp check --strict`.
