#!/usr/bin/env python3
"""
Módulo de Auditoria Hermética de Rede e Integridade de Checksum da Banca.
Implementa as Etapas 1 e 2 da especificação técnica de publicação:
- Etapa 1: Auditoria da Nova Versão (HEAD nos binários e aliases + validação de SHA-256)
- Etapa 2: Auditoria dos Links Históricos Ativos (Tolerância Zero a Links Quebrados)
"""

import json
import re
import sys
import unittest
from pathlib import Path
import urllib.request
import urllib.error
from typing import Tuple, List, Dict, Any, Optional

DEFAULT_DIST_BASE = "https://dist.2lp.in"

class SimpleHttpClient:
    """Cliente HTTP leve usando urllib padrão."""
    def __init__(self, timeout: int = 10):
        self.timeout = timeout

    def head(self, url: str) -> int:
        req = urllib.request.Request(url, method="HEAD")
        req.add_header("User-Agent", "BancaAudit/1.0 (+https://banca.2lp.in)")
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                return resp.status
        except urllib.error.HTTPError as e:
            return e.code
        except Exception:
            return 599

    def get_text(self, url: str) -> Optional[str]:
        req = urllib.request.Request(url)
        req.add_header("User-Agent", "BancaAudit/1.0 (+https://banca.2lp.in)")
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                return resp.read().decode("utf-8", errors="replace")
        except Exception:
            return None

def normalize_sha256(text: str) -> str:
    """Extrai uma hash SHA-256 de 64 hex de um conteúdo sha256sum."""
    match = re.search(r"([a-fA-F0-9]{64})", text)
    if match:
        return match.group(1).lower()
    return ""

def audit_new_release(
    payload: Dict[str, Any],
    base_url: str = DEFAULT_DIST_BASE,
    http_client: Optional[Any] = None
) -> Tuple[bool, List[str]]:
    """
    Etapa 1: Audita os arquivos físicos e aliases da nova versão declarada no payload.
    Verifica HTTP 200 via HEAD e conformidade do hash SHA-256.
    """
    client = http_client or SimpleHttpClient()
    errors: List[str] = []

    app = payload.get("app")
    channel = payload.get("channel")
    version = payload.get("version")
    assets = payload.get("assets", [])

    if not app or not channel or not version:
        return False, ["Payload inválido: 'app', 'channel' e 'version' são obrigatórios."]

    if not assets:
        return False, ["Payload inválido: lista de 'assets' vazia."]

    base_storage_url = f"{base_url.rstrip('/')}/{app}/{channel}"

    for asset in assets:
        filename = asset.get("filename")
        alias = asset.get("alias")
        declared_sha = (asset.get("sha256") or "").lower()

        if not filename:
            errors.append("Ativo sem campo 'filename'.")
            continue

        file_url = f"{base_storage_url}/{filename}"
        sha_file_url = f"{file_url}.sha256"

        # 1. HEAD no arquivo versionado
        status = client.head(file_url)
        if status != 200:
            errors.append(f"Arquivo versionado '{file_url}' retornou status HTTP {status} (esperado 200).")

        # 2. HEAD no alias canônico
        if alias:
            alias_url = f"{base_storage_url}/{alias}"
            alias_status = client.head(alias_url)
            if alias_status != 200:
                errors.append(f"Alias canônico '{alias_url}' retornou status HTTP {alias_status} (esperado 200).")

        # 3. Verificação do hash SHA-256
        if declared_sha:
            if not re.match(r"^[a-f0-9]{64}$", declared_sha):
                errors.append(f"Hash declarada inválida para {filename}: '{declared_sha}'")
            else:
                remote_sha_content = client.get_text(sha_file_url)
                if not remote_sha_content:
                    errors.append(f"Arquivo de checksum '{sha_file_url}' não pôde ser recuperado ou retornou erro.")
                else:
                    remote_sha = normalize_sha256(remote_sha_content)
                    if remote_sha != declared_sha:
                        errors.append(
                            f"Divergência de SHA-256 em '{filename}': declarado='{declared_sha}', bucket='{remote_sha}'"
                        )
        else:
            errors.append(f"Ativo '{filename}' não declarou hash SHA-256.")

    return len(errors) == 0, errors

def audit_active_history(
    catalog_path: str,
    app: str,
    channel: str,
    limit: int = 5,
    http_client: Optional[Any] = None
) -> Tuple[bool, List[str]]:
    """
    Etapa 2: Auditoria dos links de versões históricas que continuarão ativas no catálogo.
    Tolerância Zero a Links Quebrados: qualquer código HTTP != 200 falha o ciclo.
    """
    client = http_client or SimpleHttpClient()
    errors: List[str] = []

    path = Path(catalog_path)
    if not path.exists():
        return False, [f"Arquivo de catálogo não encontrado: '{catalog_path}'"]

    try:
        with open(path, "r", encoding="utf-8") as f:
            catalog = json.load(f)
    except Exception as e:
        return False, [f"Erro ao analisar JSON do catálogo '{catalog_path}': {e}"]

    apps = catalog.get("apps", {})
    app_data = apps.get(app)
    if not app_data:
        # App novo, sem histórico ativo anterior para validar
        return True, []

    channels = app_data.get("channels", {})
    ch_data = channels.get(channel, {})
    versions = ch_data.get("versions", [])

    # Versões ativas remanescentes que continuarão após inclusão da nova versão
    # Como uma nova versão entrará, as ativas remanescentes são as primeiras (limit - 1)
    active_versions = versions[: max(0, limit - 1)]

    for ver_info in active_versions:
        ver_tag = ver_info.get("version", "desconhecida")
        for asset in ver_info.get("assets", []):
            url = asset.get("url")
            filename = asset.get("filename", url)
            if not url:
                errors.append(f"Versão histórica {ver_tag} possui ativo sem URL declarada.")
                continue

            status = client.head(url)
            if status != 200:
                errors.append(
                    f"Link histórico quebrado detectado! App '{app}' ({channel}) versão {ver_tag} arquivo '{filename}' ({url}) retornou HTTP {status}."
                )

    return len(errors) == 0, errors


class TestBancaAudit(unittest.TestCase):
    """Testes unitários internos de auditoria."""

    def test_normalize_sha256(self):
        text1 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  foo.tar.gz\n"
        self.assertEqual(normalize_sha256(text1), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")

        text2 = "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"
        self.assertEqual(normalize_sha256(text2), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")

        text3 = "invalid"
        self.assertEqual(normalize_sha256(text3), "")

    def test_audit_new_release_success(self):
        class MockClient:
            def head(self, url):
                return 200
            def get_text(self, url):
                return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  tachinha-0.4.1.tar.gz\n"

        payload = {
            "app": "tachinha",
            "channel": "stable",
            "version": "0.4.1",
            "commit": "a1b2c3d4",
            "assets": [
                {
                    "filename": "tachinha-0.4.1.tar.gz",
                    "alias": "tachinha-latest.tar.gz",
                    "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                }
            ]
        }
        ok, errors = audit_new_release(payload, http_client=MockClient())
        self.assertTrue(ok)
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
