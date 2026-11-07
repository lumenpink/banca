#!/usr/bin/env bash
# ==============================================================================
# 🧪 [TESTE] Auditoria Hermética de Rede e Integridade de Checksum (#55)
# Valida as Etapas 1 e 2 da especificação técnica de distribuição da Banca.
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
echo "🧪 [TESTE] Auditoria Hermética de Rede e Integridade (#55)"
echo "================================================================="

SCRIPT_AUDIT="scripts/banca_audit.py"

check "1. Verificando existência de $SCRIPT_AUDIT" test -f "$SCRIPT_AUDIT"

check "2. Executando suíte interna de testes unitários e de rede em $SCRIPT_AUDIT" python3 -m unittest "$SCRIPT_AUDIT"

# Teste de mutação 1: Rejeição estrita se ativo retornar 404
check "3. [MUTAÇÃO] Testando sensibilidade a artefato novo inexistente (404)" python3 -c '
import sys
from unittest.mock import MagicMock
import scripts.banca_audit as ba

payload = {
    "app": "tachinha",
    "channel": "stable",
    "version": "0.4.1",
    "commit": "a1b2c3d4",
    "repo_slug": "lumen/tachinha",
    "run_id": "1842",
    "assets": [
        {
            "filename": "tachinha-0.4.1-linux-x86_64.tar.gz",
            "alias": "tachinha-latest-linux-x86_64.tar.gz",
            "type": "archive",
            "format": "tar.gz",
            "target": "linux-x86_64",
            "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        }
    ]
}

# Mock onde arquivo versionado retorna 404
mock_client = MagicMock()
mock_client.head.return_value = 404
mock_client.get_text.return_value = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

ok, errors = ba.audit_new_release(payload, base_url="https://dist.2lp.in", http_client=mock_client)
assert not ok, "Deveria ter falhado com 404"
assert any("404" in err for err in errors), f"Erro esperado 404 não encontrado: {errors}"
'

# Teste de mutação 2: Rejeição estrita se checksum divergir
check "4. [MUTAÇÃO] Testando sensibilidade a divergência de hash SHA-256" python3 -c '
import sys
from unittest.mock import MagicMock
import scripts.banca_audit as ba

payload = {
    "app": "tachinha",
    "channel": "stable",
    "version": "0.4.1",
    "commit": "a1b2c3d4",
    "repo_slug": "lumen/tachinha",
    "run_id": "1842",
    "assets": [
        {
            "filename": "tachinha-0.4.1-linux-x86_64.tar.gz",
            "alias": "tachinha-latest-linux-x86_64.tar.gz",
            "type": "archive",
            "format": "tar.gz",
            "target": "linux-x86_64",
            "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        }
    ]
}

# Mock onde status é 200 mas hash diverge
mock_client = MagicMock()
mock_client.head.return_value = 200
mock_client.get_text.return_value = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff  tachinha-0.4.1-linux-x86_64.tar.gz"

ok, errors = ba.audit_new_release(payload, base_url="https://dist.2lp.in", http_client=mock_client)
assert not ok, "Deveria ter falhado com divergência de SHA-256"
assert any("SHA-256" in err for err in errors), f"Erro esperado SHA-256 não encontrado: {errors}"
'

# Teste de mutação 3: Rejeição estrita se link histórico ativo quebrar (404)
check "5. [MUTAÇÃO] Testando tolerância zero a link quebrado no histórico ativo" python3 -c '
import json
import tempfile
from unittest.mock import MagicMock
import scripts.banca_audit as ba

mock_catalog = {
    "apps": {
        "tachinha": {
            "channels": {
                "stable": {
                    "versions": [
                        {
                            "version": "0.4.0",
                            "assets": [
                                {
                                    "filename": "tachinha-0.4.0-linux-x86_64.tar.gz",
                                    "url": "https://dist.2lp.in/tachinha/stable/tachinha-0.4.0-linux-x86_64.tar.gz",
                                    "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                                }
                            ]
                        }
                    ]
                }
            }
        }
    }
}

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump(mock_catalog, f)
    catalog_path = f.name

mock_client = MagicMock()
mock_client.head.return_value = 404

ok, errors = ba.audit_active_history(
    catalog_path=catalog_path,
    app="tachinha",
    channel="stable",
    limit=5,
    http_client=mock_client
)
assert not ok, "Deveria ter falhado com histórico quebrado"
assert any("0.4.0" in err for err in errors), f"Erro esperado de histórico não encontrado: {errors}"
'

echo "================================================================="
if [ "$FAIL" -gt 0 ]; then
    echo "💥 $FAIL TESTE(S) FALHARAM."
    exit 1
fi
echo "🎉 Todos os testes de auditoria de rede e integridade passaram!"
