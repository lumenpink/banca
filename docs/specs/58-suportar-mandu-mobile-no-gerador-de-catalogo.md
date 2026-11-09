# Especificação Técnica — Ticket #58

## fix(pratilera): suportar mandu-mobile no gerador de catalogo

### 1. Objetivo
Mapear e integrar o repositório irmão `mandu-mobile` nas rotinas de geração do catálogo F-Droid da Pratilera (`scripts/gerar-pratilera.py`), garantindo que binários APK recém-gerados, ícones de alta resolução e versões canônicas do CCCP sejam importados corretamente, preservando retrocompatibilidade com `mandu`.

### 2. Mudanças Previstas
1. **`scripts/gerar-pratilera.py`**:
   - Em `import_external_apks`: verificar e priorizar `../mandu-mobile/dist/android/mandu.apk` e `../mandu-mobile/dist/mandu.apk`.
   - Na importação de ícones: verificar e priorizar `../mandu-mobile/fastlane/metadata/android/in.twolp.mandu/icon.png` e `../mandu-mobile/assets/icon.png`.
   - Em `resolve_apk_binary`: incluir caminhos de `mandu-mobile` na lista de candidatos locais.
   - Em `get_project_version`: ao consultar versão de "mandu", priorizar `../mandu-mobile/VERSION` antes de `../mandu/VERSION`.
   - Nos metadados Fastlane localizados: verificar diretórios de metadados de `mandu-mobile`.
2. **`tests/test-pratilera-mandu.sh`**:
   - Adicionar asserções validando que o script suporta e referencia `mandu-mobile`.
