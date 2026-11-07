#!/usr/bin/env python3
"""
Orquestrador Central da Esteira de Publicação da Banca (Pipeline Curador).
Integra:
1. Auditoria da Nova Versão (HEAD nos binários e aliases + integridade SHA-256)
2. Auditoria dos Links Históricos Ativos (Tolerância Zero a Links Quebrados)
3. Rotação e Purga de Objetos Excedentes
4. Atualização de catalog.json e sincronização de manifestos retrocompatíveis
Em caso de falha em qualquer etapa, cancela o deploy e emite issue na forja do projeto.
"""

import argparse
from datetime import datetime, timezone
import json
import os
import sys
import unittest
from pathlib import Path
from typing import Dict, Any, Tuple, Optional

import scripts.banca_audit as audit_lib
import scripts.banca_storage as storage_lib
import scripts.banca_catalog as catalog_lib

DEFAULT_CATALOG_PATH = "site/downloads/catalog.json"
DEFAULT_FORGE_URL = "https://gambi.2lp.in"

def run_pipeline(
    payload: Dict[str, Any],
    catalog_path: str = DEFAULT_CATALOG_PATH,
    forge_url: str = DEFAULT_FORGE_URL,
    forge_token: str = "",
    audit_module: Optional[Any] = None,
    storage_module: Optional[Any] = None,
    base_dist_url: str = "https://dist.2lp.in"
) -> Tuple[bool, str]:
    """
    Executa a esteira curadora da banca end-to-end.
    """
    audit = audit_module or audit_lib
    storage = storage_module or storage_lib

    app = payload.get("app")
    channel = payload.get("channel", "stable")
    version = payload.get("version")
    commit = payload.get("commit", "")
    repo_slug = payload.get("repo_slug") or f"lumen/{app}"
    run_id = str(payload.get("run_id", ""))
    assets = payload.get("assets", [])

    if not app or not version:
        return False, "Payload inválido: campos 'app' e 'version' são obrigatórios."

    limit = 5 if channel == "stable" else 10

    # Etapa 1: Auditoria da Nova Versão
    print(f"-> [Etapa 1] Auditando nova versão {version} de {app} ({channel})...")
    ok1, errors1 = audit.audit_new_release(payload, base_url=base_dist_url)
    if not ok1:
        print(f"❌ Falha na Etapa 1: {errors1}")
        if forge_token:
            storage.create_forge_issue(
                forge_url=forge_url,
                forge_token=forge_token,
                repo_slug=repo_slug,
                app=app,
                channel=channel,
                version=version,
                commit=commit,
                run_id=run_id,
                errors=errors1
            )
        return False, f"Falha na auditoria da nova versão: {errors1}"

    # Etapa 2: Auditoria dos Links Históricos Ativos
    print(f"-> [Etapa 2] Auditando histórico ativo para {app} ({channel})...")
    ok2, errors2 = audit.audit_active_history(
        catalog_path=catalog_path,
        app=app,
        channel=channel,
        limit=limit
    )
    if not ok2:
        print(f"❌ Falha na Etapa 2: {errors2}")
        if forge_token:
            storage.create_forge_issue(
                forge_url=forge_url,
                forge_token=forge_token,
                repo_slug=repo_slug,
                app=app,
                channel=channel,
                version=version,
                commit=commit,
                run_id=run_id,
                errors=errors2
            )
        return False, f"Falha na auditoria do histórico ativo: {errors2}"

    # Etapa 3 & 4: Atualização do Catálogo Unificado
    print(f"-> [Etapa 3 & 4] Atualizando catálogo em '{catalog_path}'...")
    path = Path(catalog_path)
    if not path.exists():
        return False, f"Catálogo não encontrado em {catalog_path}"

    with open(path, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    apps = catalog.setdefault("apps", {})
    app_entry = apps.setdefault(app, {
        "metadata": {
            "name": app.capitalize(),
            "description": f"Aplicativo {app}",
            "homepage": f"https://2lp.in/{app}",
            "repo": f"https://gambi.2lp.in/lumen/{app}"
        },
        "channels": {
            "stable": {
                "label": "Versão Recomendada",
                "latest_version": "",
                "history_limit": 5,
                "versions": []
            },
            "dev": {
                "label": "Versão Experimental",
                "latest_version": "",
                "history_limit": 10,
                "versions": []
            }
        }
    })

    ch_entry = app_entry.setdefault("channels", {}).setdefault(channel, {
        "label": "Versão Recomendada" if channel == "stable" else "Versão Experimental",
        "latest_version": "",
        "history_limit": limit,
        "versions": []
    })

    # Construir nó da nova versão
    now_iso = datetime.now(timezone.utc).isoformat()
    new_assets = []
    base_prefix = f"{base_dist_url.rstrip('/')}/{app}/{channel}"

    for a in assets:
        filename = a.get("filename")
        alias = a.get("alias") or ""
        target = a.get("target") or "linux-x86_64"
        atype = a.get("type") or "archive"
        aformat = a.get("format") or "tar.gz"
        sha = a.get("sha256") or ""

        url = a.get("url") or f"{base_prefix}/{filename}"
        alias_url = a.get("alias_url") or (f"{base_prefix}/{alias}" if alias else "")

        new_assets.append({
            "target": target,
            "type": atype,
            "format": aformat,
            "filename": filename,
            "alias": alias,
            "url": url,
            "alias_url": alias_url,
            "sha256": sha
        })

    version_node = {
        "version": version,
        "released_at": now_iso,
        "commit": commit,
        "assets": new_assets
    }

    # Inserir no topo e podar histórico para respeitar quota
    existing_versions = [v for v in ch_entry.get("versions", []) if v.get("version") != version]
    updated_versions = [version_node] + existing_versions
    ch_entry["versions"] = updated_versions[:limit]
    ch_entry["latest_version"] = version
    catalog["updated_at"] = now_iso

    with open(path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)

    # Sincronizar manifestos retrocompatíveis em site/downloads/{app}/index.json
    downloads_dir = path.parent
    app_manifest_dir = downloads_dir / app
    if app_manifest_dir.exists():
        catalog_lib.sync_compat_manifests(catalog, downloads_dir)

    print(f"✔ Pipeline de publicação de {app} ({version} - {channel}) concluído com sucesso!")
    return True, "Publicação aprovada e catálogo atualizado com sucesso."


class TestBancaPipeline(unittest.TestCase):
    """Testes unitários internos do pipeline."""

    def test_run_pipeline_missing_app(self):
        ok, msg = run_pipeline({})
        self.assertFalse(ok)
        self.assertIn("obrigatórios", msg)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Orquestrador Curador da Banca")
    parser.add_argument("--payload", help="Payload JSON do release")
    parser.add_argument("--payload-file", help="Arquivo contendo o payload JSON")
    parser.add_argument("--catalog", default=DEFAULT_CATALOG_PATH, help="Caminho para catalog.json")
    parser.add_argument("--forge-url", default=DEFAULT_FORGE_URL, help="URL da forja")
    parser.add_argument("--forge-token", default=os.getenv("FORGE_TOKEN", ""), help="Token da forja")

    args = parser.parse_args()

    payload_data = None
    if args.payload:
        try:
            payload_data = json.loads(args.payload)
        except Exception as e:
            print(f"Erro ao analisar --payload: {e}")
            sys.exit(1)
    elif args.payload_file and os.path.exists(args.payload_file):
        with open(args.payload_file, "r", encoding="utf-8") as f:
            payload_data = json.load(f)

    if not payload_data:
        print("Nenhum payload fornecido.")
        sys.exit(1)

    success, message = run_pipeline(
        payload=payload_data,
        catalog_path=args.catalog,
        forge_url=args.forge_url,
        forge_token=args.forge_token
    )

    if not success:
        print(f"Pipeline abortado: {message}")
        sys.exit(1)
    print(f"Pipeline concluído: {message}")
    sys.exit(0)
