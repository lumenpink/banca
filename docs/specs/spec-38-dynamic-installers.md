# Especificação Técnica: Instaladores Dinâmicos Dedicados sem Root por Aplicação e Canal

**Ticket Associado:** #38  
**Branch:** `feat/38-dynamic-installers`  
**Norma:** GOST 1.5.0  

## 1. Objetivo
Disponibilizar scripts instaladores autônomos e dedicados para cada uma das aplicações de terminal e utilitários da Banca (`site/install/<app>` e `site/install/<app>-nightly`), além de um instalador genérico (`site/install.sh`), garantindo instalação sem privilégios de root por padrão em `$HOME/.local/bin`, rejeição ideológica e bem-humorada de plataformas Apple/Darwin, validação do `$PATH` do usuário e atualização da vitrine web `site/downloads/index.html`.

---

## 2. Requisitos Arquiteturais

### 2.1. Matriz de Endpoints dos Instaladores
A Banca disponibilizará os seguintes endpoints estáticos para execução direta via pipe (`curl -fsSL ... | sh`):
- **Canal Estável Dedicado:** `https://banca.2lp.in/install/<app>` (ex.: `install/cccp`, `install/mandu`, `install/navalha`).
- **Canal Nightly Dedicado:** `https://banca.2lp.in/install/<app>-nightly` (ex.: `install/cccp-nightly`, `install/mandu-nightly`).
- **Instalador Raiz Genérico:** `https://banca.2lp.in/install.sh` (suporta `sh -s -- <app> [--nightly]`).

### 2.2. Regras de Execução do Instalador Shell POSIX
1. **Destino sem Root por Padrão:**
   - Se a variável de ambiente `$BINDIR` estiver configurada, utilizar seu valor.
   - Caso contrário:
     - Se o usuário atual for root (`id -u == 0`), instalar em `/usr/local/bin`.
     - Se for usuário normal (`id -u != 0`), instalar em `$HOME/.local/bin`.
   - Criar o diretório de destino caso não exista (`mkdir -p "$TARGET_DIR"`).
2. **Rejeição de Sistemas Apple / Darwin:**
   - Detectar via `uname -s`. Se for `Darwin`, abortar com código de saída 1 e a mensagem:
     `"macOS/Darwin não é suportado pelo ecossistema soberano da Banca."`
3. **Detecção de Arquitetura Linux:**
   - `x86_64` $\to$ `linux-amd64`
   - `aarch64` ou `arm64` $\to$ `linux-arm64`
   - Outras arquiteturas: abortar com mensagem explicativa.
4. **Verificação de `$PATH`:**
   - Se o diretório alvo da instalação (ex.: `$HOME/.local/bin`) não constar no `$PATH`, emitir um aviso formatado instruindo a inclusão no arquivo de perfil da shell (`.bashrc`, `.zshrc` ou `.profile`).
5. **Download e Substituição Atômica:**
   - Baixar via `curl -fsSL` (com fallback para `wget -qO-`) para um arquivo temporário no mesmo diretório (`$TARGET_DIR/.<app>.tmp.$$`).
   - Aplicar permissão executável (`chmod 755`).
   - Mover atomicamente para o destino final (`mv "$TMP_FILE" "$TARGET_DIR/<app>"`).

### 2.3. Integração com o Gerador da Banca (`build.sh` ou `scripts/gerar-instaladores.sh`)
- Iterar com um loop `for app in "${APPS[@]}"` gerando os instaladores dedicados em `site/install/<app>` e `site/install/<app>-nightly`, além do `site/install.sh`.
- Configurar cabeçalho `Content-Type: text/plain; charset=utf-8` em `site/_headers` para `/install/*`.

### 2.4. Atualização da Interface Web (`site/downloads/index.html`)
- No card do Canal Estável:
  `curl -fsSL https://banca.2lp.in/install/<app> | sh`
- No card do Canal Nightly:
  `curl -fsSL https://banca.2lp.in/install/<app>-nightly | sh`
- Windows (PowerShell): mantido o download de arquivo `.zip`.

---

## 3. Critérios de Aceitação
1. Scripts executáveis gerados para todos os projetos catalogados em `site/install/<app>` e `site/install/<app>-nightly`.
2. Execução simulada em Linux instala em `$HOME/.local/bin` sem necessidade de `sudo`.
3. Execução simulada com `id -u == 0` instala em `/usr/local/bin`.
4. Execução simulada em ambiente `Darwin` aborta com a mensagem de repúdio à Apple.
5. `site/downloads/index.html` exibe os novos comandos dedicados dinamicamente ao trocar de app.
6. Teste automatizado `tests/test-installers.sh` valida 100% dos fluxos e mutações.
