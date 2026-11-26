# Spec #71 — Worker proxy para `pratilera.2lp.in` e `banca.2lp.in/pratilera/*`

- **Ticket:** `#71`
- **Escopo:** `wrangler.jsonc`, `src/worker.js`, `tests/worker.test.mjs`

## Contexto e Árvore de Decisões
O Cloudflare Workers Assets estático (`./site`) não executa `_redirects` e tem limite de 25 MiB por arquivo (impedindo incluir `mocambo.apk`), além de manter `site/pratilera/index-v1.json` congelado em relação às entregas do `kombinat` no R2 (`bucket.2lp.in/pratilera/*`).
- **Escolha adotada:** adicionar `src/worker.js` com binding `ASSETS` e rotas `banca.2lp.in` + `pratilera.2lp.in` em `wrangler.jsonc`. O Worker faz proxy transparente de `pratilera.2lp.in/*` e `banca.2lp.in/pratilera/*` para `https://bucket.2lp.in/pratilera/*` (com fallback para `env.ASSETS` em caso de 404 no R2, preservando ícones e páginas estáticas) e aplica redirects de aliases (`/patilera`, `/prateleira`, `/repo`, `/downloads/*`).
- **Alternativa descartada:** criar um segundo bucket R2 e duplicar configuração de credenciais/env no `kombinat` e `gossnabd`.
