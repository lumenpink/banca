#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação da Vitrine de Downloads e Retenção R2 (Ticket #31)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
DOWNLOADS_DIR="$SITE_DIR/downloads"
ROTATE_SCRIPT="$REPO_ROOT/scripts/rotate-downloads.py"

echo "================================================================="
echo "🧪 [TESTE] Validação da Vitrine de Downloads e Retenção Soberana"
echo "================================================================="

FAILURES=0

# 1. Validar existência da estrutura em site/downloads/index.html
echo -n "-> 1. Verificando existência de site/downloads/index.html... "
if [ -f "$DOWNLOADS_DIR/index.html" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (arquivo site/downloads/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 2. Validar ausência de frameworks externos e presença de Vanilla JS
echo -n "-> 2. Verificando uso estrito de Vanilla JS sem frameworks... "
if [ -f "$DOWNLOADS_DIR/index.html" ]; then
    HTML_CONTENT=$(cat "$DOWNLOADS_DIR/index.html")
    if echo "$HTML_CONTENT" | grep -qiE "react|vue|angular|jquery|cdn\.jsdelivr|unpkg\.com"; then
        echo "❌ FALHOU (detectado framework externo ou dependência de CDN)"
        FAILURES=$((FAILURES + 1))
    else
        echo "✅ OK (100% Vanilla JS local)"
    fi
else
    echo "❌ FALHOU (arquivo ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar Dropdown / Seletor de software
echo -n "-> 3. Verificando dropdown de seleção de aplicações... "
if [ -f "$DOWNLOADS_DIR/index.html" ]; then
    HTML_CONTENT=$(cat "$DOWNLOADS_DIR/index.html")
    if echo "$HTML_CONTENT" | grep -q "id=\"app-selector\"" && \
       echo "$HTML_CONTENT" | grep -q "value=\"cccp\"" && \
       echo "$HTML_CONTENT" | grep -q "value=\"navalha\""; then
        echo "✅ OK (seletor presente com apps canônicos)"
    else
        echo "❌ FALHOU (seletor #app-selector ou opções ausentes)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Validar lógica de Deep Linking (URL path e hash)
echo -n "-> 4. Verificando suporte a Deep Linking (path e #hash)... "
if [ -f "$DOWNLOADS_DIR/index.html" ]; then
    HTML_CONTENT=$(cat "$DOWNLOADS_DIR/index.html")
    if echo "$HTML_CONTENT" | grep -q "window.location.hash" && \
       echo "$HTML_CONTENT" | grep -q "history.pushState"; then
        echo "✅ OK (deep linking funcional implementado)"
    else
        echo "❌ FALHOU (lógica de hash ou pushState ausente)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. Validar Estética Anti-Design e Paleta Oficial
echo -n "-> 5. Verificando variáveis e estética Anti-Design... "
if [ -f "$DOWNLOADS_DIR/index.html" ]; then
    HTML_CONTENT=$(cat "$DOWNLOADS_DIR/index.html")
    if echo "$HTML_CONTENT" | grep -q -- "--pink:" && \
       echo "$HTML_CONTENT" | grep -q -- "--bg:" && \
       echo "$HTML_CONTENT" | grep -q -- "--font-mono:"; then
        echo "✅ OK (estética anti-design preservada)"
    else
        echo "❌ FALHOU (variáveis CSS canônicas ausentes)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 6. Validar regras de roteamento em site/_redirects
echo -n "-> 6. Verificando redirecionamento /downloads/* em _redirects... "
if [ -f "$SITE_DIR/_redirects" ]; then
    REDIRECTS_CONTENT=$(cat "$SITE_DIR/_redirects")
    if echo "$REDIRECTS_CONTENT" | grep -q "/downloads/\*" || echo "$REDIRECTS_CONTENT" | grep -q "/downloads "; then
        echo "✅ OK (regras de roteamento presentes)"
    else
        echo "❌ FALHOU (regras para /downloads ausentes em _redirects)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/_redirects ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 7. Validar script de rotação e retenção scripts/rotate-downloads.py
echo -n "-> 7. Verificando existência e interface de scripts/rotate-downloads.py... "
if [ -f "$ROTATE_SCRIPT" ]; then
    if python3 "$ROTATE_SCRIPT" --help >/dev/null 2>&1; then
        echo "✅ OK (script executável)"
    else
        echo "❌ FALHOU (script rotate-downloads.py falhou ao executar --help)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo scripts/rotate-downloads.py ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 8. Testar retenção estrita de 5 estáveis e 10 nightlies via rotate-downloads.py
echo -n "-> 8. Testando algoritmo de retenção (5 estáveis, 10 nightlies)... "
if [ -f "$ROTATE_SCRIPT" ]; then
    TMP_JSON=$(mktemp --suffix=.json)
    cat << 'EOF' > "$TMP_JSON"
{
  "app": "testapp",
  "name": "Test App",
  "description": "App de teste para retenção",
  "stable_latest": "1.0.0",
  "nightly_latest": "1.1.0-dev.1",
  "stables": [
    {"version": "1.0.0"}, {"version": "1.0.1"}, {"version": "1.0.2"},
    {"version": "1.0.3"}, {"version": "1.0.4"}, {"version": "1.0.5"}
  ],
  "nightlies": [
    {"version": "dev.1"}, {"version": "dev.2"}, {"version": "dev.3"},
    {"version": "dev.4"}, {"version": "dev.5"}, {"version": "dev.6"},
    {"version": "dev.7"}, {"version": "dev.8"}, {"version": "dev.9"},
    {"version": "dev.10"}, {"version": "dev.11"}, {"version": "dev.12"}
  ]
}
EOF
    python3 "$ROTATE_SCRIPT" --prune-manifest "$TMP_JSON" >/dev/null 2>&1 || true
    STABLES_COUNT=$(python3 -c "import json; d=json.load(open('$TMP_JSON')); print(len(d['stables']))")
    NIGHTLIES_COUNT=$(python3 -c "import json; d=json.load(open('$TMP_JSON')); print(len(d['nightlies']))")
    rm -f "$TMP_JSON"

    if [ "$STABLES_COUNT" -le 5 ] && [ "$NIGHTLIES_COUNT" -le 10 ]; then
        echo "✅ OK (retidos $STABLES_COUNT estáveis <= 5 e $NIGHTLIES_COUNT nightlies <= 10)"
    else
        echo "❌ FALHOU (esperado <= 5 estáveis e <= 10 nightlies, obtido $STABLES_COUNT e $NIGHTLIES_COUNT)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (rotate-downloads.py ausente)"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM."
    exit 1
else
    echo "🎉 TODOS OS TESTES DE DOWNLOADS PASSARAM!"
    exit 0
fi
