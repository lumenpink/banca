#!/bin/sh
set -eu

NAVALHA_BIN="/home/lumen/src/navalha/target/release/navalha"
if ! command -v navalha >/dev/null 2>&1 && [ ! -x "$NAVALHA_BIN" ]; then
    echo "Erro: executável 'navalha' não encontrado no PATH nem em $NAVALHA_BIN" >&2
    exit 1
fi

NAVALHA="${NAVALHA_BIN}"
if command -v navalha >/dev/null 2>&1; then
    NAVALHA="navalha"
fi

PROJECT="${1:-}"
ESTETICA="${2:-punk-riot}"
TEXTO_TOP="${3:-$PROJECT}"
TEXTO_BOTTOM="${4:-BANCA DE ZINES // LUMEN.PINK}"
OUTPUT_DIR="site/assets/banners"
OUTPUT_FILE="${OUTPUT_DIR}/${PROJECT}-banner.png"

if [ -z "$PROJECT" ]; then
    echo "Uso: ./scripts/gerar-banner.sh <nome-do-projeto> [estetica] [texto-topo] [texto-baixo]"
    echo "Estéticas: punk-riot, navalha-sata, xerox-podre, fanzine-digital, risografia, tabloide-popular, trash-polka"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Imagem de entrada: usa poster do projeto ou acervo livre do navalha
INPUT_IMG="/home/lumen/src/navalha/site/assets/exemplos/exemplo-amara-moira.png"
if [ -f "/home/lumen/src/${PROJECT}/site/assets/poster.jpg" ]; then
    INPUT_IMG="/home/lumen/src/${PROJECT}/site/assets/poster.jpg"
elif [ -f "/home/lumen/src/${PROJECT}/assets/poster.png" ]; then
    INPUT_IMG="/home/lumen/src/${PROJECT}/assets/poster.png"
fi

echo "✂ Gerando pôster para '$PROJECT' com estética '$ESTETICA'..."
"$NAVALHA" poster "$INPUT_IMG" \
    --estetica "$ESTETICA" \
    --frase-superior "$TEXTO_TOP" \
    --frase "$TEXTO_BOTTOM" \
    --saida "$OUTPUT_FILE"

echo "✔ Pôster gerado com sucesso: $OUTPUT_FILE"
