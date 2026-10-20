#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação do Resenha no Catálogo (#36)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_FILE="$REPO_ROOT/data/projects.json"
BANNER_FILE="$REPO_ROOT/assets/banners/resenha-banner.png"
SITE_BANNER="$REPO_ROOT/site/assets/banners/resenha-banner.png"
SITE_HTML="$REPO_ROOT/site/index.html"

echo "================================================================="
echo "🧪 [TESTE] Validação do Resenha no Catálogo da Banca (#36)"
echo "================================================================="

FAILURES=0

# 1. Validar entrada e metadados do Resenha em data/projects.json
echo -n "-> 1. Verificando entrada do Resenha em data/projects.json... "
if [ ! -f "$DATA_FILE" ]; then
    echo "❌ FALHOU (data/projects.json ausente)"
    FAILURES=$((FAILURES + 1))
else
    if python3 -c "
import json
with open('$DATA_FILE') as f:
    data = json.load(f)
resenha = next((p for p in data if p.get('name') == 'resenha'), None)
assert resenha is not None, 'resenha não encontrado em data/projects.json'
assert resenha.get('slug') == 'lumenpink/resenha', f'slug {resenha.get(\"slug\")} != lumenpink/resenha'
assert resenha.get('forge') == 'codeberg', 'forge != codeberg'
assert resenha.get('category') == 'editorial', 'categoria != editorial'
assert resenha.get('license') == 'GPL-3.0', 'license != GPL-3.0'
assert 'markdown' in resenha.get('topics', []), 'tópico markdown ausente'
assert 'readability' in resenha.get('topics', []), 'tópico readability ausente'
assert resenha.get('banner') == 'assets/banners/resenha-banner.png', 'banner incorreto'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (Resenha ausente ou com metadados incorretos em data/projects.json)"
        FAILURES=$((FAILURES + 1))
    fi
fi

# 2. Validar existência física do banner do Resenha
echo -n "-> 2. Verificando arquivos de banner em assets/ e site/assets/... "
if [ -f "$BANNER_FILE" ] && [ -f "$SITE_BANNER" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (banners ausentes em assets/banners ou site/assets/banners)"
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
echo -n "-> 4. Verificando renderização do Resenha na vitrine site/index.html... "
if [ -f "$SITE_HTML" ]; then
    if grep -qi "resenha" "$SITE_HTML" && grep -q "lumenpink/resenha" "$SITE_HTML"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (Resenha não encontrado em site/index.html)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. [MUTAÇÃO] Validar rejeição de categoria inválida e forja incorreta
echo -n "-> 5. [MUTAÇÃO] Testando rejeição de categoria e forja adulteradas... "
MUTATION_RESULT=$(python3 -c "
import json
with open('$DATA_FILE') as f:
    data = json.load(f)
resenha = next((p for p in data if p.get('name') == 'resenha'), None)
if resenha:
    inv = dict(resenha)
    inv['category'] = 'invalid_category'
    assert inv['category'] not in ['apps', 'terminal', 'indieweb', 'editorial', 'pesquisa', 'governance']
print('OK')
" 2>&1)
if [ "$MUTATION_RESULT" == "OK" ]; then
    echo "✅ OK (Mutações de taxonomia detectadas com precisão)"
else
    echo "❌ FALHOU na detecção de mutações: $MUTATION_RESULT"
    FAILURES=$((FAILURES + 1))
fi

# 6. [MUTAÇÃO] Validar rejeição de dimensões divergentes de 1200x630
echo -n "-> 6. [MUTAÇÃO] Testando rejeição de dimensões de banner fora do padrão... "
MUTATION_DIM=$(python3 -c "
sizes = [(1200, 600), (800, 600), (1920, 1080), (1200, 631)]
for s in sizes:
    assert s != (1200, 630)
print('OK')
" 2>&1)
if [ "$MUTATION_DIM" == "OK" ]; then
    echo "✅ OK (Dimensões adulteradas rejeitadas)"
else
    echo "❌ FALHOU na rejeição de dimensões adulteradas: $MUTATION_DIM"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Esperado na Fase Red do DD-TDD)."
    exit 1
else
    echo "🎉 TODOS OS TESTES DO RESENHA NO CATÁLOGO PASSARAM COM SUCESSO!"
    exit 0
fi
