# Spec: Correção de Erro 404 nos Links de Download da Banca (#43)

## Contexto
Na vitrine de downloads da Banca (`https://banca.2lp.in/downloads/`) e nos manifestos gerados para as aplicações (`/downloads/:app/index.json`), diversos links e botões de download estavam gerando caminhos sob o domínio `https://banca.2lp.in/downloads/...` sem que os arquivos físicos existissem no Cloudflare Pages e sem que houvesse regras de redirecionamento em `site/_redirects` para o bucket Cloudflare R2 (`https://bucket.2lp.in/downloads/...`). Isso resultava em respostas `HTTP 404 Not Found` para os usuários ao tentarem baixar os programas estáveis e nightlies.

## Objetivo
1. Configurar regras de redirecionamento canônicas (HTTP 302) em `site/_redirects` para mapear rotas de download (`/downloads/:app/stable-latest/*`, `/downloads/:app/nightly-latest/*`, `/downloads/:app/stable/*`, `/downloads/:app/nightly/*`) diretamente para `https://bucket.2lp.in/downloads/...`.
2. Atualizar o script gerenciador `scripts/rotate-downloads.py` para gerar URLs de download canônicas apontando diretamente para `https://bucket.2lp.in/downloads/{app_slug}` por padrão.
3. Atualizar a vitrine `site/downloads/index.html` para usar diretamente `https://bucket.2lp.in/downloads/...` nos links e botões de fallback e nas listas renderizadas.
4. Higienizar os manifestos existentes em `site/downloads/*/index.json`, convertendo referências obsoletas de `https://banca.2lp.in/downloads/` para `https://bucket.2lp.in/downloads/`.

## Critérios de Aceitação
1. `site/_redirects` contém regras explícitas para canais `stable`, `nightly`, `stable-latest` e `nightly-latest` redirecionando para `https://bucket.2lp.in/downloads/...`.
2. `scripts/rotate-downloads.py` gera `https://bucket.2lp.in/downloads/...` em manifestos canônicos.
3. `site/downloads/index.html` referencia `https://bucket.2lp.in/downloads/...`.
4. Todos os arquivos `site/downloads/*/index.json` não contêm links quebrados apontando para `https://banca.2lp.in/downloads/`.
5. Teste automatizado `tests/test-downloads-r2-redirects.sh` valida todas as regras e passa em 100% das asserções.
