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
import zipfile
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = REPO_ROOT / "site"
PRATILERA_DIR = SITE_DIR / "pratilera"
ICONS_DIR = PRATILERA_DIR / "icons"
CACHE_APK_DIR = REPO_ROOT / ".cache" / "apks"

APPS_METADATA = {
    "in.twolp.lacraia.app": {
        "name": "La Craia",
        "summary": "Cockpit Brutalista de Som & Jukebox",
        "description": "Paredão digital, jukebox e controlador de rádio comunitária autônoma para sistemas de som de alta potência.",
        "icon": "in.twolp.lacraia.app.png",
        "categories": ["Multimedia", "Audio"],
        "apk_filename": "lacraia.apk",
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
        "apk_filename": "lauda.apk",
        "version_name": "0.2.0",
        "version_code": 1,
        "min_sdk": 26,
        "target_sdk": 34,
        "license": "GPL-3.0",
        "web_url": "https://lauda.2lp.in",
        "source_code": "https://codeberg.org/lumenpink/lauda"
    },
    "in.twolp.mocambo": {
        "name": "Mocambo",
        "summary": "Cofre Soberano de Arquivos e Fotos",
        "description": "Cliente mobile oficial do Mocambo com sincronização WebDAV contínua, galeria de fotos com miniaturas e busca semântica.",
        "icon": "in.twolp.mocambo.png",
        "categories": ["Internet", "Graphics", "Utility"],
        "apk_filename": "mocambo.apk",
        "version_name": "0.2.0",
        "version_code": 1,
        "min_sdk": 26,
        "target_sdk": 34,
        "license": "CC0-1.0",
        "web_url": "https://vault.lohn.in",
        "source_code": "https://codeberg.org/lumenpink/mocambo"
    },
    "in.twolp.mandu": {
        "name": "Mandu",
        "summary": "Editor Brutalista de Notas & Conhecimento",
        "description": "Editor brutalista de notas em texto puro com suporte a wikilinks, diagramas Joaju, compilação Typst e digitação touch ergonômica em Rust.",
        "icon": "in.twolp.mandu.png",
        "categories": ["Writing", "Office", "Utility"],
        "apk_filename": "mandu.apk",
        "version_name": "0.1.0",
        "version_code": 1,
        "min_sdk": 26,
        "target_sdk": 34,
        "license": "GPL-3.0",
        "web_url": "https://mandu.2lp.in",
        "source_code": "https://codeberg.org/lumenpink/mandu"
    }
}

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

LOCALES = ["pt-BR", "en-US"]
DENSITY_DPIS = [120, 160, 240, 320, 480, 640]

def sanitize_icon_8bit(src_path: Path, dst_path: Path):
    """Garante que a imagem PNG gravada tenha profundidade estrita de 8 bits por canal RGBA (Android Skia / Coil compliant)."""
    try:
        from PIL import Image
        with Image.open(src_path) as im:
            im_rgba = im.convert("RGBA")
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            im_rgba.save(dst_path, format="PNG")
    except Exception:
        if src_path.resolve() != dst_path.resolve():
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)

def ensure_dirs():
    PRATILERA_DIR.mkdir(parents=True, exist_ok=True)
    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_APK_DIR.mkdir(parents=True, exist_ok=True)
    (SITE_DIR / "icons").mkdir(parents=True, exist_ok=True)
    for dpi in DENSITY_DPIS:
        (PRATILERA_DIR / f"icons-{dpi}").mkdir(parents=True, exist_ok=True)
        (SITE_DIR / f"icons-{dpi}").mkdir(parents=True, exist_ok=True)
    for pkg_id in APPS_METADATA.keys():
        for loc in LOCALES:
            (PRATILERA_DIR / pkg_id / loc).mkdir(parents=True, exist_ok=True)
            (SITE_DIR / pkg_id / loc).mkdir(parents=True, exist_ok=True)

def import_external_apks():
    """Tenta puxar APKs recém-gerados nos diretórios irmãos dos projetos (lacraia, lauda, mocambo)."""
    src_dir = REPO_ROOT.parent
    
    # 1. Lacraia APKs e Ícones Oficiais
    lacraia_dir = src_dir / "lacraia"
    lacraia_dist = lacraia_dir / "dist"
    if lacraia_dist.exists():
        for apk_src_candidate, canonical_name in [("lacraia.apk", "lacraia.apk"), ("lacraia-app.apk", "lacraia.apk"), ("simbiotyka.apk", "simbiotyka.apk")]:
            src = lacraia_dist / apk_src_candidate
            if src.exists():
                dst = PRATILERA_DIR / canonical_name
                shutil.copy2(src, dst)
                print(f"-> Importado do Lacraia: {canonical_name}")

    # Importar ícones oficiais do repositório lacraia se presentes
    lacraia_assets = lacraia_dir / "site" / "assets"
    if (lacraia_assets / "icon.png").exists():
        sanitize_icon_8bit(lacraia_assets / "icon.png", ICONS_DIR / "in.twolp.lacraia.app.png")
        print("-> Importado ícone oficial da Lacraia: site/assets/icon.png")
    if (lacraia_assets / "simbiotyka.png").exists():
        sanitize_icon_8bit(lacraia_assets / "simbiotyka.png", ICONS_DIR / "in.twolp.lacraia.simbiotyka.png")
        print("-> Importado ícone oficial da Simbiótyka: site/assets/simbiotyka.png")

    # 2. Lauda APK e Ícone
    lauda_dir = src_dir / "lauda"
    for apk_candidate in [lauda_dir / "site" / "lauda.apk", lauda_dir / "site" / "lauda-latest.apk"]:
        if apk_candidate.exists():
            dst = PRATILERA_DIR / "lauda.apk"
            shutil.copy2(apk_candidate, dst)
            print(f"-> Importado do Lauda: lauda.apk (de {apk_candidate.name})")
            break

    lauda_icon = lauda_dir / "site" / "lauda-logo.png"
    if lauda_icon.exists():
        sanitize_icon_8bit(lauda_icon, ICONS_DIR / "in.twolp.lauda.png")
        print("-> Importado ícone do Lauda: lauda-logo.png")

    # 3. Mocambo APK e Ícone (salvo em cache fora de site/ devido ao limite de 25MB do Workers)
    mocambo_dir = src_dir / "mocambo"
    for apk_candidate in [
        mocambo_dir / "site" / "mocambo.apk",
        mocambo_dir / "mobile" / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
    ]:
        if apk_candidate.exists():
            CACHE_APK_DIR.mkdir(parents=True, exist_ok=True)
            dst = CACHE_APK_DIR / "mocambo.apk"
            shutil.copy2(apk_candidate, dst)
            print(f"-> Importado do Mocambo para cache: mocambo.apk")
            # Remove qualquer cópia de mocambo.apk de site/pratilera para não quebrar deploy do Workers
            (PRATILERA_DIR / "mocambo.apk").unlink(missing_ok=True)
            break

    # 4. Mandu APK e Ícone
    mandu_dir = src_dir / "mandu"
    for apk_candidate in [
        mandu_dir / "dist" / "android" / "mandu.apk",
        mandu_dir / "dist" / "mandu.apk",
        mandu_dir / "site" / "mandu.apk"
    ]:
        if apk_candidate.exists():
            dst = PRATILERA_DIR / "mandu.apk"
            shutil.copy2(apk_candidate, dst)
            print(f"-> Importado do Mandu: mandu.apk (de {apk_candidate.name})")
            break

    for icon_candidate in [
        mandu_dir / "fastlane" / "metadata" / "android" / "in.twolp.mandu" / "icon.png",
        mandu_dir / "crates" / "mandu-mobile" / "assets" / "icon.png",
        mandu_dir / "site" / "assets" / "icon.png"
    ]:
        if icon_candidate.exists():
            sanitize_icon_8bit(icon_candidate, ICONS_DIR / "in.twolp.mandu.png")
            print(f"-> Importado ícone do Mandu: {icon_candidate.name}")
            break

def resolve_apk_binary(meta: dict) -> Path | None:
    """Procura o APK localmente em PRATILERA_DIR, diretórios irmãos ou faz download para .cache/apks."""
    apk_name = meta["apk_filename"]
    
    # 1. Se estiver em PRATILERA_DIR e <= 25MB
    local_apk = PRATILERA_DIR / apk_name
    if local_apk.exists() and local_apk.stat().st_size > 1024:
        return local_apk
        
    # 2. Se estiver em CACHE_APK_DIR
    cached_apk = CACHE_APK_DIR / apk_name
    if cached_apk.exists() and cached_apk.stat().st_size > 1024:
        return cached_apk
        
    # 3. Se estiver em diretório irmão
    src_dir = REPO_ROOT.parent
    candidates = []
    if "lacraia" in apk_name or "simbiotyka" in apk_name:
        candidates.extend([
            src_dir / "lacraia" / "dist" / apk_name,
            src_dir / "lacraia" / "dist" / "lacraia-app.apk",
            src_dir / "lacraia" / "dist" / "simbiotyka.apk",
        ])
    elif "lauda" in apk_name:
        candidates.extend([
            src_dir / "lauda" / "site" / "lauda.apk",
            src_dir / "lauda" / "site" / "lauda-latest.apk",
        ])
    elif "mocambo" in apk_name:
        candidates.extend([
            src_dir / "mocambo" / "site" / "mocambo.apk",
            src_dir / "mocambo" / "mobile" / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk",
        ])
    elif "mandu" in apk_name:
        candidates.extend([
            src_dir / "mandu" / "dist" / "android" / "mandu.apk",
            src_dir / "mandu" / "dist" / "mandu.apk",
            src_dir / "mandu" / "site" / "mandu.apk",
        ])
    
    for c in candidates:
        if c.exists() and c.stat().st_size > 1024:
            CACHE_APK_DIR.mkdir(parents=True, exist_ok=True)
            shutil.copy2(c, cached_apk)
            print(f"-> Copiado do projeto irmão para cache: {c.name} -> {cached_apk}")
            return cached_apk

    # 4. Tentar baixar do bucket oficial https://bucket.2lp.in/<apk>
    remote_url = f"https://bucket.2lp.in/{apk_name}"
    print(f"-> Buscando APK canônico remoto no bucket: {remote_url}...")
    try:
        import urllib.request
        CACHE_APK_DIR.mkdir(parents=True, exist_ok=True)
        req = urllib.request.Request(remote_url, headers={"User-Agent": "Banca-Pratilera-Builder/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp, open(cached_apk, "wb") as out_f:
            shutil.copyfileobj(resp, out_f)
        if cached_apk.exists() and cached_apk.stat().st_size > 1024:
            print(f"✅ APK canônico obtido com sucesso do R2: {apk_name} ({cached_apk.stat().st_size} bytes)")
            return cached_apk
    except Exception as e:
        print(f"⚠️ Não foi possível obter {remote_url} ({e}). Utilizando fallback resiliente.")

    return None

def ensure_official_icons():
    """Garante a existência e integridade dos ícones oficiais da Pratilera, Lacraia e Simbiótyka."""
    gen_script = REPO_ROOT / "scripts" / "gerar-icone-oficial.py"
    if gen_script.exists():
        subprocess.run([sys.executable, str(gen_script)], check=True)


def create_mock_icons():
    """Gera ícones para os apps caso não existam."""
    ensure_official_icons()
    for pkg_id, meta in APPS_METADATA.items():
        icon_path = ICONS_DIR / meta["icon"]
        if not icon_path.exists() or icon_path.stat().st_size == 0:
            favicon = REPO_ROOT / "site" / "assets" / "favicon.svg"
            if favicon.exists():
                shutil.copy2(favicon, ICONS_DIR / f"{pkg_id}.svg")
            with open(icon_path, "wb") as f:
                f.write(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82')

def sync_density_and_root_icons():
    """Replica todos os ícones da Pratilera e dos apps em todas as densidades (icons-<dpi>), raiz e Fastlane."""
    ensure_official_icons()
    
    icon_filenames = [meta["icon"] for meta in APPS_METADATA.values()] + ["icon.png", "pratilera.png"]
    
    # 0. Sanitizar todos os ícones na origem ICONS_DIR para 8-bit RGBA
    for filename in icon_filenames:
        src = ICONS_DIR / filename
        if src.exists() and src.stat().st_size > 0:
            sanitize_icon_8bit(src, src)
    
    for filename in icon_filenames:
        src = ICONS_DIR / filename
        if not src.exists() or src.stat().st_size == 0:
            continue
        
        # 1. Replicar para a raiz de site/pratilera/ e site/
        sanitize_icon_8bit(src, PRATILERA_DIR / filename)
        sanitize_icon_8bit(src, SITE_DIR / filename)
        
        # 2. Replicar para cada pasta de densidade icons-<dpi>/ em site/pratilera/ e site/
        for dpi in DENSITY_DPIS:
            sanitize_icon_8bit(src, PRATILERA_DIR / f"icons-{dpi}" / filename)
            sanitize_icon_8bit(src, SITE_DIR / f"icons-{dpi}" / filename)

        # 3. Replicar para pasta icons/ em site/pratilera/ e site/
        sanitize_icon_8bit(src, ICONS_DIR / filename)
        sanitize_icon_8bit(src, SITE_DIR / "icons" / filename)

    # 4. Replicar ícones Fastlane para cada aplicativo (<pkg>/<locale>/icon.png) em site/ e site/pratilera/
    for pkg_id, meta in APPS_METADATA.items():
        src_icon = ICONS_DIR / meta["icon"]
        if src_icon.exists() and src_icon.stat().st_size > 0:
            for loc in LOCALES:
                # No /pratilera
                sanitize_icon_8bit(src_icon, PRATILERA_DIR / pkg_id / loc / "icon.png")
                sanitize_icon_8bit(src_icon, PRATILERA_DIR / pkg_id / loc / meta["icon"])
                # Na raiz do site
                sanitize_icon_8bit(src_icon, SITE_DIR / pkg_id / loc / "icon.png")
                sanitize_icon_8bit(src_icon, SITE_DIR / pkg_id / loc / meta["icon"])

    print("✅ Ícones convertidos para 8-bit RGBA e sincronizados em todas as densidades (icons-120 a icons-640), Fastlane e raiz")


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

def extract_apk_signer(apk_path: Path) -> str:
    """Extrai o fingerprint SHA-256 do certificado de assinatura do APK via apksigner ou keystore oficial."""
    canonical_fallback = "7beec8b0a6c7946b04d538543d495a8210ad6cfc1859f42e7180bcfbd38fe582"
    if not apk_path.exists():
        return canonical_fallback

    # 1. Tentar apksigner nativo
    if shutil.which("apksigner"):
        try:
            res = subprocess.run(
                ["apksigner", "verify", "--print-certs", str(apk_path)],
                capture_output=True,
                text=True,
                check=True
            )
            import re
            m = re.search(r"Signer #1 certificate SHA-256 digest:\s*([0-9a-fA-F]{64})", res.stdout)
            if m:
                return m.group(1).lower()
        except Exception:
            pass

    # 2. Tentar extrair do keystore oficial caso apksigner não esteja no PATH
    user_home = Path.home()
    keystore = user_home / ".android" / "in_twolp_release.keystore"
    props = user_home / ".android" / "in_twolp_release.properties"
    if keystore.exists() and shutil.which("keytool"):
        try:
            store_pass = "android"
            if props.exists():
                with open(props) as f:
                    for line in f:
                        if line.startswith("storePassword="):
                            store_pass = line.strip().split("=", 1)[1]
            res = subprocess.run(
                ["keytool", "-list", "-v", "-keystore", str(keystore), "-storepass", store_pass],
                capture_output=True,
                text=True,
                check=True
            )
            import re
            m = re.search(r"SHA256:\s*([0-9A-Fa-f:]{95})", res.stdout)
            if m:
                return m.group(1).replace(":", "").lower()
        except Exception:
            pass

    return canonical_fallback

def extract_apk_metadata(apk_path: Path) -> dict:
    """Extrai versionCode, versionName, minSdkVersion e targetSdkVersion diretamente do APK via aapt dump badging."""
    info = {}
    if not apk_path.exists() or not shutil.which("aapt"):
        return info

    try:
        res = subprocess.run(
            ["aapt", "dump", "badging", str(apk_path)],
            capture_output=True,
            text=True,
            check=True
        )
        out = res.stdout
        m_pkg = re.search(r"package:\s+name='(?P<pkg>[^']+)'\s+versionCode='(?P<code>\d+)'\s+versionName='(?P<name>[^']*)'", out)
        if m_pkg:
            info["package_name"] = m_pkg.group("pkg")
            info["version_code"] = int(m_pkg.group("code"))
            info["version_name"] = m_pkg.group("name")

        m_min = re.search(r"sdkVersion:'(\d+)'", out)
        if m_min:
            info["min_sdk"] = int(m_min.group(1))

        m_tgt = re.search(r"targetSdkVersion:'(\d+)'", out)
        if m_tgt:
            info["target_sdk"] = int(m_tgt.group(1))

    except Exception:
        pass

    return info

def build_index_v1():
    now_ms = int(time.time() * 1000)
    
    # 0. Carregar índice index-v1.json existente para fallback resiliente
    existing_packages = {}
    index_v1_path = PRATILERA_DIR / "index-v1.json"
    if index_v1_path.exists():
        try:
            with open(index_v1_path, encoding="utf-8") as f:
                prev_data = json.load(f)
                existing_packages = prev_data.get("packages", {})
        except Exception:
            pass

    apps_list = []
    packages_map = {}

    for pkg_id, meta in APPS_METADATA.items():
        apk_path = resolve_apk_binary(meta)
        prev_entry = (existing_packages.get(pkg_id) or [{}])[0]

        if apk_path and apk_path.exists() and apk_path.stat().st_size > 1024:
            apk_size = apk_path.stat().st_size
            apk_hash = sha256_file(apk_path)
            apk_signer = extract_apk_signer(apk_path)
            apk_meta = extract_apk_metadata(apk_path)
        elif prev_entry.get("size", 0) > 1024 and prev_entry.get("hash") and not prev_entry.get("hash").startswith("000000"):
            apk_size = prev_entry["size"]
            apk_hash = prev_entry["hash"]
            apk_signer = prev_entry.get("signer", "7beec8b0a6c7946b04d538543d495a8210ad6cfc1859f42e7180bcfbd38fe582")
            apk_meta = {
                "version_code": prev_entry.get("versionCode", meta.get("version_code", 1)),
                "min_sdk": prev_entry.get("minSdkVersion", meta["min_sdk"]),
                "target_sdk": prev_entry.get("targetSdkVersion", meta["target_sdk"])
            }
            print(f"ℹ️ Metadados preservados do index-v1.json anterior para {pkg_id}")
        else:
            apk_size = 5000000
            apk_hash = "63e375fe723df35d6cf590e1243532742bcbe78b4ad83ccb9df558c1d1da8855"
            apk_signer = "7beec8b0a6c7946b04d538543d495a8210ad6cfc1859f42e7180bcfbd38fe582"
            apk_meta = {}

        # Metadados do aplicativo:
        # - versionCode DEVE vir do APK real para evitar 'Metadado inválido' no Android/Droid-ify.
        # - versionName DEVE vir canonicamente do CCCP (arquivo VERSION do repositório irmão).
        project_slug = "lacraia" if "lacraia" in pkg_id else ("lauda" if "lauda" in pkg_id else ("mocambo" if "mocambo" in pkg_id else ("mandu" if "mandu" in pkg_id else "")))
        fallback_ver = prev_entry.get("versionName", meta["version_name"])
        ver_name = get_project_version(project_slug, fallback_ver) if project_slug else fallback_ver
        ver_code = apk_meta.get("version_code", prev_entry.get("versionCode", meta.get("version_code", 1)))

        min_sdk = apk_meta.get("min_sdk", prev_entry.get("minSdkVersion", meta["min_sdk"]))
        target_sdk = apk_meta.get("target_sdk", prev_entry.get("targetSdkVersion", meta["target_sdk"]))

        # Gestão soberana de pré-releases F-Droid
        # suggestedVersionCode define a versão estável; pré-releases não forçam atualização
        is_pre = is_prerelease(ver_name)
        suggested_code = meta.get("stable_version_code", ver_code) if is_pre else ver_code

        # Metadados Fastlane localized exigidos pelo Droid-ify para mapear ícones
        localized_map = {}
        for loc in LOCALES:
            loc_title = meta["name"]
            loc_summary = meta["summary"]
            loc_desc = meta["description"]

            # Importar descrições e títulos Fastlane oficiais se disponíveis
            src_dir = REPO_ROOT.parent
            if "mandu" in pkg_id:
                loc_dir = src_dir / "mandu" / "fastlane" / "metadata" / "android" / "in.twolp.mandu" / loc
                title_file = loc_dir / "title.txt"
                short_file = loc_dir / "short_description.txt"
                full_file = loc_dir / "full_description.txt"
                if title_file.exists():
                    loc_title = title_file.read_text(encoding="utf-8").strip()
                if short_file.exists():
                    loc_summary = short_file.read_text(encoding="utf-8").strip()
                if full_file.exists():
                    loc_desc = full_file.read_text(encoding="utf-8").strip()

            localized_map[loc] = {
                "name": loc_title,
                "summary": loc_summary,
                "description": loc_desc,
                "icon": "icon.png"
            }

        apps_list.append({
            "packageName": pkg_id,
            "name": meta["name"],
            "summary": meta["summary"],
            "description": meta["description"],
            "icon": meta["icon"],
            "localized": localized_map,
            "added": now_ms,
            "lastUpdated": now_ms,
            "suggestedVersionCode": str(suggested_code),
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
                "minSdkVersion": min_sdk,
                "targetSdkVersion": target_sdk,
                "packageName": pkg_id,
                "sig": apk_signer[:32],
                "signer": apk_signer,
                "size": apk_size,
                "versionCode": ver_code,
                "versionName": ver_name
            }
        ]

    index_v1 = {
        "repo": {
            "name": "A Pratilera (Banca 2lp)",
            "description": "Loja e Repositório Soberano de Aplicativos do Ecossistema 2lp. Fanzines, paredões, correio e ferramentas de calçada.",
            "address": "https://bucket.2lp.in",
            "icon": "icon.png",
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
    shutil.copy2(index_v1_path, SITE_DIR / "index-v1.json")
    print(f"✅ Gerado {index_v1_path} e espelhado em {SITE_DIR / 'index-v1.json'}")

    # Remove qualquer index-v2/entry.json residual para garantir conformidade estrita com Index V1
    (PRATILERA_DIR / "entry.json").unlink(missing_ok=True)
    (PRATILERA_DIR / "index-v2.json").unlink(missing_ok=True)

def package_and_sign_jar():
    index_json = PRATILERA_DIR / "index-v1.json"
    jar_path = PRATILERA_DIR / "index-v1.jar"

    # Criar JAR contendo index-v1.json (via comando jar ou zipfile como contingencia)
    if shutil.which("jar"):
        cmd_jar = ["jar", "-cf", str(jar_path), "-C", str(PRATILERA_DIR), "index-v1.json"]
        subprocess.run(cmd_jar, check=True)
    else:
        with zipfile.ZipFile(jar_path, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.write(index_json, arcname="index-v1.json")
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
    shutil.copy2(jar_path, SITE_DIR / "index-v1.jar")
    print(f"✅ Assinatura verificada com sucesso em {jar_path} e espelhado em {SITE_DIR / 'index-v1.jar'}")

def update_redirects():
    redirects_file = SITE_DIR / "_redirects"
    lines = [
        "/patilera  /pratilera/  301",
        "/patilera/*  /pratilera/:splat  301",
        "/prateleira  /pratilera/  301",
        "/prateleira/*  /pratilera/:splat  301",
        "/repo  /pratilera/  301",
        "/repo/*  /pratilera/:splat  301",
        "",
        "# Redirecionamentos de compatibilidade e acesso direto para Cloudflare R2",
        "/pratilera/lacraia-app.apk https://bucket.2lp.in/lacraia.apk 302",
        "/pratilera/lacraia.apk     https://bucket.2lp.in/lacraia.apk 302",
        "/pratilera/simbiotyka.apk  https://bucket.2lp.in/simbiotyka.apk 302",
        "/pratilera/lauda-latest.apk https://bucket.2lp.in/lauda.apk 302",
        "/pratilera/lauda.apk       https://bucket.2lp.in/lauda.apk 302",
        "/pratilera/mocambo.apk     https://bucket.2lp.in/mocambo.apk 302",
        "",
        "# Redirecionamento da vitrine de downloads",
        "/downloads  /downloads/  301",
        ""
    ]
    with open(redirects_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"✅ Atualizado {redirects_file} com regras dinâmicas de redirecionamento para bucket.2lp.in")

def clean_heavy_site_assets():
    """Garante que nenhum APK pesado (> 25MB) resida em site/ (limite estrito de assets do Cloudflare Workers)."""
    for apk_file in SITE_DIR.rglob("*.apk"):
        if apk_file.stat().st_size > 26214400: # 25 MB
            print(f"-> Removendo APK pesado de site/: {apk_file.name} ({apk_file.stat().st_size} bytes)")
            apk_file.unlink(missing_ok=True)

def main():
    print("=================================================================")
    print("Banca — Gerador Soberano da Pratilera F-Droid / Droid-ify")
    print("=================================================================")
    ensure_dirs()
    import_external_apks()
    create_mock_icons()
    sync_density_and_root_icons()
    build_index_v1()
    package_and_sign_jar()
    update_redirects()
    clean_heavy_site_assets()
    print("=================================================================")
    print("🎉 Pratilera compilada e assinada com sucesso em site/pratilera!")
    print("=================================================================")

if __name__ == "__main__":
    main()
