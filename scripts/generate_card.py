#!/usr/bin/env python3
"""
Gerador Universal de Cards Open Graph e Banners Sociais (Norma GOST Cap. 11)
- Resolução canônica: 1200x630 pixels.
- Safe Zone 4:3 centralizada (miolo útil 720-840px, proteção contra recorte móvel e WhatsApp).
- Tipografia geométrica, alto contraste e grid estrutural.
"""

import os
import sys
import argparse
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1200, 630

FONT_BOLD_CANDIDATES = [
    "/usr/share/fonts/truetype/firacode/FiraCode-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]

FONT_REG_CANDIDATES = [
    "/usr/share/fonts/truetype/firacode/FiraCode-Regular.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
]

FONT_MONO_CANDIDATES = [
    "/usr/share/fonts/truetype/firacode/FiraCode-Medium.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
]

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 3:
        hex_str = "".join([c*2 for c in hex_str])
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def get_font(candidates, size):
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()

def draw_centered_text(draw, y, text, font, fill, shadow=None, shadow_offset=2):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (W - tw) // 2
    if shadow:
        draw.text((x + shadow_offset, y + shadow_offset), text, font=font, fill=shadow)
    draw.text((x, y), text, font=font, fill=fill)
    return x, y, tw, bbox[3] - bbox[1]

def generate_gost_card(
    name,
    title,
    subtitle,
    badge,
    tags,
    url,
    meta,
    bg_hex="#0e1117",
    accent1_hex="#ff0055",
    accent2_hex="#ffee00",
    text_hex="#f0f6fc",
    output_path="site/assets/og_preview.png"
):
    c_bg = hex_to_rgb(bg_hex) + (255,)
    c_accent1 = hex_to_rgb(accent1_hex) + (255,)
    c_accent2 = hex_to_rgb(accent2_hex) + (255,)
    c_text = hex_to_rgb(text_hex) + (255,)
    c_muted = (139, 148, 158, 220)
    c_grid = (hex_to_rgb(accent1_hex)[0], hex_to_rgb(accent1_hex)[1], hex_to_rgb(accent1_hex)[2], 30)
    c_panel = (max(0, c_bg[0]-5), max(0, c_bg[1]-5), max(0, c_bg[2]-5), 230)
    c_border = (60, 68, 78, 180)

    base = Image.new("RGBA", (W, H), c_bg)
    draw = ImageDraw.Draw(base)

    # 1. Grid Blueprint Geométrico
    step = 32
    for x in range(0, W, step):
        draw.line([(x, 0), (x, H)], fill=c_grid, width=1)
    for y in range(0, H, step):
        draw.line([(0, y), (W, y)], fill=c_grid, width=1)

    # 2. Glow Ambiental Central
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([320, 100, 880, 500], fill=c_accent1[:3] + (35,))
    gdraw.ellipse([420, 160, 780, 440], fill=c_accent2[:3] + (25,))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    base = Image.alpha_composite(base, glow)
    draw = ImageDraw.Draw(base)

    # 3. Fontes
    # Ajuste de tamanho da fonte do brand com base no comprimento
    brand_len = len(title)
    if brand_len > 18:
        brand_size = 54
    elif brand_len > 12:
        brand_size = 68
    else:
        brand_size = 84

    f_badge = get_font(FONT_BOLD_CANDIDATES, 15)
    f_brand = get_font(FONT_BOLD_CANDIDATES, brand_size)
    f_sub   = get_font(FONT_REG_CANDIDATES, 22)
    f_tag   = get_font(FONT_MONO_CANDIDATES, 14)
    f_foot  = get_font(FONT_BOLD_CANDIDATES, 19)
    f_meta  = get_font(FONT_REG_CANDIDATES, 17)

    # 4. Top Accent Lines
    draw.line([(0, 0), (W, 0)], fill=c_accent1, width=4)
    draw.line([(0, 3), (W, 3)], fill=c_accent2, width=2)

    # 5. Badge Superior no Miolo Central
    badge_label = f"  {badge.strip()}  "
    bbox_b = draw.textbbox((0, 0), badge_label, font=f_badge)
    bw = bbox_b[2] - bbox_b[0]
    bh = bbox_b[3] - bbox_b[1]
    bx = (W - bw) // 2
    by = 52
    draw.rectangle([bx - 14, by - 6, bx + bw + 14, by + bh + 6], fill=(12, 14, 18, 230), outline=c_accent2, width=1)
    draw.text((bx, by), badge_label, font=f_badge, fill=c_accent2)

    # 6. Hero Brand
    brand_y = 125 if brand_size <= 68 else 120
    bbox_br = draw.textbbox((0, 0), title, font=f_brand)
    brw = bbox_br[2] - bbox_br[0]
    brx = (W - brw) // 2

    # Sombra brutalista
    for ox, oy, alpha in [(4, 4, 160), (2, 2, 100)]:
        draw.text((brx + ox, brand_y + oy), title, font=f_brand, fill=c_accent1[:3] + (alpha,))
    draw.text((brx, brand_y), title, font=f_brand, fill=c_text)

    # Linha divisória sob a marca
    bar_y = brand_y + (bbox_br[3] - bbox_br[1]) + 18
    bar_w = min(840, max(680, brw + 120))
    bar_x = (W - bar_w) // 2
    draw.line([(bar_x, bar_y), (bar_x + bar_w, bar_y)], fill=c_accent1, width=2)
    draw.line([(bar_x + (bar_w // 2) - 40, bar_y), (bar_x + (bar_w // 2) + 40, bar_y)], fill=c_accent2, width=2)

    # 7. Subtítulo / Descrição
    s_y = bar_y + 24
    draw_centered_text(draw, s_y, subtitle, f_sub, c_accent2)

    # 8. Tags de Contexto
    tag_list = tags[:4]
    tag_total_w = sum(draw.textbbox((0, 0), f"[ {t.upper()} ]", font=f_tag)[2] for t in tag_list) + (len(tag_list) - 1) * 16
    tx = (W - tag_total_w) // 2
    ty = s_y + 54

    for t in tag_list:
        label = f"[ {t.upper()} ]"
        lbox = draw.textbbox((0, 0), label, font=f_tag)
        lw = lbox[2] - lbox[0]
        lh = lbox[3] - lbox[1]
        draw.rectangle([tx - 6, ty - 4, tx + lw + 6, ty + lh + 4], fill=c_panel, outline=c_border, width=1)
        draw.text((tx, ty), label, font=f_tag, fill=c_muted)
        tx += lw + 16

    # 9. Rodapé no Miolo Central
    foot_y = H - 85
    f_bar_w = 780
    f_bar_x = (W - f_bar_w) // 2
    draw.line([(f_bar_x, foot_y - 16), (f_bar_x + f_bar_w, foot_y - 16)], fill=c_border, width=1)

    # LED indicador
    draw.ellipse([f_bar_x, foot_y + 4, f_bar_x + 14, foot_y + 18], fill=c_accent2)
    draw.text((f_bar_x + 24, foot_y), url, font=f_foot, fill=c_accent2)

    # Créditos / Licença na direita
    cbox = draw.textbbox((0, 0), meta, font=f_meta)
    draw.text((f_bar_x + f_bar_w - (cbox[2] - cbox[0]), foot_y + 2), meta, font=f_meta, fill=c_muted)

    # Borda decorativa inferior
    draw.line([(0, H - 3), (W, H - 3)], fill=c_accent2, width=3)
    draw.line([(0, H - 1), (W, H - 1)], fill=c_accent1, width=1)

    # Salvar
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    final = base.convert("RGB")
    final.save(output_path, format="PNG", optimize=True)
    
    # Cópia em poster.png no mesmo diretório
    poster_path = os.path.join(os.path.dirname(output_path), "poster.png")
    final.save(poster_path, format="PNG", optimize=True)
    
    kb = os.path.getsize(output_path) / 1024
    print(f"✔ Card gerado: {output_path} ({W}x{H}, {kb:.1f} KB)")
    return output_path

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--subtitle", required=True)
    parser.add_argument("--badge", required=True)
    parser.add_argument("--tags", nargs="+", default=[])
    parser.add_argument("--url", required=True)
    parser.add_argument("--meta", required=True)
    parser.add_argument("--bg", default="#0e1117")
    parser.add_argument("--accent1", default="#ff0055")
    parser.add_argument("--accent2", default="#ffee00")
    parser.add_argument("--text", default="#f0f6fc")
    parser.add_argument("--out", default="site/assets/og_preview.png")
    args = parser.parse_args()

    generate_gost_card(
        args.name,
        args.title,
        args.subtitle,
        args.badge,
        args.tags,
        args.url,
        args.meta,
        bg_hex=args.bg,
        accent1_hex=args.accent1,
        accent2_hex=args.accent2,
        text_hex=args.text,
        output_path=args.out
    )
