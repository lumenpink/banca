# Especificação Técnica: Sincronização do Catálogo de Downloads com Manifestos Recentes

- **Ticket:** [#53](https://gambi.2lp.in/lumen/banca/issues/53)
- **Status:** Concluído
- **Autor:** Lumen Pink (Baquara)

---

## 1. Objetivo

Regenerar e sincronizar o arquivo de catálogo consolidado `site/downloads/catalog.json` para refletir as releases mais recentes registradas nos manifestos `site/downloads/*/index.json`, garantindo a atualização do Joaju (`0.2.0-dev.137+20261105.e672a64`) e de outros aplicativos (Lacraia, Lauda, Mandu, Mocambo e Navalha) para consumo pela Jornaleira e portal da Banca.

---

## 2. Critérios de Aceite

1. O arquivo `site/downloads/catalog.json` deve conter a versão mais recente do Joaju em paridade com `site/downloads/joaju/index.json`.
2. A suíte de testes `tests/test-downloads-catalog.sh` deve auditar a integridade estrutural, a paridade do Joaju e a sensibilidade a mutações.
3. Ciclo GOST DD-TDD concluído com aprovação nos testes automatizados.
