#!/usr/bin/env bash
# ==============================================================================
# 🧪 [TESTE] Validação de Instalação de Hooks Pré-Auditoria no CI (#65)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift
    echo -n "-> $desc... "
    if "$@"; then
        echo "✅ OK"
        PASS=$((PASS + 1))
    else
        echo "❌ FALHOU"
        FAIL=$((FAIL + 1))
    fi
}

echo "================================================================="
echo "🧪 [TESTE] Hooks do Maestro no CI (#65)"
echo "================================================================="

CI_WORKFLOW=".forgejo/workflows/ci.yml"

check "1. Verificando existência de $CI_WORKFLOW" test -f "$CI_WORKFLOW"

check "2. Verificando cccp hook -i antes de cccp check --strict" python3 -c '
import sys

with open(".forgejo/workflows/ci.yml") as f:
    content = f.read()

idx_hook = content.find("cccp hook -i")
idx_check = content.find("cccp check --strict")

if idx_hook == -1:
    print("\nERRO: cccp hook -i nao encontrado no workflow", file=sys.stderr)
    sys.exit(1)

if idx_check == -1:
    print("\nERRO: cccp check --strict nao encontrado no workflow", file=sys.stderr)
    sys.exit(1)

if idx_hook >= idx_check:
    print("\nERRO: cccp hook -i deve preceder cccp check --strict", file=sys.stderr)
    sys.exit(1)
'

check "3. Verificando inclusao do teste no script de validacao da esteira" grep -q "test-ci-hooks-install.sh" "$CI_WORKFLOW"

# Testes de Mutação (Fase 7)
check "4. [MUTAÇÃO] Rejeição de workflow sem cccp hook -i" python3 -c '
import sys

def validate(content):
    idx_hook = content.find("cccp hook -i")
    idx_check = content.find("cccp check --strict")
    if idx_hook == -1 or idx_check == -1 or idx_hook >= idx_check:
        return False
    return True

mutant = "test -f .gost/GOST.md\ncccp check --strict\n"
if validate(mutant):
    print("ERRO: Validador nao rejeitou mutante sem hook", file=sys.stderr)
    sys.exit(1)
'

check "5. [MUTAÇÃO] Rejeição de workflow com ordem invertida" python3 -c '
import sys

def validate(content):
    idx_hook = content.find("cccp hook -i")
    idx_check = content.find("cccp check --strict")
    if idx_hook == -1 or idx_check == -1 or idx_hook >= idx_check:
        return False
    return True

mutant_inverted = "cccp check --strict\ncccp hook -i\n"
if validate(mutant_inverted):
    print("ERRO: Validador nao rejeitou mutante com ordem invertida", file=sys.stderr)
    sys.exit(1)
'

echo "================================================================="
if [ "$FAIL" -gt 0 ]; then
    echo "❌ $FAIL teste(s) falharam."
    exit 1
else
    echo "🎉 Todos os testes de hooks na CI passaram!"
    exit 0
fi
