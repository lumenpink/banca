#!/usr/bin/env python3
"""
Gera o ícone oficial unificado da Pratilera & Banca diretamente em PIL (512x512).
Garante controle milimétrico de tipografia, sombras e proporções sem cortes.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = REPO_ROOT / "site"
PRATILERA_DIR = SITE_DIR / "pratilera"
ICONS_DIR = PRATILERA_DIR / "icons"
ASSETS_DIR = SITE_DIR / "assets"

FONT_MONO_BOLD = "/usr/share/fonts/truetype/firacode/FiraCode-Bold.ttf"
FONT_SANS_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()

def draw_dashed_rounded_rect(draw, bbox, radius, color, width=2, dash_len=8, gap_len=6):
    x0, y0, x1, y1 = bbox
    # Gerar pontos ao longo do retângulo arredondado
    points = []
    # Top edge
    for x in range(int(x0 + radius), int(x1 - radius), 2):
        points.append((x, y0))
    # Top-right arc
    for deg in range(270, 360, 4):
        rad = math.radians(deg)
        points.append((x1 - radius + radius * math.cos(rad), y0 + radius + radius * math.sin(rad)))
    # Right edge
    for y in range(int(y0 + radius), int(y1 - radius), 2):
        points.append((x1, y))
    # Bottom-right arc
    for deg in range(0, 90, 4):
        rad = math.radians(deg)
        points.append((x1 - radius + radius * math.cos(rad), y1 - radius + radius * math.sin(rad)))
    # Bottom edge
    for x in range(int(x1 - radius), int(x0 + radius), -2):
        points.append((x, y1))
    # Bottom-left arc
    for deg in range(90, 180, 4):
        rad = math.radians(deg)
        points.append((x0 + radius + radius * math.cos(rad), y1 - radius + radius * math.sin(rad)))
    # Left edge
    for y in range(int(y1 - radius), int(y0 + radius), -2):
        points.append((x0, y))
    # Top-left arc
    for deg in range(180, 270, 4):
        rad = math.radians(deg)
        points.append((x0 + radius + radius * math.cos(rad), y0 + radius + radius * math.sin(rad)))

    # Desenha em traços pontilhados
    is_dash = True
    dist_accum = 0.0
    for i in range(len(points) - 1):
        p1 = points[i]
        p2 = points[i+1]
        seg_dist = math.hypot(p2[0] - p1[0], p2[1] - p1[1])
        if is_dash:
            draw.line([p1, p2], fill=color, width=width)
        dist_accum += seg_dist
        if is_dash and dist_accum >= dash_len:
            is_dash = False
            dist_accum = 0.0
        elif not is_dash and dist_accum >= gap_len:
            is_dash = True
            dist_accum = 0.0

def generate_icon():
    im = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # 1. Base Shield (Chassi grafite escuro com cantos arredondados)
    draw.rounded_rectangle([16, 16, 496, 496], radius=88, fill=(20, 21, 24, 255), outline=(50, 54, 64, 255), width=5)
    
    # Textura sutil de grade
    for x in range(32, 480, 24):
        draw.line([(x, 32), (x, 480)], fill=(28, 30, 36, 255), width=1)
    for y in range(32, 480, 24):
        draw.line([(32, y), (480, y)], fill=(28, 30, 36, 255), width=1)

    # Borda tracejada fúcsia interna (respiro de segurança)
    draw_dashed_rounded_rect(draw, [34, 34, 478, 478], radius=72, color=(230, 0, 80, 255), width=3, dash_len=10, gap_len=6)

    # 2. Toldo da Banca (Kiosk Awning) com listras diagonais
    # Máscara trapezoidal para as listras
    awning_mask = Image.new("L", (512, 512), 0)
    draw_mask = ImageDraw.Draw(awning_mask)
    awning_poly = [(72, 68), (440, 68), (454, 126), (58, 126)]
    draw_mask.polygon(awning_poly, fill=255)

    awning_layer = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_awning = ImageDraw.Draw(awning_layer)
    # Desenhar listras fúcsia e pretas
    stripe_w = 26
    for x in range(-512, 1024, stripe_w * 2):
        draw_awning.polygon([(x, 0), (x + stripe_w, 0), (x + stripe_w - 180, 512), (x - 180, 512)], fill=(230, 0, 80, 255))
        draw_awning.polygon([(x + stripe_w, 0), (x + stripe_w * 2, 0), (x + stripe_w * 2 - 180, 512), (x + stripe_w - 180, 512)], fill=(16, 17, 20, 255))

    im.paste(awning_layer, (0, 0), awning_mask)

    # Contorno do toldo
    draw.polygon(awning_poly, outline=(0, 0, 0, 255), width=4)

    # Franja amarela dente-de-serra (Scallop fringe)
    fringe_pts = [(58, 126)]
    step = 22
    cur_x = 58
    down = True
    while cur_x < 454:
        next_x = min(cur_x + step, 454)
        mid_x = (cur_x + next_x) // 2
        fringe_pts.append((mid_x, 138))
        fringe_pts.append((next_x, 126))
        cur_x = next_x
    draw.polygon(fringe_pts, fill=(212, 255, 0, 255), outline=(0, 0, 0, 255), width=3)

    # 3. Placa do Letreiro "BANCA 2LP"
    f_sign = get_font(FONT_SANS_BOLD, 18)
    sign_text = "★ BANCA 2LP ★"
    bbox_s = f_sign.getbbox(sign_text)
    tw_s = bbox_s[2] - bbox_s[0]
    th_s = bbox_s[3] - bbox_s[1]
    
    pad_x, pad_y = 24, 10
    sign_w = tw_s + pad_x * 2
    sign_h = th_s + pad_y * 2
    sign_x = (512 - sign_w) // 2
    sign_y = 148

    # Sombra da placa
    draw.rectangle([sign_x + 4, sign_y + 4, sign_x + sign_w + 4, sign_y + sign_h + 4], fill=(0, 0, 0, 220))
    # Placa
    draw.rectangle([sign_x, sign_y, sign_x + sign_w, sign_y + sign_h], fill=(0, 0, 0, 255), outline=(212, 255, 0, 255), width=2)
    draw.text((sign_x + pad_x, sign_y + pad_y - 2), sign_text, fill=(255, 255, 255, 255), font=f_sign)

    # 4. Prateleira 1 (Superior)
    # Viga de aço
    p1_y = 282
    draw.rectangle([64, p1_y, 448, p1_y + 12], fill=(36, 40, 50, 255), outline=(0, 0, 0, 255), width=3)
    draw.line([(64, p1_y + 1), (448, p1_y + 1)], fill=(212, 255, 0, 255), width=2)
    # Rebites
    draw.ellipse([72, p1_y + 3, 78, p1_y + 9], fill=(212, 255, 0, 255), outline=(0, 0, 0, 255))
    draw.ellipse([434, p1_y + 3, 440, p1_y + 9], fill=(212, 255, 0, 255), outline=(0, 0, 0, 255))

    # FANZINES NA PRATELEIRA 1
    # Zine 1 (Esquerda - Magenta inclinado)
    z1 = Image.new("RGBA", (72, 94), (0, 0, 0, 0))
    dz1 = ImageDraw.Draw(z1)
    dz1.rectangle([0, 0, 71, 93], fill=(230, 0, 80, 255), outline=(0, 0, 0, 255), width=3)
    dz1.rectangle([8, 8, 63, 44], fill=(255, 255, 255, 255), outline=(0, 0, 0, 255), width=2)
    f_z1 = get_font(FONT_MONO_BOLD, 15)
    dz1.text((14, 16), "ZINE", fill=(0, 0, 0, 255), font=f_z1)
    dz1.line([(8, 56), (63, 56)], fill=(0, 0, 0, 255), width=3)
    dz1.line([(8, 66), (52, 66)], fill=(0, 0, 0, 255), width=2)
    dz1.line([(8, 74), (58, 74)], fill=(0, 0, 0, 255), width=2)
    z1_rot = z1.rotate(6, expand=True, resample=Image.BICUBIC)
    im.paste(z1_rot, (94, 184), z1_rot)

    # Zine 2 (Centro - Amarelo Veneno / APK vertical)
    z2 = Image.new("RGBA", (84, 106), (0, 0, 0, 0))
    dz2 = ImageDraw.Draw(z2)
    # Sombra
    dz2.rectangle([4, 4, 83, 105], fill=(0, 0, 0, 180))
    dz2.rectangle([0, 0, 79, 101], fill=(212, 255, 0, 255), outline=(0, 0, 0, 255), width=3)
    dz2.rectangle([8, 8, 71, 40], fill=(0, 0, 0, 255))
    f_apk = get_font(FONT_MONO_BOLD, 17)
    dz2.text((18, 14), ".APK", fill=(212, 255, 0, 255), font=f_apk)
    # Código de barras
    for bar_x, bar_w in [(12, 2), (18, 4), (26, 2), (32, 5), (41, 2), (47, 4), (55, 2), (61, 3)]:
        dz2.line([(bar_x, 52), (bar_x, 88)], fill=(0, 0, 0, 255), width=bar_w)
    im.paste(z2, (214, 174), z2)

    # Zine 3 (Direita - Branco Kraft inclinado)
    z3 = Image.new("RGBA", (72, 94), (0, 0, 0, 0))
    dz3 = ImageDraw.Draw(z3)
    dz3.rectangle([0, 0, 71, 93], fill=(244, 237, 226, 255), outline=(0, 0, 0, 255), width=3)
    dz3.ellipse([18, 12, 54, 48], fill=(230, 0, 80, 255))
    f_2lp = get_font(FONT_MONO_BOLD, 14)
    dz3.text((23, 21), "2lp", fill=(255, 255, 255, 255), font=f_2lp)
    dz3.line([(8, 58), (63, 58)], fill=(0, 0, 0, 255), width=3)
    dz3.line([(8, 68), (50, 68)], fill=(0, 0, 0, 255), width=2)
    dz3.line([(8, 76), (56, 76)], fill=(0, 0, 0, 255), width=2)
    z3_rot = z3.rotate(-7, expand=True, resample=Image.BICUBIC)
    im.paste(z3_rot, (342, 184), z3_rot)

    # 5. Prateleira 2 (Inferior)
    p2_y = 390
    draw.rectangle([64, p2_y, 448, p2_y + 14], fill=(36, 40, 50, 255), outline=(0, 0, 0, 255), width=3)
    draw.line([(64, p2_y + 1), (448, p2_y + 1)], fill=(230, 0, 80, 255), width=2)
    # Rebites
    draw.ellipse([72, p2_y + 4, 78, p2_y + 10], fill=(230, 0, 80, 255), outline=(0, 0, 0, 255))
    draw.ellipse([434, p2_y + 4, 440, p2_y + 10], fill=(230, 0, 80, 255), outline=(0, 0, 0, 255))

    # Console / HUD de Som & Apps no meio das prateleiras
    hud_x0, hud_y0, hud_x1, hud_y1 = 136, 302, 376, 380
    draw.rectangle([hud_x0 + 4, hud_y0 + 4, hud_x1 + 4, hud_y1 + 4], fill=(0, 0, 0, 180))
    draw.rectangle([hud_x0, hud_y0, hud_x1, hud_y1], fill=(12, 13, 16, 255), outline=(230, 0, 80, 255), width=3)
    # Tela interna
    draw.rectangle([hud_x0 + 10, hud_y0 + 10, hud_x1 - 10, hud_y1 - 10], fill=(6, 7, 9, 255), outline=(45, 48, 60, 255), width=1)
    
    # Equalizador / Ondas sonoras
    eq_bars = [18, 36, 48, 28, 52, 38, 24, 44, 20]
    for idx, h in enumerate(eq_bars):
        bx = hud_x0 + 26 + idx * 16
        by = hud_y0 + 45
        draw.line([(bx, by - h // 2), (bx, by + h // 2)], fill=(212, 255, 0, 255), width=4)

    # Indicador de Status / LIVE LED
    draw.ellipse([hud_x1 - 54, hud_y0 + 24, hud_x1 - 42, hud_y0 + 36], fill=(212, 255, 0, 255))
    f_live = get_font(FONT_MONO_BOLD, 12)
    draw.text((hud_x1 - 58, hud_y0 + 42), "LIVE", fill=(255, 255, 255, 255), font=f_live)

    # 6. Faixa Inferior de Destaque "A PRATILERA"
    f_bot = get_font(FONT_MONO_BOLD, 25)
    bot_text = "A PRATILERA"
    bbox_b = f_bot.getbbox(bot_text)
    tw_b = bbox_b[2] - bbox_b[0]
    th_b = bbox_b[3] - bbox_b[1]

    bot_w = 340
    bot_h = 56
    bot_x = (512 - bot_w) // 2
    bot_y = 418

    # Sombra
    draw.rounded_rectangle([bot_x + 5, bot_y + 5, bot_x + bot_w + 5, bot_y + bot_h + 5], radius=12, fill=(0, 0, 0, 220))
    # Caixa magenta
    draw.rounded_rectangle([bot_x, bot_y, bot_x + bot_w, bot_y + bot_h], radius=12, fill=(230, 0, 80, 255), outline=(0, 0, 0, 255), width=4)
    # Borda interna amarela neon
    draw.rounded_rectangle([bot_x + 5, bot_y + 5, bot_x + bot_w - 5, bot_y + bot_h - 5], radius=8, outline=(212, 255, 0, 255), width=2)
    # Texto
    tx = bot_x + (bot_w - tw_b) // 2
    ty = bot_y + (bot_h - th_b) // 2 - 2
    draw.text((tx, ty), bot_text, fill=(255, 255, 255, 255), font=f_bot)

    return im

def main():
    print("✦ Gerando ícone oficial com PIL...")
    img = generate_icon()

    # Copiar para todos os alvos
    targets = [
        ASSETS_DIR / "icon.png",
        PRATILERA_DIR / "icons" / "icon.png",
        PRATILERA_DIR / "icons" / "pratilera.png",
        PRATILERA_DIR / "icon.png",
        PRATILERA_DIR / "pratilera.png",
        Path("/home/lumen/.gemini/antigravity-cli/brain/000d8ca9-03ae-4b21-8834-3953b1772a3d/pratilera_icon.png")
    ]

    density_dpis = [120, 160, 240, 320, 480, 640]
    for dpi in density_dpis:
        targets.append(PRATILERA_DIR / f"icons-{dpi}" / "icon.png")
        targets.append(PRATILERA_DIR / f"icons-{dpi}" / "pratilera.png")

    targets.append(SITE_DIR / "icons" / "icon.png")
    targets.append(SITE_DIR / "icons" / "pratilera.png")

    for t in targets:
        t.parent.mkdir(parents=True, exist_ok=True)
        img.save(t, format="PNG")
        print(f"✅ Salvo: {t}")

if __name__ == "__main__":
    main()
