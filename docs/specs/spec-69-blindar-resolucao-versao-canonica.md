# Especificação Técnica #69 — Blindagem da Resolução de Versão Canônica na Pratilera

## 1. Contexto e Motivação
A Pratilera F-Droid (`site/pratilera/index-v1.json`) distribuída em `banca.2lp.in/pratilera` sofreu sucessivas regressões nas quais o aplicativo Lauda (`in.twolp.lauda`) regredia para a versão congelada `0.5.1` em vez de reportar a versão canônica ativa gerada pelo CCCP (`0.6.0-dev.*`).

O diagnóstico comprovou que:
1. No runner de CI (`gambi.2lp.in/lumen/gost-ci-banca:latest`), apenas o repositório `banca` é clonado; diretórios irmãos como `../lauda` não existem no contêiner.
2. A consulta remota à API do Forgejo em `get_project_version` estava limitada exclusivamente a `mandu` e `mandu-mobile`.
3. Ao recorrer ao manifesto estático de downloads (`site/downloads/lauda/index.json`), a instrução `latest_ver = data.get("stable_latest") or data.get("nightly_latest")` selecionava cegamente `"0.5.1"` porque `stable_latest` não estava vazio, ignorando o canal `nightly_latest` mais avançado (`0.6.0-dev...`) e a versão real extraída do binário APK via `aapt dump badging`.

---

## 2. Árvore de Decisão e Alternativas Descartadas (Para a Natasha)
- **Alternativa Descartada 1: Clonar todos os repositórios irmãos durante a CI da Banca:**
  - *Motivo do descarte:* Aumenta drasticamente o tempo do pipeline, consome banda excessiva e introduz dependência circular de autenticação entre pipelines.
- **Alternativa Descartada 2: Apenas atualizar manualmente o campo `stable_latest` no manifesto de downloads:**
  - *Motivo do descarte:* Solução frágil e paliativa. Quando o Lauda passar para `0.7.0`, o erro voltará a acontecer se a esteira de downloads não for disparada em sincronia.
- **Escolha Adotada (Blindagem Arquitetural Tríplice):**
  1. **Universalização da Resolução Remota:** `get_project_version` consulta `https://gambi.2lp.in/api/v1/repos/lumen/{project_slug}/raw/VERSION` para qualquer projeto irmão suportado (`lauda`, `lacraia`, `mocambo`, `mandu-mobile`), com timeout de 5 segundos e agente HTTP padronizado.
  2. **Comparação SemVer Dinâmica no Fallback Hermético:** Se o projeto estiver sem conexão ou em ambiente offline, `get_project_version` analisa `stable_latest`, `nightly_latest` e o `fallback` (versão do APK extraída via `aapt`), selecionando a versão com maior precedência SemVer. Nunca uma versão semanticamente inferior (`0.5.1`) sobrescreverá uma versão superior (`0.6.0-dev.*`).
  3. **Atualização Consolidada dos Manifestos:** Alinhamento de `site/downloads/lauda/index.json` e `site/downloads/catalog.json` com o canal nightly atualizado.

---

## 3. Ordem Estrita de Precedência na Resolução de Versão
1. `REPO_ROOT.parent / project_name / "VERSION"` (disco local no ambiente integrado de desenvolvimento).
2. API remota do Forgejo: `https://gambi.2lp.in/api/v1/repos/lumen/{project_slug}/raw/VERSION`.
3. Resolução hermética resiliente: maior versão SemVer entre `stable_latest`, `nightly_latest` e `fallback_ver` (versão extraída do APK via `aapt`).
4. `fallback_ver` / `prev_entry.get("versionName")` / metadado padrão.

---

## 4. Critérios de Aceitação
1. Em ambiente simulado sem o diretório `../lauda`, `get_project_version("lauda")` deve retornar a versão canônica remota ou SemVer maior (ex.: `0.6.0-dev.*`), nunca regredindo para `0.5.1`.
2. A suíte `./tests/test-pratilera.sh` deve passar com 100% de sucesso (33/33 testes) incluindo a validação de metadados.
3. O catálogo `site/pratilera/index-v1.json` gerado deve conter `in.twolp.lauda` com a versão `0.6.0-dev.*`.

---

## 5. Laudo de Fechamento e Homologação
- **Status:** Concluído e Aprovado no Quality Gate (Fase 8).
- **Implementação:** Resolução remota universal via Forgejo e ordenação SemVer no fallback hermético implementadas em `scripts/gerar-pratilera.py`.
- **Validação:** 33/33 testes em `tests/test-pratilera.sh` e 24/24 checagens no `cccp check --strict` aprovadas com 100% de conformidade.
- **Data de Homologação:** 2026-11-24


