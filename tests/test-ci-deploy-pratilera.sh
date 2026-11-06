#!/usr/bin/env bash
set -euo pipefail

echo "=== Test: Verificar regeneração da Pratilera no deploy-site do CI ==="

CI_FILE=".forgejo/workflows/ci.yml"

if [ ! -f "$CI_FILE" ]; then
  echo "❌ ERRO: Arquivo $CI_FILE não encontrado."
  exit 1
fi

# Extrai o bloco do job deploy-site
DEPLOY_BLOCK=$(awk '/deploy-site:/{flag=1; next} flag && /^[a-zA-Z0-9_-]+:/{flag=0} flag' "$CI_FILE")

# Verifica se python3 scripts/gerar-pratilera.py está presente no job deploy-site
if ! echo "$DEPLOY_BLOCK" | grep -q "python3 scripts/gerar-pratilera.py"; then
  echo "❌ ERRO: O job deploy-site não executa 'python3 scripts/gerar-pratilera.py' antes do deploy."
  exit 1
fi

# Verifica se ./build.sh está presente no job deploy-site
if ! echo "$DEPLOY_BLOCK" | grep -q "./build.sh"; then
  echo "❌ ERRO: O job deploy-site não executa './build.sh' antes do deploy."
  exit 1
fi

echo "✓ Sucesso: job deploy-site regenera o catálogo da Pratilera e executa build antes do deploy."
exit 0
