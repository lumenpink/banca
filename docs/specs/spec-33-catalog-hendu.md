# Especificação Técnica: Inclusão do Hendu no Catálogo da Banca (Ticket #33)

## 1. Contexto e Motivação
O **Hendu** (`lumenpink/hendu`) é um bot de WhatsApp em Rust auto-hospedado dedicado à acessibilidade comunitária, provendo:
- Transcrição automatizada de mensagens de voz/áudio para pessoas surdas ou com deficiência auditiva;
- Audiodescrição estruturada de imagens, fotografias e figurinhas para pessoas cegas ou com baixa visão (via integração com modelos multimodais locais e Gemini).

Este ticket formaliza a inclusão do Hendu na vitrine principal e no catálogo público de projetos da Banca (`data/projects.json`).

---

## 2. Requisitos de Metadados e Catálogo

1. **Entrada Canônica em `data/projects.json`**:
   ```json
   {
     "name": "hendu",
     "forge": "codeberg",
     "slug": "lumenpink/hendu",
     "description": "Bot de WhatsApp em Rust para acessibilidade comunitária, transcrição de áudio e audiodescrição",
     "topics": [
       "rust",
       "whatsapp",
       "accessibility",
       "gemini",
       "bot"
     ],
     "license": "GPL-3.0",
     "website": "",
     "is_upstream": false,
     "group": "",
     "banner": "assets/banners/hendu-banner.png",
     "category": "apps"
   }
   ```
2. **Banner Visual Oficial**:
   - Localização: `assets/banners/hendu-banner.png`
   - Dimensões canônicas: 1200 x 630 pixels (aspect ratio 1.904:1 / Safe Zone da Banca)
   - Profundidade de cor: 8-bit RGB
3. **Vitrine Estática (`build.sh`)**:
   - A execução de `./build.sh` deve compilar `site/index.html` contendo o cartão do Hendu com links para o Codeberg e filtro ativo pela categoria `apps`.
