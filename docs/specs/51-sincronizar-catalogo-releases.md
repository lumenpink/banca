# Especificação Técnica: Sincronização do Catálogo da Banca com Releases Ativas

- **Ticket:** [#51](https://gambi.2lp.in/lumen/banca/issues/51)
- **Status:** Em Andamento
- **Autor:** Lumen Pink (Baquara)

---

## 1. Objetivo

Regenerar e sincronizar o arquivo de catálogo consolidado `site/downloads/catalog.json` para refletir com exatidão as versões ativas presentes nos manifestos locais (`site/downloads/*/index.json`), em especial as versões recentes de `jornaleira` e `cccp`.

---

## 2. Critérios de Aceite

1. O arquivo `site/downloads/catalog.json` deve conter a versão nightly correspondente para a `jornaleira` (`0.1.0-dev.27+20261030.11e3009`), em conformidade com o seu manifesto em `site/downloads/jornaleira/index.json`.
2. A suíte de testes `tests/test-downloads-catalog.sh` deve validar que a versão da `jornaleira` no catálogo não se encontra vazia quando há release ativa.
3. Auditoria estrita com `cccp check --strict` deve ser aprovada com 100% de conformidade.
