#!/usr/bin/env bash
# ==============================================================================
# Banca — Teste de Validação de Downloads Multi-Arquitetura e Canais (#35 & #32)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="$REPO_ROOT/site"
DOWNLOADS_DIR="$SITE_DIR/downloads"

echo "================================================================="
echo "🧪 [TESTE] Validação de Downloads Multi-Arquitetura e Canais"
echo "================================================================="

FAILURES=0

# 1. Validar que _redirects não intercepta manifestos JSON nem arquivos de binários
echo -n "-> 1. Verificando proteção de rotas estáticas em site/_redirects... "
REDIRECTS_FILE="$SITE_DIR/_redirects"
if [ ! -f "$REDIRECTS_FILE" ]; then
    echo "❌ FALHOU (arquivo site/_redirects ausente)"
    FAILURES=$((FAILURES + 1))
else
    # Deve conter regra ou exceção impedindo que /downloads/* intercepte .json ou extensões binárias
    if grep -qE '^/downloads/\*\s+/downloads/index\.html\s+200' "$REDIRECTS_FILE"; then
        echo "❌ FALHOU (rewrite cego /downloads/* intercepta arquivos estáticos e index.json)"
        FAILURES=$((FAILURES + 1))
    else
        echo "✅ OK"
    fi
fi

# 2. Validar suporte a --arch e estrutura de artifacts no rotate-downloads.py
echo -n "-> 2. Verificando suporte a --arch no scripts/rotate-downloads.py... "
ROTATE_SCRIPT="$REPO_ROOT/scripts/rotate-downloads.py"
if [ -f "$ROTATE_SCRIPT" ]; then
    if grep -q "\-\-arch" "$ROTATE_SCRIPT" && grep -q "artifacts" "$ROTATE_SCRIPT"; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (scripts/rotate-downloads.py não implementa --arch ou artifacts)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (scripts/rotate-downloads.py ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 3. Validar geração de index.json no build.sh para as ferramentas
echo -n "-> 3. Verificando manifestos index.json em site/downloads/... "
MANDU_MANIFEST="$DOWNLOADS_DIR/mandu/index.json"
if [ -f "$MANDU_MANIFEST" ]; then
    if python3 -c "
import json, sys
with open('$MANDU_MANIFEST') as f:
    d = json.load(f)
assert d.get('app') == 'mandu', 'app != mandu'
assert 'stables' in d and 'nightlies' in d, 'faltam stables/nightlies'
" 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ FALHOU (manifesto de mandu malformatado)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "❌ FALHOU (manifesto site/downloads/mandu/index.json ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 4. Validar UI de downloads: Mandu categorizado corretamente e seletores de arquitetura
echo -n "-> 4. Verificando descrição do Mandu e seletores multi-arch em site/downloads/index.html... "
DOWNLOADS_HTML="$DOWNLOADS_DIR/index.html"
if [ -f "$DOWNLOADS_HTML" ]; then
    if grep -q "Gerenciador de Pacotes" "$DOWNLOADS_HTML"; then
        echo "❌ FALHOU (Mandu ainda catalogado como 'Gerenciador de Pacotes')"
        FAILURES=$((FAILURES + 1))
    elif ! grep -q "windows-amd64" "$DOWNLOADS_HTML" || ! grep -q "linux-arm64" "$DOWNLOADS_HTML"; then
        echo "❌ FALHOU (faltam seletores de arquitetura windows-amd64 / linux-arm64)"
        FAILURES=$((FAILURES + 1))
    else
        echo "✅ OK"
    fi
else
    echo "❌ FALHOU (site/downloads/index.html ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 5. Validar PowerShell snippet para Windows
echo -n "-> 5. Verificando snippet PowerShell para Windows... "
if [ -f "$DOWNLOADS_HTML" ] && grep -qi "Invoke-WebRequest" "$DOWNLOADS_HTML"; then
    echo "✅ OK"
else
    echo "❌ FALHOU (snippet PowerShell com Invoke-WebRequest ausente)"
    FAILURES=$((FAILURES + 1))
fi

# 6. [MUTAÇÃO] Teste de Retenção Estrita (Expurgo de 6ª estável e 11ª nightly)
echo -n "-> 6. [MUTAÇÃO] Testando retenção máxima de 5 stables e 10 nightlies... "
TMP_MUTATION_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_MUTATION_DIR"' EXIT
TMP_MANIFEST="$TMP_MUTATION_DIR/index.json"

for i in $(seq 1 7); do
    python3 "$ROTATE_SCRIPT" --manifest "$TMP_MANIFEST" --app "testapp" --channel "stable" --version-str "1.0.$i" --url "https://banca.2lp.in/downloads/testapp/stable/1.0.$i/testapp" >/dev/null 2>&1
done
for j in $(seq 1 12); do
    python3 "$ROTATE_SCRIPT" --manifest "$TMP_MANIFEST" --app "testapp" --channel "nightly" --version-str "1.1.0-dev.$j" --url "https://banca.2lp.in/downloads/testapp/nightly/1.1.0-dev.$j/testapp" >/dev/null 2>&1
done

if python3 -c "
import json
with open('$TMP_MANIFEST') as f:
    d = json.load(f)
assert len(d['stables']) == 5, f'stables length {len(d[\"stables\"])} != 5'
assert len(d['nightlies']) == 10, f'nightlies length {len(d[\"nightlies\"])} != 10'
assert d['stable_latest'] == '1.0.7', f'stable_latest {d[\"stable_latest\"]} != 1.0.7'
assert d['nightly_latest'] == '1.1.0-dev.12', f'nightly_latest {d[\"nightly_latest\"]} != 1.1.0-dev.12'
" 2>/dev/null; then
    echo "✅ OK (Retenção 5 stables / 10 nightlies comprovada)"
else
    echo "❌ FALHOU (Mutação de retenção violou teto de 5 stables ou 10 nightlies)"
    FAILURES=$((FAILURES + 1))
fi

# 7. [MUTAÇÃO] Teste de Mesclagem Multi-Arquitetura sem Duplicação
echo -n "-> 7. [MUTAÇÃO] Testando agregação de artefatos multi-arch na mesma versão... "
python3 "$ROTATE_SCRIPT" --manifest "$TMP_MANIFEST" --app "testapp" --channel "stable" --version-str "2.0.0" --arch "linux-amd64" --url "https://banca.2lp.in/downloads/testapp/stable/testapp-linux-amd64" >/dev/null 2>&1
python3 "$ROTATE_SCRIPT" --manifest "$TMP_MANIFEST" --app "testapp" --channel "stable" --version-str "2.0.0" --arch "linux-arm64" --url "https://banca.2lp.in/downloads/testapp/stable/testapp-linux-arm64" >/dev/null 2>&1
python3 "$ROTATE_SCRIPT" --manifest "$TMP_MANIFEST" --app "testapp" --channel "stable" --version-str "2.0.0" --arch "windows-amd64" --url "https://banca.2lp.in/downloads/testapp/stable/testapp.exe" --tarball "https://banca.2lp.in/downloads/testapp/stable/testapp-windows-amd64.zip" >/dev/null 2>&1

if python3 -c "
import json
with open('$TMP_MANIFEST') as f:
    d = json.load(f)
v2_entries = [e for e in d['stables'] if e.get('version') == '2.0.0']
assert len(v2_entries) == 1, f'Duplicação de versão detectada: {len(v2_entries)} entradas'
art = v2_entries[0].get('artifacts', {})
assert 'linux-amd64' in art, 'linux-amd64 ausente'
assert 'linux-arm64' in art, 'linux-arm64 ausente'
assert 'windows-amd64' in art, 'windows-amd64 ausente'
assert 'testapp-windows-amd64.zip' in art['windows-amd64']['url'], 'zip windows incorreto'
" 2>/dev/null; then
    echo "✅ OK (Agregação de 3 arquiteturas em versão única comprovada)"
else
    echo "❌ FALHOU (Mutação multi-arch causou duplicação ou perda de artefato)"
    FAILURES=$((FAILURES + 1))
fi

# 8. [MUTAÇÃO] Teste de Resiliência com Arquivo Corrompido
echo -n "-> 8. [MUTAÇÃO] Testando recuperação automática de JSON corrompido... "
echo "CORRUPTED_JSON_DATA_!@#$%" > "$TMP_MANIFEST"
python3 "$ROTATE_SCRIPT" --manifest "$TMP_MANIFEST" --app "testapp" --channel "stable" --version-str "3.0.0" --url "https://banca.2lp.in/downloads/testapp/stable/testapp" >/dev/null 2>&1

if python3 -c "
import json
with open('$TMP_MANIFEST') as f:
    d = json.load(f)
assert d.get('app') == 'testapp'
assert d.get('stable_latest') == '3.0.0'
assert len(d['stables']) == 1
" 2>/dev/null; then
    echo "✅ OK (Recuperação limpa de arquivo corrompido comprovada)"
else
    echo "❌ FALHOU (Falha na recuperação de JSON corrompido)"
    FAILURES=$((FAILURES + 1))
fi

echo "================================================================="
if [ "$FAILURES" -gt 0 ]; then
    echo "💥 $FAILURES TESTE(S) FALHARAM (Esperado na Fase Red do DD-TDD)."
    exit 1
else
    echo "🎉 TODOS OS TESTES DE DOWNLOADS PASSARAM COM SUCESSO!"
    exit 0
fi
