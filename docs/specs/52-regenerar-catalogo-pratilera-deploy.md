# Especificação Técnica: Regenerar Catálogo da Pratilera antes do Deploy no Workers

- **Ticket:** [#52](https://gambi.2lp.in/lumen/banca/issues/52)
- **Status:** Em Andamento
- **Autor:** Lumen Pink (Baquara)

---

## 1. Objetivo

Garantir que a esteira de CI/CD do repositório `banca` (`.forgejo/workflows/ci.yml`), no job `deploy-site`, regenere os arquivos de catálogo da Pratilera (F-Droid) executando `python3 scripts/gerar-pratilera.py` e execute o build (`./build.sh`) antes de efetuar a publicação com `npx wrangler deploy`.

---

## 2. Contexto do Problema

O job `test` executava `python3 scripts/gerar-pratilera.py`, mas o job `deploy-site` roda em container isolado e realizava checkout limpo do repositório Git, invocando diretamente `npx wrangler deploy` sem invocar `scripts/gerar-pratilera.py`. Dessa forma, o catálogo publicado no Cloudflare Workers permanecia estático e defasado em relação aos novos APKs enviados ao bucket R2 pelas aplicações (como o `lauda`).

---

## 3. Critérios de Aceite

1. O fluxo `.forgejo/workflows/ci.yml` no job `deploy-site` deve conter a etapa de regeneração do catálogo da Pratilera executando `python3 scripts/gerar-pratilera.py` e `./build.sh` antes da chamada a `npx wrangler deploy`.
2. O teste automatizado em `tests/test-ci-deploy-pratilera.sh` deve validar que o job `deploy-site` do workflow do CI contém os comandos de regeneração do catálogo.
3. Auditoria estrita com `cccp check --strict` deve ser aprovada com 100% de conformidade.
