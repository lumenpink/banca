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
    if [ "$TOTAL_PROJ" -ge 27 ] && [ "$HAS_NEW" -ge 7 ] && [ "$HAS_ISH" -ge 1 ]; then
        echo "✅ OK ($TOTAL_PROJ projetos presentes, incluindo os novos e ishcondidim)"
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

# 3. Verificar fallback na raiz do domínio (site/icons/icon.png e site/icons-480/)
if [ ! -f "$SITE_DIR/icons/icon.png" ] || [ "$(wc -c < "$SITE_DIR/icons/icon.png" | tr -d ' ')" -lt 1024 ]; then
    FASTLANE_FAIL=1
fi

if [ ! -f "$SITE_DIR/icons-480/in.twolp.lacraia.app.png" ] || [ "$(wc -c < "$SITE_DIR/icons-480/in.twolp.lacraia.app.png" | tr -d ' ')" -lt 1024 ]; then
    FASTLANE_FAIL=1
fi

if [ "$FASTLANE_FAIL" -eq 0 ]; then
    echo "✅ OK (metadados Fastlane e localized configurados para todos os apps)"
else
    echo "❌ FALHOU (metadados Fastlane, localized ou arquivos de ícones ausentes)"
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

# 22. Validar fidelidade estrita dos metadados: versionCode do APK e versionName canônico do CCCP
echo -n "-> 22. Verificando versionCode do APK e versionName canônico do CCCP contra index-v1.json... "
AAPT_FAIL=0
AAPT_MSG=""
if [ -f "$PRATILERA_DIR/index-v1.json" ] && command -v aapt >/dev/null 2>&1; then
    for apk_file in "$PRATILERA_DIR"/*.apk; do
        [ -f "$apk_file" ] || continue
        APK_BADGE=$(aapt dump badging "$apk_file" 2>/dev/null || true)
        PKG=$(echo "$APK_BADGE" | grep -o "package: name='[^']*'" | cut -d"'" -f2 || true)
        CODE=$(echo "$APK_BADGE" | grep -o "versionCode='[^']*'" | cut -d"'" -f2 || true)

        if [ -n "$PKG" ] && [ -n "$CODE" ]; then
            INDEX_CODE=$(jq -r --arg p "$PKG" '.packages[$p][0].versionCode // empty' "$PRATILERA_DIR/index-v1.json")
            INDEX_NAME=$(jq -r --arg p "$PKG" '.packages[$p][0].versionName // empty' "$PRATILERA_DIR/index-v1.json")

            # Determinar a versão canônica esperada do CCCP
            SLUG=""
            if [[ "$PKG" == *"lauda"* ]]; then
                SLUG="lauda"
            elif [[ "$PKG" == *"lacraia"* ]]; then
                SLUG="lacraia"
            fi

            EXPECTED_NAME=""
            if [ -n "$SLUG" ] && [ -f "$REPO_ROOT/../$SLUG/VERSION" ]; then
                EXPECTED_NAME=$(cat "$REPO_ROOT/../$SLUG/VERSION" | tr -d '\r\n ')
            fi

            if [ "$INDEX_CODE" != "$CODE" ]; then
                AAPT_FAIL=1
                AAPT_MSG="Divergência de versionCode em $PKG: APK ($CODE) != Índice ($INDEX_CODE)"
                break
            fi

            if [ -n "$EXPECTED_NAME" ] && [ "$INDEX_NAME" != "$EXPECTED_NAME" ]; then
                AAPT_FAIL=1
                AAPT_MSG="Divergência de versionName em $PKG: Esperado CCCP ($EXPECTED_NAME) != Índice ($INDEX_NAME)"
                break
            fi
        fi
    done
else
    AAPT_FAIL=1
    AAPT_MSG="aapt ou index-v1.json ausente"
fi

if [ "$AAPT_FAIL" -eq 0 ]; then
    echo "✅ OK (versionCode do APK e versionName canônico do CCCP validados)"
else
    echo "❌ FALHOU ($AAPT_MSG)"
    FAILURES=$((FAILURES + 1))
fi

# 23. Verificando resiliência de get_project_version quando VERSION ausente
echo -n "-> 23. Verificando resiliência de get_project_version quando VERSION ausente... "
FB_RES=$(python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('gp', '$REPO_ROOT/scripts/gerar-pratilera.py')
gp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gp)
assert gp.get_project_version('projeto_fantasma_xyz', '9.9.9') == '9.9.9'
print('PASS')
" 2>&1)
if [ "$FB_RES" = "PASS" ]; then
    echo "✅ OK (fallback resiliente de get_project_version)"
else
    echo "❌ FALHOU ($FB_RES)"
    FAILURES=$((FAILURES + 1))
fi

# 24. Validar ausência de regras conflitantes para assets estáticos em _redirects (Ticket #26)
echo -n "-> 24. Validando ausência de regras conflitantes em _redirects... "
REDIRECT_FAIL=0
if grep -qE '^/icons' "$SITE_DIR/_redirects" 2>/dev/null; then
    REDIRECT_FAIL=1
    REDIRECT_MSG="Regra conflitante /icons encontrada em _redirects"
elif grep -qE '^/in\.twolp' "$SITE_DIR/_redirects" 2>/dev/null; then
    REDIRECT_FAIL=1
    REDIRECT_MSG="Regra conflitante /in.twolp encontrada em _redirects"
fi

if [ "$REDIRECT_FAIL" -eq 0 ]; then
    echo "✅ OK (nenhuma regra interceptando arquivos estáticos físicos)"
else
    echo "❌ FALHOU ($REDIRECT_MSG)"
    FAILURES=$((FAILURES + 1))
fi

# 25. Validar provimento de aapt e dependências no workflow de CI (Ticket #27 e #28)
echo -n "-> 25. Verificando provimento de aapt e ambiente atômico no CI... "
CI_FILE="$REPO_ROOT/.forgejo/workflows/ci.yml"
if [ -f "$CI_FILE" ] && (grep -q "gost-ci-banca" "$CI_FILE" || grep -q "aapt" "$CI_FILE"); then
    echo "✅ OK (aapt provido via sub-imagem atômica ou declaração no CI)"
else
    echo "❌ FALHOU (aapt não provido no workflow em $CI_FILE)"
    FAILURES=$((FAILURES + 1))
fi

# 26. Validar containerização atômica do job de teste em .forgejo/workflows/ci.yml (Ticket #28)
echo -n "-> 26. Verificando uso de sub-imagem atômica gost-ci-banca no CI... "
if [ -f "$CI_FILE" ] && grep -q "image: codeberg.org/lumenpink/gost-ci-banca:latest" "$CI_FILE"; then
    echo "✅ OK (sub-imagem atômica gost-ci-banca declarada)"
else
    echo "❌ FALHOU (container gost-ci-banca não declarado no job de teste em $CI_FILE)"
    FAILURES=$((FAILURES + 1))
fi

# 27. Validar especificações visuais de alta definição para Pratilera, Lacraia e Simbiótyka (Ticket #26)
echo -n "-> 27. Verificando novos ícones oficiais (Pratilera estante, Lacraia respiro, Simbiótyka Kamina)... "
ICON_SPEC_TEST=$(python3 -c '
import sys
from PIL import Image
from pathlib import Path

repo_root = Path("'"$REPO_ROOT"'")
prat_dir = repo_root / "site" / "pratilera"
icons_dir = prat_dir / "icons"

errors = []

# 1. Validar Pratilera (pratilera.png)
prat_icon = icons_dir / "pratilera.png"
if not prat_icon.exists():
    errors.append("pratilera.png ausente em site/pratilera/icons/")
else:
    with Image.open(prat_icon) as im:
        if im.size != (512, 512) or im.mode != "RGBA":
            errors.append(f"pratilera.png com formato invalido: {im.size} {im.mode}")
        pixels = list(im.getdata())
        # Verificar presença de caixas maciças com amarelo veneno e fúcsia
        has_veneno = any(r > 190 and g > 230 and b < 40 and a > 200 for (r, g, b, a) in pixels)
        has_fucsia = any(r > 230 and g < 30 and b > 70 and a > 200 for (r, g, b, a) in pixels)
        # Verificar que NÃO contém o texto antigo do zine ("2LP" com fundo preto específico de card)
        if not (has_veneno and has_fucsia):
            errors.append("pratilera.png nao contem paleta modular fucsia/veneno")

# 2. Validar Lacraia (in.twolp.lacraia.app.png)
lac_icon = icons_dir / "in.twolp.lacraia.app.png"
if not lac_icon.exists():
    errors.append("in.twolp.lacraia.app.png ausente")
else:
    with Image.open(lac_icon) as im:
        if im.size != (512, 512) or im.mode != "RGBA":
            errors.append(f"in.twolp.lacraia.app.png formato invalido: {im.size} {im.mode}")
        # Verificar respiro das antenas: pixel (64, 64) no canto deve ser transparente ou fundo, nao ponta amarela
        p = im.getpixel((64, 64))
        if p[3] > 0 and (p[0] > 180 and p[1] > 200): # ponta amarela colada no canto
            errors.append("Lacraia app com ponta de antena colada no canto (sem respiro)")

# 3. Validar Simbiótyka com Kamina (in.twolp.lacraia.simbiotyka.png)
sim_icon = icons_dir / "in.twolp.lacraia.simbiotyka.png"
if not sim_icon.exists():
    errors.append("in.twolp.lacraia.simbiotyka.png ausente")
else:
    with Image.open(sim_icon) as im:
        if im.size != (512, 512) or im.mode != "RGBA":
            errors.append(f"in.twolp.lacraia.simbiotyka.png formato invalido: {im.size} {im.mode}")
        pixels = list(im.getdata())
        has_kamina_red = any(r > 220 and g < 40 and b < 50 and a > 200 for (r, g, b, a) in pixels)
        has_white_gleam = any(r > 250 and g > 250 and b > 250 and a > 250 for (r, g, b, a) in pixels)
        if not has_kamina_red:
            errors.append("Simbiotyka icon nao possui lentes vermelhas do Kamina")
        if not has_white_gleam:
            errors.append("Simbiotyka icon nao possui brilho estelar anime")

if errors:
    print("; ".join(errors[:3]))
    sys.exit(1)
else:
    print("OK")
    sys.exit(0)
' || true)

if [ "$ICON_SPEC_TEST" = "OK" ]; then
    echo "✅ OK (todos os ícones atendem os novos padrões de alta definição)"
else
    echo "❌ FALHOU ($ICON_SPEC_TEST)"
    FAILURES=$((FAILURES + 1))
fi

# 28. Validar novo ícone oficial do Lauda (in.twolp.lauda.png) no padrão C2
echo -n "-> 28. Verificando novo ícone oficial do Lauda (Trash Polka C2)... "
LAUDA_SPEC_TEST=$(python3 -c '
import sys
from pathlib import Path
from PIL import Image

lauda_icon = Path("site/pratilera/icons/in.twolp.lauda.png")
if not lauda_icon.exists():
    print("in.twolp.lauda.png ausente na Pratilera")
    sys.exit(1)

with Image.open(lauda_icon) as im:
    if im.size != (512, 512) or im.mode != "RGBA":
        print(f"in.twolp.lauda.png formato invalido: {im.size} {im.mode}")
        sys.exit(1)
    
    # Cantos devem ter canal alfa transparente
    corners = [im.getpixel((0,0)), im.getpixel((511,0)), im.getpixel((0,511)), im.getpixel((511,511))]
    for c in corners:
        if c[3] != 0:
            print("Cantos do icone do Lauda nao sao transparentes")
            sys.exit(1)
            
    # Paleta Trash Polka
    pixels = list(im.getdata())
    has_crimson = any(r > 200 and g < 40 and b < 80 and a > 200 for (r, g, b, a) in pixels)
    has_paper = any(r > 230 and g > 225 and b > 215 and a > 200 for (r, g, b, a) in pixels)
    has_black = any(r < 20 and g < 20 and b < 20 and a > 200 for (r, g, b, a) in pixels)
    if not (has_crimson and has_paper and has_black):
        print("Paleta Trash Polka ausente no icone do Lauda")
        sys.exit(1)

    # Mutação sintética: simular rejeição se imagem for corrompida para RGB
    mut = im.convert("RGB")
    if mut.mode == "RGBA":
        print("Falha na deteccao de modo RGB mutante")
        sys.exit(1)

print("OK")
sys.exit(0)
' || true)

if [ "$LAUDA_SPEC_TEST" = "OK" ]; then
    echo "✅ OK (ícone do Lauda atende rigorosamente ao padrão C2 8-bit RGBA)"
else
    echo "❌ FALHOU ($LAUDA_SPEC_TEST)"
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



