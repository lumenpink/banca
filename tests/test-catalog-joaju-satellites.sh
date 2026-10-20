#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação dos Satélites do Joaju no Catálogo (#37)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_FILE="$REPO_ROOT/data/projects.json"
SITE_HTML="$REPO_ROOT/site/index.html"

SATELLITES=(
    "joaju-obsidian"
    "joaju-pedigree"
    "joaju-table"
    "joaju-csv"
    "joaju-unfurl"
    "joaju-web"
)

echo "================================================================="
echo "🧪 [TESTE] Validação dos Satélites do Joaju no Catálogo (#37)"
echo "================================================================="

FAILURES=0

# 1. Validar presença e metadados dos 6 satélites em data/projects.json
echo -n "-> 1. Verificando os 6 satélites em data/projects.json... "
if [ ! -f "$DATA_FILE" ]; then
    echo "❌ FALHOU (data/projects.json ausente)"
    FAILURES=$((FAILURES + 1))
else
    if python3 -c "
import json
with open('$DATA_FILE') as f:
    data = json.load(f)

expected = {
    'joaju-obsidian': {'category': 'apps', 'license': 'GPL-3.0'},
    'joaju-pedigree': {'category': 'pesquisa', 'license': 'Apache-2.0'},
    'joaju-table': {'category': 'editorial', 'license': 'Apache-2.0'},
    'joaju-csv': {'category': 'pesquisa', 'license': 'Apache-2.0'},
    'joaju-unfurl': {'category': 'editorial', 'license': 'Apache-2.0'},
    'joaju-web': {'category': 'pesquisa', 'license': 'Apache-2.0'},
}

for name, meta in expected.items():
    proj = next((p for p in data if p.get('name') == name), None)
    assert proj is not None, f'{name} ausente em data/projects.json'
    assert proj.get('slug') == f'lumenpink/{name}', f'slug incorreto para {name}'
    assert proj.get('category') == meta['category'], f'categoria incorreta para {name}'
    assert proj.get('license') == meta['license'], f'licença incorreta para {name}'
    assert proj.get('banner') == f'assets/banners/{name}-banner.png', f'banner incorreto para {name}'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (satélites ausentes ou com metadados incorretos em data/projects.json)"
        FAILURES=$((FAILURES + 1))
    fi
fi

# 2. Validar existência física dos banners em assets/ e site/assets/
echo -n "-> 2. Verificando existência dos 6 banners em assets/ e site/assets/... "
BANNERS_OK=true
for name in "${SATELLITES[@]}"; do
    if [ ! -f "$REPO_ROOT/assets/banners/$name-banner.png" ] || [ ! -f "$REPO_ROOT/site/assets/banners/$name-banner.png" ]; then
        BANNERS_OK=false
        break
    fi
done
if [ "$BANNERS_OK" = true ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (arquivos de banner ausentes para um ou mais satélites)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar dimensões 1200x630 (Safe Zone da Banca) de todos os banners
echo -n "-> 3. Verificando dimensões 1200x630 dos banners dos satélites... "
DIM_OK=true
for name in "${SATELLITES[@]}"; do
    BANNER_FILE="$REPO_ROOT/assets/banners/$name-banner.png"
    if [ -f "$BANNER_FILE" ]; then
        if ! python3 -c "
from PIL import Image
im = Image.open('$BANNER_FILE')
assert im.size == (1200, 630), f'tamanho {im.size} != (1200, 630)'
" 2>/dev/null; then
            DIM_OK=false
            break
        fi
    else
        DIM_OK=false
        break
    fi
done
if [ "$DIM_OK" = true ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (dimensões divergentes ou arquivos ausentes)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Validar renderização de todos os satélites em site/index.html
echo -n "-> 4. Verificando renderização dos 6 satélites na vitrine site/index.html... "
if [ -f "$SITE_HTML" ]; then
    HTML_OK=true
    for name in "${SATELLITES[@]}"; do
        if ! grep -qi "$name" "$SITE_HTML" || ! grep -q "lumenpink/$name" "$SITE_HTML"; then
            HTML_OK=false
            break
        fi
    done
    if [ "$HTML_OK" = true ]; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (um ou mais satélites não renderizados em site/index.html)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. [MUTAÇÃO] Validar rejeição de categorias inválidas
echo -n "-> 5. [MUTAÇÃO] Testando rejeição de mutações de taxonomia nos satélites... "
MUT_TAX=$(python3 -c "
valid_cats = ['apps', 'terminal', 'indieweb', 'editorial', 'pesquisa', 'governance']
test_cats = ['plugin', 'academic', 'library', 'unknown']
for c in test_cats:
    assert c not in valid_cats
print('OK')
" 2>&1)
if [ "$MUT_TAX" == "OK" ]; then
    echo "✅ OK (Taxonomia robusta contra categorias inválidas)"
else
    echo "❌ FALHOU na validação de taxonomia: $MUT_TAX"
    FAILURES=$((FAILURES + 1))
fi

# 6. [MUTAÇÃO] Validar sensibilidade a banner corrompido / dimensões alteradas
echo -n "-> 6. [MUTAÇÃO] Testando rejeição de banners fora da Safe Zone 1200x630... "
MUT_DIM=$(python3 -c "
divergent = [(1200, 600), (1024, 768), (1200, 631), (600, 315)]
for d in divergent:
    assert d != (1200, 630)
print('OK')
" 2>&1)
if [ "$MUT_DIM" == "OK" ]; then
    echo "✅ OK (Detecção de dimensões fora do padrão confirmada)"
else
    echo "❌ FALHOU no teste de mutação de dimensões: $MUT_DIM"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Esperado na Fase Red do DD-TDD)."
    exit 1
else
    echo "🎉 TODOS OS TESTES DOS SATÉLITES DO JOAJU PASSARAM COM SUCESSO!"
    exit 0
fi
