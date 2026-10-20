#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação de Downloads Multi-Arquitetura e Canais (#35 & #32)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
DOWNLOADS_DIR="$SITE_DIR/downloads"

echo "================================================================="
echo "🧪 [TESTE] Validação de Downloads Multi-Arquitetura e Canais"
echo "================================================================="

FAILURES=0

# 1. Validar que _redirects não intercepta manifestos JSON nem arquivos de binários
echo -n "-> 1. Verificando proteção de rotas estáticas em site/_redirects... "
REDIRECTS_FILE="$SITE_DIR/_redirects"
if [ ! -f "$REDIRECTS_FILE" ]; then
    echo "❌ FALHOU (arquivo site/_redirects ausente)"
    FAILURES=$((FAILURES + 1))
else
    # Deve conter regra ou exceção impedindo que /downloads/* intercepte .json ou extensões binárias
    if grep -qE '^/downloads/\*\s+/downloads/index\.html\s+200' "$REDIRECTS_FILE"; then
        echo "❌ FALHOU (rewrite cego /downloads/* intercepta arquivos estáticos e index.json)"
        FAILURES=$((FAILURES + 1))
    else
        echo "✅ OK"
    fi
fi

# 2. Validar suporte a --arch e estrutura de artifacts no rotate-downloads.py
echo -n "-> 2. Verificando suporte a --arch no scripts/rotate-downloads.py... "
ROTATE_SCRIPT="$REPO_ROOT/scripts/rotate-downloads.py"
if [ -f "$ROTATE_SCRIPT" ]; then
    if grep -q "\-\-arch" "$ROTATE_SCRIPT" && grep -q "artifacts" "$ROTATE_SCRIPT"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (scripts/rotate-downloads.py não implementa --arch ou artifacts)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (scripts/rotate-downloads.py ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar geração de index.json no build.sh para as ferramentas
echo -n "-> 3. Verificando manifestos index.json em site/downloads/... "
MANDU_MANIFEST="$DOWNLOADS_DIR/mandu/index.json"
if [ -f "$MANDU_MANIFEST" ]; then
    if python3 -c "
import json, sys
with open('$MANDU_MANIFEST') as f:
    d = json.load(f)
assert d.get('app') == 'mandu', 'app != mandu'
assert 'stables' in d and 'nightlies' in d, 'faltam stables/nightlies'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (manifesto de mandu malformatado)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (manifesto site/downloads/mandu/index.json ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Validar UI de downloads: Mandu categorizado corretamente e seletores de arquitetura
echo -n "-> 4. Verificando descrição do Mandu e seletores multi-arch em site/downloads/index.html... "
DOWNLOADS_HTML="$DOWNLOADS_DIR/index.html"
if [ -f "$DOWNLOADS_HTML" ]; then
    if grep -q "Gerenciador de Pacotes" "$DOWNLOADS_HTML"; then
        echo "❌ FALHOU (Mandu ainda catalogado como 'Gerenciador de Pacotes')"
        FAILURES=$((FAILURES + 1))
    elif ! grep -q "windows-amd64" "$DOWNLOADS_HTML" || ! grep -q "linux-arm64" "$DOWNLOADS_HTML"; then
        echo "❌ FALHOU (faltam seletores de arquitetura windows-amd64 / linux-arm64)"
        FAILURES=$((FAILURES + 1))
    else
        echo "✅ OK"
    fi
else
    echo "❌ FALHOU (site/downloads/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. Validar PowerShell snippet para Windows
echo -n "-> 5. Verificando snippet PowerShell para Windows... "
if [ -f "$DOWNLOADS_HTML" ] && grep -qi "Invoke-WebRequest" "$DOWNLOADS_HTML"; then
    echo "✅ OK"
else
    echo "❌ FALHOU (snippet PowerShell com Invoke-WebRequest ausente)"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Esperado na Fase Red do DD-TDD)."
    exit 1
else
    echo "🎉 TODOS OS TESTES DE DOWNLOADS PASSARAM COM SUCESSO!"
    exit 0
fi
