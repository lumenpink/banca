# Especificação Técnica — Ticket #62: Blindagem da Resolução de Versão Canônica na Pratilera

## 1. Contexto e Problema
A geração dos catálogos F-Droid da Pratilera (`site/pratilera/index-v1.json` e `site/pratilera/index-v1.jar`) é executada pelo script `scripts/gerar-pratilera.py` tanto em ambiente local quanto no runner de CI da Banca (`gambi.2lp.in/lumen/gost-ci-banca:latest`).

No ambiente hermético do CI, apenas o repositório `banca` é clonado; nenhum diretório de projeto irmão (como `../mocambo`, `../lauda`, `../mandu`) existe no sistema de arquivos.

A função `get_project_version(project_name)` buscava exclusivamente o arquivo `VERSION` em `REPO_ROOT.parent / project_name / "VERSION"`. Ao não encontrá-lo, recorria ao `fallback`, que por sua vez adotava o `versionName` do APK baixado de `https://bucket.2lp.in/<app>.apk` ou o valor padrão.

Quando um projeto atualizava seu manifesto em `site/downloads/<app>/index.json`, mas o APK do bucket ainda não havia sido substituído ou dependia de cache, a Pratilera publicava metadados defasados ou conflitantes (como `versionName: "0.1.0"` em vez da versão canônica SemVer do CCCP).

---

## 2. Árvore de Decisões e Proteção à Natasha
Para que a Natasha compreenda os motivos de cada escolha arquitetural:

### Decisão 1: Consultar `site/downloads/{project_slug}/index.json` como fonte de verdade residente
- **Alternativa Descartada A:** Fazer clone dinâmico de todos os repositórios irmãos no CI da Banca.
  - *Motivo do Descarte:* Introduz dependência de rede, tokens adicionais de acesso e eleva desnecessariamente o tempo de execução do CI.
- **Alternativa Descartada B:** Depender apenas do manifesto interno do APK (`aapt dump badging`).
  - *Motivo do Descarte:* Se o APK remoto for de canal antigo ou estiver temporariamente indisponível no R2, o catálogo da loja quebra ou exibe versões antigas.
- **Escolha Adotada:** O ecossistema soberano já mantém o catálogo consolidado em `site/downloads/{app}/index.json`, atualizado atomicamente pelos respectivos CIs de cada projeto. Se o diretório irmão não existir localmente no disco, `get_project_version()` deve inspecionar prioritariamente `site/downloads/{app}/index.json` (campos `stable_latest` ou `nightly_latest`), extraindo a versão canônica oficial já homologada.

### Decisão 2: Ordem estrita de precedência na resolução de versão
1. `REPO_ROOT.parent / project_name / "VERSION"` (se existir localmente no ambiente de desenvolvimento integrado).
2. `REPO_ROOT / "site" / "downloads" / project_name / "index.json"` (campo `stable_latest` se não vazio, senão `nightly_latest`).
3. `apk_meta.get("version_name")` (versão extraída diretamente do binário APK via `aapt`).
4. `prev_entry.get("versionName")` (versão preservada da execução anterior do `index-v1.json`).
5. `meta["version_name"]` (fallback estático declarado em `APPS_METADATA`).

---

## 3. Contrato de Testes (Fase 4 - Red)
O script de testes `tests/test-pratilera.sh` deve incluir uma verificação contratual que comprove:
1. `get_project_version` resolve com sucesso a versão do Mocambo e do Mandu a partir de `site/downloads/{app}/index.json` mesmo quando o diretório irmão não existe.
2. A versão resultante em `site/pratilera/index-v1.json` para `in.twolp.mocambo` corresponde à versão registrada no manifesto de downloads (ex.: prefixada com `0.3.0-dev.`).
