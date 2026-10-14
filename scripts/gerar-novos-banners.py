#!/usr/bin/env python3
"""
Gera os 7 novos banners para a Banca em 1200x630, respeitando rigorosamente a Safe Zone 4:3
(elementos essenciais em 720x500 centralizados, com 240px de respiro lateral).
"""
import os
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = Path("site/assets/banners")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

FONT_SANS_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_MONO_BOLD = "/usr/share/fonts/truetype/firacode/FiraCode-Bold.ttf"

def get_fonts(title_size=68, sub_size=24, badge_size=18):
    try:
        f_title = ImageFont.truetype(FONT_MONO_BOLD, title_size)
    except Exception:
        f_title = ImageFont.load_default()
    try:
        f_sub = ImageFont.truetype(FONT_SANS_BOLD, sub_size)
    except Exception:
        f_sub = ImageFont.load_default()
    try:
        f_badge = ImageFont.truetype(FONT_MONO_BOLD, badge_size)
    except Exception:
        f_badge = ImageFont.load_default()
    return f_title, f_sub, f_badge

def draw_safe_grid(draw, w=1200, h=630, color=(30, 30, 35)):
    # Grade de fundo para textura anti-design
    for x in range(0, w, 40):
        draw.line([(x, 0), (x, h)], fill=color, width=1)
    for y in range(0, h, 40):
        draw.line([(0, y), (w, y)], fill=color, width=1)
    # Moldura externa sutil
    draw.rectangle([12, 12, w-13, h-13], outline=color, width=2)

def draw_badges(draw, x_center, y_pos, badges, bg_col, text_col, border_col, font):
    # Calcula largura total dos badges para centralizar
    spacing = 16
    badge_boxes = []
    total_w = 0
    for b in badges:
        bbox = font.getbbox(b)
        bw = (bbox[2] - bbox[0]) + 24
        bh = (bbox[3] - bbox[1]) + 14
        badge_boxes.append((b, bw, bh))
        total_w += bw
    total_w += spacing * (len(badges) - 1)
    
    cur_x = x_center - (total_w // 2)
    for text, bw, bh in badge_boxes:
        draw.rectangle([cur_x, y_pos, cur_x + bw, y_pos + bh], fill=bg_col, outline=border_col, width=2)
        tb = font.getbbox(text)
        tw = tb[2] - tb[0]
        th = tb[3] - tb[1]
        tx = cur_x + (bw - tw) // 2
        ty = y_pos + (bh - th) // 2 - tb[1]
        draw.text((tx, ty), text, fill=text_col, font=font)
        cur_x += bw + spacing

def create_banner_lauda():
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), color="#0c0d10")
    draw = ImageDraw.Draw(img)
    draw_safe_grid(draw, w, h, color="#161820")
    
    # Faixas diagonais de correio aéreo nas extremidades
    for x in range(-100, w + 100, 60):
        draw.line([(x, 0), (x + 30, 0), (x + 50, 16), (x + 20, 16)], fill="#e60050", width=4)
        draw.line([(x, h-16), (x + 30, h-16), (x + 50, h), (x + 20, h)], fill="#2185d0", width=4)

    # Inserir Logo Oficial se existir
    logo_path = Path("/home/lumen/src/lauda/site/lauda-logo.png")
    if logo_path.exists():
        logo = Image.open(logo_path).convert("RGBA")
        logo.thumbnail((140, 140))
        img.paste(logo, (600 - logo.width // 2, 90), logo)

    f_title, f_sub, f_badge = get_fonts(title_size=74, sub_size=22, badge_size=16)
    
    # Carimbo no topo da safe zone
    draw.rectangle([480, 245, 720, 275], fill="#000", outline="#e60050", width=2)
    draw.text((500, 252), "★ CORREIO SOBERANO ★", fill="#e60050", font=f_badge)

    # Título
    title = "LAUDA"
    tb = f_title.getbbox(title)
    draw.text((600 - (tb[2]-tb[0])//2, 290), title, fill="#ffffff", font=f_title)

    # Subtítulo
    sub = "CLIENTE DE E-MAIL ULTRALEVE EM RUST & DIOXUS"
    sb = f_sub.getbbox(sub)
    draw.text((600 - (sb[2]-sb[0])//2, 385), sub, fill="#00f0ff", font=f_sub)

    # Frase secundária
    sub2 = "Leitura Pura, Redação Rápida e Fricção Zero // Desktop, TUI & Android"
    s2b = f_sub.getbbox(sub2)
    draw.text((600 - (s2b[2]-s2b[0])//2, 425), sub2, fill="#888899", font=f_badge)

    # Badges
    draw_badges(draw, 600, 485, ["ANDROID", "TEXTO PURO", "DIOXUS 0.8", "PRATILERA"], "#11141c", "#ffffff", "#2185d0", f_badge)

    img.save(OUTPUT_DIR / "lauda-banner.png")
    print("✔ lauda-banner.png gerado")

def create_banner_ayvu():
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), color="#161210")
    draw = ImageDraw.Draw(img)
    draw_safe_grid(draw, w, h, color="#261f1c")
    
    f_title, f_sub, f_badge = get_fonts(title_size=76, sub_size=22, badge_size=16)

    # Desenho de requadro de história em quadrinhos
    draw.rectangle([260, 80, 940, 550], outline="#ffd700", width=4)
    draw.rectangle([252, 72, 948, 558], outline="#000000", width=2)
    
    # Balão de fala estilizado
    draw.rectangle([450, 110, 750, 160], fill="#ffd700", outline="#000000", width=3)
    draw.polygon([(600, 160), (580, 185), (630, 160)], fill="#ffd700", outline="#000000")
    draw.text((475, 122), "FALA SAGRADA // GUARANI", fill="#000000", font=f_badge)

    # Título
    title = "AYVU"
    tb = f_title.getbbox(title)
    # Sombra anti-design
    draw.text((600 - (tb[2]-tb[0])//2 + 5, 205 + 5), title, fill="#000000", font=f_title)
    draw.text((600 - (tb[2]-tb[0])//2, 205), title, fill="#ffffff", font=f_title)

    # Subtítulo
    sub = "COMPILADOR DECLARATIVO DE TIRINHAS EM QUADRINHOS"
    sb = f_sub.getbbox(sub)
    draw.text((600 - (sb[2]-sb[0])//2, 310), sub, fill="#ff9900", font=f_sub)

    sub2 = "Layouting Automatizado, Fanzines, SVG Puro & Rust 2024"
    s2b = f_sub.getbbox(sub2)
    draw.text((600 - (s2b[2]-s2b[0])//2, 355), sub2, fill="#d0c0b0", font=f_badge)

    # Badges
    draw_badges(draw, 600, 440, ["COMICS / ZINES", "RUST", "SVG PURO", "EDITORIAL"], "#2a1e16", "#ffffff", "#ffd700", f_badge)

    img.save(OUTPUT_DIR / "ayvu-banner.png")
    print("✔ ayvu-banner.png gerado")

def create_banner_muiraquita():
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), color="#08140c")
    draw = ImageDraw.Draw(img)
    draw_safe_grid(draw, w, h, color="#122a1a")

    f_title, f_sub, f_badge = get_fonts(title_size=72, sub_size=22, badge_size=16)

    # Glifo central de jade
    draw.ellipse([540, 90, 660, 210], fill="#0d3319", outline="#00ff66", width=4)
    draw.text((582, 120), "🐸", font=f_title) # Emoji de sapo/amuleto

    # Tarja superior
    draw.rectangle([430, 235, 770, 270], fill="#00ff66", outline="#000000", width=2)
    draw.text((450, 243), "AMULETO DA INDIEWEB SOBERANA", fill="#000000", font=f_badge)

    # Título
    title = "MUIRAQUITÃ"
    tb = f_title.getbbox(title)
    draw.text((600 - (tb[2]-tb[0])//2 + 4, 290 + 4), title, fill="#000000", font=f_title)
    draw.text((600 - (tb[2]-tb[0])//2, 290), title, fill="#ffffff", font=f_title)

    # Subtítulo
    sub = "SUÍTE SOCIAL SOBERANA PARA A WEB ABERTA"
    sb = f_sub.getbbox(sub)
    draw.text((600 - (sb[2]-sb[0])//2, 385), sub, fill="#00ff66", font=f_sub)

    sub2 = "Cliente Nativo IndieInABox // Micropub, Webmentions & Dioxus"
    s2b = f_sub.getbbox(sub2)
    draw.text((600 - (s2b[2]-s2b[0])//2, 425), sub2, fill="#99ccaa", font=f_badge)

    # Badges
    draw_badges(draw, 600, 480, ["DIOXUS 0.8", "INDIEWEB", "RUST 2024", "FEDIVERSE"], "#0a2414", "#00ff66", "#00ff66", f_badge)

    img.save(OUTPUT_DIR / "muiraquita-banner.png")
    print("✔ muiraquita-banner.png gerado")

def create_banner_tuitata():
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), color="#160805")
    draw = ImageDraw.Draw(img)
    draw_safe_grid(draw, w, h, color="#2e140d")

    f_title, f_sub, f_badge = get_fonts(title_size=74, sub_size=22, badge_size=16)

    # Chama da Boitatá
    draw.rectangle([450, 100, 750, 145], fill="#ff3300", outline="#ffcc00", width=3)
    draw.text((475, 112), "🔥 COBRA DE FOGO // TUI 🔥", fill="#000000", font=f_badge)

    title = "TUITATÁ"
    tb = f_title.getbbox(title)
    draw.text((600 - (tb[2]-tb[0])//2 + 5, 175 + 5), title, fill="#ff3300", font=f_title)
    draw.text((600 - (tb[2]-tb[0])//2, 175), title, fill="#ffffff", font=f_title)

    sub = "CLIENTE TUI PARA GOOGLE GEMINI EM RUST"
    sb = f_sub.getbbox(sub)
    draw.text((600 - (sb[2]-sb[0])//2, 275), sub, fill="#ffcc00", font=f_sub)

    sub2 = "Streaming de Alta Fricção, Estética Boitatá & Exportação Obsidian"
    s2b = f_sub.getbbox(sub2)
    draw.text((600 - (s2b[2]-s2b[0])//2, 320), sub2, fill="#ff9977", font=f_badge)

    # Moldura simulando terminal Ratatui
    draw.rectangle([340, 375, 860, 455], fill="#260f08", outline="#ff6600", width=2)
    draw.text((365, 395), "> tuitata --prompt \"analisar manuscrito\"", fill="#00ffcc", font=f_badge)
    draw.text((365, 420), "[200 OK] streaming tokens :: 42 tok/s", fill="#88ff88", font=f_badge)

    draw_badges(draw, 600, 495, ["RATATUI", "GEMINI API", "RUST", "OBSIDIAN"], "#33120a", "#ffffff", "#ff3300", f_badge)

    img.save(OUTPUT_DIR / "tuitata-banner.png")
    print("✔ tuitata-banner.png gerado")

def create_banner_urupema():
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), color="#090d14")
    draw = ImageDraw.Draw(img)
    draw_safe_grid(draw, w, h, color="#162030")

    f_title, f_sub, f_badge = get_fonts(title_size=72, sub_size=22, badge_size=16)

    # Símbolo de peneira/filtro
    draw.rectangle([460, 95, 740, 140], fill="#000000", outline="#3388ff", width=2)
    draw.text((485, 107), "✦ PENEIRA DE CORREIO ✦", fill="#3388ff", font=f_badge)

    title = "URUPEMA"
    tb = f_title.getbbox(title)
    draw.text((600 - (tb[2]-tb[0])//2 + 4, 165 + 4), title, fill="#001133", font=f_title)
    draw.text((600 - (tb[2]-tb[0])//2, 165), title, fill="#ffffff", font=f_title)

    sub = "DISSECAÇÃO CIRÚRGICA DE MIME & TRIAGEM DE CORREIO"
    sb = f_sub.getbbox(sub)
    draw.text((600 - (sb[2]-sb[0])//2, 265), sub, fill="#00d4ff", font=f_sub)

    sub2 = "Utilitário Post-Queue em Rust // Conversão Transparente para Markdown"
    s2b = f_sub.getbbox(sub2)
    draw.text((600 - (s2b[2]-s2b[0])//2, 310), sub2, fill="#88bbdd", font=f_badge)

    # Box blueprint
    draw.rectangle([320, 360, 880, 445], fill="#0c1626", outline="#1a4070", width=2)
    draw.text((345, 380), "RFC 5322 MIME -> Markdown AST -> Maildir Archive", fill="#70a0e0", font=f_badge)
    draw.text((345, 408), "[0.02ms parsing] zero-alloc body extraction", fill="#50ffaa", font=f_badge)

    draw_badges(draw, 600, 485, ["POSTFIX MILTER", "RUST PURO", "MARKDOWN", "COMRADE"], "#10203a", "#ffffff", "#3388ff", f_badge)

    img.save(OUTPUT_DIR / "urupema-banner.png")
    print("✔ urupema-banner.png gerado")

def create_banner_tatupeba():
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), color="#14110e")
    draw = ImageDraw.Draw(img)
    draw_safe_grid(draw, w, h, color="#2b231b")

    f_title, f_sub, f_badge = get_fonts(title_size=72, sub_size=22, badge_size=16)

    # Carimbo de citação
    draw.rectangle([450, 100, 750, 145], fill="#c28e46", outline="#000000", width=2)
    draw.text((475, 112), "“ASSIM SE CONSTRÓI”", fill="#000000", font=f_badge)

    title = "TATUPEBA"
    tb = f_title.getbbox(title)
    draw.text((600 - (tb[2]-tb[0])//2 + 4, 170 + 4), title, fill="#000000", font=f_title)
    draw.text((600 - (tb[2]-tb[0])//2, 170), title, fill="#ffffff", font=f_title)

    sub = "EXTRATOR & SINCRONIZADOR CONTÍNUO DO ZOTERO"
    sb = f_sub.getbbox(sub)
    draw.text((600 - (sb[2]-sb[0])//2, 270), sub, fill="#e8b872", font=f_sub)

    sub2 = "Ponte Direta entre Acervo Bibliográfico e o Cofre Obsidian"
    s2b = f_sub.getbbox(sub2)
    draw.text((600 - (s2b[2]-s2b[0])//2, 315), sub2, fill="#bfa384", font=f_badge)

    # Box de placas de tatu
    draw.rectangle([340, 365, 860, 445], fill="#211b15", outline="#6e553a", width=2)
    draw.text((365, 385), "SQLite Zotero -> Citações ABNT -> Vault Markdown", fill="#d2a679", font=f_badge)
    draw.text((365, 412), "Indexed Collections // Tags, PDFs e Anotações", fill="#88c0a0", font=f_badge)

    draw_badges(draw, 600, 485, ["ZOTERO", "OBSIDIAN", "RUST", "PESQUISA"], "#2b2118", "#ffffff", "#c28e46", f_badge)

    img.save(OUTPUT_DIR / "tatupeba-banner.png")
    print("✔ tatupeba-banner.png gerado")

def create_banner_baquara_rs():
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), color="#080a0f")
    draw = ImageDraw.Draw(img)
    draw_safe_grid(draw, w, h, color="#121824")

    f_title, f_sub, f_badge = get_fonts(title_size=68, sub_size=22, badge_size=16)

    # Chassis de IA
    draw.rectangle([430, 95, 770, 140], fill="#00ffff", outline="#000000", width=2)
    draw.text((450, 107), "MOTOR DE IA LOCAL & MCP", fill="#000000", font=f_badge)

    title = "BAQUARA-RS"
    tb = f_title.getbbox(title)
    draw.text((600 - (tb[2]-tb[0])//2 + 4, 165 + 4), title, fill="#003344", font=f_title)
    draw.text((600 - (tb[2]-tb[0])//2, 165), title, fill="#ffffff", font=f_title)

    sub = "RAG SEMÂNTICO HÍBRIDO & SERVIDOR MCP EM RUST"
    sb = f_sub.getbbox(sub)
    draw.text((600 - (sb[2]-sb[0])//2, 265), sub, fill="#00f0ff", font=f_sub)

    sub2 = "Embeddings Rápidos, Qdrant/SQLite & Barramento de Ferramentas"
    s2b = f_sub.getbbox(sub2)
    draw.text((600 - (s2b[2]-s2b[0])//2, 310), sub2, fill="#77aacc", font=f_badge)

    # Box de telemetria
    draw.rectangle([330, 360, 870, 445], fill="#0e1422", outline="#183050", width=2)
    draw.text((355, 380), "Model Context Protocol (MCP) Server: JSON-RPC 2.0", fill="#00e5ff", font=f_badge)
    draw.text((355, 408), "Hybrid Search: BM25 + Vector Cosine Sim // Local Ollama", fill="#ffaa44", font=f_badge)

    draw_badges(draw, 600, 485, ["LOCAL LLM", "MCP SERVER", "RAG HÍBRIDO", "RUST"], "#0f1c30", "#00ffff", "#00ffff", f_badge)

    img.save(OUTPUT_DIR / "baquara-rs-banner.png")
    print("✔ baquara-rs-banner.png gerado")

if __name__ == "__main__":
    create_banner_lauda()
    create_banner_ayvu()
    create_banner_muiraquita()
    create_banner_tuitata()
    create_banner_urupema()
    create_banner_tatupeba()
    create_banner_baquara_rs()
    print("🎉 Todos os 7 banners foram gerados com sucesso na Safe Zone 4:3!")
