# Especificação Técnica: Vitrine de Downloads da Banca e Retenção Soberana (Ticket #31)

## 1. Contexto e Motivação
A distribuição de ferramentas CLI e binários compilados pelo ecossistema 2lp/Gosplan passa a ser hospedada de forma soberana na Banca (`https://banca.2lp.in/downloads`).
Para manter o desktop do usuário e a máquina de trabalho 100% responsivos, a compilação de binários ocorre unicamente na esteira sequencial (Forgejo Runner).
A Banca atua como a interface web de vitrine estática e catálogo de entrega, consumindo metadados atômicos e disponibilizando os binários com controle estrito de retenção:
- **5 versões estáveis** mais recentes (com alias `stable-latest`)
- **10 compilações de desenvolvimento/nightly** mais recentes (com alias `nightly-latest`)

## 2. Requisitos da Interface Web (`/downloads`)
1. **Tecnologia**: Vanilla JS puro, CSS minimalista e responsivo, sem bundlers, transpilers ou dependências de terceiros.
2. **Estética**: Alinhada ao manifesto anti-design / fanzine punk tropical da Banca:
   - Paleta oficial: `--bg: #f3efe6`, `--paper: #ffffff`, `--ink: #111111`, `--pink: #ff007f`, `--yellow: #ffee00`, `--cyan: #00e5ff`.
   - Tipografia monoespaçada, bordas espessas de 3px, sombras sólidas de 5px.
3. **Dropdown Seletor de Software**:
   - Elemento `<select id="app-selector">` no topo da página.
   - Lista todas as ferramentas do ecossistema: `cccp`, `navalha`, `lauda`, `lacraia`, `joaju`, `svyaz`, `mayak`, `kvant`, `ayvu`, `tuitata`, `baquara`, `mocambo`, `hendu`, `mandu`, `tatupeba`.
4. **Deep Linking Bidirecional**:
   - URLs diretas suportadas: `/downloads/<app>` (via regra de rewrite em `site/_redirects`) ou `/downloads#<app>`.
   - Ao carregar a página, se a URL contiver um app válido, seleciona o software correspondente no dropdown e exibe suas versões.
   - Ao trocar de opção no dropdown, a URL é atualizada via `history.pushState` com `#<app>` (ou path), sem recarregar a página.
5. **Apresentação dos Canais**:
   - **Canal Estável**:
     - Cartão de destaque para o alias `stable-latest`.
     - Botão de download direto do binário.
     - One-liner para cópia direta via terminal (ex.: `curl -sSL https://banca.2lp.in/downloads/<app>/stable-latest/<app> -o /usr/local/bin/<app> && chmod +x /usr/local/bin/<app>`).
     - Tabela/lista com as até 5 versões estáveis mais recentes (versão, data, tamanho, hash sha256).
   - **Canal Nightly**:
     - Cartão de destaque para o alias `nightly-latest`.
     - Tabela/lista com as até 10 compilações dev/nightly mais recentes vinculadas aos commits atômicos.
6. **Resiliência e Fallback Offline**:
   - Caso o manifesto `index.json` não esteja acessível ou ainda não tenha sido publicado no storage R2, a interface exibe os comandos e links canônicos padrão do canal estável sem quebrar a página.

## 3. Estrutura do Manifesto de Metadados (`index.json`)
Cada aplicação possui um manifesto em `https://banca.2lp.in/downloads/<app>/index.json`:
```json
{
  "app": "cccp",
  "name": "CCCP CLI",
  "description": "Ferramenta central de governança, conformidade e esteira DD-TDD do ecossistema Gosplan.",
  "stable_latest": "3.1.0",
  "nightly_latest": "3.2.0-dev.189+20261019.e3be1d3",
  "stables": [
    {
      "version": "3.1.0",
      "url": "https://banca.2lp.in/downloads/cccp/releases/v3.1.0/cccp",
      "tarball": "https://banca.2lp.in/downloads/cccp/releases/v3.1.0/cccp-3.1.0-linux-amd64.tar.gz",
      "date": "2026-10-19",
      "sha256": "abcdef..."
    }
  ],
  "nightlies": [
    {
      "version": "3.2.0-dev.189+20261019.e3be1d3",
      "url": "https://banca.2lp.in/downloads/cccp/nightly-latest/cccp",
      "date": "2026-10-19",
      "sha256": "123456..."
    }
  ]
}
```

## 4. Política de Retenção e Rotação no Storage R2
O script utilitário `scripts/rotate-downloads.py` é responsável por:
1. Inserir a nova compilação na lista apropriada (`stables` ou `nightlies`).
2. Se `len(stables) > 5`, expurgar as versões mais antigas do storage e do manifesto.
3. Se `len(nightlies) > 10`, expurgar as compilações mais antigas do storage e do manifesto.
4. Atualizar os aliases atômicos `stable-latest/<app>` e `nightly-latest/<app>`.
5. Salvar o manifesto `index.json` atualizado.
