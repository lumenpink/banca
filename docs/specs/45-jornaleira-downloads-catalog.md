# Especificação Técnica: Registro e Publicação da Jornaleira na Banca

- **Ticket:** [#45](https://gambi.2lp.in/lumen/banca/issues/45)
- **Status:** Em Andamento
- **Autor:** Lumen Pink (Baquara)

---

## 1. Objetivo

Registrar e publicar formalmente a **Jornaleira** (gestora central de aplicativos e auto-update) no ecossistema da Banca (`https://banca.2lp.in`):
1. Inclusão nos metadados de projetos de `data/projects.json` com banner GOST oficial.
2. Inclusão na lista canônica `DEFAULT_APPS` em `scripts/rotate-downloads.py`.
3. Geração de manifesto canônico inicial em `site/downloads/jornaleira/index.json`.
4. Geração de scripts de instalação unificados via shell em `site/install/jornaleira` e `site/install/jornaleira-nightly` via `scripts/gerar-instaladores.sh`.
5. Integração na vitrine web de downloads em `site/downloads/index.html`.
6. Atualização do catálogo consolidado `site/downloads/catalog.json` elevando a contagem de 15 para 16 aplicações.
7. Atualização das suítes de testes automatizados (`tests/test-downloads.sh` e `tests/test-downloads-catalog.sh`) para validar 16 aplicações.

---

## 2. Critérios de Aceite

1. `data/projects.json` deve conter o objeto correspondente à `jornaleira` com slug `lumen/jornaleira`, categoria `system`, licença `GPL-3.0` e banner `assets/banners/jornaleira-banner.png`.
2. O arquivo `site/assets/banners/jornaleira-banner.png` deve existir com resolução 1200x630.
3. `site/downloads/jornaleira/index.json` deve ser um manifesto válido contendo canais `stables` e `nightlies` estruturados com URLs canônicas.
4. `scripts/rotate-downloads.py` deve incluir `"jornaleira"` em `DEFAULT_APPS`.
5. `scripts/gerar-instaladores.sh` deve incluir `"jornaleira"` no array `APPS` e gerar os scripts executáveis em `site/install/`.
6. `site/downloads/index.html` deve oferecer `"jornaleira"` no menu `<select id="app-select">` e possuir a respectiva chave em `APP_REGISTRY`.
7. `site/downloads/catalog.json` deve listar 16 aplicações e conter a entrada de `jornaleira`.
8. Os testes automatizados em `tests/test-downloads.sh` e `tests/test-downloads-catalog.sh` devem passar com 100% de sucesso validando os 16 aplicativos.
