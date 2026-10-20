# GOST Language Specification: Python
**Identificador da Stack:** `python`  
**Padrão Base:** GOST `1.0.0`

---

## 1. Visão Geral e Filosofia
Esta especificação define os requisitos de engenharia, ferramentas e padrões para desenvolvimento em **Python** no ecossistema GOST.

O ecossistema adota **Python 3.11+** como runtime canônico, impondo tipagem estática opcional via type hints (`PEP 484`), formatação e linting estritos via `ruff` ou `black`/`flake8`, e testes unitários via `pytest`.

---

## 2. Ferramental Mandatório de Testes & Qualidade

| Requisito GOST | Ferramenta Padrão | Comando de Validação no CI |
|---|---|---|
| **Test Runner (Unit)** | **pytest** | `pytest tests/` |
| **Cobertura (≥ 90%)** | **pytest-cov** | `pytest --cov=. --cov-fail-under=90` |
| **Linter & Formatação** | **ruff** | `ruff check . && ruff format --check .` |
| **Type Checking** | **mypy** | `mypy .` |

---

## 3. Gestão de Dependências
1. **Ambiente e Dependências:** Preferência por ferramentas nativas ou `uv`/`poetry`/`pip` com `requirements.txt` congelado.
2. **Scripts Autônomos:** Scripts utilitários de build e automação utilizam exclusivamente a biblioteca padrão do Python (`sys`, `os`, `json`, `pathlib`, `urllib`), evitando dependências pesadas de terceiros sempre que viável.

---

## 4. Arquitetura e Boas Práticas
1. **PEP 8 Estrito:** Código idiomático, nomenclatura clara em snake_case para funções e variáveis, PascalCase para classes.
2. **Tratamento Seguro de I/O:** Uso obrigatório de context managers (`with open(...) as f:`) e `pathlib.Path` para manipulação de caminhos POSIX.
3. **Idempotência:** Scripts de automação e rotação devem ser idempotentes e tolerantes a falhas transitórias.
