# ✂ BANCA

> **A Banca de Zines e Projetos: Vitrine Estática e Anti-Design do Ecossistema Lumen**

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![GOST: v1.1.0](https://img.shields.io/badge/GOST-v1.1.0-red.svg)](.gost/GOST.md)
[![SemVer 2.0.0](https://img.shields.io/badge/SemVer-2.0.0-green.svg)](VERSION)

---

## 🎪 Sobre a Banca

A **Banca** é o catálogo e vitrine pública oficial dos projetos, ferramentas de terminal, utilitários e publicações independentes desenvolvidos e mantidos por **Lumen Pink (Baquara)**.

Inspirada na estética de **fanzine punk brasileiro, zines de rua, lambe-lambe urbano, colagem xerox e anti-design de alta fricção**, a Banca reúne todos os projetos autorais do ecossistema em uma interface 100% estática, autônoma e resiliente.

* **URL Pública:** [banca.2lp.in](https://banca.2lp.in)
* **Arquitetura:** Gerador estático em Shell POSIX puro (estilo *bashblog*), sem dependências externas ou runtimes pesados.
* **Motor Gráfico:** Integração nativa com o [Navalha](https://codeberg.org/lumenpink/navalha) para renderização determinística de pôsteres e cartazes com presets de anti-design.

---

## 📁 Estrutura do Repositório

```text
.
├── .cccprc                    # Configuração local do CCCP
├── .gost/                     # Especificações e regras GOST v1.1.0
├── GOSTVER                    # Declaração canônica de versão GOST
├── VERSION                    # Versão semântica (SemVer 2.0.0)
├── CHANGELOG.md               # Histórico de alterações (Keep a Changelog)
├── LICENSE                    # Licença principal GNU GPLv3
├── README.md                  # Apresentação executiva e guia da Banca
├── SPEC.md                    # Especificação técnica do projeto
├── build.sh                   # Script gerador da vitrine estática em shell
├── data/
│   └── projects.json          # Base de dados canônica dos projetos autorais
├── scripts/
│   └── gerar-banner.sh        # Utilitário de geração de pôsteres via Navalha
├── site/
│   ├── _headers               # Cabeçalhos HTTP de segurança
│   ├── index.html             # Vitrine compilada (Single-File responsivo)
│   └── assets/
│       └── banners/           # Cartazes e banners gerados
└── wrangler.jsonc             # Deploy Cloudflare Workers / Pages (*.2lp.in)
```

---

## ⚡ Comandos Rápidos

### 1. Compilar o Site
Gera o arquivo `site/index.html` a partir de `data/projects.json`:
```bash
./build.sh
```

### 2. Gerar Novo Pôster via Navalha
Para gerar um cartaz anti-design para qualquer projeto da lista:
```bash
./scripts/gerar-banner.sh <nome-do-projeto> [preset] [texto-superior] [texto-inferior]

# Exemplo:
./scripts/gerar-banner.sh kvant punk-riot "KVANT" "MICRO EDITOR // CCCP COMRADES"
```
Presets disponíveis no Navalha: `punk-riot`, `fanzine-digital`, `risografia`, `tabloide-popular`, `xerox-podre`, `navalha-sata`.

### 3. Visualizar Localmente
```bash
cccp serve site
# ou abra direto no navegador:
xdg-open site/index.html
```

---

## 📜 Política de Licenciamento

Em conformidade com a norma [GOST v1.1.0](.gost/GOST.md):
* **Código-Fonte e Gerador Shell (`build.sh`, `scripts/`):** Licenciados sob a [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
* **Pôsteres e Arte Visual (`site/assets/banners/`):** Licenciados sob a [Creative Commons Atribuição-CompartilhaIgual 4.0 Internacional (CC-BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/).
