#!/bin/sh
# ==============================================================================
# BANCA — Gerador Estático Anti-Design de Vitrine de Projetos (Estilo bashblog)
# ==============================================================================
set -eu

DATA_FILE="data/projects.json"
OUTPUT_HTML="site/index.html"

if [ ! -f "$DATA_FILE" ]; then
    echo "Erro: Arquivo de dados '$DATA_FILE' não encontrado!" >&2
    exit 1
fi

mkdir -p site/assets/banners

SYNC_RAWS=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --sync-raws|--fetch-raws) SYNC_RAWS=true ;;
        --force) FORCE=true ;;
    esac
done

# Detecta cliente HTTP (preferência estrita pelo Comrade sv / svyaz do Gosplan)
HTTP_GET=""
if command -v sv >/dev/null 2>&1; then
    HTTP_GET="sv -s -L -f -m 3 -o"
elif command -v svyaz >/dev/null 2>&1; then
    HTTP_GET="svyaz -s -L -f -m 3 -o"
elif command -v curl >/dev/null 2>&1; then
    HTTP_GET="curl -s -L -f -m 3 -o"
fi

# Se flag --sync-raws for informada, sincroniza pôsteres das URLs raw
if [ "$SYNC_RAWS" = "true" ] && [ -n "$HTTP_GET" ]; then
    echo "✦ [BANCA] Sincronizando raws remotos com nosso comrade ${HTTP_GET%% *}..."
    jq -c '.[]' "$DATA_FILE" | while read -r item; do
        NAME=$(echo "$item" | jq -r '.name')
        FORGE=$(echo "$item" | jq -r '.forge')
        SLUG=$(echo "$item" | jq -r '.slug')
        DEST="site/assets/banners/${NAME}-banner.png"

        if [ -s "$DEST" ] && [ "$FORCE" != "true" ]; then
            continue
        fi

        URLS=""
        if [ "$FORGE" = "codeberg" ]; then
            URLS="https://codeberg.org/${SLUG}/raw/branch/main/site/assets/poster.png https://codeberg.org/${SLUG}/raw/branch/main/site/assets/og_preview.png"
        elif [ "$FORGE" = "github" ]; then
            URLS="https://raw.githubusercontent.com/${SLUG}/main/site/assets/poster.png https://raw.githubusercontent.com/${SLUG}/main/site/assets/og_preview.png"
        fi

        for url in $URLS; do
            if $HTTP_GET "$DEST" "$url" 2>/dev/null; then
                if [ -s "$DEST" ]; then
                    echo "  [RAW] Pôster de '$NAME' obtido via ${HTTP_GET%% *}: $url"
                    break
                else
                    rm -f "$DEST"
                fi
            fi
        done
    done
fi

echo "✦ [BANCA] Compilando vitrine estática anti-design..."

# Extrai e formata os dados dos projetos usando jq para montar o catálogo pré-renderizado
PROJECTS_HTML=""
COUNT=$(jq 'length' "$DATA_FILE")
COMRADES_COUNT=$(jq '[.[] | select(.group == "comrades")] | length' "$DATA_FILE")

# Renderiza os cards individuais
PROJECTS_HTML=$(jq -r '
  .[] | 
  "<article class=\"zine-card" + (if .group == "comrades" then " is-comrade" else "" end) + "\" data-name=\"" + (.name | ascii_downcase) + "\" data-group=\"" + .group + "\" data-topics=\"" + (.topics | join(" ") | ascii_downcase) + "\" data-has-banner=\"" + (if .banner != "" then "true" else "false" end) + "\">" +
  "  <div class=\"zine-header\">" +
  (if .group == "comrades" then "    <span class=\"badge comrade-badge\">★ CCCP COMRADE</span>" else "" end) +
  "    <span class=\"badge forge-badge\">" + .forge + "</span>" +
  "    <span class=\"badge license-badge\">" + .license + "</span>" +
  "  </div>" +
  "  <div class=\"zine-media\">" +
  (if .banner != "" then
    "    <img src=\"" + .banner + "\" alt=\"Pôster de " + .name + "\" loading=\"lazy\" class=\"zine-poster\">"
  else
    "    <div class=\"standby-poster\"><div class=\"standby-stamp\">[ STANDBY ]</div><div class=\"standby-label\">AGUARDANDO PÔSTER</div></div>"
  end) +
  "  </div>" +
  "  <div class=\"zine-body\">" +
  "    <h2 class=\"zine-title\">" + .name + "</h2>" +
  "    <p class=\"zine-desc\">" + .description + "</p>" +
  "    <div class=\"zine-tags\">" +
  (if (.topics | length) > 0 then
    ([.topics[] | "<span class=\"tag\">#" + . + "</span>"] | join(""))
   else
    "<span class=\"tag tag-empty\">#projeto-autoral</span>"
   end) +
  "    </div>" +
  "    <div class=\"zine-actions\">" +
  "      <a href=\"" + 
         (if .forge == "codeberg" then "https://codeberg.org/" + .slug
          elif .forge == "github" then "https://github.com/" + .slug
          elif .forge == "tildegit" then "https://tildegit.org/" + .slug
          else "https://codeberg.org/" + .slug end) + 
         "\" target=\"_blank\" rel=\"noopener\" class=\"btn btn-primary\">FONTE ↗</a>" +
  (if .website != "" then
    "      <a href=\"" + .website + "\" target=\"_blank\" rel=\"noopener\" class=\"btn btn-secondary\">DOCS / SITE ↗</a>"
  else
    ""
  end) +
  "    </div>" +
  "  </div>" +
  "</article>"
' "$DATA_FILE")

cat << 'EOF' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BANCA // Zines, Projetos & Código Independente</title>
  <meta name="description" content="Mostra e vitrine anti-design dos projetos e fanzines de código desenvolvidos por Lumen Pink.">
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>✂</text></svg>">

  <!-- OpenGraph & Twitter Cards -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="BANCA // Zines, Projetos &amp; Código Independente">
  <meta property="og:description" content="Mostra e vitrine anti-design dos projetos e fanzines de código desenvolvidos por Lumen Pink.">
  <meta property="og:image" content="https://banca.2lp.in/assets/poster.png">
  <meta property="og:url" content="https://banca.2lp.in">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="BANCA // Zines, Projetos &amp; Código Independente">
  <meta name="twitter:description" content="Mostra e vitrine anti-design dos projetos e fanzines de código desenvolvidos por Lumen Pink.">
  <meta name="twitter:image" content="https://banca.2lp.in/assets/poster.png">
  <style>
    /* =========================================================================
       BANCA // ESTÉTICA ANTI-DESIGN / FANZINE PUNK TROPICAL / ALTA FRICÇÃO
       ========================================================================= */
    :root {
      --bg: #f3efe6;
      --paper: #ffffff;
      --ink: #111111;
      --pink: #ff007f;
      --pink-neon: #ff1493;
      --yellow: #ffee00;
      --cyan: #00e5ff;
      --tape: #e8d8b8;
      --border: 3px solid var(--ink);
      --shadow: 5px 5px 0px var(--ink);
      --shadow-hover: 8px 8px 0px var(--pink);
      --font-mono: "Courier New", Courier, monospace, "DejaVu Sans Mono";
      --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      background-color: var(--bg);
      background-image: 
        radial-gradient(#111111 0.75px, transparent 0.75px),
        linear-gradient(to right, rgba(0,0,0,0.03) 1px, transparent 1px);
      background-size: 16px 16px, 40px 40px;
      color: var(--ink);
      font-family: var(--font-mono);
      line-height: 1.5;
      padding: 1.5rem 1rem 4rem;
    }

    .container {
      max-width: 1240px;
      margin: 0 auto;
    }

    /* HEADER & BANNER MANIFESTO */
    header {
      background: var(--paper);
      border: var(--border);
      box-shadow: 8px 8px 0px var(--ink);
      padding: 2rem 1.5rem;
      margin-bottom: 2rem;
      position: relative;
      transform: rotate(-0.3deg);
    }

    .tape-top {
      position: absolute;
      top: -14px;
      left: 30px;
      background: var(--tape);
      border: 1px dashed rgba(0,0,0,0.4);
      padding: 4px 20px;
      font-size: 0.75rem;
      font-weight: bold;
      transform: rotate(-3deg);
      box-shadow: 1px 1px 2px rgba(0,0,0,0.2);
    }

    .masthead {
      display: flex;
      flex-wrap: wrap;
      align-items: baseline;
      justify-content: space-between;
      gap: 1rem;
      border-bottom: var(--border);
      padding-bottom: 1rem;
      margin-bottom: 1.25rem;
    }

    .brand {
      font-size: clamp(2.5rem, 8vw, 4.5rem);
      font-weight: 900;
      letter-spacing: -2px;
      text-transform: uppercase;
      line-height: 0.9;
      color: var(--ink);
      text-shadow: 3px 3px 0 var(--pink);
    }

    .brand-sub {
      background: var(--ink);
      color: var(--yellow);
      padding: 0.4rem 0.8rem;
      font-size: 0.9rem;
      font-weight: bold;
      letter-spacing: 1px;
      display: inline-block;
      margin-top: 0.5rem;
    }

    .manifesto {
      font-size: 1.05rem;
      max-width: 800px;
      margin-bottom: 1.25rem;
      font-family: var(--font-sans);
      font-weight: 500;
    }

    .meta-bar {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      font-size: 0.85rem;
      font-weight: bold;
    }

    .stat-pill {
      background: var(--yellow);
      border: 2px solid var(--ink);
      padding: 0.2rem 0.6rem;
      box-shadow: 2px 2px 0 var(--ink);
    }

    /* CONTROLES / FILTROS */
    .controls-panel {
      background: var(--paper);
      border: var(--border);
      box-shadow: var(--shadow);
      padding: 1.25rem;
      margin-bottom: 2rem;
      display: flex;
      flex-wrap: wrap;
      gap: 1rem;
      align-items: center;
      justify-content: space-between;
    }

    .filter-buttons {
      display: flex;
      flex-wrap: wrap;
      gap: 0.6rem;
    }

    .filter-btn {
      background: var(--paper);
      border: 2px solid var(--ink);
      font-family: var(--font-mono);
      font-size: 0.9rem;
      font-weight: bold;
      padding: 0.45rem 0.9rem;
      cursor: pointer;
      box-shadow: 3px 3px 0 var(--ink);
      transition: all 0.1s ease;
      text-transform: uppercase;
    }

    .filter-btn:hover {
      background: var(--yellow);
      transform: translate(-1px, -1px);
      box-shadow: 4px 4px 0 var(--ink);
    }

    .filter-btn.active {
      background: var(--pink);
      color: #ffffff;
      box-shadow: 3px 3px 0 var(--ink);
    }

    .search-box {
      flex: 1;
      min-width: 260px;
      max-width: 400px;
    }

    .search-input {
      width: 100%;
      border: 2px solid var(--ink);
      background: #fafafa;
      padding: 0.55rem 0.8rem;
      font-family: var(--font-mono);
      font-size: 0.95rem;
      outline: none;
      box-shadow: inset 2px 2px 0 rgba(0,0,0,0.1);
    }

    .search-input:focus {
      border-color: var(--pink);
      background: #ffffff;
      box-shadow: 3px 3px 0 var(--pink);
    }

    /* GRID DE PROJETOS */
    .catalog-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
      gap: 1.75rem;
    }

    /* CARD INDIVIDUAL */
    .zine-card {
      background: var(--paper);
      border: var(--border);
      box-shadow: var(--shadow);
      display: flex;
      flex-direction: column;
      transition: transform 0.15s ease, box-shadow 0.15s ease;
      position: relative;
    }

    .zine-card:hover {
      transform: translate(-3px, -3px);
      box-shadow: var(--shadow-hover);
    }

    .zine-card.is-comrade {
      border-color: #000;
      background: #fffdf5;
    }

    .zine-header {
      padding: 0.75rem 1rem;
      border-bottom: 2px solid var(--ink);
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      align-items: center;
      background: #fafafa;
    }

    .badge {
      font-size: 0.75rem;
      font-weight: bold;
      padding: 0.15rem 0.45rem;
      border: 1.5px solid var(--ink);
      text-transform: uppercase;
    }

    .forge-badge {
      background: #ffffff;
    }

    .license-badge {
      background: var(--tape);
    }

    .comrade-badge {
      background: var(--yellow);
      color: var(--ink);
      border-color: var(--ink);
      font-weight: 900;
      box-shadow: 2px 2px 0 var(--ink);
    }

    /* PÔSTER OU STANDBY */
    .zine-media {
      width: 100%;
      height: 240px;
      overflow: hidden;
      border-bottom: var(--border);
      background: #000000;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
    }

    .zine-poster {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
      transition: transform 0.2s ease;
    }

    .zine-card:hover .zine-poster {
      transform: scale(1.02);
    }

    .standby-poster {
      width: 100%;
      height: 100%;
      background: 
        repeating-linear-gradient(45deg, #181818, #181818 10px, #222222 10px, #222222 20px);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 1rem;
      text-align: center;
      color: #ffffff;
    }

    .standby-stamp {
      border: 3px dashed var(--yellow);
      color: var(--yellow);
      padding: 0.4rem 1rem;
      font-size: 1.25rem;
      font-weight: 900;
      letter-spacing: 2px;
      transform: rotate(-4deg);
      margin-bottom: 0.6rem;
    }

    .standby-label {
      font-size: 0.75rem;
      color: #aaaaaa;
      letter-spacing: 1px;
    }

    /* CORPO DO CARD */
    .zine-body {
      padding: 1.25rem;
      display: flex;
      flex-direction: column;
      flex: 1;
    }

    .zine-title {
      font-size: 1.6rem;
      font-weight: 900;
      letter-spacing: -0.5px;
      margin-bottom: 0.5rem;
      line-height: 1.1;
      word-break: break-word;
    }

    .zine-desc {
      font-family: var(--font-sans);
      font-size: 0.95rem;
      color: #2b2b2b;
      margin-bottom: 1rem;
      flex: 1;
    }

    .zine-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 0.4rem;
      margin-bottom: 1.25rem;
    }

    .tag {
      font-size: 0.75rem;
      background: #f0ede6;
      border: 1px solid var(--ink);
      padding: 0.15rem 0.4rem;
      color: #333333;
    }

    .tag-empty {
      background: transparent;
      border-style: dashed;
      color: #777777;
    }

    .zine-actions {
      display: flex;
      flex-wrap: wrap;
      gap: 0.6rem;
      border-top: 1px solid #e0ded8;
      padding-top: 1rem;
    }

    .btn {
      font-family: var(--font-mono);
      font-size: 0.85rem;
      font-weight: bold;
      text-decoration: none;
      padding: 0.45rem 0.8rem;
      border: 2px solid var(--ink);
      text-align: center;
      transition: all 0.1s ease;
      display: inline-block;
    }

    .btn-primary {
      background: var(--ink);
      color: #ffffff;
      box-shadow: 2px 2px 0 var(--pink);
    }

    .btn-primary:hover {
      background: var(--pink);
      color: #ffffff;
      box-shadow: 3px 3px 0 var(--ink);
    }

    .btn-secondary {
      background: var(--yellow);
      color: var(--ink);
      box-shadow: 2px 2px 0 var(--ink);
    }

    .btn-secondary:hover {
      background: #ffffff;
      box-shadow: 3px 3px 0 var(--ink);
    }

    /* FOOTER */
    footer {
      margin-top: 4rem;
      background: var(--paper);
      border: var(--border);
      box-shadow: var(--shadow);
      padding: 2rem 1.5rem;
      text-align: center;
      transform: rotate(0.2deg);
    }

    .footer-stamp {
      display: inline-block;
      background: var(--ink);
      color: var(--pink-neon);
      font-size: 1.1rem;
      font-weight: 900;
      padding: 0.5rem 1.2rem;
      margin-bottom: 1rem;
      letter-spacing: 1px;
    }

    .footer-text {
      font-size: 0.9rem;
      margin-bottom: 0.8rem;
    }

    .trans-pride {
      display: inline-flex;
      align-items: center;
      gap: 0.4rem;
      font-weight: bold;
      color: var(--pink);
    }

    .no-results {
      grid-column: 1 / -1;
      padding: 3rem 1rem;
      text-align: center;
      background: var(--paper);
      border: var(--border);
      font-size: 1.2rem;
      font-weight: bold;
      display: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="tape-top">DISTRIBUIÇÃO INDEPENDENTE // AMOSTRA PERMANENTE</div>
      <div class="masthead">
        <div>
          <h1 class="brand">BANCA</h1>
          <div class="brand-sub">ZINES, REPOS & CÓDIGO INDEPENDENTE // LUMEN.PINK</div>
        </div>
      </div>
      <p class="manifesto">
        Vitrine de código aberto, ferramentas de terminal, utilitários de fricção, publicações e experimentações criadas e mantidas por <strong>Lumen Pink</strong>. Arquitetura soberana, anti-design e autonomia técnica na borda.
      </p>
      <div class="meta-bar">
        <span class="stat-pill" id="stat-total">__TOTAL_COUNT__ PROJETOS AUTORAIS</span>
        <span class="stat-pill" id="stat-comrades">★ __COMRADES_COUNT__ CCCP COMRADES</span>
        <span class="stat-pill">100% CÓDIGO LIVRE</span>
        <span class="stat-pill">NORMA GOST v1.1.0</span>
      </div>

      <div class="pratilera-card" style="margin-top: 1.5rem; background: #fff; border: 3px solid #000; box-shadow: 4px 4px 0 #000; padding: 1.2rem; text-align: left;">
        <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.8rem; margin-bottom: 0.6rem;">
          <div style="display: flex; align-items: center; gap: 0.6rem;">
            <span style="font-size: 1.5rem;">📲</span>
            <h2 style="margin: 0; font-size: 1.25rem; text-transform: uppercase; font-family: monospace; letter-spacing: 0.05em; color: #000;">A PRATILERA :: LOJA F-DROID &amp; DROID-IFY</h2>
          </div>
          <span style="background: #000; color: #fff; font-size: 0.75rem; padding: 0.3rem 0.6rem; font-family: monospace; font-weight: bold;">ECOSSISTEMA 2LP</span>
        </div>
        <p style="margin: 0 0 0.8rem 0; font-size: 0.92rem; line-height: 1.5; color: #222;">
          A loja soberana de aplicativos Android de todos os projetos da Banca (La Craia, Simbiótyka, Lauda...). Sem intermediário corporativo, sem vigilância e com atualizações automáticas direto no seu aparelho via <strong>Droid-ify</strong>, <strong>Neo Store</strong> ou <strong>F-Droid</strong>.
        </p>
        <div style="display: flex; gap: 0.8rem; flex-wrap: wrap; align-items: center; margin-bottom: 0.8rem;">
          <button type="button" onclick="navigator.clipboard.writeText('https://banca.2lp.in/pratilera'); const b=this; const orig=b.innerHTML; b.innerHTML='✓ COPIADO!'; setTimeout(()=>b.innerHTML=orig, 2000);" style="background: #e60050; color: #fff; border: 2px solid #000; padding: 0.6rem 1.2rem; font-weight: bold; font-family: monospace; font-size: 0.9rem; box-shadow: 2px 2px 0 #000; cursor: pointer; display: inline-flex; align-items: center; gap: 0.4rem;">
            📋 COPIAR ENDEREÇO DA PRATILERA
          </button>
          <a href="/pratilera/index-v1.json" style="background: #f0f0f0; border: 2px solid #000; color: #000; text-decoration: none; padding: 0.55rem 1rem; font-family: monospace; font-size: 0.85rem; font-weight: bold;">
            📋 ÍNDICE JSON
          </a>
          <code style="background: #eee; padding: 0.55rem 0.8rem; border: 1px dashed #000; font-size: 0.85rem; color: #000;">https://banca.2lp.in/pratilera</code>
        </div>
        <div style="background: #f9f9f9; border-left: 4px solid #e60050; padding: 0.6rem 0.8rem; font-size: 0.82rem; font-family: monospace; color: #333;">
          💡 <strong>Dica da calçada:</strong> No Droid-ify / Neo Store / F-Droid, toque em <strong>+ (Adicionar Repositório)</strong> e cole o endereço <code>https://banca.2lp.in/pratilera</code>. Digitou <em>/patilera</em> na correria ou <em>/prateleira</em> no português fino? Relaxa que nossos redirecionamentos 301 cuidam de tudo pra você cair direto na Pratilera!
        </div>
      </div>
    </header>

    <section class="controls-panel">
      <div class="filter-buttons">
        <button class="filter-btn active" data-filter="all">★ Todos os Zines</button>
        <button class="filter-btn" data-filter="comrades">⚡ CCCP Comrades</button>
        <button class="filter-btn" data-filter="has-banner">✂ Com Cartaz</button>
      </div>
      <div class="search-box">
        <input type="text" id="search-input" class="search-input" placeholder="🔍 Filtrar projetos, tópicos, tags..." autocomplete="off">
      </div>
    </section>

    <main class="catalog-grid" id="catalog-grid">
EOF

# Injeta os cards gerados
echo "$PROJECTS_HTML" >> "$OUTPUT_HTML"

cat << 'EOF' >> "$OUTPUT_HTML"
      <div class="no-results" id="no-results">
        [ NENHUM PROJETO ENCONTRADO PARA ESTA BUSCA ]
      </div>
    </main>

    <footer>
      <div class="footer-stamp">BANCA // DISTRIBUIDORA INDEPENDENTE</div>
      <p class="footer-text">
        Projetos mantidos no Codeberg, GitHub e TildeGit. Pôsteres e cartazes gerados via <strong>Navalha</strong>.
      </p>
      <p class="trans-pride">
        <span>🏳️‍⚧️</span> Desenvolvido com carinho, estética de alta fricção e código soberano pela travesti latina Lumen Pink.
      </p>
    </footer>
  </div>

  <script>
    // Filtros e busca reativa no cliente (100% Vanilla JS)
    const cards = Array.from(document.querySelectorAll('.zine-card'));
    const buttons = document.querySelectorAll('.filter-btn');
    const searchInput = document.getElementById('search-input');
    const noResults = document.getElementById('no-results');

    let activeFilter = 'all';
    let searchQuery = '';

    function updateView() {
      let visibleCount = 0;

      cards.forEach(card => {
        const name = card.dataset.name || '';
        const group = card.dataset.group || '';
        const topics = card.dataset.topics || '';
        const hasBanner = card.dataset.hasBanner === 'true';

        // Filtro de Categoria
        let matchFilter = true;
        if (activeFilter === 'comrades') {
          matchFilter = (group === 'comrades');
        } else if (activeFilter === 'has-banner') {
          matchFilter = hasBanner;
        }

        // Filtro de Busca
        let matchSearch = true;
        if (searchQuery.trim() !== '') {
          const q = searchQuery.toLowerCase().trim();
          matchSearch = name.includes(q) || topics.includes(q);
        }

        if (matchFilter && matchSearch) {
          card.style.display = 'flex';
          visibleCount++;
        } else {
          card.style.display = 'none';
        }
      });

      if (noResults) {
        noResults.style.display = (visibleCount === 0) ? 'block' : 'none';
      }
    }

    buttons.forEach(btn => {
      btn.addEventListener('click', () => {
        buttons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        activeFilter = btn.dataset.filter;
        updateView();
      });
    });

    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        searchQuery = e.target.value;
        updateView();
      });
    }
  </script>
</body>
</html>
EOF

sed -i "s/__TOTAL_COUNT__/$COUNT/g; s/__COMRADES_COUNT__/$COMRADES_COUNT/g" "$OUTPUT_HTML"

echo "✔ [BANCA] Site estático gerado com sucesso em '$OUTPUT_HTML' ($COUNT projetos)!"
