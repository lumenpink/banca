#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "★ [TESTE] Validação de Linguagem Humanizada e Desmistificada na Banca (#44) ★"

echo "[1/4] Auditando termos técnicos proibidos em data/projects.json..."
python3 -c "
import json
with open('${ROOT_DIR}/data/projects.json', 'r', encoding='utf-8') as f:
    items = json.load(f)

for item in items:
    name = item.get('name', '')
    desc = item.get('description', '')
    desc_l = desc.lower()
    if 'soberan' in desc_l:
        raise AssertionError(f'Item {name} contém termo soberano proibido: {desc}')
    if 'wasm' in desc_l:
        raise AssertionError(f'Item {name} contém jargão técnico wasm proibido: {desc}')
    if 'rust puro' in desc_l or 'em rust' in desc_l:
        raise AssertionError(f'Item {name} contém menção técnica desnecessária a Rust: {desc}')
    if 'na borda' in desc_l:
        raise AssertionError(f'Item {name} contém termo de arquitetura borda proibido: {desc}')
    if 'fricção' in desc_l or 'friccao' in desc_l:
        raise AssertionError(f'Item {name} contém jargão de alta fricção proibido: {desc}')
    if name == 'navalha' and 'anti-design' not in desc_l:
        raise AssertionError(f'Navalha DEVE preservar anti-design: {desc}')

print(f'  Catálogo da Banca ({len(items)} itens) 100% humanizado e sem jargões!')
"

echo "[2/4] Auditando templates em build.sh e site/index.html..."
python3 -c "
for path in ['${ROOT_DIR}/build.sh', '${ROOT_DIR}/site/index.html']:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read().lower()
    if 'arquitetura soberana' in content:
        raise AssertionError(f'{path} contém arquitetura soberana')
    if 'utilitários de fricção' in content:
        raise AssertionError(f'{path} contém utilitários de fricção')
    if 'loja soberana' in content:
        raise AssertionError(f'{path} contém loja soberana')
print('  Templates da vitrine auditados com sucesso!')
"

echo "[3/4] Auditando site/downloads/index.html..."
python3 -c "
with open('${ROOT_DIR}/site/downloads/index.html', 'r', encoding='utf-8') as f:
    content = f.read().lower()
if 'distribuição soberana' in content:
    raise AssertionError('downloads/index.html contém distribuição soberana')
if 'banca soberana' in content:
    raise AssertionError('downloads/index.html contém banca soberana')
print('  Downloads auditados com sucesso!')
"

echo "[4/4] Auditando site/install.sh..."
python3 -c "
with open('${ROOT_DIR}/site/install.sh', 'r', encoding='utf-8') as f:
    content = f.read().lower()
if 'aplicativos soberanos' in content:
    raise AssertionError('install.sh contém aplicativos soberanos')
if 'ecossistema soberano' in content:
    raise AssertionError('install.sh contém ecossistema soberano')
print('  Instalador auditado com sucesso!')
"

echo "✔ Cópia da Banca 100% humanizada e em conformidade!"
exit 0
