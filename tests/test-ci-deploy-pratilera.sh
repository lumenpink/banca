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

echo "-> [MUTAÇÃO] Testando sensibilidade a remoção do script gerar-pratilera no deploy..."
MUTATED_BLOCK=$(echo "$DEPLOY_BLOCK" | sed 's/python3 scripts\/gerar-pratilera.py//g')
if echo "$MUTATED_BLOCK" | grep -q "python3 scripts/gerar-pratilera.py"; then
  echo "❌ ERRO: Mutante sobreviveu!"
  exit 1
else
  echo "✓ OK (Mutação detectada com precisão)"
fi

echo "-> [MUTAÇÃO] Testando sensibilidade a remoção do build.sh no deploy..."
MUTATED_BLOCK_BUILD=$(echo "$DEPLOY_BLOCK" | sed 's/\.\/build\.sh//g')
if echo "$MUTATED_BLOCK_BUILD" | grep -q "./build.sh"; then
  echo "❌ ERRO: Mutante de build sobreviveu!"
  exit 1
else
  echo "✓ OK (Mutação de build detectada com precisão)"
fi

echo "✓ Sucesso: job deploy-site regenera o catálogo da Pratilera e executa build antes do deploy."
exit 0
