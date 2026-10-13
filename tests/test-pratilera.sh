#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação da Pratilera (Loja F-Droid / Droid-ify)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
PRATILERA_DIR="$SITE_DIR/pratilera"

echo "================================================================="
echo "🧪 [TESTE] Validação da Pratilera F-Droid / Droid-ify"
echo "================================================================="

FAILURES=0

# 1. Validar existência da estrutura da Pratilera
echo -n "-> 1. Verificando estrutura em $PRATILERA_DIR... "
if [ -d "$PRATILERA_DIR" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (diretório site/pratilera ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 2. Validar existência e sintaxe do índice index-v1.json
echo -n "-> 2. Verificando index-v1.json... "
if [ -f "$PRATILERA_DIR/index-v1.json" ]; then
    if python3 -m json.tool "$PRATILERA_DIR/index-v1.json" >/dev/null 2>&1; then
        echo "✅ OK (JSON válido)"
    else
        echo "❌ FALHOU (JSON inválido)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo site/pratilera/index-v1.json ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar index-v1.jar assinado
echo -n "-> 3. Verificando index-v1.jar assinado... "
if [ -f "$PRATILERA_DIR/index-v1.jar" ]; then
    if jarsigner -verify "$PRATILERA_DIR/index-v1.jar" >/dev/null 2>&1; then
        echo "✅ OK (Assinatura JAR válida)"
    else
        echo "❌ FALHOU (JAR presente mas assinatura inválida)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo site/pratilera/index-v1.jar ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Validar cabeçalhos em site/_headers
echo -n "-> 4. Verificando cabeçalhos HTTP em site/_headers... "
if [ -f "$SITE_DIR/_headers" ]; then
    HEADERS=$(cat "$SITE_DIR/_headers")
    if echo "$HEADERS" | grep -q "application/java-archive" && \
       echo "$HEADERS" | grep -q "Access-Control-Allow-Origin: \*" && \
       echo "$HEADERS" | grep -q "application/vnd.android.package-archive"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (diretivas MIME ou CORS ausentes em site/_headers)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/_headers ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. Validar aliases e redirecionamentos (/patilera, /prateleira, /repo)
echo -n "-> 5. Verificando aliases (/patilera, /prateleira, /repo)... "
REDIRECTS_FILE="$SITE_DIR/_redirects"
WORKER_FILE="$REPO_ROOT/worker/index.js"
if [ -f "$REDIRECTS_FILE" ]; then
    RED_CONTENT=$(cat "$REDIRECTS_FILE")
    if echo "$RED_CONTENT" | grep -q "/patilera" && \
       echo "$RED_CONTENT" | grep -q "/prateleira" && \
       echo "$RED_CONTENT" | grep -q "/repo"; then
        echo "✅ OK (aliases encontrados em _redirects)"
    else
        echo "❌ FALHOU (aliases incompletos em _redirects)"
        FAILURES=$((FAILURES + 1))
    fi
elif [ -f "$WORKER_FILE" ]; then
    WORKER_CONTENT=$(cat "$WORKER_FILE")
    if echo "$WORKER_CONTENT" | grep -q "patilera" && \
       echo "$WORKER_CONTENT" | grep -q "prateleira" && \
       echo "$WORKER_CONTENT" | grep -q "repo"; then
        echo "✅ OK (aliases encontrados no worker)"
    else
        echo "❌ FALHOU (aliases incompletos no worker)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (nem site/_redirects nem worker/index.js configurados)"
    FAILURES=$((FAILURES + 1))
fi

# 6. Validar cartão da Pratilera e piada dos erros de digitação em site/index.html
echo -n "-> 6. Verificando vitrine e notas de digitação em site/index.html... "
if [ -f "$SITE_DIR/index.html" ]; then
    HTML_CONTENT=$(cat "$SITE_DIR/index.html")
    if echo "$HTML_CONTENT" | grep -qi "pratilera" && \
       echo "$HTML_CONTENT" | grep -qi "patilera" && \
       echo "$HTML_CONTENT" | grep -qi "prateleira" && \
       echo "$HTML_CONTENT" | grep -q "fdroidrepos://banca.2lp.in/pratilera"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (menções à Pratilera, links fdroidrepos ou notas de patilera/prateleira ausentes)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ $FAILURES -eq 0 ]; then
    echo "🎉 TODOS OS TESTES DA PRATILERA PASSARAM!"
    exit 0
else
    echo "💥 $FAILURES TESTE(S) FALHARAM."
    exit 1
fi
