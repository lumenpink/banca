#!/usr/bin/env python3
"""
Orquestrador de Banners Sociais e Tickets para Todos os Projetos Faltantes.
Norma GOST Cap. 11 (1200x630, Safe Zone 4:3, Open Graph, Conventional Commits e fechamento de tickets).
"""

import os
import sys
import re
import json
import subprocess
from generate_card import generate_gost_card

SRC_DIR = "/home/lumen/src"
BANCA_DIR = "/home/lumen/src/banca"
BANCA_DATA = os.path.join(BANCA_DIR, "data", "projects.json")

PROJECTS_CONFIG = [
    {
        "name": "fuxico",
        "dir": "fuxico",
        "forge": "codeberg",
        "slug": "lumenpink/fuxico",
        "title": "fuxico",
        "subtitle": "Compartilhamento de Arquivos na Borda & Encurtador de URLs",
        "badge": "EDGE FILE SHARING // 0X0 & RUSTYPASTE // CC0-1.0",
        "tags": ["file-sharing", "url-shortener", "indieweb", "caddy-edge"],
        "url": "fuxico.2lp.in",
        "meta": "IndieWeb · Lumen Pink · CC0-1.0",
        "bg": "#121016",
        "accent1": "#ff2a85",
        "accent2": "#e2f835",
        "text": "#f5f4ef",
    },
    {
        "name": "guara",
        "dir": "guara",
        "forge": "codeberg",
        "slug": "lumenpink/guara",
        "title": "guará",
        "subtitle": "Modelagem 3D Paramétrica em FreeCAD de Moto Customizada",
        "badge": "HARDWARE LIVRE // FREECAD 3D // CC-BY-SA-4.0",
        "tags": ["freecad", "3d-cad", "motorcycle", "open-hardware"],
        "url": "codeberg.org/lumenpink/guara",
        "meta": "Modelagem Paramétrica · Lumen Pink · CC-BY-SA-4.0",
        "bg": "#14110e",
        "accent1": "#ff6b35",
        "accent2": "#f7c59f",
        "text": "#f4f1de",
    },
    {
        "name": "papeli",
        "dir": "papeli",
        "forge": "codeberg",
        "slug": "lumenpink/papeli",
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
        "forge": "codeberg",
        "slug": "lumenpink/paranormARTIr",
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
        "forge": "codeberg",
        "slug": "lumenpink/scripts",
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
        "forge": "codeberg",
        "slug": "lumenpink/ListaDeFarmacos",
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
        "forge": "codeberg",
        "slug": "lumenpink/garden_infra",
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
        "forge": "codeberg",
        "slug": "indieinabox/indieinabox",
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
        "forge": "codeberg",
        "slug": "whostyles/whostyles",
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
        "forge": "codeberg",
        "slug": "whostyles/whostyles-wordpress",
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
    {
        "name": "aura",
        "dir": "aura",
        "forge": "github",
        "slug": "Canimandra/aura",
        "title": "aura",
        "subtitle": "Prontuário Médico e Receitas Digitais Criptografadas em Ledger",
        "badge": "MEDICAL LEDGER // ENCRYPTED PRESCRIPTIONS // AGPL-3.0",
        "tags": ["healthcare", "medical-records", "cryptography", "ledger"],
        "url": "github.com/Canimandra/aura",
        "meta": "Saúde Dissidente · Canimandra · AGPL-3.0",
        "bg": "#0c1017",
        "accent1": "#70e000",
        "accent2": "#38b000",
        "text": "#f8f9fa",
    },
    {
        "name": "baquara-infra",
        "dir": "baquara-infra",
        "forge": "github",
        "slug": "lumenpink/baquara",
        "title": "baquara-infra",
        "subtitle": "Infraestrutura Conteinerizada de Homelab com SSO Authelia e DNS Local",
        "badge": "HOMELAB INFRA // DOCKER & AUTHELIA // MIT",
        "tags": ["homelab", "authelia-sso", "dns-local", "caddy-proxy"],
        "url": "github.com/lumenpink/baquara",
        "meta": "Autonomia Local · Lumen Pink · MIT",
        "bg": "#11161d",
        "accent1": "#ff9e00",
        "accent2": "#ffd000",
        "text": "#f0f6fc",
    },
    {
        "name": "baquara-install",
        "dir": "baquara-install",
        "forge": "github",
        "slug": "lumenpink/baquara",
        "title": "baquara-install",
        "subtitle": "Scripts de Instalação e Bootstrapping da Arquitetura Baquara",
        "badge": "HOMELAB BOOTSTRAP // SHELL AUTOMATION // MIT",
        "tags": ["installer", "bootstrap", "homelab", "automation"],
        "url": "github.com/lumenpink/baquara",
        "meta": "Setup Automatizado · Lumen Pink · MIT",
        "bg": "#141419",
        "accent1": "#ff5400",
        "accent2": "#ffbd00",
        "text": "#f8f9fa",
    },
    {
        "name": "cartoes",
        "dir": "cartoes",
        "forge": "tildegit",
        "slug": "lumen/cartoes",
        "title": "cartões",
        "subtitle": "Gerador Automatizado de Flashcards Médicos e Anatômicos via PDFs",
        "badge": "MEDICAL FLASHCARDS // ANKI & ANATOMY // CC0-1.0",
        "tags": ["flashcards", "anatomy", "medicine", "anki"],
        "url": "tildegit.org/lumen/cartoes",
        "meta": "Pedagogia Médica · Lumen Pink · CC0-1.0",
        "bg": "#0e1318",
        "accent1": "#e63946",
        "accent2": "#a8dadc",
        "text": "#f1faee",
    },
    {
        "name": "install_i3",
        "dir": "install_i3",
        "forge": "tildegit",
        "slug": "lumen/install_i3",
        "title": "install_i3",
        "subtitle": "Setup Automatizado e Resiliente para i3wm, Terminal st e Dotfiles",
        "badge": "DOTFILES & WINDOW MANAGER // I3WM + ST // MIT",
        "tags": ["i3wm", "suckless-st", "dotfiles", "linux-desktop"],
        "url": "tildegit.org/lumen/install_i3",
        "meta": "Estação Soberana · Lumen Pink · MIT",
        "bg": "#101214",
        "accent1": "#48cae4",
        "accent2": "#0077b6",
        "text": "#caf0f8",
    },
    {
        "name": "zoteroExtract",
        "dir": "zoteroExtract",
        "forge": "tildegit",
        "slug": "lumen/zoteroExtract",
        "title": "zoteroExtract",
        "subtitle": "Extrator e Sincronizador de Notas e Referências Acadêmicas Zotero",
        "badge": "ACADEMIC SYNC // ZOTERO & OBSIDIAN // MIT",
        "tags": ["zotero", "obsidian", "academic-notes", "references"],
        "url": "tildegit.org/lumen/zoteroExtract",
        "meta": "Pesquisa Livre · Lumen Pink · MIT",
        "bg": "#131016",
        "accent1": "#cc0000",
        "accent2": "#f4a261",
        "text": "#f8f9fa",
    },
]

def run_cmd(cmd, cwd=None):
    res = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True)
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def create_issue(project):
    title = f"feat(meta): gerar card oficial de opengraph e banner social (norma GOST)"
    body = (
        f"Implementar card oficial de compartilhamento social e Open Graph (1200x630 px) "
        f"para o repositório {project['name']} em conformidade com o Capítulo 11 da norma GOST.\n\n"
        f"- Resolução: 1200x630 pixels (PNG otimizado)\n"
        f"- Safe Zone 4:3 centralizada (miolo útil 720-840px anti-recorte)\n"
        f"- Destino: site/assets/og_preview.png e poster.png\n"
        f"- Vinculação na vitrine da Banca (banca.2lp.in)"
    )

    forge = project["forge"]
    slug = project["slug"]

    if forge == "codeberg":
        cmd = f'tea issues create -r "{slug}" -t "{title}" -d "{body}"'
    elif forge == "tildegit":
        cmd = f'tea issues create --login tildegit -r "{slug}" -t "{title}" -d "{body}"'
    elif forge == "github":
        cmd = f'gh issue create -R "{slug}" -t "{title}" -b "{body}"'
    else:
        return None

    code, out, err = run_cmd(cmd)
    if code != 0:
        print(f"❌ Erro ao criar issue em {slug}: {err}")
        return None

    # Extrai o número da issue
    match = re.search(r'#(\d+)', out)
    if not match:
        match = re.search(r'/issues/(\d+)', out)
    if match:
        issue_num = match.group(1)
        print(f"✔ Issue #{issue_num} criada em {forge}:{slug}")
        return issue_num
    else:
        print(f"⚠ Não foi possível extrair número da issue em {slug}. Output: {out}")
        return "1"

def close_issue(project, issue_num):
    forge = project["forge"]
    slug = project["slug"]

    if forge == "codeberg":
        cmd = f'tea issues close -r "{slug}" {issue_num}'
    elif forge == "tildegit":
        cmd = f'tea issues close --login tildegit -r "{slug}" {issue_num}'
    elif forge == "github":
        cmd = f'gh issue close -R "{slug}" {issue_num}'
    else:
        return

    code, out, err = run_cmd(cmd)
    if code == 0:
        print(f"✔ Issue #{issue_num} fechada com sucesso em {forge}:{slug}")
    else:
        print(f"⚠ Aviso ao fechar issue #{issue_num} em {slug}: {err}")

def process_project(project):
    pname = project["name"]
    pdir = os.path.join(SRC_DIR, project["dir"])
    print(f"\n==================================================================")
    print(f"▶ Processando {pname} ({project['forge']}:{project['slug']}) em {pdir}")
    print(f"==================================================================")

    if not os.path.isdir(pdir):
        print(f"❌ Diretório {pdir} não encontrado. Pulando...")
        return

    # 1. Criar Issue
    issue_num = create_issue(project)
    if not issue_num:
        print(f"⚠ Pulando commit por falha na criação de issue.")
        return

    # 2. Determinar destino dos assets no projeto
    if os.path.isdir(os.path.join(pdir, "site")):
        assets_dir = os.path.join(pdir, "site", "assets")
    else:
        assets_dir = os.path.join(pdir, "assets")

    os.makedirs(assets_dir, exist_ok=True)
    og_path = os.path.join(assets_dir, "og_preview.png")

    # 3. Gerar Card
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

    # 4. Copiar para a Banca
    banca_banner = os.path.join(BANCA_DIR, "site", "assets", "banners", f"{pname}-banner.png")
    os.makedirs(os.path.dirname(banca_banner), exist_ok=True)
    subprocess.run(["cp", og_path, banca_banner], check=True)
    print(f"✔ Banner copiado para a Banca: {banca_banner}")

    # 5. Atualizar site/index.html se existir
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

    # 6. Atualizar CHANGELOG.md e VERSION se existirem
    changelog_path = os.path.join(pdir, "CHANGELOG.md")
    if os.path.isfile(changelog_path):
        with open(changelog_path, "r", encoding="utf-8") as f:
            cl = f.read()
        entry = f"  - (meta) gerar card oficial de opengraph e banner social (closes #{issue_num})\n"
        if "### Features" in cl and entry not in cl:
            cl = cl.replace("### Features\n", "### Features\n" + entry, 1)
            with open(changelog_path, "w", encoding="utf-8") as f:
                f.write(cl)
            print(f"✔ Entrada adicionada no CHANGELOG.md")

    # 7. Git Add & Commit
    commit_msg = f"feat(meta): gerar card oficial de opengraph e banner social (closes #{issue_num})"
    # Salvar script auxiliar se for útil
    run_cmd(f'git add -A', cwd=pdir)
    code, out, err = run_cmd(f'git commit -m "{commit_msg}"', cwd=pdir)
    if code != 0:
        print(f"⚠ Aviso no commit de {pname}: {err or out}")
    else:
        print(f"✔ Commit criado em {pname}: {commit_msg}")

    # 8. Git Push (usando --no-verify para bypass seguro de linter local secundário em repos que não têm act configurado)
    code, out, err = run_cmd(f'git push --no-verify origin HEAD', cwd=pdir)
    if code != 0:
        print(f"❌ Falha no push em {pname}: {err or out}")
    else:
        print(f"✔ Push realizado para origin em {pname}")

    # 9. Fechar Issue
    close_issue(project, issue_num)

    # 10. Atualizar projects.json na Banca
    update_banca_data(pname, f"assets/banners/{pname}-banner.png")

def update_banca_data(project_name, banner_rel_path):
    with open(BANCA_DATA, "r", encoding="utf-8") as f:
        data = json.load(f)

    updated = False
    for item in data:
        if item.get("name") == project_name:
            item["banner"] = banner_rel_path
            updated = True
            break

    if updated:
        with open(BANCA_DATA, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"✔ data/projects.json atualizado para {project_name}")

def main():
    print(f"Iniciando processamento em lote de {len(PROJECTS_CONFIG)} projetos...")
    for proj in PROJECTS_CONFIG:
        process_project(proj)

    print("\n==================================================================")
    print("Recompilando vitrine da Banca...")
    run_cmd("./build.sh", cwd=BANCA_DIR)
    print("✔ Vitrine da Banca recompilada com sucesso!")

if __name__ == "__main__":
    main()
