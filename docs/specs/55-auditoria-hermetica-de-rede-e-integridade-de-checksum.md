# Especificação Técnica: Auditoria Hermética de Rede e Integridade de Checksum

- **Ticket:** [#55](https://gambi.2lp.in/lumen/banca/issues/55)
- **Status:** Proposto / Em Desenvolvimento
- **Norma:** GOST v2.0.0 / Perfil Lilya v2.0.0

---

## 1. Contexto e Motivação
Na arquitetura Produtor–Curador Desacoplado da Banca, o repositório central atua como curador estrito de integridade. Antes de qualquer alteração no catálogo oficial (`catalog.json`) ou deploy no Cloudflare Pages, a esteira executa uma verificação hermética em duas etapas com **Tolerância Zero a Links Quebrados**:
1. **Etapa 1: Auditoria da Nova Versão:**
   - Para cada ativo informado no payload de notificação (`assets`), emite requisição `HEAD` no storage/bucket para o arquivo físico versionado (`200 OK`).
   - Emite requisição `HEAD` para o arquivo de alias canônico correspondente (`200 OK`).
   - Verifica se o hash SHA-256 declarado bate com o hash publicado no storage (`.sha256`) ou calcula/compara conforme disponibilidade.
2. **Etapa 2: Auditoria dos Links Históricos Ativos:**
   - Carrega o catálogo `catalog.json` atual para a aplicação e canal informados.
   - Determina as versões que continuarão ativas após a rotação (até 4 estáveis anteriores para `stable` ou até 9 de desenvolvimento anteriores para `dev`).
   - Executa verificação `HEAD` em todas as URLs declaradas para essas versões ativas.
   - Se qualquer link retornar código diferente de `200` (ex.: `404 Not Found`), a auditoria falha imediatamente com código de erro e relatório detalhado.

---

## 2. Contrato de Entrada (Payload `release-published`)
A rotina recebe o evento da esteira ou CLI:
```json
{
  "app": "tachinha",
  "channel": "stable",
  "version": "0.4.1",
  "commit": "a1b2c3d4",
  "repo_slug": "lumen/tachinha",
  "run_id": "1842",
  "assets": [
    {
      "filename": "tachinha-0.4.1-linux-x86_64.tar.gz",
      "alias": "tachinha-latest-linux-x86_64.tar.gz",
      "type": "archive",
      "format": "tar.gz",
      "target": "linux-x86_64",
      "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    }
  ]
}
```

---

## 3. Módulo Implementador (`scripts/banca_audit.py`)
O módulo de auditoria fornece:
- `audit_new_release(payload, base_url, timeout=10, http_client=None)`:
  - Valida parâmetros obrigatórios do payload.
  - Testa existência do arquivo versionado e do alias via `HEAD`.
  - Testa existência e conformidade do arquivo `.sha256` correspondente no bucket.
- `audit_active_history(catalog_path, app, channel, base_url, limit, timeout=10, http_client=None)`:
  - Extrai as versões ativas remanescentes da aplicação e canal.
  - Testa existência de todos os ativos declarados via `HEAD`.
- Retorno padronizado de diagnóstico:
  - Sucesso: `(True, [])`
  - Falha: `(False, [lista_de_erros])`
  - Erros detalham URL, status HTTP retornado ou divergência de checksum.
