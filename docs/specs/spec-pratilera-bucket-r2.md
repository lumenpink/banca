# Especificação Técnica: Distribuição de APKs via bucket.2lp.in & Canonização de Nomes

## 1. Contexto e Motivação
O deploy dos assets estáticos do Cloudflare Workers (`banca.2lp.in`) possui limite estrito de 25 MiB por arquivo. Com a compilação multi-arch completa (`arm64-v8a` + `x86_64`) nos aplicativos móveis (`lauda`, `mocambo`, `lacraia`, `simbiotyka`), os APKs ultrapassam esse limite.
Além disso, para economizar custos de computação de worker e oferecer downloads com suporte nativo a HTTP Range (RFC 7233) e zero egress, a distribuição dos binários é desacoplada para o bucket Cloudflare R2 com domínio dedicado `https://bucket.2lp.in`.

## 2. Requisitos de Nomenclatura Canônica
Os nomes dos arquivos APK no bucket e no manifesto F-Droid são estritamente os nomes dos apps sem sufixos (`-app` ou `-latest`):
- `in.twolp.lacraia.app` -> `lacraia.apk`
- `in.twolp.lacraia.simbiotyka` -> `simbiotyka.apk`
- `in.twolp.lauda` -> `lauda.apk`
- `in.twolp.mocambo` -> `mocambo.apk`

## 3. Estrutura do Manifesto F-Droid (`index-v1.json`)
- O campo `repo.address` passa a apontar diretamente para `https://bucket.2lp.in`.
- O cliente Droid-ify / F-Droid resolve a URL de download como `{repo.address}/{package.apkName}`, baixando diretamente de `https://bucket.2lp.in/<app>.apk` sem intermediários ou saltos de redirecionamento.
- O repositório continua sendo adicionado pelo usuário na URL de metadados `https://banca.2lp.in/pratilera`.

## 4. Redirecionamentos Dinâmicos (`site/_redirects`)
O script `gerar-pratilera.py` gera e atualiza `site/_redirects` dinamicamente a cada execução, contendo:
- Regras legadas para manter compatibilidade com links antigos:
  - `/pratilera/lacraia-app.apk https://bucket.2lp.in/lacraia.apk 302!`
  - `/pratilera/lauda-latest.apk https://bucket.2lp.in/lauda.apk 302!`
- Regras canônicas para acessos web diretos:
  - `/pratilera/lacraia.apk https://bucket.2lp.in/lacraia.apk 302!`
  - `/pratilera/simbiotyka.apk https://bucket.2lp.in/simbiotyka.apk 302!`
  - `/pratilera/lauda.apk https://bucket.2lp.in/lauda.apk 302!`
  - `/pratilera/mocambo.apk https://bucket.2lp.in/mocambo.apk 302!`
  - `/pratilera/:apk https://bucket.2lp.in/:apk 302!`
