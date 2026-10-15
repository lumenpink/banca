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

# 17. Validar diretórios de densidade icons-<dpi> (120, 160, 240, 320, 480, 640) para Droid-ify
echo -n "-> 17. Verificando diretórios de densidade icons-<dpi> e ícones para Droid-ify... "
DENSITY_FAIL=0
DPIS=(120 160 240 320 480 640)
REQUIRED_ICONS=("in.twolp.lacraia.app.png" "in.twolp.lacraia.simbiotyka.png" "in.twolp.lauda.png" "pratilera.png" "icon.png")

for dpi in "${DPIS[@]}"; do
    DPI_DIR="$PRATILERA_DIR/icons-$dpi"
    if [ ! -d "$DPI_DIR" ]; then
        DENSITY_FAIL=1
        break
    fi
    for ic in "${REQUIRED_ICONS[@]}"; do
        if [ ! -f "$DPI_DIR/$ic" ] || [ "$(wc -c < "$DPI_DIR/$ic" | tr -d ' ')" -lt 1024 ]; then
            DENSITY_FAIL=1
            break 2
        fi
    done
done

# Validar que ícones dos apps também estão presentes na raiz de site/pratilera/
for ic in "${REQUIRED_ICONS[@]}"; do
    if [ ! -f "$PRATILERA_DIR/$ic" ] || [ "$(wc -c < "$PRATILERA_DIR/$ic" | tr -d ' ')" -lt 1024 ]; then
        DENSITY_FAIL=1
        break
    fi
done

if [ "$DENSITY_FAIL" -eq 0 ]; then
    echo "✅ OK (todas as 6 pastas de densidade icons-<dpi> e raiz contêm ícones válidos > 1KB)"
else
    echo "❌ FALHOU (pastas icons-<dpi> ou ícones de apps/loja ausentes/inválidos)"
    FAILURES=$((FAILURES + 1))
fi

# 18. Validar metadados Fastlane (bloco localized no index-v1 e pastas <pkg>/<locale>/icon.png)
echo -n "-> 18. Verificando metadados Fastlane (localized e pastas <pkg>/<locale>/icon.png)... "
FASTLANE_FAIL=0
PACKAGES=("in.twolp.lacraia.app" "in.twolp.lacraia.simbiotyka" "in.twolp.lauda")
LOCALES=("pt-BR" "en-US")

# 1. Verificar index-v1.json para localized
if [ -f "$PRATILERA_DIR/index-v1.json" ]; then
    for pkg in "${PACKAGES[@]}"; do
        for loc in "${LOCALES[@]}"; do
            HAS_LOC=$(jq -r --arg pkg "$pkg" --arg loc "$loc" \
                '.apps[] | select(.packageName == $pkg) | .localized[$loc].icon // empty' "$PRATILERA_DIR/index-v1.json")
            if [ -z "$HAS_LOC" ]; then
                FASTLANE_FAIL=1
                break 2
            fi
        done
    done
else
    FASTLANE_FAIL=1
fi

# 2. Verificar pastas físicas Fastlane
for pkg in "${PACKAGES[@]}"; do
    for loc in "${LOCALES[@]}"; do
        FASTLANE_ICON="$PRATILERA_DIR/$pkg/$loc/icon.png"
        if [ ! -f "$FASTLANE_ICON" ] || [ "$(wc -c < "$FASTLANE_ICON" | tr -d ' ')" -lt 1024 ]; then
            FASTLANE_FAIL=1
            break 2
        fi
    done
done

# 3. Verificar fallback na raiz do domínio (site/icons/icon.png) e _redirects
if [ ! -f "$SITE_DIR/icons/icon.png" ] || [ "$(wc -c < "$SITE_DIR/icons/icon.png" | tr -d ' ')" -lt 1024 ]; then
    FASTLANE_FAIL=1
fi

if ! grep -q "/icons/\*" "$SITE_DIR/_redirects" 2>/dev/null; then
    FASTLANE_FAIL=1
fi

if [ "$FASTLANE_FAIL" -eq 0 ]; then
    echo "✅ OK (metadados Fastlane e localized configurados para todos os apps)"
else
    echo "❌ FALHOU (metadados Fastlane, localized, site/icons ou _redirects ausentes)"
    FAILURES=$((FAILURES + 1))
fi

# 19. Validar profundidade 8-bit RGBA em todos os ícones PNG (Android Skia / Coil compatibility)
echo -n "-> 19. Verificando profundidade estrita de 8 bits por canal nos PNGs... "
DEPTH_FAIL=0
PNG_FILES=$(find "$PRATILERA_DIR" "$SITE_DIR/icons" -type f -name "*.png" 2>/dev/null)
for png in $PNG_FILES; do
    # Byte 24 do header PNG é a profundidade de bits (Bit depth)
    BIT_DEPTH=$(python3 -c "import sys; f=open(sys.argv[1], 'rb'); f.seek(24); print(f.read(1)[0])" "$png" 2>/dev/null)
    if [ "$BIT_DEPTH" -ne 8 ]; then
        DEPTH_FAIL=1
        break
    fi
done

if [ "$DEPTH_FAIL" -eq 0 ]; then
    echo "✅ OK (todos os ícones PNG possuem profundidade canônica de 8 bits por canal)"
else
    echo "❌ FALHOU (encontrado ícone PNG com profundidade diferente de 8-bit)"
    FAILURES=$((FAILURES + 1))
fi

# 20. Validar suggestedVersionCode como String e repo.icon canônico no index-v1.json
echo -n "-> 20. Verificando tipagem de suggestedVersionCode (string) e repo.icon... "
TYPE_FAIL=0
if [ -f "$PRATILERA_DIR/index-v1.json" ]; then
    NON_STRING_VER=$(jq '[.apps[] | select(.suggestedVersionCode | type != "string")] | length' "$PRATILERA_DIR/index-v1.json")
    REPO_ICON=$(jq -r '.repo.icon // empty' "$PRATILERA_DIR/index-v1.json")
    if [ "$NON_STRING_VER" -gt 0 ] || [ "$REPO_ICON" != "icon.png" ]; then
        TYPE_FAIL=1
    fi
else
    TYPE_FAIL=1
fi

if [ "$TYPE_FAIL" -eq 0 ]; then
    echo "✅ OK (suggestedVersionCode é String e repo.icon é icon.png)"
else
    echo "❌ FALHOU (suggestedVersionCode não é string ou repo.icon não é icon.png)"
    FAILURES=$((FAILURES + 1))
fi

# 21. Validar resiliência e idempotência de sanitize_icon_8bit para mesma origem e sem PIL
echo -n "-> 21. Verificando resiliência de sanitize_icon_8bit para mesma origem e sem PIL... "
MOCK_RES=$(python3 -c "
import importlib.util, sys
from pathlib import Path
sys.modules['PIL'] = None
sys.modules['PIL.Image'] = None
spec = importlib.util.spec_from_file_location('gp', '$REPO_ROOT/scripts/gerar-pratilera.py')
gp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gp)
test_file = Path('$SITE_DIR/icons/icon.png')
try:
    gp.sanitize_icon_8bit(test_file, test_file)
    print('PASS')
except Exception as e:
    print('FAIL:', type(e).__name__, e)
" 2>&1)

if [ "$MOCK_RES" = "PASS" ]; then
    echo "✅ OK (sanitize_icon_8bit é resiliente e idempotente)"
else
    echo "❌ FALHOU ($MOCK_RES)"
    FAILURES=$((FAILURES + 1))
fi

# 22. Validar fidelidade estrita dos metadados de versionCode e versionName contra os APKs reais (aapt)
echo -n "-> 22. Verificando fidelidade de versionCode e versionName dos APKs contra index-v1.json... "
AAPT_FAIL=0
AAPT_MSG=""
if [ -f "$PRATILERA_DIR/index-v1.json" ] && command -v aapt >/dev/null 2>&1; then
    for apk_file in "$PRATILERA_DIR"/*.apk; do
        [ -f "$apk_file" ] || continue
        APK_BADGE=$(aapt dump badging "$apk_file" 2>/dev/null || true)
        PKG=$(echo "$APK_BADGE" | grep -o "package: name='[^']*'" | cut -d"'" -f2 || true)
        CODE=$(echo "$APK_BADGE" | grep -o "versionCode='[^']*'" | cut -d"'" -f2 || true)
        NAME=$(echo "$APK_BADGE" | grep -o "versionName='[^']*'" | cut -d"'" -f2 || true)

        if [ -n "$PKG" ] && [ -n "$CODE" ]; then
            INDEX_CODE=$(jq -r --arg p "$PKG" '.packages[$p][0].versionCode // empty' "$PRATILERA_DIR/index-v1.json")
            INDEX_NAME=$(jq -r --arg p "$PKG" '.packages[$p][0].versionName // empty' "$PRATILERA_DIR/index-v1.json")
            if [ "$INDEX_CODE" != "$CODE" ] || [ "$INDEX_NAME" != "$NAME" ]; then
                AAPT_FAIL=1
                AAPT_MSG="Divergência em $PKG: APK ($CODE, $NAME) != Índice ($INDEX_CODE, $INDEX_NAME)"
                break
            fi
        fi
    done
else
    AAPT_FAIL=1
    AAPT_MSG="aapt ou index-v1.json ausente"
fi

if [ "$AAPT_FAIL" -eq 0 ]; then
    echo "✅ OK (versionCode e versionName 100% fiéis aos APKs reais)"
else
    echo "❌ FALHOU ($AAPT_MSG)"
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


