# Especificação Técnica: Catálogo Consolidado de Downloads (catalog.json)

- **Ticket:** [#41](https://gambi.2lp.in/lumen/banca/issues/41)
- **Status:** Aprovado
- **Autor:** Lumen Pink (Baquara)

---

## 1. Objetivo

Fornecer um endpoint JSON consolidado em `site/downloads/catalog.json` (servido publicamente em `https://banca.2lp.in/downloads/catalog.json`) contendo o catálogo completo de aplicações do ecossistema, seus canais (`stable_latest`, `nightly_latest`), metadados e URLs de manifestos.

Este catálogo serve como fonte primária para a **Jornaleira** (e qualquer outro consumidor automatizado) descobrir dinamicamente todos os aplicativos disponíveis na Banca em uma única requisição HTTP, sem necessidade de hardcoding de lista de apps nos clientes.

---

## 2. Contrato de Dados (`site/downloads/catalog.json`)

```json
{
  "updated_at": "2026-10-23T22:15:00Z",
  "banca_url": "https://banca.2lp.in",
  "total_apps": 15,
  "apps": [
    {
      "app": "cccp",
      "name": "CCCP CLI",
      "category": "governance",
      "description": "Guardião de Conventional Commits e governança GOST",
      "repo": "https://gambi.2lp.in/lumen/cccp",
      "stable_latest": "0.1.0",
      "nightly_latest": "3.2.0-dev.227+20261020.50fb04f+20261023.fc29a5b",
      "manifest_url": "https://banca.2lp.in/downloads/cccp/index.json"
    }
  ]
}
```

---

## 3. Critérios de Aceite

1. O script `scripts/rotate-downloads.py` deve suportar o argumento `--generate-catalog <downloads_dir>` (ou atualizar automaticamente o catálogo durante `--generate-defaults`).
2. O arquivo `site/downloads/catalog.json` deve ser gerado pelo pipeline de compilação (`./build.sh`).
3. O catálogo deve conter todas as aplicações registradas nos manifestos de `site/downloads/*/index.json`.
4. Os testes automatizados em `tests/test-downloads-catalog.sh` devem validar formato JSON estrito, campos obrigatórios e contagem mínima de aplicações.
