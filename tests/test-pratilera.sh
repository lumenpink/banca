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

# 6. Validar cartão da Pratilera, botão de cópia e notas de digitação em site/index.html
echo -n "-> 6. Verificando vitrine, botão de cópia e HTTPS canônico em site/index.html... "
if [ -f "$SITE_DIR/index.html" ]; then
    if grep -qi "pratilera" "$SITE_DIR/index.html" && \
       grep -qi "patilera" "$SITE_DIR/index.html" && \
       grep -qi "prateleira" "$SITE_DIR/index.html" && \
       grep -q "https://banca.2lp.in/pratilera" "$SITE_DIR/index.html" && \
       grep -qi "copiar" "$SITE_DIR/index.html"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (botão de cópia, URL https canônica ou notas de patilera/prateleira ausentes)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 7. Validar suporte a suggestedVersionCode e prereleases no gerador da Pratilera
echo -n "-> 7. Verificando suporte a pré-releases e suggestedVersionCode em gerar-pratilera.py... "
if [ -f "$REPO_ROOT/scripts/gerar-pratilera.py" ]; then
    if grep -q "suggestedVersionCode" "$REPO_ROOT/scripts/gerar-pratilera.py" && \
       grep -q "is_prerelease" "$REPO_ROOT/scripts/gerar-pratilera.py"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (lógica de pré-release ou suggestedVersionCode ausente em gerar-pratilera.py)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (scripts/gerar-pratilera.py ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 8. Validar expansão para 27 projetos em data/projects.json e inclusão dos 7 projetos autorais
echo -n "-> 8. Verificando expansão para 27 projetos e presença dos 7 novos em data/projects.json... "
DATA_FILE="$REPO_ROOT/data/projects.json"
if [ -f "$DATA_FILE" ]; then
    TOTAL_PROJ=$(jq 'length' "$DATA_FILE")
    HAS_NEW=$(jq '[.[] | select(.name == "lauda" or .name == "ayvu" or .name == "muiraquita" or .name == "tuitata" or .name == "urupema" or .name == "tatupeba" or .name == "baquara-rs")] | length' "$DATA_FILE")
    HAS_ISH=$(jq '[.[] | select(.name == "ishcondidim")] | length' "$DATA_FILE")
    if [ "$TOTAL_PROJ" -eq 27 ] && [ "$HAS_NEW" -eq 7 ] && [ "$HAS_ISH" -eq 1 ]; then
        echo "✅ OK (27 projetos presentes, incluindo os 7 novos e ishcondidim)"
    else
        echo "❌ FALHOU (Total: $TOTAL_PROJ [esperado 27], novos presentes: $HAS_NEW [esperado 7])"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (data/projects.json ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 9. Validar padronização PT-BR das descrições (sem inglês residual)
echo -n "-> 9. Verificando padronização em PT-BR das descrições dos projetos... "
if [ -f "$DATA_FILE" ]; then
    HAS_EN=$(jq '[.[] | select(.description | test("Decentralized Automotive|Micro terminal text|Micro HTTP/HTTPS|Micro static HTTP|personal typographic|WordPress plugin adding"; "i"))] | length' "$DATA_FILE")
    if [ "$HAS_EN" -eq 0 ]; then
        echo "✅ OK (descrições 100% em PT-BR)"
    else
        echo "❌ FALHOU (encontradas $HAS_EN descrições com resíduos em inglês)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (data/projects.json ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 10. Validar Safe Zone 1200x630 no CSS (.zine-media aspect-ratio) e piada "erros para mais e para menos"
echo -n "-> 10. Verificando Safe Zone 1200x630 e piada de erros para mais e para menos... "
BUILD_FILE="$REPO_ROOT/build.sh"
if grep -q "aspect-ratio: 1200 / 630" "$BUILD_FILE" && \
   grep -q "erros para mais e para menos" "$SITE_DIR/index.html"; then
    echo "✅ OK"
else
    echo "❌ FALHOU (aspect-ratio 1200 / 630 em build.sh ou piada de erros para mais e para menos ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 11. Validar campo category em todos os 27 projetos
echo -n "-> 11. Verificando campo category válido em todos os 27 projetos... "
if [ -f "$DATA_FILE" ]; then
    INVALID_CATS=$(jq '[.[] | select(.category == null or (.category != "apps" and .category != "terminal" and .category != "indieweb" and .category != "editorial" and .category != "pesquisa" and .category != "governance"))] | length' "$DATA_FILE")
    if [ "$INVALID_CATS" -eq 0 ]; then
        echo "✅ OK (todos os 27 projetos possuem categoria canônica)"
    else
        echo "❌ FALHOU ($INVALID_CATS projeto(s) com category ausente ou inválida)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (data/projects.json ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 12. Validar botões de filtro e badges de categoria no build.sh
echo -n "-> 12. Verificando botões de filtro de categoria no build.sh... "
if grep -q 'data-filter="apps"' "$BUILD_FILE" && \
   grep -q 'data-filter="terminal"' "$BUILD_FILE" && \
   grep -q 'data-filter="indieweb"' "$BUILD_FILE" && \
   grep -q 'data-filter="editorial"' "$BUILD_FILE" && \
   grep -q 'data-filter="pesquisa"' "$BUILD_FILE" && \
   grep -q 'data-filter="governance"' "$BUILD_FILE"; then
    echo "✅ OK"
else
    echo "❌ FALHOU (botões de filtro de categoria ausentes no build.sh)"
    FAILURES=$((FAILURES + 1))
fi

# 13. Validar arquivos de ícone oficial da Pratilera (Droid-ify / F-Droid)
echo -n "-> 13. Verificando arquivos de ícone oficial da Pratilera (Droid-ify / F-Droid)... "
ICON_FAIL=0
for icon_path in "$PRATILERA_DIR/icons/icon.png" \
                 "$PRATILERA_DIR/icons/pratilera.png" \
                 "$PRATILERA_DIR/icon.png" \
                 "$PRATILERA_DIR/pratilera.png"; do
    if [ ! -f "$icon_path" ]; then
        ICON_FAIL=1
        break
    fi
    # Garantir tamanho > 1KB (não mock 1x1)
    FILE_SIZE=$(wc -c < "$icon_path" | tr -d ' ')
    if [ "$FILE_SIZE" -lt 1024 ]; then
        ICON_FAIL=1
        break
    fi
done

if [ "$ICON_FAIL" -eq 0 ]; then
    echo "✅ OK (todos os caminhos de ícone da Pratilera atendidos)"
else
    echo "❌ FALHOU (ícones da Pratilera ausentes ou são placeholders vazios)"
    FAILURES=$((FAILURES + 1))
fi

# 14. Validar ícone e favicon unificados na Banca (site/assets/icon.png e favicon)
echo -n "-> 14. Verificando ícone unificado e favicon na Banca... "
if [ -f "$SITE_DIR/assets/icon.png" ] && \
   [ -f "$SITE_DIR/favicon.svg" ] && \
   grep -qi 'rel="icon"' "$BUILD_FILE"; then
    echo "✅ OK"
else
    echo "❌ FALHOU (site/assets/icon.png, site/favicon.svg ou rel=icon em build.sh ausentes)"
    FAILURES=$((FAILURES + 1))
fi

# 15. Validar existência física e integridade dos APKs (> 1MB e hashes não-nulos)
echo -n "-> 15. Verificando APKs físicos e metadados no index-v1.json (> 1MB)... "
APK_FAIL=0
for apk in "lacraia-app.apk" "simbiotyka.apk" "lauda-latest.apk"; do
    if [ ! -f "$PRATILERA_DIR/$apk" ]; then
        APK_FAIL=1
        break
    fi
    SZ=$(stat -c%s "$PRATILERA_DIR/$apk")
    if [ "$SZ" -lt 1048576 ]; then
        APK_FAIL=1
        break
    fi
done

# Verificar se index-v1.json não contém tamanho 1024 nem hashes zerados
if [ -f "$PRATILERA_DIR/index-v1.json" ]; then
    HAS_DUMMY=$(jq '[.packages[][] | select(.size <= 1024 or (.hash | test("^0+$")))] | length' "$PRATILERA_DIR/index-v1.json")
    if [ "$HAS_DUMMY" -gt 0 ]; then
        APK_FAIL=1
    fi
else
    APK_FAIL=1
fi

if [ "$APK_FAIL" -eq 0 ]; then
    echo "✅ OK (APKs reais presentes e index-v1.json com tamanhos e hashes verídicos)"
else
    echo "❌ FALHOU (APKs ausentes, menores que 1MB ou index com valores dummy)"
    FAILURES=$((FAILURES + 1))
fi

# 16. Validar signer SHA-256 canônico (64 hexadecimais) no index-v1.json (sem dummy in_twolp)
echo -n "-> 16. Verificando signer SHA-256 canônico nos pacotes do index-v1.json... "
SIGNER_FAIL=0
if [ -f "$PRATILERA_DIR/index-v1.json" ]; then
    INVALID_SIGNERS=$(jq '[.packages[][] | select(.signer == "in_twolp" or (.signer | test("^[0-9a-f]{64}$") | not))] | length' "$PRATILERA_DIR/index-v1.json")
    if [ "$INVALID_SIGNERS" -gt 0 ]; then
        SIGNER_FAIL=1
    fi
else
    SIGNER_FAIL=1
fi

if [ "$SIGNER_FAIL" -eq 0 ]; then
    echo "✅ OK (todos os signers possuem SHA-256 canônico de 64 caracteres hex)"
else
    echo "❌ FALHOU (signers contêm placeholder textual ou não possuem SHA-256 válido)"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ $FAILURES -eq 0 ]; then
    echo "🎉 TODOS OS TESTES DA VITRINE PASSARAM!"
    exit 0
else
    echo "💥 $FAILURES TESTE(S) FALHARAM."
    exit 1
fi


