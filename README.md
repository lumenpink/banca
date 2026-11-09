# ✂ BANCA

> **A Banca de Zines e Projetos: Vitrine Estática e Anti-Design do Ecossistema Lumen**

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![GOST: v1.5.0](https://img.shields.io/badge/GOST-v1.5.0-red.svg)](.gost/GOST.md)
[![SemVer 2.0.0](https://img.shields.io/badge/SemVer-2.0.0-green.svg)](VERSION)

---

## 🎪 Sobre a Banca

A **Banca** é o catálogo e vitrine pública oficial dos projetos, ferramentas de terminal, utilitários e publicações independentes desenvolvidos e mantidos por **Lumen Pink (Baquara)**.

* **URL Pública:** [banca.2lp.in](https://banca.2lp.in)
* **Arquitetura:** Gerador estático em Shell POSIX puro, sem dependências externas de runtime.
* **Motor Gráfico:** Integração com o [Navalha](https://codeberg.org/lumenpink/navalha) para cartazes anti-design.

---

## 📲 A Pratilera (Loja Android F-Droid & Droid-ify)

A Banca hospeda a **Pratilera**, o repositório de aplicativos Android do ecossistema 2lp (`in.twolp.*`):
* **URL Oficial:** `https://banca.2lp.in/pratilera`
* **Deep Link:** `fdroidrepos://banca.2lp.in/pratilera`
* **Aliases:** `/patilera`, `/prateleira` e `/repo`
* **Assinatura:** Índices F-Droid (`index-v1.jar`) assinados com a chave oficial `in_twolp`.

---

## ⚡ Comandos Rápidos

```bash
# Compilar a vitrine estática
./build.sh

# Gerar pôster anti-design via Navalha
./scripts/gerar-banner.sh <projeto> [preset]

# Testes de validação
./tests/test-pratilera.sh
```

---

## 📜 Licenciamento

* Código e scripts: [GNU GPLv3](LICENSE)
* Marcas e insígnias: [CC-BY-ND 4.0](LICENSE-LOGO)
* Pôsteres e mídias: [CC-BY-SA 4.0](LICENSE-MEDIA)
