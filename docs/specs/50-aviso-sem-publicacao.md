# Especificação Técnica: Indicação de Ausência de Publicação por Canal na Banca

**Ticket Associado:** #50  
**Branch:** `fix/50-aviso-sem-publicacao`  
**Norma:** GOST 2.0.0

## 1. Objetivo
Evitar a exibição enganosa de versões fictícias como `v0.1.0` ou `dev-latest` quando um determinado canal (`stable` ou `nightly`) não possuir publicações de binários reais, fornecendo feedback visual claro e desabilitando links de download inexistentes na vitrine web e nos catálogos.

## 2. Requisitos Técnicos
1. **Vitrine Web (`site/downloads/index.html`)**:
   - Para o canal Estável: se `stables` estiver vazio ou não houver versão com artefato real, exibir `"Nenhuma versão estável lançada"` no `#stable-ver-text`. O botão `#stable-download-btn` deve receber a classe `.disabled` (com atributo `aria-disabled="true"` e estilo de botão desabilitado), e o histórico deve indicar ausência de publicações.
   - Para o canal Nightly: se `nightlies` estiver vazio ou não houver versão com artefato real, exibir `"Nenhuma versão de desenvolvimento lançada"` no `#nightly-ver-text`. O botão `#nightly-download-btn` deve receber a classe `.disabled`, e o histórico deve indicar ausência de compilações.
2. **Rotação e Catálogo (`scripts/rotate-downloads.py`)**:
   - `prune_manifest_data` e `generate_default_manifests`: quando uma lista de versões estiver vazia ou contiver apenas entradas sem artefatos ou hash, os campos `stable_latest` e `nightly_latest` devem ser strings vazias `""` (e não `"0.1.0"`).
   - O `generate_catalog_json` propaga strings vazias para canais não publicados.
3. **Testes Automatizados (`tests/test-downloads-empty-channel.sh`)**:
   - Validar que manifests sem artefatos reais no canal produzem mensagens de aviso e desabilitação em vez de `v0.1.0`.

## 3. Critérios de Aceitação
- Ausência de menções a `v0.1.0` para apps que só possuem nightlies.
- Vitrine web exibe mensagens amigáveis e desabilita cliques em downloads inexistentes.
- Todos os testes de download e catálogo passam com 100% de sucesso.
