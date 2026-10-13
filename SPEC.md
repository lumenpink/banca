# Especificação Técnica: BANCA

## 1. Visão Geral
A **Banca** é o gerador e portal estático de apresentação de todos os projetos autorais do ecossistema mantido por Lumen Pink.

## 2. Requisitos Arquiteturais
- **Linguagem / Stack:** Shell POSIX puro (`sh` / `dash` / `bash`) e `jq`.
- **Motor Gráfico:** `navalha poster` para renderização visual.
- **Formato de Saída:** Single-file HTML estático com CSS e JavaScript progressivo embutidos, sem dependências de CDN externa.
- **Fonte de Dados:** `data/projects.json` estruturado com suporte a metadados estendidos e agrupamento.
- **Norma Técnica:** GOST v1.1.0 (perfil `profiles/lumen.md`, tipologia Shell/Web).
- **Publicação:** Cloudflare Workers Static Assets (`banca.2lp.in`) e Codeberg Pages.

## 3. A Pratilera: Loja e Repositório F-Droid / Droid-ify Soberano

A **Pratilera** é o repositório centralizado de distribuição de aplicativos Android do ecossistema 2lp (`in.twolp.*`), compatível nativamente com Droid-ify, Neo Store, F-Droid e Obtainium.

### 3.1 Topologia de Rotas e Aliases
- **Rota Canônica:** `https://banca.2lp.in/pratilera/`
- **Aliases com Redirecionamento 301:**
  - `https://banca.2lp.in/patilera` $\rightarrow$ `/pratilera/` (tolerância a digitação abreviada)
  - `https://banca.2lp.in/prateleira` $\rightarrow$ `/pratilera/` (tolerância a norma culta)
  - `https://banca.2lp.in/repo` $\rightarrow$ `/pratilera/` (compatibilidade com convenção clássica F-Droid)
- **Deep Link Droid-ify:** `fdroidrepos://banca.2lp.in/pratilera`

### 3.2 Estrutura de Arquivos (`site/pratilera/`)
```
site/pratilera/
├── index-v1.jar          # Índice assinado criptograficamente com a chave in_twolp via jarsigner
├── index-v1.json         # Manifesto canônico de pacotes, versões, tamanhos e hashes SHA256
├── entry.json            # Ponto de entrada do protocolo Index-v2 moderno
├── index-v2.json         # Payload estruturado Index-v2
├── icons/                # Ícones dos aplicativos em alta resolução
└── *.apk                 # Binários Android de produção assinados (lacraia-app.apk, etc.)
```

### 3.3 Chave e Assinatura Criptográfica
- Todos os pacotes são identificados sob o domínio `in.twolp.*`.
- O arquivo `index-v1.jar` é assinado utilizando a chave soberana `in_twolp` oriunda de `~/.android/in_twolp_release.keystore`.
- A impressão digital SHA256 da chave garante integridade e confiança unificada em um único repositório no smartphone do usuário.
