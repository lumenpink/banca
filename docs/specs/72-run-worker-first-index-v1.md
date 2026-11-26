# Spec #72 — Habilitar `run_worker_first` e `no-cache` para `index-v1`

- **Ticket:** `#72`
- **Escopo:** `wrangler.jsonc`, `src/worker.js`

## Contexto e Árvore de Decisões
Sem `"run_worker_first": true` no bloco `assets` do `wrangler.jsonc`, o Cloudflare Workers Assets servia as cópias estáticas antigas de `site/index-v1.json` e `site/pratilera/index-v1.{json,jar}` antes de invocar `src/worker.js`.
- **Escolha adotada:** definir `"run_worker_first": true` em `wrangler.jsonc` e desabilitar cache de edge para `index-v1.{json,jar}` no Worker, mantendo `no-cache` na resposta do índice.
- **Alternativa descartada:** remover manualmente arquivos de `site/pratilera/` quebrando testes legados de estrutura local.
