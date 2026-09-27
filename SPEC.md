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
