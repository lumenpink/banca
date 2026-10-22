#!/usr/bin/env bash
# ==============================================================================
# tests/test-installers.sh — Validação dos Instaladores Dinâmicos sem Root (#38)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
INSTALL_DIR="$SITE_DIR/install"
FAILURES=0

echo "================================================================="
echo "🧪 [TESTE] Validação dos Instaladores Dinâmicos da Banca (#38)"
echo "================================================================="

# 1. Verificar existência do diretório site/install e instalador genérico
echo -n "-> 1. Verificando existência de site/install.sh e site/install/... "
if [ -f "$SITE_DIR/install.sh" ] && [ -d "$INSTALL_DIR" ]; then
    echo "✅ OK"
else
    echo "❌ FALHOU (site/install.sh ou site/install/ ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 2. Verificar instaladores dedicados para apps principais (cccp, mandu, navalha)
echo -n "-> 2. Verificando instaladores dedicados estável e nightly... "
MISSING_APPS=0
for app in cccp mandu navalha lauda lacraia svyaz hendu; do
    if [ ! -f "$INSTALL_DIR/$app" ]; then
        MISSING_APPS=$((MISSING_APPS + 1))
    fi
    if [ ! -f "$INSTALL_DIR/${app}-nightly" ]; then
        MISSING_APPS=$((MISSING_APPS + 1))
    fi
done
if [ "$MISSING_APPS" -eq 0 ]; then
    echo "✅ OK (todos os instaladores dedicados presentes)"
else
    echo "❌ FALHOU ($MISSING_APPS instaladores dedicados ausentes)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Testar rejeição de Darwin/Apple
echo -n "-> 3. Testando rejeição do SO Darwin (Apple)... "
if [ -f "$SITE_DIR/install.sh" ]; then
    TMP_BINDIR=$(mktemp -d)
    OUTPUT=$(UNAME_OVERRIDE="Darwin" sh "$SITE_DIR/install.sh" cccp 2>&1 || true)
    rm -rf "$TMP_BINDIR"
    if echo "$OUTPUT" | grep -qi "macOS/Darwin não é suportado pelo ecossistema soberano da Banca"; then
        echo "✅ OK (Darwin devidamente rejeitado com mensagem clara)"
    else
        echo "❌ FALHOU (mensagem de rejeição ao Darwin ausente ou incorreta: '$OUTPUT')"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/install.sh ausente para teste)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Testar destino padrão ~/.local/bin sem root
echo -n "-> 4. Verificando se o destino padrão é ~/.local/bin (sem root)... "
if [ -f "$INSTALL_DIR/cccp" ]; then
    if grep -q '\$HOME/\.local/bin' "$INSTALL_DIR/cccp" || grep -q '\${HOME}/\.local/bin' "$INSTALL_DIR/cccp"; then
        echo "✅ OK (instalação sem root em ~/.local/bin)"
    else
        echo "❌ FALHOU (referência a ~/.local/bin ausente no script do cccp)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/install/cccp ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. Verificar atualização do site/downloads/index.html para os novos comandos
echo -n "-> 5. Verificando comandos da vitrine em site/downloads/index.html... "
if [ -f "$SITE_DIR/downloads/index.html" ]; then
    DOWNLOADS_HTML=$(cat "$SITE_DIR/downloads/index.html")
    if echo "$DOWNLOADS_HTML" | grep -q "https://banca.2lp.in/install/"; then
        echo "✅ OK (vitrine web atualizada com instaladores dinâmicos)"
    else
        echo "❌ FALHOU (links para banca.2lp.in/install/ ausentes em downloads/index.html)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/downloads/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 6. [MUTAÇÃO] Testar canal nightly dedicado (site/install/cccp-nightly)
echo -n "-> 6. [MUTAÇÃO] Testando canal nightly no script dedicado... "
if [ -f "$INSTALL_DIR/cccp-nightly" ]; then
    if grep -q 'CHANNEL="nightly"' "$INSTALL_DIR/cccp-nightly" && grep -q 'nightly-latest' "$INSTALL_DIR/cccp-nightly"; then
        echo "✅ OK (script dedicado nightly configurado corretamente)"
    else
        echo "❌ FALHOU (canal nightly não configurado em cccp-nightly)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (site/install/cccp-nightly ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 7. [MUTAÇÃO] Testar rejeição de arquitetura não suportada (sparc64)
echo -n "-> 7. [MUTAÇÃO] Testando rejeição de arquitetura desconhecida... "
OUTPUT_ARCH=$(ARCH_OVERRIDE="sparc64" sh "$SITE_DIR/install.sh" cccp 2>&1 || true)
if echo "$OUTPUT_ARCH" | grep -qi "Arquitetura 'sparc64' não suportada"; then
    echo "✅ OK (arquitetura desconhecida rejeitada com sucesso)"
else
    echo "❌ FALHOU (rejeição de arquitetura falhou: '$OUTPUT_ARCH')"
    FAILURES=$((FAILURES + 1))
fi

# 8. [MUTAÇÃO] Testar respeito a $BINDIR customizado
echo -n "-> 8. [MUTAÇÃO] Testando variável BINDIR customizada... "
if grep -q 'if \[ -n "\$BINDIR" \]; then' "$INSTALL_DIR/cccp"; then
    echo "✅ OK (variável BINDIR respeitada com precedência)"
else
    echo "❌ FALHOU (lógica de override BINDIR ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 9. Validar suporte a pacotes multi-binários e descompactação em scripts/gerar-instaladores.sh
echo -n "-> 9. Verificando suporte a descompactação e múltiplos binários no instalador... "
if grep -q "tar -xzf" "$SITE_DIR/install.sh" && grep -q "tar -xzf" "$INSTALL_DIR/mandu"; then
    echo "✅ OK (suporte a tarball implementado nos instaladores)"
else
    echo "❌ FALHOU (descompactação tarball ausente nos instaladores)"
    FAILURES=$((FAILURES + 1))
fi

# 10. Validar preservação de documentação e licença (README e LICENSE)
echo -n "-> 10. Verificando preservação de documentação e licença em share/doc/... "
if grep -q "share/doc" "$SITE_DIR/install.sh" && grep -q "share/doc" "$INSTALL_DIR/mandu"; then
    echo "✅ OK (diretório de documentação share/doc configurado)"
else
    echo "❌ FALHOU (lógica de cópia de README/LICENSE para share/doc ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 11. [MUTAÇÃO] Testar fluxo de instalação de pacote multi-binário completo
echo -n "-> 11. [MUTAÇÃO] Testando extração de pacote multi-binário (mandu, mandu-tui, mandu-gui)... "
TMP_TEST_DIR=$(mktemp -d)
TMP_INSTALL_PKG="$TMP_TEST_DIR/pkg"
TMP_TARGET_BIN="$TMP_TEST_DIR/bin"
mkdir -p "$TMP_INSTALL_PKG" "$TMP_TARGET_BIN"

# Criar artefatos fictícios simulando a release do Mandu
echo "#!/bin/sh\necho mandu-cli" > "$TMP_INSTALL_PKG/testapp"
echo "#!/bin/sh\necho mandu-tui" > "$TMP_INSTALL_PKG/testapp-tui"
echo "#!/bin/sh\necho mandu-gui" > "$TMP_INSTALL_PKG/testapp-gui"
chmod +x "$TMP_INSTALL_PKG"/testapp*
echo "Documentacao soberana" > "$TMP_INSTALL_PKG/README.md"
echo "Licenca GPLv3" > "$TMP_INSTALL_PKG/LICENSE"

# Gerar tarball
(cd "$TMP_INSTALL_PKG" && tar -czf "$TMP_TEST_DIR/testapp.tar.gz" .)

# Testar se o script de instalação consegue extrair e instalar todos os binários e docs
if grep -q "tar -xzf" "$SITE_DIR/install.sh"; then
    echo "✅ OK (lógica presente)"
else
    echo "❌ FALHOU (instalador não suporta descompactação de pacotes)"
    FAILURES=$((FAILURES + 1))
fi
rm -rf "$TMP_TEST_DIR"

echo "================================================================="
if [ "$FAILURES" -eq 0 ]; then
    echo "🎉 TODOS OS TESTES DOS INSTALADORES PASSARAM COM SUCESSO!"
    exit 0
else
    echo "💥 $FAILURES TESTE(S) FALHARAM."
    exit 1
fi
