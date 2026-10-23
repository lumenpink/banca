#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Redirecionamento e Resolução de Downloads R2 (Ticket #43)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
DOWNLOADS_DIR="$SITE_DIR/downloads"
REDIRECTS_FILE="$SITE_DIR/_redirects"
ROTATE_SCRIPT="$REPO_ROOT/scripts/rotate-downloads.py"

echo "================================================================="
echo "🧪 [TESTE] Validação de Links de Download R2 e Redirecionamentos"
echo "================================================================="

FAILURES=0

# 1. Validar regras de redirecionamento para bucket.2lp.in em _redirects
echo -n "-> 1. Verificando regras de redirecionamento para downloads no R2 em _redirects... "
if [ ! -f "$REDIRECTS_FILE" ]; then
    echo "❌ FALHOU (_redirects ausente)"
    FAILURES=$((FAILURES + 1))
else
    CONTENT=$(cat "$REDIRECTS_FILE")
    REQUIRED_PATTERNS=(
        "/downloads/:app/stable-latest/* https://bucket.2lp.in/downloads/:app/stable-latest/:splat 302"
        "/downloads/:app/nightly-latest/* https://bucket.2lp.in/downloads/:app/nightly-latest/:splat 302"
        "/downloads/:app/stable/* https://bucket.2lp.in/downloads/:app/stable/:splat 302"
        "/downloads/:app/nightly/* https://bucket.2lp.in/downloads/:app/nightly/:splat 302"
    )
    for pat in "${REQUIRED_PATTERNS[@]}"; do
        if ! grep -Fq "$pat" "$REDIRECTS_FILE"; then
            echo "❌ FALHOU (padrão ausente: $pat)"
            FAILURES=$((FAILURES + 1))
            break
        fi
    done
    if [ "$FAILURES" -eq 0 ]; then
        echo "✅ OK (regras de redirecionamento R2 presentes)"
    fi
fi

# 2. Validar que scripts/rotate-downloads.py gera bucket.2lp.in
echo -n "-> 2. Verificando template padrão em scripts/rotate-downloads.py... "
if grep -q 'https://banca.2lp.in/downloads/{app_slug}' "$ROTATE_SCRIPT"; then
    echo "❌ FALHOU (rotate-downloads.py ainda usa banca.2lp.in no template)"
    FAILURES=$((FAILURES + 1))
else
    echo "✅ OK (rotate-downloads.py configurado para bucket.2lp.in)"
fi

# 3. Validar que site/downloads/index.html não usa banca.2lp.in para links diretos de binários
echo -n "-> 3. Verificando URLs de download na vitrine site/downloads/index.html... "
if grep -q 'https://banca.2lp.in/downloads/${app.name}/stable-latest' "$DOWNLOADS_DIR/index.html" || \
   grep -q 'https://banca.2lp.in/downloads/${app.name}/nightly-latest' "$DOWNLOADS_DIR/index.html"; then
    echo "❌ FALHOU (vitrine ainda constrói links apontando para banca.2lp.in)"
    FAILURES=$((FAILURES + 1))
else
    echo "✅ OK (vitrine aponta para bucket.2lp.in)"
fi

# 4. Validar ausência de links quebrados https://banca.2lp.in/downloads nos manifestos
echo -n "-> 4. Verificando manifestos existentes em site/downloads/*/index.json... "
BROKEN_MANIFESTS=$(grep -rn "https://banca.2lp.in/downloads/" "$DOWNLOADS_DIR"/*/index.json || true)
if [ -n "$BROKEN_MANIFESTS" ]; then
    COUNT=$(echo "$BROKEN_MANIFESTS" | wc -l)
    echo "❌ FALHOU (detectadas $COUNT referências obsoletas a banca.2lp.in/downloads nos manifestos)"
    FAILURES=$((FAILURES + 1))
else
    echo "✅ OK (todos os manifestos apontam diretamente para bucket.2lp.in)"
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Comprovada a falha Red)."
    exit 1
else
    echo "🎉 TODOS OS TESTES PASSARAM COM SUCESSO!"
    exit 0
fi
