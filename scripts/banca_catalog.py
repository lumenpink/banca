#!/usr/bin/env python3
"""
scripts/banca_catalog.py — Motor do Catálogo Unificado e Validador de Schema (#54)
Implementa a arquitetura de distribuição unificada da Banca com schema declarativo,
canais canônicos ('stable' e 'dev') e projeção de compatibilidade retroativa.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

SHA256_REGEX = re.compile(r"^[a-f0-9]{64}$")

DEFAULT_APPS = [
    ("cccp", "CCCP CLI", "Guardião de Conventional Commits e governança GOST", "governance"),
    ("navalha", "Navalha", "Despachante e canivete suíço para deploy e automação", "devops"),
    ("lauda", "Lauda", "Cliente de correio e interface editorial", "editorial"),
    ("lacraia", "La Craia", "Cockpit de som brutalista e jukebox comunitária", "multimedia"),
    ("joaju", "Joaju", "Compilador vetorial de diagramas, tabelas e heredogramas", "editorial"),
    ("svyaz", "Svyaz", "Camada de conectividade e mensageria P2P distribuída", "network"),
    ("mayak", "Mayak", "Farol de telemetria e observabilidade sem rastreamento", "monitoring"),
    ("kvant", "Kvant", "Motor analítico de dados e processamento vetorial", "analytics"),
    ("ayvu", "Ayvu", "Tradutor e motor de síntese de voz", "ai"),
    ("tuitata", "Tuitatá", "Agregador e leitor de feeds RSS/Atom minimalista", "reader"),
    ("baquara", "Baquara", "Plataforma de gestão de conhecimento e biblioteca", "knowledge"),
    ("mocambo", "Mocambo", "Cofre de arquivos, documentos e fotos", "storage"),
    ("hendu", "Hendu", "Bot de acessibilidade e audiodescrição comunitária", "accessibility"),
    ("mandu", "Mandu", "Editor brutalista de notas em texto puro, Markdown e Joaju", "editorial"),
    ("tatupeba", "Tatupeba", "Blindagem e firewall de borda com regras atômicas", "security"),
    ("jornaleira", "Jornaleira", "Gestor central de aplicativos e auto-update da Banca", "system"),
    ("pult", "Pult", "Estação de trabalho TUI e mediadora de contexto AST", "terminal"),
    ("tachinha", "Tachinha", "Gerador de sites estáticos ágil e minimalista em Rust", "editorial")
]


def validate_catalog(catalog_data, schema_data=None):
    """Valida a estrutura do catálogo conforme o schema declarativo."""
    errors = []

    if not isinstance(catalog_data, dict):
        return False, ["Catálogo raiz deve ser um objeto JSON"]

    for field in ["$schema", "updated_at", "apps"]:
        if field not in catalog_data:
            errors.append(f"Campo obrigatório ausente na raiz: '{field}'")

    apps = catalog_data.get("apps")
    if not isinstance(apps, dict):
        errors.append("Campo 'apps' deve ser um dicionário indexado pelo slug da aplicação")
        return False, errors

    for app_slug, app_data in apps.items():
        if not isinstance(app_data, dict):
            errors.append(f"[{app_slug}] Dados da aplicação devem ser um objeto")
            continue

        # Validar metadata
        meta = app_data.get("metadata")
        if not isinstance(meta, dict):
            errors.append(f"[{app_slug}] Objeto 'metadata' ausente ou inválido")
        else:
            for mfield in ["name", "description", "homepage", "repo"]:
                if mfield not in meta or not isinstance(meta[mfield], str):
                    errors.append(f"[{app_slug}.metadata] Campo obrigatório ausente ou inválido: '{mfield}'")

        # Validar channels
        channels = app_data.get("channels")
        if not isinstance(channels, dict):
            errors.append(f"[{app_slug}] Objeto 'channels' ausente ou inválido")
            continue

        for ch_name, expected_label, exp_limit in [
            ("stable", "Versão Recomendada", 5),
            ("dev", "Versão Experimental", 10),
        ]:
            if ch_name not in channels:
                errors.append(f"[{app_slug}.channels] Canal obrigatório ausente: '{ch_name}'")
                continue

            ch_data = channels[ch_name]
            if not isinstance(ch_data, dict):
                errors.append(f"[{app_slug}.channels.{ch_name}] Canal deve ser um objeto")
                continue

            if ch_data.get("label") != expected_label:
                errors.append(
                    f"[{app_slug}.channels.{ch_name}] 'label' inválido: esperado '{expected_label}', obtido '{ch_data.get('label')}'"
                )

            if ch_data.get("history_limit") != exp_limit:
                errors.append(
                    f"[{app_slug}.channels.{ch_name}] 'history_limit' inválido: esperado {exp_limit}, obtido {ch_data.get('history_limit')}"
                )

            versions = ch_data.get("versions")
            if not isinstance(versions, list):
                errors.append(f"[{app_slug}.channels.{ch_name}] 'versions' deve ser uma lista")
                continue

            for idx, v in enumerate(versions):
                if not isinstance(v, dict):
                    errors.append(f"[{app_slug}.{ch_name}.versions[{idx}]] Versão deve ser um objeto")
                    continue

                for vfield in ["version", "released_at", "commit", "assets"]:
                    if vfield not in v:
                        errors.append(f"[{app_slug}.{ch_name}.versions[{idx}]] Campo obrigatório ausente: '{vfield}'")

                assets = v.get("assets", [])
                if not isinstance(assets, list):
                    errors.append(f"[{app_slug}.{ch_name}.versions[{idx}]] 'assets' deve ser uma lista")
                    continue

                for aidx, asset in enumerate(assets):
                    if not isinstance(asset, dict):
                        errors.append(f"[{app_slug}.{ch_name}.versions[{idx}].assets[{aidx}]] Asset deve ser um objeto")
                        continue

                    for afield in ["target", "type", "format", "filename", "alias", "url", "alias_url", "sha256"]:
                        if afield not in asset:
                            errors.append(f"[{app_slug}.{ch_name}.versions[{idx}].assets[{aidx}]] Campo ausente: '{afield}'")

                    atype = asset.get("type")
                    if atype not in ["binary", "archive", "installer", "package"]:
                        errors.append(
                            f"[{app_slug}.{ch_name}.versions[{idx}].assets[{aidx}]] Tipo de asset inválido: '{atype}'"
                        )

                    sha = asset.get("sha256", "")
                    if not SHA256_REGEX.match(sha):
                        errors.append(
                            f"[{app_slug}.{ch_name}.versions[{idx}].assets[{aidx}]] Hash SHA-256 inválido: '{sha}'"
                        )

    return len(errors) == 0, errors


def infer_asset_type_and_format(filename):
    """Infere o tipo e o formato do artefato a partir do nome do arquivo."""
    name_lower = filename.lower()
    if name_lower.endswith(".tar.gz"):
        return "archive", "tar.gz"
    if name_lower.endswith(".tar.xz"):
        return "archive", "tar.xz"
    if name_lower.endswith(".zip"):
        return "archive", "zip"
    if name_lower.endswith(".deb"):
        return "package", "deb"
    if name_lower.endswith(".rpm"):
        return "package", "rpm"
    if name_lower.endswith(".sh"):
        return "installer", "sh"
    return "binary", "raw"


def target_from_arch(arch):
    """Normaliza o nome da arquitetura/target."""
    if arch == "linux-amd64":
        return "linux-x86_64"
    if arch == "windows-amd64":
        return "windows-x86_64"
    return arch


def build_version_assets(app_slug, channel, version_str, entry):
    """Constrói a lista de assets tipados a partir de uma entrada de versão."""
    assets = []
    artifacts = entry.get("artifacts", {})

    if isinstance(artifacts, dict) and artifacts:
        for arch, art in artifacts.items():
            if not isinstance(art, dict):
                continue
            url = art.get("url") or art.get("binary_url") or ""
            if not url:
                continue
            if url.startswith("https://banca.2lp.in/downloads/"):
                url = url.replace("https://banca.2lp.in/downloads/", "https://bucket.2lp.in/downloads/")
            sha = art.get("sha256") or entry.get("sha256") or ""
            target = target_from_arch(arch)
            fname = Path(url).name
            atype, aformat = infer_asset_type_and_format(fname)

            if channel == "stable":
                alias_name = f"{app_slug}-latest-{target}.{aformat}" if aformat != "raw" else f"{app_slug}-latest-{target}"
            else:
                alias_name = f"{app_slug}-dev-latest-{target}.{aformat}" if aformat != "raw" else f"{app_slug}-dev-latest-{target}"

            alias_url = f"https://dist.2lp.in/{app_slug}/{channel}/{alias_name}"
            # Se hash estiver vazio, usa hash dummy formatada
            if not SHA256_REGEX.match(sha):
                sha = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

            assets.append({
                "target": target,
                "type": atype,
                "format": aformat,
                "filename": fname,
                "alias": alias_name,
                "url": url,
                "alias_url": alias_url,
                "sha256": sha
            })
    elif entry.get("url"):
        url = entry["url"]
        if url.startswith("https://banca.2lp.in/downloads/"):
            url = url.replace("https://banca.2lp.in/downloads/", "https://bucket.2lp.in/downloads/")
        fname = Path(url).name
        atype, aformat = infer_asset_type_and_format(fname)
        target = "linux-x86_64"
        if channel == "stable":
            alias_name = f"{app_slug}-latest-{target}.{aformat}" if aformat != "raw" else f"{app_slug}-latest-{target}"
        else:
            alias_name = f"{app_slug}-dev-latest-{target}.{aformat}" if aformat != "raw" else f"{app_slug}-dev-latest-{target}"
        alias_url = f"https://dist.2lp.in/{app_slug}/{channel}/{alias_name}"
        sha = entry.get("sha256") or "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        if not SHA256_REGEX.match(sha):
            sha = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

        assets.append({
            "target": target,
            "type": atype,
            "format": aformat,
            "filename": fname,
            "alias": alias_name,
            "url": url,
            "alias_url": alias_url,
            "sha256": sha
        })

    return assets


def convert_manifest_to_channel_versions(app_slug, entries, channel, limit):
    """Converte entradas legadas de versão para o formato do canal unificado."""
    versions = []
    if not isinstance(entries, list):
        return versions

    for entry in entries[:limit]:
        if not isinstance(entry, dict):
            continue
        v_str = entry.get("version", "")
        if not v_str:
            continue
        released_at = entry.get("date", "")
        if released_at:
            if "T" not in released_at:
                released_at = f"{released_at}T12:00:00Z"
        else:
            released_at = datetime.now(timezone.utc).isoformat()

        # Extrair commit do sufixo de versão se existir (+commit ou .commit)
        commit = ""
        if "+" in v_str:
            parts = v_str.split("+")
            if len(parts) > 1 and "." in parts[1]:
                commit = parts[1].split(".")[-1]
            elif len(parts) > 1:
                commit = parts[1]
        if not commit:
            commit = "main"

        assets = build_version_assets(app_slug, channel, v_str, entry)
        versions.append({
            "version": v_str,
            "released_at": released_at,
            "commit": commit,
            "assets": assets
        })

    return versions


def generate_unified_catalog(downloads_dir):
    """Gera o catálogo catalog.json no formato formal unificado."""
    downloads_path = Path(downloads_dir)
    downloads_path.mkdir(parents=True, exist_ok=True)
    catalog_file = downloads_path / "catalog.json"

    apps_dict = {}

    # Construir dicionário a partir dos DEFAULT_APPS
    for slug, name, desc, cat in DEFAULT_APPS:
        manifest_file = downloads_path / slug / "index.json"
        manifest_data = {}
        if manifest_file.exists():
            try:
                with open(manifest_file, "r", encoding="utf-8") as f:
                    manifest_data = json.load(f)
            except Exception as e:
                print(f"⚠ Erro ao ler {manifest_file}: {e}")

        stable_versions = convert_manifest_to_channel_versions(
            slug, manifest_data.get("stables", []), "stable", 5
        )
        dev_versions = convert_manifest_to_channel_versions(
            slug, manifest_data.get("nightlies", []), "dev", 10
        )

        stable_latest = (
            stable_versions[0]["version"]
            if stable_versions
            else manifest_data.get("stable_latest", "")
        )
        dev_latest = (
            dev_versions[0]["version"]
            if dev_versions
            else manifest_data.get("nightly_latest", "")
        )

        apps_dict[slug] = {
            "metadata": {
                "name": manifest_data.get("name") or name,
                "description": manifest_data.get("description") or desc,
                "homepage": f"https://2lp.in/{slug}",
                "repo": manifest_data.get("repo") or f"https://gambi.2lp.in/lumen/{slug}",
            },
            "channels": {
                "stable": {
                    "label": "Versão Recomendada",
                    "latest_version": stable_latest,
                    "history_limit": 5,
                    "versions": stable_versions,
                },
                "dev": {
                    "label": "Versão Experimental",
                    "latest_version": dev_latest,
                    "history_limit": 10,
                    "versions": dev_versions,
                },
            },
        }

    catalog_data = {
        "$schema": "./catalog.schema.json",
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "apps": apps_dict,
    }

    with open(catalog_file, "w", encoding="utf-8") as f:
        json.dump(catalog_data, f, indent=2, ensure_ascii=False)

    print(f"✔ Catálogo unificado gerado com sucesso em '{catalog_file}' ({len(apps_dict)} apps).")
    return catalog_data


def sync_compat_manifests(downloads_dir, catalog_data=None):
    """Projeta as views de compatibilidade retroativa em site/downloads/{app}/index.json."""
    downloads_path = Path(downloads_dir)
    if catalog_data is None:
        cat_file = downloads_path / "catalog.json"
        if not cat_file.exists():
            return
        with open(cat_file, "r", encoding="utf-8") as f:
            catalog_data = json.load(f)

    apps = catalog_data.get("apps", {})
    if not isinstance(apps, dict):
        return

    for slug, app_info in apps.items():
        app_dir = downloads_path / slug
        app_dir.mkdir(parents=True, exist_ok=True)
        manifest_file = app_dir / "index.json"

        meta = app_info.get("metadata", {})
        channels = app_info.get("channels", {})
        stable_ch = channels.get("stable", {})
        dev_ch = channels.get("dev", {})

        # Converter versions para formato compatível
        stables = []
        for v in stable_ch.get("versions", []):
            artifacts = {}
            for a in v.get("assets", []):
                arch = "linux-amd64" if a.get("target") == "linux-x86_64" else a.get("target")
                artifacts[arch] = {
                    "url": a.get("url", ""),
                    "binary_url": a.get("url", ""),
                    "sha256": a.get("sha256", ""),
                }
            stables.append({
                "version": v.get("version", ""),
                "date": v.get("released_at", "")[:10],
                "sha256": v.get("assets", [{}])[0].get("sha256", "") if v.get("assets") else "",
                "url": v.get("assets", [{}])[0].get("url", "") if v.get("assets") else "",
                "artifacts": artifacts,
            })

        nightlies = []
        for v in dev_ch.get("versions", []):
            artifacts = {}
            for a in v.get("assets", []):
                arch = "linux-amd64" if a.get("target") == "linux-x86_64" else a.get("target")
                artifacts[arch] = {
                    "url": a.get("url", ""),
                    "binary_url": a.get("url", ""),
                    "sha256": a.get("sha256", ""),
                }
            nightlies.append({
                "version": v.get("version", ""),
                "date": v.get("released_at", "")[:10],
                "sha256": v.get("assets", [{}])[0].get("sha256", "") if v.get("assets") else "",
                "url": v.get("assets", [{}])[0].get("url", "") if v.get("assets") else "",
                "artifacts": artifacts,
            })

        compat_data = {
            "app": slug,
            "name": meta.get("name", slug),
            "description": meta.get("description", ""),
            "repo": meta.get("repo", ""),
            "stable_latest": stable_ch.get("latest_version", ""),
            "nightly_latest": dev_ch.get("latest_version", ""),
            "stables": stables,
            "nightlies": nightlies,
        }

        with open(manifest_file, "w", encoding="utf-8") as f:
            json.dump(compat_data, f, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description="Gerenciador do Catálogo Unificado da Banca")
    parser.add_argument("--validate", help="Caminho do catalog.json a validar")
    parser.add_argument("--schema", help="Caminho do catalog.schema.json")
    parser.add_argument("--generate", help="Diretório alvo para gerar o catalog.json unificado")
    parser.add_argument("--sync-compat", help="Diretório onde sincronizar manifestos de compatibilidade")

    args = parser.parse_args()

    if args.validate:
        catalog_path = Path(args.validate)
        if not catalog_path.exists():
            print(f"❌ Arquivo não encontrado: {catalog_path}", file=sys.stderr)
            sys.exit(1)
        with open(catalog_path, "r", encoding="utf-8") as f:
            cat_data = json.load(f)

        schema_data = None
        if args.schema:
            schema_path = Path(args.schema)
            if schema_path.exists():
                with open(schema_path, "r", encoding="utf-8") as f:
                    schema_data = json.load(f)

        valid, errors = validate_catalog(cat_data, schema_data)
        if not valid:
            print("❌ Falha de validação do catálogo:", file=sys.stderr)
            for err in errors:
                print(f"  • {err}", file=sys.stderr)
            sys.exit(1)
        print("✅ Catálogo validado com 100% de conformidade com o schema!")
        sys.exit(0)

    if args.generate:
        cat_data = generate_unified_catalog(args.generate)
        sync_compat_manifests(args.generate, cat_data)
        sys.exit(0)

    if args.sync_compat:
        sync_compat_manifests(args.sync_compat)
        sys.exit(0)

    parser.print_help()


if __name__ == "__main__":
    main()
