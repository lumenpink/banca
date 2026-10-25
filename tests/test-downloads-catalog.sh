#!/usr/bin/env bash
# ==============================================================================
# tests/test-downloads-catalog.sh — Validação do Catálogo Consolidado (catalog.json) (#41)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
DOWNLOADS_DIR="$SITE_DIR/downloads"
CATALOG_FILE="$DOWNLOADS_DIR/catalog.json"
FAILURES=0

echo "================================================================="
echo "🧪 [TESTE] Validação do Catálogo Consolidado da Banca (catalog.json)"
echo "================================================================="

# 1. Verificar existência do arquivo catalog.json
echo -n "-> 1. Verificando existência de site/downloads/catalog.json... "
if [ -f "$CATALOG_FILE" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (arquivo $CATALOG_FILE ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 2. Validar sintaxe JSON estrita
echo -n "-> 2. Validando integridade sintática do JSON... "
if [ -f "$CATALOG_FILE" ]; then
    if python3 -m json.tool "$CATALOG_FILE" >/dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (arquivo não é JSON válido)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar campos essenciais e contagem mínima de apps
echo -n "-> 3. Validando estrutura de campos e contagem mínima de 16 apps (incluindo Jornaleira)... "
if [ -f "$CATALOG_FILE" ]; then
    TOTAL=$(python3 -c "
import json, sys
try:
    with open('$CATALOG_FILE') as f:
        d = json.load(f)
    assert 'updated_at' in d
    assert 'banca_url' in d
    assert 'apps' in d
    assert isinstance(d['apps'], list)
    assert len(d['apps']) >= 16
    app_slugs = set()
    for a in d['apps']:
        assert 'app' in a and a['app']
        assert 'name' in a and a['name']
        assert 'description' in a
        assert 'stable_latest' in a
        assert 'nightly_latest' in a
        assert 'manifest_url' in a
        app_slugs.add(a['app'])
    assert 'jornaleira' in app_slugs, 'jornaleira ausente no catalog.json'
    print(len(d['apps']))
except Exception as e:
    sys.exit(1)
" 2>/dev/null || true)

    if [ -n "$TOTAL" ] && [ "$TOTAL" -ge 16 ]; then
        echo "✅ OK ($TOTAL apps validados com sucesso)"
    else
        echo "❌ FALHOU (estrutura inválida, menos de 16 apps ou jornaleira ausente)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo ausente)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -gt 0 ]; then
    echo "❌ Teste falhou com $FAILURES erro(s)."
    exit 1
fi

echo "🎉 Todos os testes de catalog.json passaram com sucesso!"
exit 0
