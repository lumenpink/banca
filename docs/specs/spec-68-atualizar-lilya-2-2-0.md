# Spec #68: Atualizar Perfil Lilya para Versão 2.2.0

## 1. Contexto e Motivação
Com o lançamento do GOST Lilya 2.2.0 e Kollontai 2.2.0, o compilador Rust de referência foi atualizado para rustc >= 1.100.0 e as rotas canônicas de regras foram unificadas. O repositório banca precisa atualizar suas definições de governança (.gost/GOST.md e .gost/rules.toml) para herdar as regras e padrões da versão 2.2.0.

## 2. Escopo
- Atualizar referências de `2.1.0` para `2.2.0` em `.gost/GOST.md` e `.gost/rules.toml`.
- Validar conformidade estrita com `cccp check --strict`.
- Validar suíte de testes de integridade da banca.

## 3. Plano de Implementação (GOST DD-TDD)
1. Fase 3: Especificação técnica (este documento).
2. Fase 4: Teste Red (N/A - governança).
3. Fase 5: Atualização de `.gost/GOST.md` e `.gost/rules.toml`.
4. Fase 6-7: Refatoração e Mutação (N/A).
5. Fase 8: Quality Gate (testes da banca e `cccp check --strict`).
6. Fase 9: Fechamento do ticket e sincronização.

## 4. Árvore de Decisão e Guardiã da Natasha
- **Por que atualizar imediatamente?** Manter o repositório sincronizado com a Metanorma 2.2.0 previne desvios de auditoria e garante que o catálogo da banca referencie perfis canônicos ativos.
- **Alternativa descartada:** Manter 2.1.0 geraria alertas em pipelines automatizadas e descontinuidade com os artefatos gerados pelo ecossistema.

## 5. Resultados e Validação
- cccp check: 24/24 PASS (100% de conformidade com Lilya 2.2.0).
- testes: Toda a suíte de testes em `tests/*.sh` (32 verificações de vitrine, testes de integridade, downloads e pipeline) passou com 100% de sucesso.
