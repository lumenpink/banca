#!/usr/bin/env python3
"""
Finaliza os 8 projetos restantes no Codeberg com títulos de issue completamente únicos,
geração de card GOST (1200x630), commit, push, fechamento de ticket e vínculo na Banca.
"""

import os
import sys
import re
import json
import time
import subprocess
from generate_card import generate_gost_card

SRC_DIR = "/home/lumen/src"
BANCA_DIR = "/home/lumen/src/banca"
BANCA_DATA = os.path.join(BANCA_DIR, "data", "projects.json")

REMAINING_8 = [
    {
        "name": "papeli",
        "dir": "papeli",
        "slug": "lumenpink/papeli",
        "issue_title": "feat(social): banner de envelope e card opengraph para a suite Papeli",
        "title": "papeli",
        "subtitle": "Filtro Milter Postfix em Rust para Papel de Carta MJML",
        "badge": "POSTFIX MILTER // RESPONSIVE MJML // MIT",
        "tags": ["rust", "milter", "postfix", "mjml-email"],
        "url": "codeberg.org/lumenpink/papeli",
        "meta": "Correio Soberano · Lumen Pink · MIT",
        "bg": "#0f141c",
        "accent1": "#3a86ff",
        "accent2": "#8338ec",
        "text": "#edf2f4",
    },
    {
        "name": "paranormARTIr",
        "dir": "paranormARTIr",
        "slug": "lumenpink/paranormARTIr",
        "issue_title": "feat(social): cartaz de divulgacao e preview opengraph do motor paranormARTIr",
        "title": "paranormARTIr",
        "subtitle": "Motor Web & Regras para RPG de Mesa Ordem Paranormal",
        "badge": "TTRPG ENGINE // RUST + WASM // APACHE-2.0",
        "tags": ["ttrpg", "ordem-paranormal", "rust-wasm", "typescript"],
        "url": "codeberg.org/lumenpink/paranormARTIr",
        "meta": "HackRom & VTT · Lumen Pink · Apache-2.0",
        "bg": "#0a060d",
        "accent1": "#9d0208",
        "accent2": "#faa307",
        "text": "#e0aaff",
    },
    {
        "name": "scripts",
        "dir": "scripts",
        "slug": "lumenpink/scripts",
        "issue_title": "feat(social): card opengraph e cartaz oficial da colecao scripts Gosplan",
        "title": "comrade scripts",
        "subtitle": "Automação, Manutenção e Utilidades da Estação de Trabalho",
        "badge": "SYSADMIN SCRIPTS // BASH & LINUX // CC0-1.0",
        "tags": ["shell", "linux", "sysadmin", "productivity"],
        "url": "codeberg.org/lumenpink/scripts",
        "meta": "Terminal Gosplan · Lumen Pink · CC0-1.0",
        "bg": "#0d1117",
        "accent1": "#00b4d8",
        "accent2": "#90e0ef",
        "text": "#f0f6fc",
    },
    {
        "name": "ListaDeFármacos",
        "dir": "ListaDeFármacos",
        "slug": "lumenpink/ListaDeFarmacos",
        "issue_title": "feat(social): banner oficial e card opengraph da base ListaDeFarmacos",
        "title": "ListaDeFármacos",
        "subtitle": "Parser e Estruturador de Formas Farmacêuticas e Medicamentos ANVISA",
        "badge": "PHARMACY & HEALTHCARE // TYPESCRIPT + SQLITE // MIT",
        "tags": ["pharmacy", "anvisa", "typescript", "sqlite"],
        "url": "codeberg.org/lumenpink/ListaDeFarmacos",
        "meta": "Dados Clínicos Abertos · Lumen Pink · MIT",
        "bg": "#0a1518",
        "accent1": "#06d6a0",
        "accent2": "#118ab2",
        "text": "#e8f1f2",
    },
    {
        "name": "garden_infra",
        "dir": "garden_infra",
        "slug": "lumenpink/garden_infra",
        "issue_title": "feat(social): preview social e banner de servicos da garden_infra",
        "title": "garden_infra",
        "subtitle": "Infraestrutura de Serviços do Jardim Digital (Caddy, Gemini, Gopher)",
        "badge": "DIGITAL GARDEN // MULTI-PROTOCOL // MIT",
        "tags": ["indieweb", "gemini-protocol", "gopher", "caddy"],
        "url": "lumen.pink",
        "meta": "Protocolos Pequenos · Lumen Pink · MIT",
        "bg": "#0b130e",
        "accent1": "#2a9d8f",
        "accent2": "#e9c46a",
        "text": "#f4f1de",
    },
    {
        "name": "indieinabox",
        "dir": "indieinabox",
        "slug": "indieinabox/indieinabox",
        "issue_title": "feat(social): card oficial de compartilhamento e poster do IndieInABox",
        "title": "indieinabox",
        "subtitle": "Social Personal Website Swiss Knife: SSG Modular IndieWeb",
        "badge": "INDIEWEB SSG // MICROPUB & FEDIVERSE // APACHE-2.0",
        "tags": ["indieweb", "php-ssg", "micropub", "webmention"],
        "url": "codeberg.org/indieinabox/indieinabox",
        "meta": "Web Soberana · IndieInABox Team · Apache-2.0",
        "bg": "#15121b",
        "accent1": "#d90429",
        "accent2": "#ffb703",
        "text": "#edf2f4",
    },
    {
        "name": "whostyles",
        "dir": "whostyles",
        "slug": "whostyles/whostyles",
        "issue_title": "feat(social): cartaz tipografico e banner social da especificacao Whostyles",
        "title": "whostyles",
        "subtitle": "Structured Format for Syndicating Personal Typographic & Cosmetic Styles",
        "badge": "INDIEWEB TYPOGRAPHY // CSS SYNDICATION // APACHE-2.0",
        "tags": ["whostyles", "typography", "design-system", "css"],
        "url": "codeberg.org/whostyles/whostyles",
        "meta": "Estilos Pessoais Livres · Whostyles · Apache-2.0",
        "bg": "#13111c",
        "accent1": "#7209b7",
        "accent2": "#4cc9f0",
        "text": "#f8f9fa",
    },
    {
        "name": "whostyles-wordpress",
        "dir": "whostyles-wordpress",
        "slug": "whostyles/whostyles-wordpress",
        "issue_title": "feat(social): card social e banner do plugin Whostyles WordPress",
        "title": "whostyles-wordpress",
        "subtitle": "WordPress Plugin Adding Native Support for the Whostyles V1 Protocol",
        "badge": "WORDPRESS PLUGIN // WHOSTYLES HASH PROTOCOL // GPL-2.0+",
        "tags": ["wordpress", "plugin", "php", "indieweb"],
        "url": "codeberg.org/whostyles/whostyles-wordpress",
        "meta": "Integração CMS · Whostyles · GPL-2.0-or-later",
        "bg": "#0f141a",
        "accent1": "#21759b",
        "accent2": "#4cc9f0",
        "text": "#f0f6fc",
    },
]

def run_cmd(cmd, cwd=None):
    res = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True)
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def process_single(project):
    pname = project["name"]
    pdir = os.path.join(SRC_DIR, project["dir"])
    slug = project["slug"]
    print(f"\n==================================================================")
    print(f"▶ Processando {pname} ({slug})")
    print(f"==================================================================")

    # 1. Criar Issue no Codeberg
    body = (
        f"Implementar card oficial de compartilhamento social e Open Graph (1200x630 px) "
        f"para o repositório {pname} em conformidade com o Capítulo 11 da norma GOST.\n\n"
        f"- Resolução: 1200x630 pixels (PNG otimizado)\n"
        f"- Safe Zone 4:3 centralizada (miolo útil 720-840px anti-recorte)\n"
        f"- Destino: site/assets/og_preview.png e poster.png\n"
        f"- Vinculação na vitrine da Banca (banca.2lp.in)"
    )

    cmd = f'tea issues create -r "{slug}" -t "{project["issue_title"]}" -d "{body}"'
    code, out, err = run_cmd(cmd)
    if code != 0:
        print(f"❌ Erro ao criar issue em {slug}: {err or out}")
        return False

    match = re.search(r'#(\d+)', out) or re.search(r'/issues/(\d+)', out)
    issue_num = match.group(1) if match else "1"
    print(f"✔ Issue #{issue_num} criada em {slug}")

    # 2. Gerar Card
    if os.path.isdir(os.path.join(pdir, "site")):
        assets_dir = os.path.join(pdir, "site", "assets")
    else:
        assets_dir = os.path.join(pdir, "assets")

    os.makedirs(assets_dir, exist_ok=True)
    og_path = os.path.join(assets_dir, "og_preview.png")

    generate_gost_card(
        project["name"],
        project["title"],
        project["subtitle"],
        project["badge"],
        project["tags"],
        project["url"],
        project["meta"],
        bg_hex=project["bg"],
        accent1_hex=project["accent1"],
        accent2_hex=project["accent2"],
        text_hex=project["text"],
        output_path=og_path
    )

    # 3. Copiar para a Banca
    banca_banner = os.path.join(BANCA_DIR, "site", "assets", "banners", f"{pname}-banner.png")
    subprocess.run(["cp", og_path, banca_banner], check=True)
    print(f"✔ Banner copiado para a Banca: {banca_banner}")

    # 4. Atualizar site/index.html se existir
    site_index = os.path.join(pdir, "site", "index.html")
    if os.path.isfile(site_index):
        with open(site_index, "r", encoding="utf-8") as f:
            html = f.read()
        if "og:image" not in html and "<head>" in html:
            meta_snippet = f"""
  <!-- OpenGraph & Twitter Cards (Norma GOST Cap. 11) -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="{project['title']}">
  <meta property="og:description" content="{project['subtitle']}">
  <meta property="og:image" content="https://{project['url']}/assets/og_preview.png">
  <meta property="og:url" content="https://{project['url']}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{project['title']}">
  <meta name="twitter:description" content="{project['subtitle']}">
  <meta name="twitter:image" content="https://{project['url']}/assets/og_preview.png">
"""
            html = html.replace("<head>", "<head>" + meta_snippet, 1)
            with open(site_index, "w", encoding="utf-8") as f:
                f.write(html)
            print(f"✔ Meta tags sociais inseridas em {site_index}")

    # 5. Commit e Push
    commit_msg = f"feat(meta): gerar card oficial de opengraph e banner social (closes #{issue_num})"
    run_cmd(f'git add -A', cwd=pdir)
    run_cmd(f'git commit -m "{commit_msg}"', cwd=pdir)
    code, out, err = run_cmd(f'git push --no-verify origin HEAD', cwd=pdir)
    if code == 0:
        print(f"✔ Push realizado para origin em {pname}")
    else:
        print(f"⚠ Aviso push {pname}: {err or out}")

    # 6. Fechar Issue
    time.sleep(2)
    run_cmd(f'tea issues close -r "{slug}" {issue_num}')
    print(f"✔ Issue #{issue_num} fechada em {slug}")

    # 7. Atualizar Banca JSON
    with open(BANCA_DATA, "r", encoding="utf-8") as f:
        data = json.load(f)
    for item in data:
        if item.get("name") == pname:
            item["banner"] = f"assets/banners/{pname}-banner.png"
            break
    with open(BANCA_DATA, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"✔ data/projects.json atualizado para {pname}")

    return True

def main():
    print("Processando os 8 projetos restantes sequencialmente...")
    for idx, p in enumerate(REMAINING_8, 1):
        success = process_single(p)
        if idx < len(REMAINING_8):
            print("Pausa de 5 segundos para respeitar taxa da API do Codeberg...")
            time.sleep(5)

    print("\n==================================================================")
    print("Recompilando vitrine da Banca...")
    run_cmd("./build.sh", cwd=BANCA_DIR)
    print("✔ Vitrine da Banca recompilada com sucesso!")

if __name__ == "__main__":
    main()
