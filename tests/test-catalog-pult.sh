#!/usr/bin/env bash
# ==============================================================================
# tests/test-catalog-pult.sh — Validação do Pult na Vitrine e Downloads (#46)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_FILE="$REPO_ROOT/data/projects.json"
CATALOG_FILE="$REPO_ROOT/site/downloads/catalog.json"
MANIFEST_FILE="$REPO_ROOT/site/downloads/pult/index.json"
BANNER_FILE="$REPO_ROOT/site/assets/banners/pult-banner.png"
SITE_INDEX="$REPO_ROOT/site/index.html"

FAILURES=0

echo "=== Testando Registro do Pult na Banca ==="

# 1. projects.json
echo -n "-> 1. projects.json contém pult... "
if jq -e '.[] | select(.name == "pult")' "$DATA_FILE" >/dev/null; then
    echo "✅ OK"
else
    echo "❌ FALHOU"
    FAILURES=$((FAILURES + 1))
fi

# 2. catalog.json
echo -n "-> 2. catalog.json contém pult... "
if jq -e '.apps[] | select(.app == "pult")' "$CATALOG_FILE" >/dev/null; then
    echo "✅ OK"
else
    echo "❌ FALHOU"
    FAILURES=$((FAILURES + 1))
fi

# 3. index.json
echo -n "-> 3. site/downloads/pult/index.json existe e é válido... "
if [ -f "$MANIFEST_FILE" ] && python3 -m json.tool "$MANIFEST_FILE" >/dev/null; then
    echo "✅ OK"
else
    echo "❌ FALHOU"
    FAILURES=$((FAILURES + 1))
fi

# 4. Banner
echo -n "-> 4. site/assets/banners/pult-banner.png existe... "
if [ -s "$BANNER_FILE" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU"
    FAILURES=$((FAILURES + 1))
fi

# 5. site/index.html
echo -n "-> 5. site/index.html possui o card do pult renderizado... "
if grep -q "pult-banner.png" "$SITE_INDEX" && grep -q "pult.2lp.in" "$SITE_INDEX"; then
    echo "✅ OK"
else
    echo "❌ FALHOU"
    FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "🎉 Todos os 5 testes do Pult na Banca passaram com sucesso!"
    exit 0
else
    echo "❌ $FAILURES falhas detectadas."
    exit 1
fi
