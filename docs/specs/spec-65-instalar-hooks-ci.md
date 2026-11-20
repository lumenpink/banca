# Especificação — Ticket #65: Instalar Hooks do Maestro antes da Auditoria de Conformidade em CI

## 1. Contexto e Motivação
Após a migração para o GOST v3 (ticket #63), a esteira de validação em CI passou a executar compulsoriamente `cccp check --strict`.
Em ambientes de CI baseados em contêineres (`gambi.2lp.in/lumen/gost-ci-banca:latest`), o checkout automatizado efetuado por `actions/checkout@v4` não provê hooks do Git em `.git/hooks/`, já que hooks locais são excluídos do versionamento Git por projeto.
Como consequência, a regra `KOLLONTAI-018` (`GIT-HOOKS-MAESTRO-PARITY`) acusa a ausência do hook `commit-msg`, falhando a esteira e bloqueando o deploy da vitrine no Cloudflare Workers.

## 2. Escopo Técnico
1. Adicionar o comando `cccp hook -i` no arquivo `.forgejo/workflows/ci.yml`, imediatamente antes da execução de `cccp check --strict`.
2. Adicionar teste automatizado de regressão que valida se o workflow contém a instalação de hooks pré-auditoria.
3. Garantir que `cccp check --strict` mantenha 100% de conformidade com as 24 regras vigentes.

## 3. Critérios de Aceite
- `.forgejo/workflows/ci.yml` contém a invocação `cccp hook -i` precedendo `cccp check --strict`.
- Teste de conformidade de CI passa validando a presença da salvaguarda.
- `cccp check --strict` mantém 100% de conformidade sem degradação.

## 4. Árvore de Decisões e Registro Arquitetural (para a Natasha)
1. **Instalar hooks antes do check vs Desativar regra no `.gost/config`:**
   - *Decisão:* Adotar `cccp hook -i` no workflow de CI.
   - *Alternativa Descartada:* Desativar `KOLLONTAI-018` via `DISABLED_RULES`.
   - *Justificativa:* Desativar no `.gost/config` removeria a garantia de hooks gerenciados nos clones de desenvolvimento local, permitindo commits fora do padrão ou sem execução de gates pré-push.
2. **Correção direta no workflow vs Aguardar evolução do perfil Kollontai:**
   - *Decisão:* Corrigir imediatamente no workflow da Banca seguindo o precedente do `joaju-refs`.
   - *Alternativa Descartada:* Bloquear o deploy da vitrine até um novo ciclo e release do perfil upstream `gost-profile-kollontai`.
   - *Justificativa:* A vitrine da Banca acumula rotações pendentes de artefatos de diversos projetos que dependem do deploy para ficarem acessíveis.

## 5. Laudo de Resolução (Fases 8 e 9)
- **Status:** Concluído com 100% de conformidade GOST.
- **Data de Fechamento:** 2026-11-20
- **Validação Final:** Aprovado em todos os gates.
- **Implementação:**
  - Adicionado `cccp hook -i` no `.forgejo/workflows/ci.yml` antecedendo `cccp check --strict`.
  - Adicionado teste de validação e testes de mutação em `tests/test-ci-hooks-install.sh`.
  - Integrado `tests/test-ci-hooks-install.sh` na suíte de verificação da esteira.
- **Validação:** `cccp check --strict` com 24 regras conformes (100%), suite de testes aprovada.
