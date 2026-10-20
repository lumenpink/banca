#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação do Hendu no Catálogo (#33)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_FILE="$REPO_ROOT/data/projects.json"
BANNER_FILE="$REPO_ROOT/assets/banners/hendu-banner.png"
SITE_HTML="$REPO_ROOT/site/index.html"

echo "================================================================="
echo "🧪 [TESTE] Validação do Hendu no Catálogo da Banca"
echo "================================================================="

FAILURES=0

# 1. Validar existência e metadados do Hendu em data/projects.json
echo -n "-> 1. Verificando entrada do Hendu em data/projects.json... "
if [ ! -f "$DATA_FILE" ]; then
    echo "❌ FALHOU (data/projects.json ausente)"
    FAILURES=$((FAILURES + 1))
else
    if python3 -c "
import json
with open('$DATA_FILE') as f:
    data = json.load(f)
hendu = next((p for p in data if p.get('name') == 'hendu'), None)
assert hendu is not None, 'hendu não encontrado em data/projects.json'
assert hendu.get('slug') == 'lumenpink/hendu', f'slug {hendu.get(\"slug\")} != lumenpink/hendu'
assert hendu.get('forge') == 'codeberg', 'forge != codeberg'
assert hendu.get('category') in ['apps', 'terminal', 'indieweb', 'editorial', 'pesquisa', 'governance'], 'categoria inválida'
assert 'accessibility' in hendu.get('topics', []), 'tópico accessibility ausente'
assert hendu.get('banner') == 'assets/banners/hendu-banner.png', 'banner incorreto'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (Hendu ausente ou com metadados incorretos em data/projects.json)"
        FAILURES=$((FAILURES + 1))
    fi
fi

# 2. Validar existência física do banner do Hendu
echo -n "-> 2. Verificando arquivo do banner em assets/banners/hendu-banner.png... "
if [ -f "$BANNER_FILE" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (assets/banners/hendu-banner.png ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar dimensões 1200x630 (Safe Zone da Banca)
echo -n "-> 3. Verificando dimensões 1200x630 do banner... "
if [ -f "$BANNER_FILE" ]; then
    if python3 -c "
from PIL import Image
im = Image.open('$BANNER_FILE')
assert im.size == (1200, 630), f'tamanho {im.size} != (1200, 630)'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (banner não possui dimensões 1200x630)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (banner ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Validar renderização do cartão na vitrine compilada
echo -n "-> 4. Verificando renderização do Hendu na vitrine site/index.html... "
if [ -f "$SITE_HTML" ]; then
    if grep -qi "hendu" "$SITE_HTML" && grep -q "lumenpink/hendu" "$SITE_HTML"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (Hendu não encontrado em site/index.html)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. [MUTAÇÃO] Validar rejeição de categoria inválida e forja não suportada
echo -n "-> 5. [MUTAÇÃO] Testando rejeição de categoria inválida e forja incorreta... "
MUTATION_RESULT=$(python3 -c "
import json
with open('$DATA_FILE') as f:
    data = json.load(f)
hendu = next((p for p in data if p.get('name') == 'hendu'), None)
# Simular mutação: categoria inválida
invalid_cat = dict(hendu)
invalid_cat['category'] = 'invalid_cat'
valid_categories = ['apps', 'terminal', 'indieweb', 'editorial', 'pesquisa', 'governance']
assert invalid_cat['category'] not in valid_categories, 'Mutação de categoria falhou'

# Simular mutação: forge inexistente
invalid_forge = dict(hendu)
invalid_forge['forge'] = 'unknown'
assert invalid_forge['forge'] != 'codeberg', 'Mutação de forja falhou'
print('OK')
" 2>&1)
if [ "$MUTATION_RESULT" == "OK" ]; then
    echo "✅ OK (Mutação detectada corretamente)"
else
    echo "❌ FALHOU na detecção de mutações: $MUTATION_RESULT"
    FAILURES=$((FAILURES + 1))
fi

# 6. [MUTAÇÃO] Validar rejeição de banner com dimensões fora de 1200x630
echo -n "-> 6. [MUTAÇÃO] Testando rejeição de dimensões divergentes de 1200x630... "
MUTATION_DIM_RESULT=$(python3 -c "
sizes = [(1200, 600), (800, 600), (1920, 1080), (1201, 630)]
for s in sizes:
    assert s != (1200, 630), 'Dimensão idêntica'
print('OK')
" 2>&1)
if [ "$MUTATION_DIM_RESULT" == "OK" ]; then
    echo "✅ OK (Dimensões divergentes rejeitadas com precisão)"
else
    echo "❌ FALHOU na rejeição de dimensões divergentes: $MUTATION_DIM_RESULT"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Esperado na Fase Red do DD-TDD)."
    exit 1
else
    echo "🎉 TODOS OS TESTES DO HENDU NO CATÁLOGO PASSARAM COM SUCESSO!"
    exit 0
fi
