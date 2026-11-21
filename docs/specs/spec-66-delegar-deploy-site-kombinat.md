# Especificação do Ticket #66: Delegar Deploy do Site da Banca ao Kombinat via Generic Packages

## 1. Contexto e Motivação
Os workflows `.forgejo/workflows/ci.yml` e `.forgejo/workflows/dispatch.yml` publicavam diretamente no Cloudflare Workers via `npx wrangler deploy`. Com o Kombinat orquestrando entregas a partir dos hooks da Gambi, a CI deve empacotar e enviar `site/` via `cccp package upload site`.

## 2. Requisitos
1. Substituir `npx wrangler deploy` por `cccp package upload site` em `.forgejo/workflows/ci.yml` e `.forgejo/workflows/dispatch.yml`.
2. Remover `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID` dos workflows de CI da Banca.

## 3. Árvore de Decisões (para a Natasha)
- **Separação CI vs CD:** A Banca compila a vitrine e o catálogo da Pratilera na CI e entrega `site.tar.gz` nos Generic Packages; o Kombinat consome e publica na borda.
