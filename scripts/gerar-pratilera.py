#!/usr/bin/env python3
"""
Banca — Gerador Soberano da Pratilera (Loja e Repositório F-Droid / Droid-ify)
Gera os índices index-v1.json, entry.json, index-v2.json e assina index-v1.jar com jarsigner.
"""
import os
import sys
import json
import time
import hashlib
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = REPO_ROOT / "site"
PRATILERA_DIR = SITE_DIR / "pratilera"
ICONS_DIR = PRATILERA_DIR / "icons"

APPS_METADATA = {
    "in.twolp.lacraia.app": {
        "name": "La Craia",
        "summary": "Cockpit Brutalista de Som & Jukebox",
        "description": "Paredão digital, jukebox e controlador de rádio comunitária autônoma para sistemas de som de alta potência.",
        "icon": "in.twolp.lacraia.app.png",
        "categories": ["Multimedia", "Audio"],
        "apk_filename": "lacraia-app.apk",
        "version_name": "0.2.0",
        "version_code": 1,
        "min_sdk": 26,
        "target_sdk": 34,
        "license": "GPL-3.0",
        "web_url": "https://lacraia.2lp.in",
        "source_code": "https://codeberg.org/lumenpink/lacraia"
    },
    "in.twolp.lacraia.simbiotyka": {
        "name": "Simbiótyka",
        "summary": "HUD de Letras Sincronizadas & Cifras",
        "description": "HUD flutuante que renderiza letras sincronizadas (LRC) sobre qualquer reprodutor de mídia sem roubar o foco da janela.",
        "icon": "in.twolp.lacraia.simbiotyka.png",
        "categories": ["Multimedia", "Audio"],
        "apk_filename": "simbiotyka.apk",
        "version_name": "0.2.0",
        "version_code": 1,
        "min_sdk": 26,
        "target_sdk": 34,
        "license": "GPL-3.0",
        "web_url": "https://lacraia.2lp.in",
        "source_code": "https://codeberg.org/lumenpink/lacraia"
    },
    "in.twolp.lauda": {
        "name": "Lauda",
        "summary": "Cliente de Correio Soberano Minimalista",
        "description": "Cliente de e-mail em texto puro com suporte a Dioxus, Maildir e sincronização sem rastreamento.",
        "icon": "in.twolp.lauda.png",
        "categories": ["Internet", "Email"],
        "apk_filename": "lauda-latest.apk",
        "version_name": "0.2.0",
        "version_code": 1,
        "min_sdk": 26,
        "target_sdk": 34,
        "license": "GPL-3.0",
        "web_url": "https://lauda.2lp.in",
        "source_code": "https://codeberg.org/lumenpink/lauda"
    }
}

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def ensure_dirs():
    PRATILERA_DIR.mkdir(parents=True, exist_ok=True)
    ICONS_DIR.mkdir(parents=True, exist_ok=True)

def import_external_apks():
    """Tenta puxar APKs recém-gerados nos diretórios irmãos dos projetos (lacraia, lauda)."""
    src_dir = REPO_ROOT.parent
    
    # 1. Lacraia APKs
    lacraia_dist = src_dir / "lacraia" / "dist"
    if lacraia_dist.exists():
        for apk in ["lacraia-app.apk", "simbiotyka.apk"]:
            src = lacraia_dist / apk
            dst = PRATILERA_DIR / apk
            if src.exists() and not dst.exists():
                shutil.copy2(src, dst)
                print(f"-> Importado do Lacraia: {apk}")

    # 2. Lauda APK
    lauda_apk = src_dir / "lauda" / "site" / "lauda-latest.apk"
    if lauda_apk.exists():
        dst = PRATILERA_DIR / "lauda-latest.apk"
        if not dst.exists():
            shutil.copy2(lauda_apk, dst)
            print("-> Importado do Lauda: lauda-latest.apk")

def create_mock_icons():
    """Gera ícones SVG/PNG para os apps caso não existam."""
    for pkg_id, meta in APPS_METADATA.items():
        icon_path = ICONS_DIR / meta["icon"]
        if not icon_path.exists():
            # Cria um ícone PNG 1x1 ou cópia de favicon existente
            favicon = REPO_ROOT / "site" / "assets" / "favicon.svg"
            if favicon.exists():
                shutil.copy2(favicon, ICONS_DIR / f"{pkg_id}.svg")
            # Mock placeholder PNG básico
            with open(icon_path, "wb") as f:
                # 1x1 transparent PNG bytes
                f.write(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82')

def is_prerelease(version_name: str) -> bool:
    """Detecta se uma versão SemVer do CCCP é considerada pré-release/dev."""
    v = version_name.lower()
    return any(marker in v for marker in ["-dev", "-alpha", "-beta", "-rc", "+"])

def get_project_version(project_name: str, fallback: str = "0.2.0") -> str:
    """Tenta ler a versão canônica do CCCP em VERSION do projeto irmão."""
    candidate = REPO_ROOT.parent / project_name / "VERSION"
    if candidate.exists():
        try:
            val = candidate.read_text(encoding="utf-8").strip()
            if val:
                return val
        except Exception:
            pass
    return fallback

def build_index_v1():
    now_ms = int(time.time() * 1000)
    
    apps_list = []
    packages_map = {}

    for pkg_id, meta in APPS_METADATA.items():
        apk_path = PRATILERA_DIR / meta["apk_filename"]
        has_apk = apk_path.exists()
        apk_size = apk_path.stat().st_size if has_apk else 1024
        apk_hash = sha256_file(apk_path) if has_apk else "0" * 64

        # Resolver versão via CCCP se disponível no projeto irmão
        project_slug = "lacraia" if "lacraia" in pkg_id else ("lauda" if "lauda" in pkg_id else "")
        ver_name = get_project_version(project_slug, meta["version_name"]) if project_slug else meta["version_name"]
        ver_code = meta.get("version_code", 1)

        # Gestão soberana de pré-releases F-Droid
        # suggestedVersionCode define a versão estável; pré-releases não forçam atualização
        is_pre = is_prerelease(ver_name)
        suggested_code = meta.get("stable_version_code", 1) if is_pre else ver_code

        apps_list.append({
            "packageName": pkg_id,
            "name": meta["name"],
            "summary": meta["summary"],
            "description": meta["description"],
            "icon": meta["icon"],
            "added": now_ms,
            "lastUpdated": now_ms,
            "suggestedVersionCode": suggested_code,
            "authorName": "Lumen Pink",
            "license": meta["license"],
            "categories": meta["categories"],
            "webURL": meta["web_url"],
            "sourceCode": meta["source_code"]
        })

        packages_map[pkg_id] = [
            {
                "added": now_ms,
                "apkName": meta["apk_filename"],
                "hash": apk_hash,
                "hashType": "sha256",
                "minSdkVersion": meta["min_sdk"],
                "targetSdkVersion": meta["target_sdk"],
                "packageName": pkg_id,
                "sig": "d41d8cd98f00b204e9800998ecf8427e",
                "signer": "in_twolp",
                "size": apk_size,
                "versionCode": ver_code,
                "versionName": ver_name
            }
        ]

    index_v1 = {
        "repo": {
            "name": "A Pratilera (Banca 2lp)",
            "description": "Loja e Repositório Soberano de Aplicativos do Ecossistema 2lp. Fanzines, paredões, correio e ferramentas de calçada.",
            "address": "https://banca.2lp.in/pratilera",
            "icon": "pratilera.png",
            "timestamp": now_ms,
            "version": 20
        },
        "requests": {
            "install": [],
            "uninstall": []
        },
        "apps": apps_list,
        "packages": packages_map
    }

    index_v1_path = PRATILERA_DIR / "index-v1.json"
    with open(index_v1_path, "w", encoding="utf-8") as f:
        json.dump(index_v1, f, indent=2, ensure_ascii=False)
    print(f"✅ Gerado {index_v1_path}")

    # Index v2 entry
    entry_v2 = {
        "version": 20000,
        "timestamp": now_ms,
        "maxAge": 14,
        "index": {
            "name": "/index-v2.json",
            "sha256": sha256_file(index_v1_path),
            "size": index_v1_path.stat().st_size
        }
    }
    with open(PRATILERA_DIR / "entry.json", "w", encoding="utf-8") as f:
        json.dump(entry_v2, f, indent=2)
    with open(PRATILERA_DIR / "index-v2.json", "w", encoding="utf-8") as f:
        json.dump(index_v1, f, indent=2, ensure_ascii=False)

def package_and_sign_jar():
    index_json = PRATILERA_DIR / "index-v1.json"
    jar_path = PRATILERA_DIR / "index-v1.jar"

    # Criar JAR contendo index-v1.json
    cmd_jar = ["jar", "-cf", str(jar_path), "-C", str(PRATILERA_DIR), "index-v1.json"]
    subprocess.run(cmd_jar, check=True)
    print(f"✅ Empacotado {jar_path}")

    # Localizar chaves de assinatura
    user_home = Path.home()
    keystore = user_home / ".android" / "in_twolp_release.keystore"
    props = user_home / ".android" / "in_twolp_release.properties"
    debug_keystore = user_home / ".android" / "debug.keystore"

    if keystore.exists() and props.exists():
        print(f"-> Assinando com chave oficial in_twolp: {keystore}")
        store_pass = ""
        key_pass = ""
        key_alias = "in_twolp"
        with open(props, "r") as f:
            for line in f:
                if line.startswith("storePassword="):
                    store_pass = line.strip().split("=", 1)[1]
                elif line.startswith("keyPassword="):
                    key_pass = line.strip().split("=", 1)[1]
                elif line.startswith("keyAlias="):
                    key_alias = line.strip().split("=", 1)[1]

        cmd_sign = [
            "jarsigner",
            "-keystore", str(keystore),
            "-storepass", store_pass,
            "-keypass", key_pass,
            str(jar_path),
            key_alias
        ]
        subprocess.run(cmd_sign, check=True)
    elif debug_keystore.exists():
        print(f"-> Assinando com debug.keystore de contingência: {debug_keystore}")
        cmd_sign = [
            "jarsigner",
            "-keystore", str(debug_keystore),
            "-storepass", "android",
            "-keypass", "android",
            str(jar_path),
            "androiddebugkey"
        ]
        subprocess.run(cmd_sign, check=True)
    else:
        # Criar debug keystore efêmero se necessário
        print("-> Gerando debug.keystore efêmero para assinatura...")
        cmd_gen = [
            "keytool", "-genkey", "-v",
            "-keystore", str(jar_path.parent / "temp.keystore"),
            "-storepass", "android",
            "-alias", "tempkey",
            "-keypass", "android",
            "-keyalg", "RSA", "-keysize", "2048", "-validity", "1000",
            "-dname", "CN=Temp,O=Banca,C=BR"
        ]
        subprocess.run(cmd_gen, check=True)
        subprocess.run([
            "jarsigner",
            "-keystore", str(jar_path.parent / "temp.keystore"),
            "-storepass", "android",
            "-keypass", "android",
            str(jar_path),
            "tempkey"
        ], check=True)
        (jar_path.parent / "temp.keystore").unlink(missing_ok=True)

    # Verificar assinatura
    subprocess.run(["jarsigner", "-verify", str(jar_path)], check=True)
    print(f"✅ Assinatura verificada com sucesso em {jar_path}")

def main():
    print("=================================================================")
    print("Banca — Gerador Soberano da Pratilera F-Droid / Droid-ify")
    print("=================================================================")
    ensure_dirs()
    import_external_apks()
    create_mock_icons()
    build_index_v1()
    package_and_sign_jar()
    print("=================================================================")
    print("🎉 Pratilera compilada e assinada com sucesso em site/pratilera!")
    print("=================================================================")

if __name__ == "__main__":
    main()
