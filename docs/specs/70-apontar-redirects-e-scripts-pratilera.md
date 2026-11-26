# Spec #70 — Apontar redirects e scripts da Pratilera para `https://bucket.2lp.in/pratilera/`

- **Ticket:** `#70`
- **Escopo:** `scripts/gerar-pratilera.py`, `site/_redirects`

## Contexto e Árvore de Decisões
O `kombinat` passa a armazenar todos os APKs exclusivamente sob o prefixo `pratilera/<app>.apk` no R2 (`twolp-bucket`), evitando duplicação na raiz do bucket.
- **Escolha adotada:** atualizar `gerar-pratilera.py` (`remote_url`) e `site/_redirects` para `https://bucket.2lp.in/pratilera/<app>.apk`.
- **Alternativa descartada:** manter cópias na raiz do bucket R2.
