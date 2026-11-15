# Especificação Técnica — Ticket #61

## chore(pratilera): sincronizar versao 107 do mandu

### 1. Objetivo
Atualizar o catálogo da Pratilera (`index-v1.json` e `index-v1.jar`) e os metadados Fastlane com a nova versão oficial do Mandu (`0.1.0-dev.107+20261115.a9a699d`, `versionCode: 26111505`), com integridade criptográfica assinada.

### 2. Mudanças
- Atualização de `site/index-v1.json` e `site/pratilera/index-v1.json` com novo hash SHA-256 e versionCode.
- Regeneração e assinatura JAR com a chave `in_twolp`.
- Adição dos descritores Fastlane em `site/pratilera/in.twolp.mandu/`.

### 3. Validação
- `tests/test-pratilera.sh` 100% aprovado (31 testes).
- `tests/test-pratilera-mandu.sh` 100% aprovado (10 testes e mutações).
- Hash validado contra `https://bucket.2lp.in/mandu.apk`.
