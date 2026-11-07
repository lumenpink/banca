# Especificação Técnica: Rotina de Purga no Bucket e Emissor de Issues na Forja

- **Ticket:** [#56](https://gambi.2lp.in/lumen/banca/issues/56)
- **Status:** Proposto / Em Desenvolvimento
- **Norma:** GOST v2.0.0 / Perfil Lilya v2.0.0

---

## 1. Contexto e Motivação
Na topologia de bucket único particionado (`banca-artifacts/{app}/{channel}/`), a Banca precisa manter as cotas de retenção operacional estipuladas pela especificação:
- **Canal Recomendado (`stable`):** 5 versões mais recentes.
- **Canal Experimental (`dev`):** 10 versões mais recentes.

Além da rotação de arquivos físicos no storage (Cloudflare R2 / S3), qualquer inconsistência identificada durante as etapas de auditoria ou rotação aciona o **Emissor de Issues**, criando um ticket automático na forja (`POST /api/v1/repos/{repo_slug}/issues`) no repositório de origem da aplicação com os detalhes exatos da falha.

---

## 2. Regras de Purga no Bucket
1. **Identificação e Isolamento de Aliases:**
   - Aliases canônicos (`*-latest.*` e `*-dev-latest.*`) nunca são deletados durante a rotação; eles são cópias sobrescritas.
2. **Agrupamento por Versão:**
   - Os arquivos sob o prefixo `{app}/{channel}/` são agrupados por versão.
   - Versões são ordenadas cronologicamente ou por SemVer.
3. **Identificação de Excedentes:**
   - Versões que ultrapassarem o limite (5 para `stable`, 10 para `dev`) são marcadas para purga.
   - Para cada versão a ser purgada, todos os seus arquivos físicos (binários, tarballs, instaladores e arquivos `.sha256`) são removidos do bucket.

---

## 3. Emissor de Issues na Forja
Se houver falha de validação ou de integridade:
- Endpoint: `POST /api/v1/repos/{repo_slug}/issues`
- Autenticação: Header `Authorization: token <FORGE_TOKEN>`
- Schema do Issue:
  - `title`: `[Banca] Artefato da versão {version} ({channel}) ausente ou corrompido`
  - `body`: Relatório estruturado contendo:
    - Aplicação, canal, versão e commit.
    - Run ID da esteira produtora.
    - Lista detalhada de erros diagnosticados na auditoria.
