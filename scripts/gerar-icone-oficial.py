#!/usr/bin/env python3
"""
Gera os ícones oficiais de alta resolução da Pratilera, Lacraia e Simbiótyka (512x512, 8-bit RGBA).
Utiliza supersampling 2x (1024x1024 -> 512x512) com antialiasing LANCZOS:
1. Pratilera: Estante modular industrial com caixas maciças em X (zero texto).
2. Lacraia: Avatar vetorial com chassi escuro, ocelos veneno e antenas com respiro.
3. Simbiótyka: Avatar com os óculos do Kamina sem armação e brilho estelar anime de 4 pontas.
"""
from pathlib import Path
from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = REPO_ROOT / "site"
PRATILERA_DIR = SITE_DIR / "pratilera"
ICONS_DIR = PRATILERA_DIR / "icons"
ASSETS_DIR = SITE_DIR / "assets"

def draw_bezier_curve(draw, p0, p1, p2, p3, color, width, steps=100):
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        tt = t * t
        uu = u * u
        uuu = uu * u
        ttt = tt * t
        x = uuu * p0[0] + 3 * uu * t * p1[0] + 3 * u * tt * p2[0] + ttt * p3[0]
        y = uuu * p0[1] + 3 * uu * t * p1[1] + 3 * u * tt * p2[1] + ttt * p3[1]
        points.append((x, y))
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=color, width=width)
        draw.ellipse([points[i][0] - width/2, points[i][1] - width/2,
                      points[i][0] + width/2, points[i][1] + width/2], fill=color)

def draw_chassis(draw, size=1024):
    pad = 48
    rad = 192
    draw.rounded_rectangle([pad, pad, size - pad, size - pad], radius=rad, fill=(21, 22, 24, 255), outline=(66, 70, 78, 255), width=18)
    dash_pad = 84
    dash_rad = 160
    draw.rounded_rectangle([dash_pad, dash_pad, size - dash_pad, size - dash_pad], radius=dash_rad, outline=(43, 29, 20, 255), width=6)

def draw_anime_star_gleam(draw, cx, cy, radius=110):
    rx = radius * 1.3
    ry = radius * 0.9
    draw.polygon([
        (cx - rx, cy),
        (cx - rx * 0.1, cy - 8),
        (cx, cy - 8),
        (cx + rx, cy),
        (cx + rx * 0.1, cy + 8),
        (cx, cy + 8)
    ], fill=(255, 255, 255, 255))
    draw.polygon([
        (cx, cy - ry),
        (cx + 8, cy - ry * 0.1),
        (cx + 8, cy),
        (cx, cy + ry),
        (cx - 8, cy + ry * 0.1),
        (cx - 8, cy)
    ], fill=(255, 255, 255, 255))
    d_len = radius * 0.4
    draw.polygon([(cx - d_len, cy - d_len), (cx, cy), (cx + d_len, cy + d_len)], fill=(255, 255, 255, 220))
    draw.polygon([(cx + d_len, cy - d_len), (cx, cy), (cx - d_len, cy + d_len)], fill=(255, 255, 255, 220))
    draw.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], fill=(255, 255, 255, 255))

def render_lacraia(with_kamina=False) -> Image.Image:
    size = 1024
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    draw_chassis(draw, size)

    # Antenas com respiro
    draw_bezier_curve(draw, (448, 512), (390, 360), (280, 260), (180, 185), color=(212, 255, 0, 255), width=32)
    draw.ellipse([180 - 28, 185 - 28, 180 + 28, 185 + 28], fill=(212, 255, 0, 255))
    draw.ellipse([180 - 14, 185 - 14, 180 + 14, 185 + 14], fill=(255, 255, 255, 255))

    draw_bezier_curve(draw, (576, 512), (634, 360), (744, 260), (844, 185), color=(212, 255, 0, 255), width=32)
    draw.ellipse([844 - 28, 185 - 28, 844 + 28, 185 + 28], fill=(212, 255, 0, 255))
    draw.ellipse([844 - 14, 185 - 14, 844 + 14, 185 + 14], fill=(255, 255, 255, 255))

    # Forcípulas
    draw_bezier_curve(draw, (352, 736), (288, 832), (352, 912), (432, 880), color=(255, 0, 85, 255), width=28)
    draw.ellipse([432 - 14, 880 - 14, 432 + 14, 880 + 14], fill=(255, 0, 85, 255))

    draw_bezier_curve(draw, (672, 736), (736, 832), (672, 912), (592, 880), color=(255, 0, 85, 255), width=28)
    draw.ellipse([592 - 14, 880 - 14, 592 + 14, 880 + 14], fill=(255, 0, 85, 255))

    # Placa Cefálica
    head_box = [320, 448, 704, 768]
    draw.rounded_rectangle([head_box[0] + 10, head_box[1] + 10, head_box[2] + 10, head_box[3] + 10], radius=96, fill=(10, 11, 13, 200))
    draw.rounded_rectangle(head_box, radius=96, fill=(31, 33, 38, 255), outline=(255, 0, 85, 255), width=24)

    # Fenestra Central
    for y in range(head_box[1] + 48, head_box[3] - 48, 36):
        draw.line([(512, y), (512, y + 20)], fill=(66, 70, 78, 255), width=16)

    # Ocelos
    eye_y = 576
    eye_l_x = 416
    eye_r_x = 608
    eye_r = 38

    draw.ellipse([eye_l_x - eye_r - 8, eye_y - eye_r - 8, eye_l_x + eye_r + 8, eye_y + eye_r + 8], fill=(212, 255, 0, 120))
    draw.ellipse([eye_l_x - eye_r, eye_y - eye_r, eye_l_x + eye_r, eye_y + eye_r], fill=(212, 255, 0, 255))
    draw.ellipse([eye_l_x - 14, eye_y - 14, eye_l_x + 14, eye_y + 14], fill=(255, 255, 255, 255))

    draw.ellipse([eye_r_x - eye_r - 8, eye_y - eye_r - 8, eye_r_x + eye_r + 8, eye_y + eye_r + 8], fill=(212, 255, 0, 120))
    draw.ellipse([eye_r_x - eye_r, eye_y - eye_r, eye_r_x + eye_r, eye_y + eye_r], fill=(212, 255, 0, 255))
    draw.ellipse([eye_r_x - 14, eye_y - 14, eye_r_x + 14, eye_y + 14], fill=(255, 255, 255, 255))

    # Kamina Shades
    if with_kamina:
        left_lens = [(512, 530), (160, 430), (320, 680)]
        right_lens = [(512, 530), (864, 430), (704, 680)]

        shades_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d_sh = ImageDraw.Draw(shades_shadow)
        d_sh.polygon([(p[0], p[1] + 14) for p in left_lens], fill=(0, 0, 0, 200))
        d_sh.polygon([(p[0], p[1] + 14) for p in right_lens], fill=(0, 0, 0, 200))
        im = Image.alpha_composite(im, shades_shadow)

        shades_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d_sl = ImageDraw.Draw(shades_layer)

        d_sl.polygon(left_lens, fill=(245, 15, 38, 255))
        d_sl.polygon(right_lens, fill=(245, 15, 38, 255))

        draw_anime_star_gleam(d_sl, cx=740, cy=475, radius=110)

        im = Image.alpha_composite(im, shades_layer)

    return im.resize((512, 512), resample=Image.Resampling.LANCZOS)

def draw_parcel_box(draw, bbox, fill_color, tape_color, with_x=True):
    x0, y0, x1, y1 = bbox
    draw.rounded_rectangle([x0 + 8, y0 + 8, x1 + 8, y1 + 8], radius=14, fill=(10, 11, 14, 200))
    draw.rounded_rectangle(bbox, radius=14, fill=fill_color, outline=(15, 16, 20, 255), width=8)

    if with_x:
        tape_w = 12
        draw.line([(x0 + 12, y0 + 12), (x1 - 12, y1 - 12)], fill=tape_color, width=tape_w)
        draw.line([(x0 + 12, y1 - 12), (x1 - 12, y0 + 12)], fill=tape_color, width=tape_w)
        mid_x = (x0 + x1) // 2
        mid_y = (y0 + y1) // 2
        draw.ellipse([mid_x - 10, mid_y - 10, mid_x + 10, mid_y + 10], fill=tape_color)

def render_pratilera_shelves_clean() -> Image.Image:
    """
    A Pratilera - Design Minimalista Oficial:
    Estante com 3 prateleiras industriais e caixas/encomendas maciças com fita em X.
    Totalmente sem texto, com legibilidade máxima a qualquer tamanho.
    """
    size = 1024
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    draw_chassis(draw, size)

    # Topo da estante
    draw.rounded_rectangle([120, 140, 904, 176], radius=10, fill=(34, 38, 48, 255), outline=(10, 10, 14, 255), width=8)
    draw.line([(130, 143), (894, 143)], fill=(212, 255, 0, 255), width=6)

    # ── PRATELEIRA 1 (Superior) ──
    draw_parcel_box(draw, [180, 220, 370, 370], fill_color=(255, 0, 85, 255), tape_color=(212, 255, 0, 255), with_x=True)
    draw_parcel_box(draw, [420, 200, 604, 370], fill_color=(212, 255, 0, 255), tape_color=(255, 0, 85, 255), with_x=True)
    draw_parcel_box(draw, [654, 235, 844, 370], fill_color=(38, 42, 54, 255), tape_color=(255, 0, 85, 255), with_x=True)

    draw.rounded_rectangle([120, 370, 904, 406], radius=10, fill=(34, 38, 48, 255), outline=(10, 10, 14, 255), width=8)
    draw.line([(130, 373), (894, 373)], fill=(255, 0, 85, 255), width=6)

    # ── PRATELEIRA 2 (Média) ──
    draw_parcel_box(draw, [170, 450, 480, 600], fill_color=(240, 232, 220, 255), tape_color=(255, 0, 85, 255), with_x=True)
    draw_parcel_box(draw, [544, 450, 854, 600], fill_color=(255, 0, 85, 255), tape_color=(212, 255, 0, 255), with_x=True)

    draw.rounded_rectangle([120, 600, 904, 636], radius=10, fill=(34, 38, 48, 255), outline=(10, 10, 14, 255), width=8)
    draw.line([(130, 603), (894, 603)], fill=(212, 255, 0, 255), width=6)

    # ── PRATELEIRA 3 (Inferior) ──
    draw_parcel_box(draw, [180, 690, 330, 830], fill_color=(212, 255, 0, 255), tape_color=(20, 21, 26, 255), with_x=True)
    draw_parcel_box(draw, [380, 670, 644, 830], fill_color=(26, 28, 36, 255), tape_color=(212, 255, 0, 255), with_x=True)
    draw_parcel_box(draw, [694, 690, 844, 830], fill_color=(255, 0, 85, 255), tape_color=(212, 255, 0, 255), with_x=True)

    draw.rounded_rectangle([120, 830, 904, 874], radius=12, fill=(34, 38, 48, 255), outline=(10, 10, 14, 255), width=8)
    draw.line([(130, 834), (894, 834)], fill=(255, 0, 85, 255), width=6)

    for rx in [160, 260, 512, 764, 864]:
        draw.ellipse([rx - 12, 852 - 12, rx + 12, 852 + 12], fill=(212, 255, 0, 255), outline=(10, 10, 14, 255), width=3)

    return im.resize((512, 512), resample=Image.Resampling.LANCZOS)

def main():
    print("✦ Gerando ícones oficiais em 8-bit RGBA (512x512)...")
    
    # 1. Pratilera
    img_pratilera = render_pratilera_shelves_clean()
    targets_pratilera = [
        ASSETS_DIR / "icon.png",
        PRATILERA_DIR / "icons" / "icon.png",
        PRATILERA_DIR / "icons" / "pratilera.png",
        PRATILERA_DIR / "icon.png",
        PRATILERA_DIR / "pratilera.png",
        SITE_DIR / "icons" / "icon.png",
        SITE_DIR / "icons" / "pratilera.png",
    ]
    for dpi in [120, 160, 240, 320, 480, 640]:
        targets_pratilera.append(PRATILERA_DIR / f"icons-{dpi}" / "icon.png")
        targets_pratilera.append(PRATILERA_DIR / f"icons-{dpi}" / "pratilera.png")
        targets_pratilera.append(SITE_DIR / f"icons-{dpi}" / "icon.png")
        targets_pratilera.append(SITE_DIR / f"icons-{dpi}" / "pratilera.png")

    for t in targets_pratilera:
        t.parent.mkdir(parents=True, exist_ok=True)
        img_pratilera.save(t, format="PNG")
        print(f"✅ Pratilera salva em: {t}")

    # 2. Lacraia
    img_lacraia = render_lacraia(with_kamina=False)
    lacraia_target = ICONS_DIR / "in.twolp.lacraia.app.png"
    lacraia_target.parent.mkdir(parents=True, exist_ok=True)
    img_lacraia.save(lacraia_target, format="PNG")
    print(f"✅ Lacraia salva em: {lacraia_target}")

    # 3. Simbiótyka
    img_simbiotyka = render_lacraia(with_kamina=True)
    simbiotyka_target = ICONS_DIR / "in.twolp.lacraia.simbiotyka.png"
    simbiotyka_target.parent.mkdir(parents=True, exist_ok=True)
    img_simbiotyka.save(simbiotyka_target, format="PNG")
    print(f"✅ Simbiótyka salva em: {simbiotyka_target}")

if __name__ == "__main__":
    main()
