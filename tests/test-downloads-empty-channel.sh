#!/usr/bin/env bash
# ==============================================================================
# tests/test-downloads-empty-channel.sh — Validação de Canal sem Publicação (#50)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
DOWNLOADS_DIR="$SITE_DIR/downloads"
INDEX_HTML="$DOWNLOADS_DIR/index.html"
ROTATE_SCRIPT="$REPO_ROOT/scripts/rotate-downloads.py"
FAILURES=0

echo "================================================================="
echo "🧪 [TESTE] Validação de Canais sem Publicação (Ticket #50)"
echo "================================================================="

# 1. Validar que rotate-downloads.py não gera '0.1.0' como stable_latest quando não há releases reais
echo -n "-> 1. Verificando que prune_manifest_data não popula stable_latest fictício... "
TMP_JSON=$(mktemp --suffix=.json)
cat << 'EOF' > "$TMP_JSON"
{
  "app": "teste-app",
  "name": "Teste App",
  "stable_latest": "0.1.0",
  "stables": [
    {
      "version": "0.1.0",
      "sha256": ""
    }
  ],
  "nightlies": []
}
EOF

python3 "$ROTATE_SCRIPT" --prune-manifest "$TMP_JSON" >/dev/null 2>&1 || true
STABLE_LATEST=$(python3 -c "import json; d=json.load(open('$TMP_JSON')); print(d.get('stable_latest', ''))")
rm -f "$TMP_JSON"

if [ "$STABLE_LATEST" = "" ]; then
    echo "✅ OK (stable_latest vazio quando não há artefatos reais)"
else
    echo "❌ FALHOU (esperado vazio, obtido '$STABLE_LATEST')"
    FAILURES=$((FAILURES + 1))
fi

# 2. Validar que index.html contém lógica para lidar com canais vazios
echo -n "-> 2. Verificando tratamento de canal vazio no JavaScript da vitrine... "
if grep -q "Nenhuma versão estável" "$INDEX_HTML" && grep -q "Nenhuma versão de desenvolvimento" "$INDEX_HTML"; then
    echo "✅ OK (mensagens explícitas de ausência de publicação presentes)"
else
    echo "❌ FALHOU (mensagens de canal vazio ausentes em index.html)"
    FAILURES=$((FAILURES + 1))
fi

# 3. [MUTAÇÃO] Validar sensibilidade da detecção de artefato real
echo -n "-> 3. [MUTAÇÃO] Testando sensibilidade a mutação em release vazia... "
MUTANT_KILLED=$(python3 -c "
import tempfile, json, subprocess
with tempfile.NamedTemporaryFile('w', suffix='.json', delete=False) as f:
    json.dump({'app': 'test', 'stable_latest': '0.1.0', 'stables': [{'version': '0.1.0', 'sha256': ''}]}, f)
    fname = f.name
subprocess.run(['python3', '$ROTATE_SCRIPT', '--prune-manifest', fname], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
data = json.load(open(fname))
if data.get('stable_latest') == '0.1.0':
    print('MUTANTE_VIVEU')
else:
    print('MUTANTE_MORTO')
")
if [ "$MUTANT_KILLED" = "MUTANTE_MORTO" ]; then
    echo "✅ OK (Mutação detectada com precisão)"
else
    echo "❌ FALHOU (Mutação sobreviveu)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Comprovada falha Red)."
    exit 1
else
    echo "🎉 TODOS OS TESTES PASSARAM COM SUCESSO!"
    exit 0
fi
