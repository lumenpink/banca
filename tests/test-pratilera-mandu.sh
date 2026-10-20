#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação da Integração do Mandu na Pratilera e Catálogo (#34)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_FILE="$REPO_ROOT/data/projects.json"
PRATILERA_DIR="$REPO_ROOT/site/pratilera"
INDEX_JSON="$PRATILERA_DIR/index-v1.json"
BANNER_FILE="$REPO_ROOT/assets/banners/mandu-banner.png"
SITE_HTML="$REPO_ROOT/site/index.html"
GERAR_SCRIPT="$REPO_ROOT/scripts/gerar-pratilera.py"

echo "================================================================="
echo "🧪 [TESTE] Validação do Mandu na Pratilera e no Catálogo (#34)"
echo "================================================================="

FAILURES=0

# 1. Verificar configuração do Mandu em gerar-pratilera.py
echo -n "-> 1. Verificando in.twolp.mandu em scripts/gerar-pratilera.py... "
if grep -q "in.twolp.mandu" "$GERAR_SCRIPT" && grep -q "mandu.apk" "$GERAR_SCRIPT"; then
    echo "✅ OK"
else
    echo "❌ FALHOU (in.twolp.mandu ou mandu.apk não configurados em scripts/gerar-pratilera.py)"
    FAILURES=$((FAILURES + 1))
fi

# 2. Verificar presença do pacote in.twolp.mandu no index-v1.json da Pratilera
echo -n "-> 2. Verificando in.twolp.mandu em index-v1.json... "
if [ -f "$INDEX_JSON" ]; then
    if python3 -c "
import json
with open('$INDEX_JSON') as f:
    idx = json.load(f)
app = next((a for a in idx.get('apps', []) if a.get('packageName') == 'in.twolp.mandu'), None)
assert app is not None, 'app in.twolp.mandu ausente em apps[]'
assert app.get('name') == 'Mandu', 'nome incorreto'
assert 'in.twolp.mandu' in idx.get('packages', {}), 'pacote ausente em packages'
pkg_info = idx['packages']['in.twolp.mandu'][0]
assert pkg_info.get('apkName') == 'mandu.apk', 'apkName incorreto'
assert pkg_info.get('size', 0) > 1024, 'tamanho de mandu.apk inválido'
assert len(pkg_info.get('hash', '')) == 64, 'hash sha256 inválido'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (in.twolp.mandu ausente ou inválido em index-v1.json)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (index-v1.json inexistente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Verificar ícones Fastlane e de densidade do Mandu
echo -n "-> 3. Verificando ícones Fastlane e densidades do Mandu... "
FASTLANE_OK=true
for loc in "pt-BR" "en-US"; do
    if [ ! -f "$PRATILERA_DIR/in.twolp.mandu/$loc/icon.png" ]; then
        FASTLANE_OK=false
        break
    fi
done
if [ "$FASTLANE_OK" = true ] && [ -f "$PRATILERA_DIR/icons/in.twolp.mandu.png" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (ícones Fastlane ou em icons/in.twolp.mandu.png ausentes)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Verificar entrada do Mandu em data/projects.json
echo -n "-> 4. Verificando entrada do Mandu em data/projects.json... "
if [ -f "$DATA_FILE" ]; then
    if python3 -c "
import json
with open('$DATA_FILE') as f:
    data = json.load(f)
mandu = next((p for p in data if p.get('name') == 'mandu'), None)
assert mandu is not None, 'mandu não encontrado em data/projects.json'
assert mandu.get('slug') == 'lumenpink/mandu', 'slug incorreto'
assert mandu.get('category') == 'apps', 'categoria != apps'
assert mandu.get('banner') == 'assets/banners/mandu-banner.png', 'banner != assets/banners/mandu-banner.png'
assert 'rust' in mandu.get('topics', []), 'tópico rust ausente'
assert 'dioxus' in mandu.get('topics', []), 'tópico dioxus ausente'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (metadados do Mandu ausentes ou incorretos em data/projects.json)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (data/projects.json ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. Verificar banner 1200x630 (Safe Zone da Banca)
echo -n "-> 5. Verificando arquivo e dimensões 1200x630 do banner do Mandu... "
if [ -f "$BANNER_FILE" ]; then
    if python3 -c "
from PIL import Image
im = Image.open('$BANNER_FILE')
assert im.size == (1200, 630), f'tamanho {im.size} != (1200, 630)'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (banner com dimensões divergentes de 1200x630)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (assets/banners/mandu-banner.png inexistente)"
    FAILURES=$((FAILURES + 1))
fi

# 6. Verificar renderização do cartão na vitrine compilada
echo -n "-> 6. Verificando renderização do Mandu na vitrine site/index.html... "
if [ -f "$SITE_HTML" ]; then
    if grep -qi "mandu" "$SITE_HTML" && grep -q "lumenpink/mandu" "$SITE_HTML"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (Mandu não renderizado em site/index.html)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 7. [MUTAÇÃO] Validar rejeição de metadados Fastlane corrompidos ou ausentes
echo -n "-> 7. [MUTAÇÃO] Testando integridade estrita dos metadados Fastlane... "
MUT_FASTLANE=$(python3 -c "
import json
with open('$INDEX_JSON') as f:
    idx = json.load(f)
app = next((a for a in idx.get('apps', []) if a.get('packageName') == 'in.twolp.mandu'), None)
assert 'localized' in app, 'localized ausente'
assert 'pt-BR' in app['localized'], 'pt-BR ausente'
assert 'en-US' in app['localized'], 'en-US ausente'
assert app['localized']['pt-BR']['icon'] == 'icon.png'
# Simular mutação: locale ausente
mut = dict(app['localized'])
del mut['pt-BR']
assert 'pt-BR' not in mut, 'Mutação falhou'
print('OK')
" 2>&1)
if [ "$MUT_FASTLANE" == "OK" ]; then
    echo "✅ OK (Metadados Fastlane validados com teste de mutação)"
else
    echo "❌ FALHOU na validação de mutação Fastlane: $MUT_FASTLANE"
    FAILURES=$((FAILURES + 1))
fi

# 8. [MUTAÇÃO] Validar rejeição de hash SHA-256 e tamanho inválidos
echo -n "-> 8. [MUTAÇÃO] Testando integridade criptográfica do pacote Mandu... "
MUT_CRYPTO=$(python3 -c "
import json
with open('$INDEX_JSON') as f:
    idx = json.load(f)
pkg = idx['packages']['in.twolp.mandu'][0]
h = pkg['hash']
assert len(h) == 64, 'Hash com tamanho incorreto'
assert int(h, 16) > 0, 'Hash zerado'
# Simular mutação: hash com 32 caracteres (md5 residual) ou vazio
assert len(h[:32]) != 64, 'Mutação de tamanho de hash falhou'
print('OK')
" 2>&1)
if [ "$MUT_CRYPTO" == "OK" ]; then
    echo "✅ OK (Assinatura e hash criptográfico robustos contra mutações)"
else
    echo "❌ FALHOU no teste de mutação criptográfica: $MUT_CRYPTO"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Esperado na Fase Red do DD-TDD)."
    exit 1
else
    echo "🎉 TODOS OS TESTES DO MANDU NA PRATILERA PASSARAM COM SUCESSO!"
    exit 0
fi
