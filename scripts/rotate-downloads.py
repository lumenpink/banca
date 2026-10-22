#!/usr/bin/env python3
"""
scripts/rotate-downloads.py — Gerenciador de Rotação, Retenção e Multi-Arquitetura da Banca (#35 & #32)
Garante a retenção estrita de até 5 versões estáveis e até 10 compilações nightlies
no manifesto index.json e no storage R2 para cada aplicação do ecossistema,
com suporte a linux-amd64, linux-arm64 e windows-amd64.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

MAX_STABLES = 5
MAX_NIGHTLIES = 10

DEFAULT_APPS = [
    ("cccp", "CCCP CLI", "Guardião de Conventional Commits e governança GOST", "governance"),
    ("navalha", "Navalha", "Despachante e canivete suíço para deploy e automação", "devops"),
    ("lauda", "Lauda", "Cliente de correio soberano e interface editorial", "editorial"),
    ("lacraia", "La Craia", "Cockpit de som brutalista e jukebox comunitária", "multimedia"),
    ("joaju", "Joaju", "Compilador vetorial de diagramas, tabelas e heredogramas", "editorial"),
    ("svyaz", "Svyaz", "Camada de conectividade e mensageria P2P distribuída", "network"),
    ("mayak", "Mayak", "Farol de telemetria e observabilidade sem rastreamento", "monitoring"),
    ("kvant", "Kvant", "Motor analítico de dados e processamento vetorial", "analytics"),
    ("ayvu", "Ayvu", "Tradutor e motor de síntese de voz soberano", "ai"),
    ("tuitata", "Tuitatá", "Agregador e leitor de feeds RSS/Atom minimalista", "reader"),
    ("baquara", "Baquara", "Plataforma de gestão de conhecimento e biblioteca", "knowledge"),
    ("mocambo", "Mocambo", "Cofre soberano de arquivos, documentos e fotos", "storage"),
    ("hendu", "Hendu", "Bot de acessibilidade e audiodescrição comunitária", "accessibility"),
    ("mandu", "Mandu", "Editor brutalista de notas em texto puro, Markdown e Joaju", "editorial"),
    ("tatupeba", "Tatupeba", "Blindagem e firewall de borda com regras atômicas", "security")
]

def prune_manifest_data(data):
    """
    Trunca listas de versões para os limites máximos permitidos:
    - stables: máximo 5 versões
    - nightlies: máximo 10 versões
    """
    if "stables" in data and isinstance(data["stables"], list):
        data["stables"] = data["stables"][:MAX_STABLES]
        if data["stables"] and not data.get("stable_latest"):
            data["stable_latest"] = data["stables"][0].get("version", "")

    if "nightlies" in data and isinstance(data["nightlies"], list):
        data["nightlies"] = data["nightlies"][:MAX_NIGHTLIES]
        if data["nightlies"] and not data.get("nightly_latest"):
            data["nightly_latest"] = data["nightlies"][0].get("version", "")

    return data

def prune_manifest_file(file_path):
    if not os.path.exists(file_path):
        print(f"Erro: Arquivo {file_path} não encontrado.", file=sys.stderr)
        return False

    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    data = prune_manifest_data(data)

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"✔ Manifesto {file_path} podado com sucesso (<= {MAX_STABLES} stables, <= {MAX_NIGHTLIES} nightlies).")
    return True

def add_entry(manifest_path, channel, version, url, sha256="", tarball="", arch="linux-amd64", app_name=""):
    """
    Adiciona ou mescla uma versão no manifesto atômico index.json, preservando
    e agregando os artefatos por arquitetura (linux-amd64, linux-arm64, windows-amd64).
    """
    data = {
        "app": app_name or Path(manifest_path).parent.name or "app",
        "stables": [],
        "nightlies": []
    }
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
            except Exception:
                pass

    if app_name:
        data["app"] = app_name

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    target_list_key = "stables" if channel == "stable" else "nightlies"
    entries = data.get(target_list_key, [])

    # Localizar se a versão já existe para mesclar artefatos multi-arch
    existing_entry = None
    for item in entries:
        if item.get("version") == version:
            existing_entry = item
            break

    # Garantir que a URL do artefato seja sempre absoluta (http/https)
    artifact_download_url = url
    if tarball and (tarball.startswith("http://") or tarball.startswith("https://")):
        artifact_download_url = tarball

    if existing_entry is not None:
        if "artifacts" not in existing_entry or not isinstance(existing_entry["artifacts"], dict):
            existing_entry["artifacts"] = {}
        existing_entry["artifacts"][arch] = {
            "url": artifact_download_url,
            "binary_url": url,
            "sha256": sha256
        }
        if arch == "linux-amd64" or not existing_entry.get("url"):
            existing_entry["url"] = artifact_download_url
            existing_entry["sha256"] = sha256
            if tarball:
                existing_entry["tarball"] = tarball
    else:
        new_entry = {
            "version": version,
            "url": artifact_download_url,
            "date": today,
            "sha256": sha256,
            "artifacts": {
                arch: {
                    "url": artifact_download_url,
                    "binary_url": url,
                    "sha256": sha256
                }
            }
        }
        if tarball:
            new_entry["tarball"] = tarball
        entries = [new_entry] + entries

    data[target_list_key] = entries
    if channel == "stable":
        data["stable_latest"] = version
    else:
        data["nightly_latest"] = version

    data = prune_manifest_data(data)

    os.makedirs(os.path.dirname(os.path.abspath(manifest_path)), exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"✔ Adicionada versão {version} ({arch}) ao canal {channel} em {manifest_path}.")
    return True

def generate_default_manifests(downloads_dir):
    """Gera manifestos canônicos index.json iniciais para todos os aplicativos."""
    downloads_path = Path(downloads_dir)
    downloads_path.mkdir(parents=True, exist_ok=True)

    for app_slug, app_title, app_desc, app_cat in DEFAULT_APPS:
        app_dir = downloads_path / app_slug
        app_dir.mkdir(parents=True, exist_ok=True)
        manifest_file = app_dir / "index.json"

        # Se já existe e é válido, não sobrescreve
        if manifest_file.exists():
            continue

        base_url = f"https://banca.2lp.in/downloads/{app_slug}"
        manifest_data = {
            "app": app_slug,
            "name": app_title,
            "category": app_cat,
            "description": app_desc,
            "repo": f"https://codeberg.org/lumenpink/{app_slug}",
            "stable_latest": "0.1.0",
            "nightly_latest": "0.1.0-dev",
            "stables": [
                {
                    "version": "0.1.0",
                    "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
                    "url": f"{base_url}/stable-latest/{app_slug}",
                    "sha256": "",
                    "artifacts": {
                        "linux-amd64": {
                            "url": f"{base_url}/stable/{app_slug}-0.1.0-linux-amd64.tar.gz",
                            "binary_url": f"{base_url}/stable-latest/{app_slug}-linux-amd64",
                            "sha256": ""
                        },
                        "linux-arm64": {
                            "url": f"{base_url}/stable/{app_slug}-0.1.0-linux-arm64.tar.gz",
                            "binary_url": f"{base_url}/stable-latest/{app_slug}-linux-arm64",
                            "sha256": ""
                        },
                        "windows-amd64": {
                            "url": f"{base_url}/stable/{app_slug}-0.1.0-windows-amd64.zip",
                            "binary_url": f"{base_url}/stable-latest/{app_slug}.exe",
                            "sha256": ""
                        }
                    }
                }
            ],
            "nightlies": [
                {
                    "version": "0.1.0-dev",
                    "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
                    "url": f"{base_url}/nightly-latest/{app_slug}",
                    "sha256": "",
                    "artifacts": {
                        "linux-amd64": {
                            "url": f"{base_url}/nightly/{app_slug}-nightly-linux-amd64.tar.gz",
                            "binary_url": f"{base_url}/nightly-latest/{app_slug}-linux-amd64",
                            "sha256": ""
                        }
                    }
                }
            ]
        }

        with open(manifest_file, "w", encoding="utf-8") as f:
            json.dump(manifest_data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"✔ Manifesto inicial gerado: {manifest_file}")

    print("✔ Todos os manifestos padrão gerados com sucesso.")

def main():
    parser = argparse.ArgumentParser(
        description="Gerenciador de Rotação, Retenção e Multi-Arquitetura da Banca (5 estáveis, 10 nightlies)."
    )
    parser.add_argument("--prune-manifest", help="Caminho do arquivo index.json para podar")
    parser.add_argument("--generate-defaults", help="Diretório alvo para gerar manifestos iniciais de todas as apps")
    parser.add_argument("--manifest", help="Caminho do index.json alvo para adicionar versão")
    parser.add_argument("--app", default="", help="Slug da aplicação")
    parser.add_argument("--channel", choices=["stable", "nightly"], help="Canal da release")
    parser.add_argument("--version-str", help="Identificador semver ou atômico da versão")
    parser.add_argument("--arch", default="linux-amd64", choices=["linux-amd64", "linux-arm64", "windows-amd64"], help="Arquitetura do artefato")
    parser.add_argument("--url", help="URL do binário no storage R2")
    parser.add_argument("--sha256", default="", help="Hash SHA-256 do binário")
    parser.add_argument("--tarball", default="", help="URL do tarball comprimido (opcional)")

    args = parser.parse_args()

    if args.prune_manifest:
        if not prune_manifest_file(args.prune_manifest):
            sys.exit(1)
        return

    if args.generate_defaults:
        generate_default_manifests(args.generate_defaults)
        return

    if args.manifest and args.channel and args.version_str and args.url:
        add_entry(
            manifest_path=args.manifest,
            channel=args.channel,
            version=args.version_str,
            url=args.url,
            sha256=args.sha256,
            tarball=args.tarball,
            arch=args.arch,
            app_name=args.app
        )
        return

    parser.print_help()

if __name__ == "__main__":
    main()
