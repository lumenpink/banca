#!/usr/bin/env python3
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TARGET = REPO_ROOT / "site" / "pratilera" / "icons" / "in.twolp.lacraia.simbiotyka.png"

svg_content = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="glow-veneno" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="0" stdDeviation="4" flood-color="#d4ff00" flood-opacity="0.9"/>
    </filter>
    <filter id="glow-fucsia" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="0" stdDeviation="4" flood-color="#ff0055" flood-opacity="0.8"/>
    </filter>
  </defs>

  <!-- BASE SHIELD -->
  <rect x="24" y="24" width="464" height="464" rx="96" fill="#151618" stroke="#333742" stroke-width="6"/>
  <rect x="44" y="44" width="424" height="424" rx="80" fill="none" stroke="#ff0055" stroke-width="2.5" stroke-dasharray="8,6"/>

  <!-- HUD JANELA FLUTUANTE -->
  <rect x="80" y="90" width="352" height="332" rx="20" fill="#1a1c22" stroke="#ff0055" stroke-width="4" filter="url(#glow-fucsia)"/>
  <!-- Barra de título HUD -->
  <rect x="80" y="90" width="352" height="50" rx="20" fill="#242730"/>
  <rect x="80" y="120" width="352" height="20" fill="#242730"/>
  <circle cx="115" cy="115" r="8" fill="#ff0055"/>
  <circle cx="140" cy="115" r="8" fill="#d4ff00"/>
  <text x="260" y="122" fill="#ffffff" font-family="monospace" font-weight="900" font-size="18" text-anchor="middle" letter-spacing="2">SIMBIÓTYKA :: HUD</text>

  <!-- LETRAS SINCRONIZADAS / LRC -->
  <!-- Linha anterior (esmaecida) -->
  <text x="110" y="190" fill="#666b7a" font-family="monospace" font-weight="700" font-size="16">[01:18.20] // paredão ligado</text>

  <!-- Linha ativa (destaque em neon fúcsia e amarelo) -->
  <rect x="100" y="215" width="312" height="60" rx="10" fill="#000000" stroke="#d4ff00" stroke-width="2" filter="url(#glow-veneno)"/>
  <text x="115" y="244" fill="#d4ff00" font-family="monospace" font-weight="900" font-size="14">[01:23.45]</text>
  <text x="115" y="264" fill="#ffffff" font-family="monospace" font-weight="900" font-size="17">♪ GRAVE BATE NA LATA ♪</text>

  <!-- Linha posterior (esmaecida) -->
  <text x="110" y="315" fill="#666b7a" font-family="monospace" font-weight="700" font-size="16">[01:28.90] // distorção soberana</text>

  <!-- INDICADOR DE CIFRAS & ESPECTRO -->
  <g stroke="#ff0055" stroke-width="4" stroke-linecap="round">
    <line x1="110" y1="365" x2="140" y2="365"/>
    <line x1="150" y1="355" x2="180" y2="355"/>
    <line x1="190" y1="375" x2="220" y2="375"/>
    <line x1="230" y1="360" x2="260" y2="360"/>
    <line x1="270" y1="350" x2="300" y2="350"/>
  </g>
  <rect x="330" y="348" width="70" height="32" rx="6" fill="#d4ff00" stroke="#000000" stroke-width="2"/>
  <text x="365" y="370" fill="#000000" font-family="monospace" font-weight="900" font-size="16" text-anchor="middle">LRC</text>
</svg>
"""

tmp_svg = REPO_ROOT / "temp_simbiotyka.svg"
tmp_svg.write_text(svg_content, encoding="utf-8")
subprocess.run(["convert", "-background", "none", "-size", "512x512", str(tmp_svg), str(TARGET)], check=True)
tmp_svg.unlink(missing_ok=True)
print(f"✅ Gerado ícone oficial do Simbiótyka em {TARGET}")
