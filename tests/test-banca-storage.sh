#!/usr/bin/env bash
# ==============================================================================
# 🧪 [TESTE] Rotina de Purga no Bucket e Emissor de Issues na Forja (#56)
# Valida as Etapas 3 e 4 (Purga R2/S3 e abertura de tickets em caso de falha).
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
echo "🧪 [TESTE] Purga no Bucket e Emissor de Issues (#56)"
echo "================================================================="

SCRIPT_STORAGE="scripts/banca_storage.py"

check "1. Verificando existência de $SCRIPT_STORAGE" test -f "$SCRIPT_STORAGE"

check "2. Executando suíte interna de testes unitários em $SCRIPT_STORAGE" python3 -m unittest "$SCRIPT_STORAGE"

# Teste de mutação 1: Purga respeitando cota e preservando aliases
check "3. [MUTAÇÃO] Testando cálculo de purga preservando aliases canônicos" python3 -c '
import scripts.banca_storage as bs

# Lista de 7 versões estáveis (limite é 5)
objects = [
    "tachinha/stable/tachinha-latest-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-latest-linux-x86_64.tar.gz.sha256",
    "tachinha/stable/tachinha-0.4.7-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-0.4.7-linux-x86_64.tar.gz.sha256",
    "tachinha/stable/tachinha-0.4.6-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-0.4.6-linux-x86_64.tar.gz.sha256",
    "tachinha/stable/tachinha-0.4.5-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-0.4.5-linux-x86_64.tar.gz.sha256",
    "tachinha/stable/tachinha-0.4.4-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-0.4.4-linux-x86_64.tar.gz.sha256",
    "tachinha/stable/tachinha-0.4.3-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-0.4.3-linux-x86_64.tar.gz.sha256",
    "tachinha/stable/tachinha-0.4.2-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-0.4.2-linux-x86_64.tar.gz.sha256",
    "tachinha/stable/tachinha-0.4.1-linux-x86_64.tar.gz",
    "tachinha/stable/tachinha-0.4.1-linux-x86_64.tar.gz.sha256",
]

to_delete = bs.compute_purge_objects(objects, app="tachinha", channel="stable", limit=5)

# Aliases nunca podem ser deletados
assert not any("latest" in obj for obj in to_delete), "Aliases não podem ser deletados!"
# As 2 versões mais antigas (0.4.2 e 0.4.1) devem ser purgadas (total 4 arquivos)
assert any("0.4.1" in obj for obj in to_delete), "Versão 0.4.1 deveria estar na lista de purga"
assert any("0.4.2" in obj for obj in to_delete), "Versão 0.4.2 deveria estar na lista de purga"
assert not any("0.4.7" in obj for obj in to_delete), "Versão mais recente 0.4.7 não pode ser purgada"
'

# Teste de mutação 2: Emissor de issues formata requisição e headers corretamente
check "4. [MUTAÇÃO] Testando formato de payload e cabeçalho do emissor de issues" python3 -c '
from unittest.mock import MagicMock
import scripts.banca_storage as bs

mock_client = MagicMock()
mock_client.post_json.return_value = (201, {"id": 42, "html_url": "https://gambi.2lp.in/lumen/tachinha/issues/42"})

ok, res = bs.create_forge_issue(
    forge_url="https://gambi.2lp.in",
    forge_token="fake-token-xyz",
    repo_slug="lumen/tachinha",
    app="tachinha",
    channel="stable",
    version="0.4.1",
    commit="a1b2c3d4",
    run_id="1842",
    errors=["Arquivo versionado retornou 404"],
    http_client=mock_client
)

assert ok, "Deveria ter criado issue com sucesso"
mock_client.post_json.assert_called_once()
call_args = mock_client.post_json.call_args
url = call_args[0][0]
payload = call_args[0][1]
headers = call_args[0][2]

assert "api/v1/repos/lumen/tachinha/issues" in url
assert "0.4.1" in payload["title"]
assert "stable" in payload["title"]
assert "Arquivo versionado retornou 404" in payload["body"]
assert headers.get("Authorization") == "token fake-token-xyz"
'

echo "================================================================="
if [ "$FAIL" -gt 0 ]; then
    echo "💥 $FAIL TESTE(S) FALHARAM."
    exit 1
fi
echo "🎉 Todos os testes de purga e emissor de issues passaram!"
