#!/usr/bin/env bash
set -euo pipefail

echo "== Validação de Estrutura GOST v3 =="
if [ -f "GOSTVER" ]; then
    echo "FALHA: GOSTVER legado ainda presente na raiz"
    exit 1
fi

if [ ! -f ".gost/GOST.md" ]; then
    echo "FALHA: .gost/GOST.md nao encontrado"
    exit 1
fi

if [ ! -f ".gost/delivery.toml" ]; then
    echo "FALHA: .gost/delivery.toml nao encontrado"
    exit 1
fi

echo "Conformidade basica ok."
