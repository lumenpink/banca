#!/usr/bin/env python3
"""
Módulo de Storage e Comunicação com a Forja da Banca.
Implementa:
- Rotação e purga de objetos no bucket (R2 / S3) mantendo quotas e protegendo aliases canônicos.
- Abertura automática de issues na forja em caso de inconsistência diagnosticada.
"""

import json
import re
import sys
import unittest
import urllib.request
import urllib.error
from typing import Tuple, List, Dict, Any, Optional

class SimpleRestForgeClient:
    """Cliente HTTP REST simples para interação com a API da forja (Gitea/Forgejo)."""
    def __init__(self, timeout: int = 15):
        self.timeout = timeout

    def post_json(
        self,
        url: str,
        payload: Dict[str, Any],
        headers: Optional[Dict[str, str]] = None
    ) -> Tuple[int, Any]:
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(url, data=data, method="POST")
        req.add_header("Content-Type", "application/json")
        req.add_header("User-Agent", "BancaNotifier/1.0 (+https://banca.2lp.in)")
        if headers:
            for k, v in headers.items():
                req.add_header(k, v)

        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                resp_data = resp.read().decode("utf-8", errors="replace")
                try:
                    return resp.status, json.loads(resp_data)
                except Exception:
                    return resp.status, resp_data
        except urllib.error.HTTPError as e:
            err_data = e.read().decode("utf-8", errors="replace")
            try:
                return e.code, json.loads(err_data)
            except Exception:
                return e.code, err_data
        except Exception as e:
            return 599, str(e)


def extract_version_from_key(key: str, app: str) -> Optional[str]:
    """
    Extrai a versão de uma chave S3 como '{app}/stable/{app}-{version}-{target}.{ext}'.
    Retorna None se for alias canônico (contém '-latest' ou '-dev-latest').
    """
    filename = key.split("/")[-1]
    if "-latest" in filename or "-dev-latest" in filename:
        return None

    # Remove app- prefix
    prefix = f"{app}-"
    if not filename.startswith(prefix):
        return None

    rest = filename[len(prefix):]
    # Remover extensões comuns e sufixo .sha256
    clean = re.sub(r"\.sha256$", "", rest)
    clean = re.sub(r"\.(tar\.(gz|xz|bz2)|zip|deb|rpm|sh|apk|bin|exe)$", "", clean)

    # Identificar SemVer:
    # 1) Caso dev: x.y.z-dev.n+build
    dev_match = re.match(
        r"^(\d+\.\d+\.\d+-dev\.[0-9a-zA-Z.+]+?)(?:-(?:linux|windows|darwin|macos|android|x86_64|amd64|arm64|aarch64|armv7|all)[a-z0-9_-]*)?$",
        clean
    )
    if dev_match:
        return dev_match.group(1)

    # 2) Caso stable: x.y.z(-target)?
    stable_match = re.match(r"^(\d+\.\d+\.\d+)(?:-.*)?$", clean)
    if stable_match:
        return stable_match.group(1)

    return None


def parse_semver_sort_key(version_str: str) -> Tuple[int, int, int, int]:
    """Chave de ordenação aproximada para SemVer com e sem sufixo dev."""
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:-dev\.(\d+))?", version_str)
    if match:
        major, minor, patch, dev = match.groups()
        dev_num = int(dev) if dev else 999999
        return (int(major), int(minor), int(patch), dev_num)
    return (0, 0, 0, 0)


def compute_purge_objects(
    objects: List[str],
    app: str,
    channel: str,
    limit: int
) -> List[str]:
    """
    Identifica os arquivos do bucket a serem purgados sob '{app}/{channel}/',
    respeitando a quota de retenção e nunca removendo aliases canônicos.
    """
    version_to_files: Dict[str, List[str]] = {}

    for key in objects:
        filename = key.split("/")[-1]
        # Aliases canônicos nunca são removidos
        if "-latest" in filename or "-dev-latest" in filename:
            continue

        ver = extract_version_from_key(key, app)
        if ver:
            version_to_files.setdefault(ver, []).append(key)

    # Ordenar versões da mais recente para a mais antiga
    sorted_versions = sorted(
        version_to_files.keys(),
        key=parse_semver_sort_key,
        reverse=True
    )

    # Versões que excedem a cota
    excess_versions = sorted_versions[limit:]

    to_purge: List[str] = []
    for ver in excess_versions:
        to_purge.extend(version_to_files[ver])

    return to_purge


def create_forge_issue(
    forge_url: str,
    forge_token: str,
    repo_slug: str,
    app: str,
    channel: str,
    version: str,
    commit: str,
    run_id: str,
    errors: List[str],
    http_client: Optional[Any] = None
) -> Tuple[bool, Any]:
    """
    Cria uma issue automática na forja via API REST caso a auditoria da banca falhe.
    """
    client = http_client or SimpleRestForgeClient()

    endpoint = f"{forge_url.rstrip('/')}/api/v1/repos/{repo_slug}/issues"
    headers = {"Authorization": f"token {forge_token}"}

    title = f"[Banca] Artefato da versão {version} ({channel}) ausente ou corrompido"

    error_lines = "\n".join(f"- {err}" for err in errors)
    body = (
        f"### 🚨 Falha de Auditoria na Publicação da Banca\n\n"
        f"A esteira da **Banca** rejeitou a publicação dos artefatos declarados para **{app}** "
        f"no canal **{channel}** devido a violações da política de tolerância zero a links quebrados.\n\n"
        f"**Metadados do Disparo:**\n"
        f"- **Aplicação:** `{app}`\n"
        f"- **Canal:** `{channel}`\n"
        f"- **Versão Declarada:** `{version}`\n"
        f"- **Commit de Origem:** `{commit}`\n"
        f"- **ID de Execução CI Produtor:** `{run_id}`\n\n"
        f"**Inconformidades Detectadas:**\n"
        f"{error_lines}\n\n"
        f"---\n"
        f"*Notificação gerada automaticamente pela esteira de curadoria da Banca.*"
    )

    payload = {
        "title": title,
        "body": body,
    }

    status, response = client.post_json(endpoint, payload, headers)
    is_success = status in (200, 201)
    return is_success, response


class TestBancaStorage(unittest.TestCase):
    """Testes unitários de purga e formatação de storage."""

    def test_extract_version_from_key(self):
        self.assertIsNone(extract_version_from_key("tachinha/stable/tachinha-latest-linux-x86_64.tar.gz", "tachinha"))
        self.assertIsNone(extract_version_from_key("tachinha/dev/tachinha-dev-latest-linux-x86_64.tar.gz", "tachinha"))
        self.assertEqual(
            extract_version_from_key("tachinha/stable/tachinha-0.4.1-linux-x86_64.tar.gz", "tachinha"),
            "0.4.1"
        )
        self.assertEqual(
            extract_version_from_key("tachinha/stable/tachinha-0.4.1-linux-x86_64.tar.gz.sha256", "tachinha"),
            "0.4.1"
        )
        self.assertEqual(
            extract_version_from_key("tachinha/dev/tachinha-0.4.2-dev.3+20261106.g7e8f9a-linux-x86_64.tar.gz", "tachinha"),
            "0.4.2-dev.3+20261106.g7e8f9a"
        )

    def test_compute_purge_objects(self):
        objs = [
            "tachinha/stable/tachinha-latest-linux-x86_64.tar.gz",
            "tachinha/stable/tachinha-0.4.3-linux-x86_64.tar.gz",
            "tachinha/stable/tachinha-0.4.2-linux-x86_64.tar.gz",
            "tachinha/stable/tachinha-0.4.1-linux-x86_64.tar.gz",
        ]
        # Limite de 2 versões: apenas 0.4.1 deve ser purgada
        purged = compute_purge_objects(objs, "tachinha", "stable", limit=2)
        self.assertEqual(purged, ["tachinha/stable/tachinha-0.4.1-linux-x86_64.tar.gz"])


if __name__ == "__main__":
    unittest.main()
