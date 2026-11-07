# Especificação Técnica: Esteira de Dispatch Serializada e Orquestração de Deploy

- **Ticket:** [#57](https://gambi.2lp.in/lumen/banca/issues/57)
- **Status:** Proposto / Em Desenvolvimento
- **Norma:** GOST v2.0.0 / Perfil Lilya v2.0.0

---

## 1. Contexto e Motivação
A publicação de novos artefatos pelas aplicações produtoras dispara a esteira da Banca via `repository_dispatch` com `event_type: "release-published"`.
Para evitar condições de corrida em publicações concorrentes de diferentes projetos, a esteira opera sob fila serializada:
```yaml
concurrency:
  group: "update-catalog"
  cancel-in-progress: false
```

---

## 2. Orquestração do Pipeline (`scripts/banca_pipeline.py`)
O fluxo é orquestrado em 4 etapas atômicas:
```text
[1. Auditoria Nova Versão] ──(ok)──> [2. Auditoria Histórico Ativo] ──(ok)──> [3. Rotação/Purga] ──(ok)──> [4. Atualização & Deploy]
            │                                     │                                    │
         (falha)                               (falha)                              (falha)
            └─────────────────────────────────────┴────────────────────────────────────┴──> [Abre Ticket na Forja]
```

1. **Auditoria da Nova Versão:**
   - Emite HEAD nos arquivos versionados e aliases no R2.
   - Confere o checksum SHA-256.
2. **Auditoria dos Links Históricos Ativos:**
   - Tolerância zero a links quebrados nas versões que permanecerão ativas.
3. **Rotação e Purga no Bucket:**
   - Purga arquivos das versões que ultrapassarem as quotas (5 stable / 10 dev).
4. **Atualização do Catálogo e Deploy:**
   - Insere a nova versão em `site/downloads/catalog.json` e remove versões purgadas.
   - Sincroniza os manifestos de compatibilidade `site/downloads/{app}/index.json`.
   - Gera a vitrine (`build.sh` e `gerar-pratilera.py`).
   - Se disparado via CI, comita a alteração e despacha o deploy no Cloudflare Pages/Workers.

---

## 3. Workflow de Integração Contínua (`.forgejo/workflows/dispatch.yml`)
Configuração dedicada para o evento `repository_dispatch`:
- Gatilho: `repository_dispatch: types: [release-published]`
- Fila serial: `concurrency: { group: "update-catalog", cancel-in-progress: false }`
- Execução hermética do orquestrador `scripts/banca_pipeline.py`.
