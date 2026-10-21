#!/usr/bin/env bash
# ==============================================================================
# scripts/gerar-instaladores.sh — Gerador de Instaladores Dinâmicos da Banca (#38)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
INSTALL_DIR="$SITE_DIR/install"

mkdir -p "$INSTALL_DIR"

APPS=(
  "cccp"
  "navalha"
  "lauda"
  "lacraia"
  "joaju"
  "svyaz"
  "mayak"
  "kvant"
  "ayvu"
  "tuitata"
  "baquara"
  "mocambo"
  "hendu"
  "mandu"
  "tatupeba"
)

gerar_script_app() {
  local app="$1"
  local channel="$2"
  local outfile="$3"

  cat << 'EOF_HEADER' > "$outfile"
#!/bin/sh
# ==============================================================================
# BANCA - Instalador Oficial de Aplicativos Soberanos (banca.2lp.in)
EOF_HEADER

  cat << EOF_CONFIG >> "$outfile"
# App: $app | Canal: $channel
# ==============================================================================
set -e

APP="$app"
CHANNEL="$channel"
BANCA_URL="https://banca.2lp.in"
EOF_CONFIG

  cat << 'EOF_BODY' >> "$outfile"

# 1. Rejeição incondicional de sistemas Apple / Darwin
OS_NAME="${UNAME_OVERRIDE:-$(uname -s)}"
case "$OS_NAME" in
    Darwin*)
        printf "\n\033[1;31m[ERRO BANCA]\033[0m macOS/Darwin não é suportado pelo ecossistema soberano da Banca.\n\n" >&2
        exit 1
        ;;
    Linux*)
        ;;
    *)
        printf "\n\033[1;31m[ERRO BANCA]\033[0m Sistema operacional '%s' não suportado.\n" "$OS_NAME" >&2
        exit 1
        ;;
esac

# 2. Detecção de arquitetura
RAW_ARCH="${ARCH_OVERRIDE:-$(uname -m)}"
case "$RAW_ARCH" in
    x86_64|amd64)
        ARCH="linux-amd64"
        ;;
    aarch64|arm64)
        ARCH="linux-arm64"
        ;;
    *)
        printf "\n\033[1;31m[ERRO BANCA]\033[0m Arquitetura '%s' não suportada para %s.\n" "$RAW_ARCH" "$APP" >&2
        exit 1
        ;;
esac

# 3. Determinação do diretório de destino (sem root por padrão)
if [ -n "$BINDIR" ]; then
    TARGET_DIR="$BINDIR"
elif [ "$(id -u)" -eq 0 ]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="${HOME}/.local/bin"
fi

mkdir -p "$TARGET_DIR"

# 4. Resolução da URL de download
if [ "$CHANNEL" = "nightly" ]; then
    DOWNLOAD_URL="${BANCA_URL}/downloads/${APP}/nightly-latest/${APP}-${ARCH}"
    FALLBACK_URL="${BANCA_URL}/downloads/${APP}/nightly-latest/${APP}"
else
    DOWNLOAD_URL="${BANCA_URL}/downloads/${APP}/stable-latest/${APP}-${ARCH}"
    FALLBACK_URL="${BANCA_URL}/downloads/${APP}/stable-latest/${APP}"
fi

printf "\033[1;33m★ [BANCA]\033[0m Instalando \033[1m%s\033[0m (%s) em \033[1m%s\033[0m...\n" "$APP" "$CHANNEL" "$TARGET_DIR"

TMP_FILE="${TARGET_DIR}/.${APP}.tmp.$$"

download_file() {
    url="$1"
    dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$dest" "$url"
    else
        printf "\033[1;31m[ERRO BANCA]\033[0m curl ou wget são necessários para o download.\n" >&2
        return 1
    fi
}

if ! download_file "$DOWNLOAD_URL" "$TMP_FILE"; then
    if ! download_file "$FALLBACK_URL" "$TMP_FILE"; then
        printf "\033[1;31m[ERRO BANCA]\033[0m Falha ao baixar %s a partir de %s\n" "$APP" "$DOWNLOAD_URL" >&2
        rm -f "$TMP_FILE"
        exit 1
    fi
fi

chmod 755 "$TMP_FILE"
mv -f "$TMP_FILE" "${TARGET_DIR}/${APP}"

printf "\033[1;32m✓ [SUCESSO]\033[0m %s instalado com sucesso em %s/%s!\n" "$APP" "$TARGET_DIR" "$APP"

# 5. Verificação de PATH
case ":$PATH:" in
    *:"$TARGET_DIR":*)
        ;;
    *)
        printf "\n\033[1;33m[AVISO DE PATH]\033[0m O diretório '%s' não está no seu \$PATH.\n" "$TARGET_DIR"
        printf "Para executar '%s' diretamente no terminal, adicione a linha abaixo ao seu ~/.bashrc, ~/.zshrc ou ~/.profile:\n\n" "$APP"
        printf "    export PATH=\"%s:\$PATH\"\n\n" "$TARGET_DIR"
        ;;
esac
EOF_BODY

  chmod 755 "$outfile"
}

# 1. Gerar instaladores dedicados (estável e nightly) para cada app
for app in "${APPS[@]}"; do
  gerar_script_app "$app" "stable" "$INSTALL_DIR/$app"
  gerar_script_app "$app" "nightly" "$INSTALL_DIR/${app}-nightly"
done

# 2. Gerar instalador genérico site/install.sh
cat << 'EOF_GENERIC' > "$SITE_DIR/install.sh"
#!/bin/sh
# ==============================================================================
# BANCA - Instalador Oficial de Aplicativos Soberanos (banca.2lp.in)
# Instalador Dinâmico Genérico
# Uso: curl -fsSL https://banca.2lp.in/install.sh | sh -s -- <app> [--nightly]
# ==============================================================================
set -e

APP="${1:-cccp}"
CHANNEL="stable"

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --nightly|-n)
            CHANNEL="nightly"
            ;;
        --help|-h)
            printf "Uso: curl -fsSL https://banca.2lp.in/install.sh | sh -s -- <app> [--nightly]\n"
            exit 0
            ;;
        -*)
            ;;
        *)
            APP="$arg"
            ;;
    esac
done

BANCA_URL="https://banca.2lp.in"

# 1. Rejeição incondicional de sistemas Apple / Darwin
OS_NAME="${UNAME_OVERRIDE:-$(uname -s)}"
case "$OS_NAME" in
    Darwin*)
        printf "\n\033[1;31m[ERRO BANCA]\033[0m macOS/Darwin não é suportado pelo ecossistema soberano da Banca.\n\n" >&2
        exit 1
        ;;
    Linux*)
        ;;
    *)
        printf "\n\033[1;31m[ERRO BANCA]\033[0m Sistema operacional '%s' não suportado.\n" "$OS_NAME" >&2
        exit 1
        ;;
esac

# 2. Detecção de arquitetura
RAW_ARCH="${ARCH_OVERRIDE:-$(uname -m)}"
case "$RAW_ARCH" in
    x86_64|amd64)
        ARCH="linux-amd64"
        ;;
    aarch64|arm64)
        ARCH="linux-arm64"
        ;;
    *)
        printf "\n\033[1;31m[ERRO BANCA]\033[0m Arquitetura '%s' não suportada para %s.\n" "$RAW_ARCH" "$APP" >&2
        exit 1
        ;;
esac

# 3. Determinação do diretório de destino (sem root por padrão)
if [ -n "$BINDIR" ]; then
    TARGET_DIR="$BINDIR"
elif [ "$(id -u)" -eq 0 ]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="${HOME}/.local/bin"
fi

mkdir -p "$TARGET_DIR"

# 4. Resolução da URL de download
if [ "$CHANNEL" = "nightly" ]; then
    DOWNLOAD_URL="${BANCA_URL}/downloads/${APP}/nightly-latest/${APP}-${ARCH}"
    FALLBACK_URL="${BANCA_URL}/downloads/${APP}/nightly-latest/${APP}"
else
    DOWNLOAD_URL="${BANCA_URL}/downloads/${APP}/stable-latest/${APP}-${ARCH}"
    FALLBACK_URL="${BANCA_URL}/downloads/${APP}/stable-latest/${APP}"
fi

printf "\033[1;33m★ [BANCA]\033[0m Instalando \033[1m%s\033[0m (%s) em \033[1m%s\033[0m...\n" "$APP" "$CHANNEL" "$TARGET_DIR"

TMP_FILE="${TARGET_DIR}/.${APP}.tmp.$$"

download_file() {
    url="$1"
    dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$dest" "$url"
    else
        printf "\033[1;31m[ERRO BANCA]\033[0m curl ou wget são necessários para o download.\n" >&2
        return 1
    fi
}

if ! download_file "$DOWNLOAD_URL" "$TMP_FILE"; then
    if ! download_file "$FALLBACK_URL" "$TMP_FILE"; then
        printf "\033[1;31m[ERRO BANCA]\033[0m Falha ao baixar %s a partir de %s\n" "$APP" "$DOWNLOAD_URL" >&2
        rm -f "$TMP_FILE"
        exit 1
    fi
fi

chmod 755 "$TMP_FILE"
mv -f "$TMP_FILE" "${TARGET_DIR}/${APP}"

printf "\033[1;32m✓ [SUCESSO]\033[0m %s instalado com sucesso em %s/%s!\n" "$APP" "$TARGET_DIR" "$APP"

# 5. Verificação de PATH
case ":$PATH:" in
    *:"$TARGET_DIR":*)
        ;;
    *)
        printf "\n\033[1;33m[AVISO DE PATH]\033[0m O diretório '%s' não está no seu \$PATH.\n" "$TARGET_DIR"
        printf "Para executar '%s' diretamente no terminal, adicione a linha abaixo ao seu ~/.bashrc, ~/.zshrc ou ~/.profile:\n\n" "$APP"
        printf "    export PATH=\"%s:\$PATH\"\n\n" "$TARGET_DIR"
        ;;
esac
EOF_GENERIC

chmod 755 "$SITE_DIR/install.sh"
echo "Gerados 30 instaladores dedicados em site/install/ e 1 instalador raiz site/install.sh."
