# Especificação Técnica — Ticket #59

## fix(pratilera): servir mandu.apk diretamente sem redirects e validar fail-fast

### 1. Objetivo
Garantir que o artefato Android `mandu.apk` do aplicativo Mandu (`in.twolp.mandu`) seja distribuído e servido diretamente pela Pratilera (`site/pratilera/mandu.apk`), eliminando qualquer dependência de regras de redirecionamento HTTP 302 em `site/_redirects`. Implementar validação estrita fail-fast no script gerador e na suíte de testes para assegurar que ausência de binário ou corrupção de metadados aborte imediatamente a esteira.

### 2. Causa Raiz
No Droid-ify / F-Droid, clientes configurados com a URL da Pratilera (`https://banca.2lp.in/pratilera`) buscam o binário do aplicativo em `https://banca.2lp.in/pratilera/mandu.apk`.
Anteriormente, o script `scripts/gerar-pratilera.py` baixava ou resolvia o APK para o cache local (`.cache/apks/mandu.apk`), mas não copiava o artefato para `site/pratilera/mandu.apk` quando o binário vinha do bucket ou cache externo. Como consequência, a pasta `site/` publicada via Cloudflare Workers Static Assets não continha o binário, resultando em erro HTTP 404 durante a tentativa de instalação no Droid-ify.

### 3. Mudanças Previstas
1. **Publicação Direta em `scripts/gerar-pratilera.py`**:
   - Ao resolver o APK via `resolve_apk_binary()`, garantir que o binário resultante seja copiado fisicamente para `PRATILERA_DIR / meta["apk_filename"]` (`site/pratilera/mandu.apk`), desde que seu tamanho respeite o teto de 25 MB do Cloudflare Workers (`<= 26214400 bytes`).
   - Se o APK não puder ser obtido ou tiver tamanho anômalo (< 1 MB), abortar imediatamente com erro fatal fail-fast (`sys.exit(1)`).
   - Não adicionar nenhuma regra de redirecionamento 302 para `mandu.apk` em `site/_redirects`.
2. **Suíte de Testes `tests/test-pratilera-mandu.sh`**:
   - Adicionar asserção fail-fast verificando que `site/pratilera/mandu.apk` existe no disco e possui tamanho válido (>= 1 MB).
   - Validar que a integridade do pacote no `index-v1.json` reflete o tamanho e hash SHA-256 do arquivo presente em `site/pratilera/`.
3. **Suíte Geral `tests/test-pratilera.sh`**:
   - Manter testes de regressão íntegros e compatíveis com a entrega estática direta.
