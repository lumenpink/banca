#!/usr/bin/env bash
# ==============================================================================
# tests/test-catalog-schema.sh — Validação do Schema e Catálogo Unificado (#54)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
DOWNLOADS_DIR="$SITE_DIR/downloads"
CATALOG_FILE="$DOWNLOADS_DIR/catalog.json"
SCHEMA_FILE="$DOWNLOADS_DIR/catalog.schema.json"
VALIDATOR_SCRIPT="$REPO_ROOT/scripts/banca_catalog.py"
FAILURES=0

echo "================================================================="
echo "🧪 [TESTE] Validação do Schema Declarativo e Catálogo Unificado (#54)"
echo "================================================================="

# 1. Verificar existência do catalog.schema.json
echo -n "-> 1. Verificando existência de site/downloads/catalog.schema.json... "
if [ -f "$SCHEMA_FILE" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (arquivo $SCHEMA_FILE ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 2. Verificar existência do módulo validador/gerador banca_catalog.py
echo -n "-> 2. Verificando existência de scripts/banca_catalog.py... "
if [ -f "$VALIDATOR_SCRIPT" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (arquivo $VALIDATOR_SCRIPT ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar catalog.json contra o catalog.schema.json
echo -n "-> 3. Validando conformidade estrita de catalog.json com o schema... "
if [ -f "$CATALOG_FILE" ] && [ -f "$SCHEMA_FILE" ] && [ -f "$VALIDATOR_SCRIPT" ]; then
    if python3 "$VALIDATOR_SCRIPT" --validate "$CATALOG_FILE" --schema "$SCHEMA_FILE"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (catalog.json não está em conformidade com o schema)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivos necessários ausentes)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Validar contagem mínima de apps e canais stable/dev
echo -n "-> 4. Validando presença de canais stable e dev em cada aplicação... "
if [ -f "$CATALOG_FILE" ]; then
    APP_COUNT=$(python3 -c "
import json, sys
try:
    with open('$CATALOG_FILE') as f:
        data = json.load(f)
    apps = data.get('apps', {})
    assert isinstance(apps, dict), 'apps deve ser um dicionário'
    assert len(apps) >= 16, f'Menos de 16 apps encontrados ({len(apps)})'
    for slug, app_data in apps.items():
        assert 'metadata' in app_data, f'{slug} sem metadata'
        assert 'channels' in app_data, f'{slug} sem channels'
        channels = app_data['channels']
        assert 'stable' in channels, f'{slug} sem canal stable'
        assert 'dev' in channels, f'{slug} sem canal dev'
        assert channels['stable'].get('label') == 'Versão Recomendada', f'{slug} label stable incorreto'
        assert channels['dev'].get('label') == 'Versão Experimental', f'{slug} label dev incorreto'
        assert channels['stable'].get('history_limit') == 5, f'{slug} history_limit stable != 5'
        assert channels['dev'].get('history_limit') == 10, f'{slug} history_limit dev != 10'
    print(len(apps))
except Exception as e:
    print(f'ERRO: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null || true)

    if [ -n "$APP_COUNT" ] && [ "$APP_COUNT" -ge 16 ]; then
        echo "✅ OK ($APP_COUNT apps validados com sucesso)"
    else
        echo "❌ FALHOU (estrutura de canais inválida ou menos de 16 apps)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (arquivo $CATALOG_FILE ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. [MUTAÇÃO] Validar sensibilidade a ausência de canal dev
echo -n "-> 5. [MUTAÇÃO] Testando sensibilidade a app sem canal dev... "
if [ -f "$VALIDATOR_SCRIPT" ] && [ -f "$SCHEMA_FILE" ] && [ -f "$CATALOG_FILE" ]; then
    MUTANT_STATUS=$(python3 -c "
import json, subprocess, tempfile
with open('$CATALOG_FILE') as f:
    d = json.load(f)
if 'tachinha' in d.get('apps', {}):
    del d['apps']['tachinha']['channels']['dev']
elif d.get('apps'):
    first_key = list(d['apps'].keys())[0]
    del d['apps'][first_key]['channels']['dev']
with tempfile.NamedTemporaryFile('w', suffix='.json') as tmp:
    json.dump(d, tmp)
    tmp.flush()
    res = subprocess.run(['python3', '$VALIDATOR_SCRIPT', '--validate', tmp.name, '--schema', '$SCHEMA_FILE'], capture_output=True)
    if res.returncode != 0:
        print('MUTANTE_MORTO')
    else:
        print('MUTANTE_VIVEU')
" 2>/dev/null || true)

    if [ "$MUTANT_STATUS" = "MUTANTE_MORTO" ]; then
        echo "✅ OK (Mutação detectada com precisão)"
    else
        echo "❌ FALHOU (Mutação não detectada)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (ambiente de teste incompleto)"
    FAILURES=$((FAILURES + 1))
fi

# 6. [MUTAÇÃO] Validar sensibilidade a hash SHA-256 truncado/inválido
echo -n "-> 6. [MUTAÇÃO] Testando sensibilidade a hash SHA-256 inválido... "
if [ -f "$VALIDATOR_SCRIPT" ] && [ -f "$SCHEMA_FILE" ] && [ -f "$CATALOG_FILE" ]; then
    MUTANT_SHA_STATUS=$(python3 -c "
import json, subprocess, tempfile
with open('$CATALOG_FILE') as f:
    d = json.load(f)
mutated = False
for app, data in d.get('apps', {}).items():
    for ch in ['stable', 'dev']:
        for v in data.get('channels', {}).get(ch, {}).get('versions', []):
            for a in v.get('assets', []):
                a['sha256'] = 'invalid_hash_too_short'
                mutated = True
                break
            if mutated: break
        if mutated: break
    if mutated: break

with tempfile.NamedTemporaryFile('w', suffix='.json') as tmp:
    json.dump(d, tmp)
    tmp.flush()
    res = subprocess.run(['python3', '$VALIDATOR_SCRIPT', '--validate', tmp.name, '--schema', '$SCHEMA_FILE'], capture_output=True)
    if res.returncode != 0:
        print('MUTANTE_MORTO')
    else:
        print('MUTANTE_VIVEU')
" 2>/dev/null || true)

    if [ "$MUTANT_SHA_STATUS" = "MUTANTE_MORTO" ]; then
        echo "✅ OK (Mutação detectada com precisão)"
    else
        echo "❌ FALHOU (Mutação não detectada)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (ambiente de teste incompleto)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -gt 0 ]; then
    echo "❌ Teste falhou com $FAILURES erro(s)."
    exit 1
fi

echo "🎉 Todos os testes do catálogo e schema foram aprovados com sucesso!"
exit 0
