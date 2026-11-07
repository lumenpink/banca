#!/usr/bin/env bash
# ==============================================================================
# 🧪 [TESTE] Esteira de Dispatch Serializada e Orquestração de Deploy (#57)
# ==============================================================================
set -euo pipefail

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift
    echo -n "-> $desc... "
    if "$@"; then
        echo "✅ OK"
        PASS=$((PASS + 1))
    else
        echo "❌ FALHOU"
        FAIL=$((FAIL + 1))
    fi
}

echo "================================================================="
echo "🧪 [TESTE] Orquestração do Pipeline e Dispatch (#57)"
echo "================================================================="

SCRIPT_PIPELINE="scripts/banca_pipeline.py"
WORKFLOW_DISPATCH=".forgejo/workflows/dispatch.yml"

check "1. Verificando existência de $SCRIPT_PIPELINE" test -f "$SCRIPT_PIPELINE"

check "2. Verificando existência do workflow $WORKFLOW_DISPATCH" test -f "$WORKFLOW_DISPATCH"

check "3. Verificando configuração de concorrência serial no workflow" grep -q "group: \"update-catalog\"" "$WORKFLOW_DISPATCH"

check "4. Verificando cancel-in-progress falso para fila ordenada" grep -q "cancel-in-progress: false" "$WORKFLOW_DISPATCH"

check "5. Verificando evento repository_dispatch configurado" grep -q "repository_dispatch:" "$WORKFLOW_DISPATCH"

check "6. Executando suíte interna de testes unitários em $SCRIPT_PIPELINE" python3 -m unittest "$SCRIPT_PIPELINE"

# Teste de mutação 1: Pipeline aborta e abre issue em caso de falha de auditoria
check "7. [MUTAÇÃO] Testando fluxo de aborto e emissão de ticket em falha" python3 -c '
from unittest.mock import MagicMock
import scripts.banca_pipeline as bp

mock_audit = MagicMock()
mock_audit.audit_new_release.return_value = (False, ["Arquivo tachinha.tar.gz retornou 404"])

mock_storage = MagicMock()
mock_storage.create_forge_issue.return_value = (True, {"id": 123})

payload = {
    "app": "tachinha",
    "channel": "stable",
    "version": "0.4.1",
    "commit": "a1b2c3d4",
    "repo_slug": "lumen/tachinha",
    "run_id": "1842",
    "assets": []
}

success, msg = bp.run_pipeline(
    payload=payload,
    catalog_path="site/downloads/catalog.json",
    forge_url="https://gambi.2lp.in",
    forge_token="fake-token",
    audit_module=mock_audit,
    storage_module=mock_storage
)

assert not success, "Pipeline deveria ter falhado!"
assert "404" in msg, f"Mensagem esperada de erro não encontrada: {msg}"
mock_storage.create_forge_issue.assert_called_once()
'

# Teste de mutação 2: Pipeline de sucesso atualiza catálogo sem emitir issue
check "8. [MUTAÇÃO] Testando fluxo completo de sucesso sem emissão de issue" python3 -c '
import tempfile
import json
from unittest.mock import MagicMock
import scripts.banca_pipeline as bp

mock_audit = MagicMock()
mock_audit.audit_new_release.return_value = (True, [])
mock_audit.audit_active_history.return_value = (True, [])

mock_storage = MagicMock()

payload = {
    "app": "tachinha",
    "channel": "stable",
    "version": "0.4.1",
    "commit": "a1b2c3d4",
    "repo_slug": "lumen/tachinha",
    "run_id": "1842",
    "assets": [
        {
            "target": "linux-x86_64",
            "type": "archive",
            "format": "tar.gz",
            "filename": "tachinha-0.4.1-linux-x86_64.tar.gz",
            "alias": "tachinha-latest-linux-x86_64.tar.gz",
            "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        }
    ]
}

mock_catalog = {
    "$schema": "./catalog.schema.json",
    "updated_at": "2026-11-06T18:00:00Z",
    "apps": {
        "tachinha": {
            "metadata": {"name": "Tachinha"},
            "channels": {
                "stable": {"label": "Versão Recomendada", "latest_version": "0.4.0", "versions": []},
                "dev": {"label": "Versão Experimental", "latest_version": "", "versions": []}
            }
        }
    }
}

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump(mock_catalog, f)
    catalog_path = f.name

success, msg = bp.run_pipeline(
    payload=payload,
    catalog_path=catalog_path,
    forge_url="https://gambi.2lp.in",
    forge_token="fake-token",
    audit_module=mock_audit,
    storage_module=mock_storage
)

assert success, f"Pipeline deveria ter sucedido: {msg}"
mock_storage.create_forge_issue.assert_not_called()

# Conferir atualização do catálogo
with open(catalog_path, "r") as f:
    updated = json.load(f)
assert updated["apps"]["tachinha"]["channels"]["stable"]["latest_version"] == "0.4.1"
'

echo "================================================================="
if [ "$FAIL" -gt 0 ]; then
    echo "💥 $FAIL TESTE(S) FALHARAM."
    exit 1
fi
echo "🎉 Todos os testes de orquestração do pipeline passaram!"
