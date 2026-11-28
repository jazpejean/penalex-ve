// Penalex VE — Sección /leyes (web). Réplica de la estructura visual de la
// app Flutter (RepositorioLeyesScreen + LeyEstructuraScreen + _ArticuloSheet):
// mismo header azul marino con buscador, mismas cards con icono 📖, mismo
// árbol jerárquico colapsable Libro→Título→Capítulo→Sección con badges
// dorados y mismos items de artículo. El SEO (titles, JSON-LD Legislation,
// canonical, sitemap) se mantiene intacto sobre esta base.
//
// Tres tipos de página:
//   1. GET /leyes  y  /leyes/         → SPA índice (noindex): busca leyes Y
//      artículos sobre un índice plano (R2 leyes/indice.json, equivalente al
//      penalex_indice_leyes_v3.json de la app). Sin consulta → lista de leyes.
//   2. GET /leyes/{slug}              → página de ley indexable: header con
//      gradiente + badge "N artículos" + buscador interno + árbol jerárquico.
//   3. GET /leyes/{slug}/articulos/{id} → página de artículo indexable:
//      badge dorado "Artículo N", texto completo, numerales, parágrafos,
//      estado, breadcrumb y JSON-LD Legislation.
//   4. GET /leyes/indice.json         → el índice plano (para la SPA).
//
// Las leyes viven en R2 (penalex-ve-v2/leyes/{slug}.json, sincronizadas por
// penalex-web/scripts/sincronizar_leyes.mjs desde Supabase Storage).
//
// Env: R2_JURISPRUDENCIA, SUPABASE_URL (fallback), SITIO_JURISPRUDENCIA.

const cacheLeyes = new Map(); // slug -> {ley, at}
const TTL_LEY = 60 * 60 * 1000; // 1 h
const TTL_MANIFEST = 60 * 60 * 1000;

let manifestCache = null;

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function recortar(texto, max) {
  const limpio = String(texto || '').replace(/\s+/g, ' ').trim();
  if (limpio.length <= max) return limpio;
  const corte = limpio.slice(0, max);
  const esp = corte.lastIndexOf(' ');
  return `${corte.slice(0, esp > 0 ? esp : max).trim()}…`;
}

/** "CÓDIGO ORGÁNICO PROCESAL PENAL" → "Código Orgánico Procesal Penal". */
function tituloLey(nombre) {
  const texto = String(nombre || '').trim();
  const minusculas = new Set(['de', 'del', 'la', 'las', 'el', 'los', 'y', 'o', 'a', 'al', 'para', 'por', 'sobre', 'en', 'contra', 'con']);
  return texto
    .toLowerCase()
    .split(/\s+/)
    .map((w, i) => {
      const limpia = w.replace(/[^a-záéíóúñü0-9]/g, '');
      if (i > 0 && minusculas.has(limpia)) return w;
      return w.charAt(0).toUpperCase() + w.slice(1);
    })
    .join(' ');
}

// Abreviaturas y alias de búsqueda de las leyes más citadas. La gente busca
// "artículo 100 del COPP", "art 347 código penal", "ley cicpc", "lopnna"…
const ALIASES = {
  copp: { abrev: 'COPP', alias: ['copp', 'código procesal penal', 'procesal penal'] },
  'codigo-penal': { abrev: 'Código Penal', alias: ['código penal', 'cp', 'ley penal'] },
  crbv: { abrev: 'Constitución', alias: ['constitución', 'crbv', 'constitución bolivariana', 'constitución 1999'] },
  'ley-de-violencia': { abrev: 'Ley de Violencia', alias: ['violencia', 'violencia de género', 'mujeres', 'lodmvlv', 'ley orgánica de la mujer'] },
  'ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes': { abrev: 'LOPNNA', alias: ['lopnna', 'niños', 'niñas', 'adolescentes'] },
  'ley-organica-de-drogas': { abrev: 'Ley de Drogas', alias: ['drogas', 'estupefacientes', 'psicotrópicos'] },
  'codigo-organico-penitenciario': { abrev: 'Código Penitenciario', alias: ['penitenciario', 'prisión', 'cárcel', 'cop'] },
  'ley-organica-de-extinsion-de-dominio': { abrev: 'Ley de Extinción de Dominio', alias: ['extinción de dominio', 'bienes', 'decomiso'] },
  'ley-organica-de-amparo-a-la-libertad': { abrev: 'Ley de Amparo a la Libertad', alias: ['amparo', 'hábeas corpus', 'libertad personal'] },
  'ley-organica-del-servicio-de-policia-de-investigacion-el-cuerpo-de-investigaciones-cientificas-penales-y-criminalisticas-y-el-servicio-nacional-de-medicina-y-ciencias-forenses': { abrev: 'Ley del CICPC', alias: ['cicpc', 'policía de investigación', 'investigación penal', 'forense'] },
  'ley-del-estatuto-de-la-funcion-de-la-policia-de-investigacion': { abrev: 'Estatuto Policía de Investigación', alias: ['policía de investigación', 'cicpc estatuto'] },
  'ley-organica-del-ministerio-publico': { abrev: 'Ley del Ministerio Público', alias: ['ministerio público', 'fiscal', 'fiscalía'] },
  'ley-organica-de-la-defensa-publica': { abrev: 'Ley de la Defensa Pública', alias: ['defensa pública', 'defensor público'] },
  'ley-sobre-el-delito-de-contrabando': { abrev: 'Ley de Contrabando', alias: ['contrabando', 'delito de contrabando'] },
  'ley-penal-del-ambiente': { abrev: 'Ley Penal del Ambiente', alias: ['ambiente', 'delitos ambientales', 'ecología'] },
  'ley-especial-contra-los-delitos-informaticos': { abrev: 'Ley de Delitos Informáticos', alias: ['delitos informáticos', 'informática', 'ciberdelitos', 'internet'] },
  'ley-contra-el-secuestro-y-la-extorsion': { abrev: 'Ley de Secuestro y Extorsión', alias: ['secuestro', 'extorsión', 'plagio'] },
  'ley-para-el-desarme-y-control-de-armas-y-municiones': { abrev: 'Ley de Desarme', alias: ['desarme', 'armas', 'municiones', 'porte de armas'] },
  'ley-organica-contra-la-delincuencia-organizada-y-financiamiento-al-terrorismo': { abrev: 'Ley de Delincuencia Organizada', alias: ['delincuencia organizada', 'terrorismo', 'crimen organizado'] },
  'ley-de-registro-de-antecedentes-penales': { abrev: 'Ley de Antecedentes Penales', alias: ['antecedentes penales', 'certificado de antecedentes'] },
  'ley-para-la-prevencion-y-erradicacion-del-abuso-sexual-contra-ninas-ninos-y-adolescentes': { abrev: 'Ley de Abuso Sexual NNA', alias: ['abuso sexual', 'niños', 'niñas', 'adolescentes'] },
};

// Año de vigencia de la versión cuya NUMERACIÓN coincide con la actual de
// cada ley (verificado contra fuentes: COPP 2012 Gaceta 6.078 renumeró y su
// numeración persiste en la reforma parcial 2021; CP 2005 Gaceta 5.768;
// CRBV 1999; LOPNNA 2015; Ley de Violencia 2021 — confirmados por usuario).
const ANIO_VIGENCIA = {
  copp: 2012,
  'codigo-penal': 2005,
  crbv: 1999,
  'ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes': 2015,
  'ley-de-violencia': 2021,
};

// Artículos del COPP CUYO CONTENIDO cambió en la reforma de 2021 (GORBV
// 6.644 Ext. del 17-09-2021), según el cuadro "antes y después" aportado
// por el usuario. Para estos, solo valen sentencias de 2021 en adelante
// (las anteriores citan el texto de la versión 2012). El resto de
// artículos mantiene la numeración y contenido desde 2012.
const COPP_REFORMADOS_2021 = new Set([
  '30', '69', '122', '124', '126', '126-a', '175', '230', '237', '267',
  '295', '309', '318', '320', '325', '430', '473', '516', '517',
]);

function aliasDe(slug) {
  return ALIASES[slug] || null;
}

/** Slug de un identificador de artículo: "100" → "100"; "Preámbulo" → "preambulo". */
function slugArticulo(id) {
  const t = String(id || '').trim();
  if (/^\d+$/.test(t)) return t.replace(/^0+/, '') || '0';
  return t
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Rubro temático de un artículo SIN inventar texto: usa el encabezado real si
 * existe; si no, deriva del título de la sección/capítulo/título/libro donde
 * vive el artículo en el propio documento (materia real de la norma).
 * Limpia prefijos de nivel ("TÍTULO II." / "CAPÍTULO I." / "SECCIÓN 1ª" /
 * "LIBRO PRIMERO.") y recorta frases largas en un límite de palabra.
 */
const REG_PREFIJO_NIVEL = /^(?:T[IÍ]TULO|CAP[IÍ]TULO|SECCI[OÓ]N|LIBRO)\b[^:.]*[.:—–-]\s*/i;
const MAX_RUBRO = 64;

/** "DISPOSICIONES TRANSITORIAS" → "Disposiciones transitorias" (solo si el
 *  título está en mayúsculas completas, respetando siglas conocidas). */
function normalizarCaps(t) {
  if (t !== t.toUpperCase()) return t;
  return t
    .toLowerCase()
    .split(/\s+/)
    .map((w) => (w === w.toUpperCase() && w.length <= 4 ? w : w.charAt(0).toUpperCase() + w.slice(1)))
    .join(' ');
}

function rubroDe(art, bloque) {
  const propio = String(art?.encabezado || '').trim();
  if (propio) return propio;

  const b = bloque || {};
  // Orden de especificidad: sección > capítulo > título > libro.
  const candidatos = [b.seccion, b.capitulo, b.titulo, b.libro];
  for (const raw of candidatos) {
    if (!raw) continue;
    let t = String(raw).trim().replace(/\s+/g, ' ');
    t = t.replace(REG_PREFIJO_NIVEL, '').trim();
    if (!t) continue;
    // Primer corte en punto/coma cuando la frase continúa con detalles
    // ("…, de su competencia y de la jurisdicción, y de los deberes…").
    const corte = t.search(/[.,](?=\s)/);
    if (corte > 12) t = t.slice(0, corte).trim();
    t = normalizarCaps(t);
    t = t.charAt(0).toUpperCase() + t.slice(1);
    if (t.length > MAX_RUBRO) {
      const cortePalabra = t.lastIndexOf(' ', MAX_RUBRO);
      t = (cortePalabra > 24 ? t.slice(0, cortePalabra) : t.slice(0, MAX_RUBRO)).trim() + '…';
    }
    return t;
  }
  return '';
}

// ── Carga de datos ──────────────────────────────────────────────────────────

async function cargarManifest(env) {
  if (manifestCache && Date.now() - manifestCache.at < TTL_MANIFEST) return manifestCache.datos;
  const obj = await env.R2_JURISPRUDENCIA.get('leyes/manifest.json');
  if (!obj) return null;
  const datos = JSON.parse(await obj.text());
  manifestCache = { datos, at: Date.now() };
  return datos;
}

async function cargarLey(env, slug) {
  const cacheado = cacheLeyes.get(slug);
  if (cacheado && Date.now() - cacheado.at < TTL_LEY) return cacheado.ley;

  let texto = null;
  const obj = await env.R2_JURISPRUDENCIA.get(`leyes/${slug}.json`);
  if (obj) {
    texto = await obj.text();
  } else {
    // Fallback: storage público de Supabase (bucket público "leyes").
    const base = (env.SUPABASE_URL || '').replace(/\/+$/, '');
    if (base) {
      const res = await fetch(`${base}/storage/v1/object/public/leyes/${slug}.json`);
      if (res.ok) texto = await res.text();
    }
  }
  if (!texto) return null;
  try {
    const ley = JSON.parse(texto);
    cacheLeyes.set(slug, { ley, at: Date.now() });
    return ley;
  } catch {
    return null;
  }
}

async function cargarIndice(env) {
  const obj = await env.R2_JURISPRUDENCIA.get('leyes/indice.json');
  if (!obj) return null;
  return JSON.parse(await obj.text());
}

/** Aplana la estructura de una ley en una lista de {bloque, articulo, slug}. */
function aplanar(ley) {
  const planos = [];
  for (const bloque of ley.estructura || []) {
    for (const art of bloque.articulos || []) {
      planos.push({ bloque, articulo: art, slug: slugArticulo(art.identificador) });
    }
  }
  return planos;
}

/** Es un artículo real (excluye Preámbulo y Disposiciones Derogatorias,
 *  Transitorias y Finales): tipo_norma "Artículo" o identificador numérico. */
function esArticuloReal(art) {
  const tipo = String(art?.tipo_norma || '').trim().toLowerCase();
  if (tipo && tipo !== 'artículo' && tipo !== 'articulo') return false;
  if (/^\d+$/.test(String(art?.identificador || '').trim())) return true;
  return tipo === 'artículo' || tipo === 'articulo';
}

/** Cuenta SOLO los artículos reales de una ley (sin preámbulos ni
 *  disposiciones). No confiar en el manifest: se recalcula de la estructura. */
function contarArticulos(ley) {
  let n = 0;
  for (const bloque of ley.estructura || []) {
    for (const art of bloque.articulos || []) {
      if (esArticuloReal(art)) n++;
    }
  }
  return n;
}

/** Construye slugs únicos (si hay colisiones añade -2, -3…). */
function slugsUnicos(planos) {
  const usados = new Map();
  for (const p of planos) {
    let slug = p.slug;
    const n = usados.get(slug) || 0;
    usados.set(slug, n + 1);
    if (n > 0) slug = `${slug}-${n + 1}`;
    p.slugFinal = slug;
  }
  return planos;
}

// ── CSS (paleta y formas de la app: azul marino #0F172A + dorado #C5A059) ──

const ESTILO = `
:root { --azul:#0F172A; --dorado:#C5A059; --fondo:#F1F5F9; --texto:#0F172A; --texto2:#475569; --texto-tenue:#94A3B8; --borde:#E2E8F0; --tarjeta:#ffffff; --campo:#F1F5F9; --capa:#E2E8F0; }
* { box-sizing:border-box; margin:0; padding:0; }
body { font-family:system-ui,-apple-system,'Segoe UI',Roboto,sans-serif; background:var(--fondo); color:var(--texto); }
a { text-decoration:none; color:inherit; }
header { position:sticky; top:0; z-index:40; border-bottom:1px solid var(--borde); background:rgba(255,255,255,.95); backdrop-filter:blur(8px); }
.hdr-in { max-width:1100px; margin:0 auto; display:flex; align-items:center; justify-content:space-between; gap:12px; padding:8px 16px; }
.logo-img { height:44px; width:auto; object-fit:contain; }
.hdr-nav { display:none; align-items:center; gap:4px; }
.hdr-nav a { border-radius:8px; padding:8px 12px; font-size:14px; font-weight:500; color:var(--texto2); }
.hdr-nav a:hover { background:var(--fondo); color:var(--azul); }
.hdr-acciones { display:none; align-items:center; gap:8px; }
.hdr-link { border:1px solid var(--borde); border-radius:8px; padding:8px 14px; font-size:13px; font-weight:500; color:var(--texto2); }
.hdr-link:hover { background:var(--fondo); color:var(--azul); }
.hdr-btn { background:var(--azul); border-radius:8px; padding:8px 14px; font-size:13px; font-weight:600; color:#fff; }
.hdr-btn:hover { background:var(--azul-hover, #06305f); }
.hdr-burger { display:inline-flex; align-items:center; justify-content:center; width:40px; height:40px; border:none; border-radius:8px; background:transparent; color:var(--azul); cursor:pointer; }
.hdr-burger svg { width:24px; height:24px; }
.hdr-menu { display:none; flex-direction:column; gap:2px; padding:6px 16px 14px; border-top:1px solid var(--borde); background:#fff; }
.hdr-menu.open { display:flex; }
.hdr-menu a { border-radius:8px; padding:12px; font-size:14px; font-weight:500; color:#334155; }
.hdr-menu a:hover { background:var(--fondo); color:var(--azul); }
.hdr-menu .hdr-link, .hdr-menu .hdr-btn { text-align:center; margin-top:4px; }
@media (min-width: 768px) {
  .hdr-nav { display:flex; }
  .hdr-acciones { display:flex; }
  .hdr-burger { display:none; }
  .hdr-menu { display:none !important; }
}
main { max-width:860px; margin:0 auto; padding:0 0 80px; }
/* Cabecera azul marino con buscador (RepositorioLeyesScreen) */
.busqueda-header { background:var(--azul); padding:20px 16px; box-shadow:0 2px 8px rgba(0,0,0,.15); }
.busqueda-header h1 { color:#fff; font-size:20px; font-weight:800; margin-bottom:4px; }
.busqueda-header .sub { color:rgba(255,255,255,.6); font-size:12px; margin-bottom:14px; }
.barra input { flex:1; padding:14px 16px; font-size:15px; border:1px solid transparent; border-radius:12px; background:rgba(255,255,255,.12); outline:none; color:#fff; }
.barra input::placeholder { color:rgba(255,255,255,.48); }
.barra input:focus { border-color:var(--dorado); background:rgba(255,255,255,.16); }
.barra { display:flex; gap:8px; }
.hint { margin-top:8px; display:flex; align-items:center; gap:5px; color:rgba(255,255,255,.48); font-size:12px; }
.hint svg { width:12px; height:12px; fill:rgba(197,160,89,.48); }
/* Lista de leyes */
.ley-lista { padding:16px; display:grid; grid-template-columns:1fr; gap:12px; }
.ley-card { background:var(--tarjeta); border:1px solid rgba(15,23,42,.45); border-radius:14px; box-shadow:0 1px 3px rgba(15,23,42,.08); display:flex; align-items:center; gap:12px; padding:14px; transition:border-color .15s; }
.ley-card:hover { border-color:var(--dorado); }
.ley-icono { width:44px; height:44px; flex:0 0 44px; border-radius:11px; background:var(--azul); display:flex; align-items:center; justify-content:center; }
.ley-icono svg { width:22px; height:22px; fill:var(--dorado); }
.ley-card .info { flex:1; min-width:0; }
.ley-card .nombre { font-weight:700; font-size:14px; color:var(--texto); line-height:1.3; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.ley-card .meta { margin-top:4px; font-size:12px; color:var(--texto2); }
.ley-card .chev { color:var(--azul); flex:0 0 auto; }
/* Resultados de búsqueda (cards de artículo) */
.resultados { padding:16px; display:grid; gap:12px; }
.resultado-card { background:var(--tarjeta); border-radius:12px; box-shadow:0 1px 3px rgba(15,23,42,.08); padding:16px; display:block; }
.resultado-card .fila1 { display:flex; align-items:center; gap:8px; }
.resultado-card .badge-ley { background:var(--azul); color:var(--dorado); font-size:10px; font-weight:700; padding:4px 8px; border-radius:6px; max-width:38%; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.resultado-card .titulo-corto { font-weight:700; font-size:15px; color:var(--texto); flex:1; }
.resultado-card .encabezado { color:var(--texto2); font-size:12px; text-align:right; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; max-width:40%; }
.resultado-card .extracto { margin-top:8px; font-size:13px; line-height:1.4; color:var(--texto); display:-webkit-box; -webkit-line-clamp:3; -webkit-box-orient:vertical; overflow:hidden; }
.resultado-card .ver { margin-top:8px; text-align:right; font-size:12px; font-weight:600; color:var(--texto); }
.estado { padding:8px 16px 0; font-size:13px; color:var(--texto2); min-height:20px; }
.vacio { text-align:center; padding:48px 16px; color:var(--texto2); }
.vacio .icono { width:80px; height:80px; margin:0 auto 24px; opacity:.18; }
.vacio h3 { font-size:20px; font-weight:700; color:rgba(15,23,42,.48); }
.vacio p { margin-top:12px; font-size:14px; color:rgba(15,23,42,.48); }
.spinner { display:inline-block; width:26px; height:26px; border:3px solid rgba(15,23,42,.2); border-top-color:var(--azul); border-radius:50%; animation:girar .8s linear infinite; }
@keyframes girar { to { transform:rotate(360deg); } }
/* Header de ley (LeyEstructuraScreen): azul marino sólido, SIN degradado —
   la app en su modo por defecto (oscuro) no muestra degradado a blanco. */
.ley-header { background:var(--azul); border-bottom:1px solid rgba(197,160,89,.24); padding:16px; }
.ley-header .fila1 { display:flex; align-items:center; gap:12px; }
.badge-art { background:var(--dorado); color:var(--azul); font-weight:700; font-size:12px; padding:6px 12px; border-radius:20px; white-space:nowrap; }
.ley-header .hint2 { color:rgba(255,255,255,.48); font-size:12px; flex:1; }
/* Input del filtro: campo gris claro con texto navy, como el TextField de
   LeyEstructuraScreen en modo claro (TemaGlobal.campoTexto #F1F5F9). */
.ley-header input { width:100%; margin-top:12px; padding:10px 14px; font-size:14px; border:none; border-radius:10px; background:#F1F5F9; outline:none; color:#0F172A; }
.ley-header input::placeholder { color:#9CA3AF; }
.ley-header input:focus { box-shadow:0 0 0 1.5px var(--dorado); }
/* Árbol jerárquico */
.arbol { padding:4px 12px 24px; }
.nodo { margin:4px 0; border-radius:12px; }
.nodo.n0 { background:var(--tarjeta); border:1px solid rgba(15,23,42,.24); }
.nodo.n1, .nodo.n2, .nodo.n3 { background:rgba(255,255,255,.48); border:1px solid rgba(15,23,42,.12); margin-left:8px; }
details > summary { list-style:none; display:flex; align-items:center; gap:8px; padding:10px 12px; cursor:pointer; user-select:none; }
details > summary::-webkit-details-marker { display:none; }
details > summary .tri { width:8px; height:8px; border-right:2px solid var(--texto2); border-bottom:2px solid var(--texto2); transform:rotate(-45deg); transition:transform .15s; flex:0 0 auto; }
details[open] > summary .tri { transform:rotate(45deg); }
.nodo.n0 > summary .etiqueta { color:var(--dorado); font-weight:700; font-size:15px; flex:1; }
.nodo.n1 > summary .etiqueta, .nodo.n2 > summary .etiqueta, .nodo.n3 > summary .etiqueta { color:var(--texto); font-weight:600; font-size:14px; flex:1; }
.rango { background:rgba(15,23,42,.12); color:var(--azul); font-size:11px; font-weight:600; padding:3px 8px; border-radius:10px; white-space:nowrap; }
.nodo .hijos { padding:0 0 8px; }
/* Item de artículo (en el árbol y en filtros) */
.art-item { display:flex; align-items:flex-start; gap:12px; background:var(--tarjeta); border:1px solid var(--capa); border-radius:10px; margin:5px 12px; padding:12px; }
.art-item .badge { background:var(--dorado); color:var(--azul); font-weight:700; font-size:12px; padding:4px 8px; border-radius:6px; white-space:nowrap; flex:0 0 auto; }
.art-item .contenido { flex:1; min-width:0; }
.art-item .enc { font-weight:700; font-size:13px; color:var(--texto); }
.art-item .txt { margin-top:4px; font-size:13px; line-height:1.4; color:var(--texto2); display:-webkit-box; -webkit-line-clamp:3; -webkit-box-orient:vertical; overflow:hidden; }
.art-item .chev { color:var(--azul); flex:0 0 auto; align-self:center; }
.art-item .path { color:var(--texto2); font-size:11px; margin-top:4px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
/* Página de artículo (estilo bottom sheet de la app) */
.migas { padding:14px 16px 0; font-size:12.5px; color:var(--texto-tenue); }
.migas a { color:var(--azul); }
.articulo { background:var(--tarjeta); border-radius:14px; margin:12px 16px; padding:20px; }
.articulo .fila1 { display:flex; align-items:center; gap:10px; margin-bottom:14px; }
.articulo .badge { background:var(--dorado); color:var(--azul); font-weight:700; font-size:14px; padding:5px 10px; border-radius:8px; white-space:nowrap; }
.articulo .ley-nombre { color:var(--texto2); font-size:13px; flex:1; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.articulo h1 { font-size:17px; font-weight:700; line-height:1.3; color:var(--texto); }
.articulo .cuerpo { margin-top:12px; font-size:15px; line-height:1.7; color:var(--texto); text-align:justify; white-space:pre-line; }
.articulo .subtitulo { margin-top:16px; font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.5px; color:var(--texto2); }
.articulo .numeral, .articulo .parrafo { margin-top:8px; font-size:14px; line-height:1.5; color:var(--texto2); }
.articulo .estado-note { margin-top:12px; color:#B45309; font-weight:700; font-size:13px; }
.articulo .nota { margin-top:14px; padding:10px 14px; background:#fffbeb; border:1px solid #fde68a; border-radius:8px; font-size:13px; line-height:1.6; color:#78350f; }
.nav-art { margin:14px 16px 0; display:flex; justify-content:space-between; gap:10px; }
.nav-art a { padding:9px 14px; font-size:12.5px; border:1px solid var(--borde); border-radius:10px; background:#fff; color:var(--azul); font-weight:600; }
.nav-art a:hover { border-color:var(--azul); }
.sent-rel { margin:20px 16px 0; padding:14px 16px; background:var(--tarjeta); border:1px solid var(--borde); border-radius:12px; }
.sent-rel h2 { font-size:12px; font-weight:800; text-transform:uppercase; letter-spacing:.5px; color:var(--texto2); margin-bottom:8px; }
.sent-rel ul { list-style:none; margin:0; padding:0; }
.sent-rel li { padding:5px 0; border-bottom:1px solid var(--borde); font-size:13px; }
.sent-rel li:last-child { border-bottom:none; }
.sent-rel a { color:var(--azul); font-weight:600; }
.sent-rel a:hover { color:var(--dorado-osc); }
footer { margin-top:44px; text-align:center; font-size:12px; color:#94a3b8; }
`;

const ICONO_LIBRO = `<svg viewBox="0 0 24 24"><path d="M4 6h5a3 3 0 0 1 3 3v10a2 2 0 0 0-2-2H4V6zm16 0h-5a3 3 0 0 0-3 3v10a2 2 0 0 1 2-2h6V6z"/></svg>`;
const ICONO_BUSCAR = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>`;
const ICONO_CHEVRON = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" width="18" height="18"><path d="m9 6 6 6-6 6"/></svg>`;
const ICONO_AWESOME = `<svg viewBox="0 0 24 24"><path d="M12 2l1.6 5.4L19 9l-5.4 1.6L12 16l-1.6-5.4L5 9l5.4-1.6L12 2zM19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8L19 15z"/></svg>`;
const ICONO_VACIO = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3M8.5 11h5"/></svg>`;

// ── Sentencias relacionadas (cita literal + ley correcta + vigencia) ────────

const MESES_REL = { enero: 1, febrero: 2, marzo: 3, abril: 4, mayo: 5, junio: 6, julio: 7, agosto: 8, septiembre: 9, octubre: 10, noviembre: 11, diciembre: 12 };
function parsearFechaRel(txt) {
  const m = String(txt || '').match(/(\d{1,2}) de ([a-záéíóú]+) de (\d{4})/i);
  if (!m) return 0;
  return Number(m[3]) * 10000 + (MESES_REL[String(m[2]).toLowerCase()] || 0) * 100 + Number(m[1]);
}

function nombreSalaRel(cod) {
  const map = {
    scp: 'Sala de Casación Penal', scon: 'Sala Constitucional',
    scs: 'Sala de Casación Social', sca: 'Sala de Casación Administrativa',
    scc: 'Sala de Casación Civil', se: 'Sala Electoral',
  };
  return map[cod] || 'Tribunal Supremo de Justicia';
}

function numeroSentenciaRel(s) {
  const n = String(s.num_sentencia || '').trim();
  const d = Number(n.slice(0, 2));
  const m = Number(n.slice(2, 4));
  if (/^\d{6}$/.test(n) && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
    const key = s.r2_html_key || '';
    const primer = key.split('/').pop().split('-')[0];
    if (/^\d+$/.test(primer)) return primer;
  }
  return n || '';
}

/**
 * Busca sentencias que CITAN "artículo N de la Ley X" en su ratio/decision,
 * con el nombre de la ley en la MISMA FRASE (ventana corta) y del año de la
 * versión vigente en adelante. Es una relación literal y verificable.
 * Devuelve hasta 5 ids ordenados por recencia real.
 */
async function sentenciasPorCita(env, art, nombreLey, slug) {
  const num = String(art?.identificador || '').trim().replace(/^0+/, '');
  if (!/^\d+$/.test(num)) return [];
  const urlBase = (env.SUPABASE_URL || '').replace(/\/+$/, '');
  const anon = env.SUPABASE_ANON_KEY || '';
  if (!urlBase || !anon) return [];
  // Umbral de año según versión: si el artículo del COPP fue reformado en
  // 2021 (contenido nuevo), solo valen sentencias de 2021+; si no, vale la
  // vigencia base de la numeración (COPP 2012, CP 2005, etc.).
  let anioMin = ANIO_VIGENCIA[slug] || 0;
  if (slug === 'copp' && COPP_REFORMADOS_2021.has(String(art?.identificador || '').trim().toLowerCase())) {
    anioMin = 2021;
  }

  // Núcleos del nombre de la ley (normalizados a minúsculas) + variantes.
  const leyNucleo = String(nombreLey || '').replace(/[«»]/g, '').replace(/\s{2,}/g, ' ').trim();
  const nucleos = [leyNucleo, leyNucleo.replace(/^(Ley|Decreto|Código)\s+/i, '')]
    .filter((n) => n && n.length >= 10)
    .map((n) => n.toLowerCase());
  const variantes = {
    'código orgánico procesal penal': ['copp', 'ley adjetiva penal', 'código procesal penal'],
    'código penal': ['cp'],
    'código orgánico para la protección de niños, niñas y adolescentes': ['lopnna'],
    'ley orgánica sobre el derecho de las mujeres a una vida libre de violencia': ['ley de violencia', 'ley sobre el derecho de las mujeres'],
  };
  for (const v of variantes[leyNucleo.toLowerCase()] || []) nucleos.push(v);
  if (!nucleos.length) return [];

  const cols = 'id,sala,num_sentencia,fecha,anio,extracto,ratio_decidendi,decision,procedimiento,r2_html_key';
  const cab = { apikey: anon, Authorization: 'Bearer ' + anon };
  const vistos = new Set();
  const resultados = [];
  const numP = `artículo ${num}`;
  const VENTANA = 90;

  const fetchCol = async (col) => {
    const fp = new URLSearchParams();
    fp.set('select', cols);
    fp.set('es_mero_tramite', 'eq.false');
    if (anioMin) fp.set('anio', 'gte.' + anioMin);
    fp.set(col, 'ilike.*' + numP + '*');
    fp.set('order', 'anio.desc');
    fp.set('limit', '40');
    const res = await fetch(`${urlBase}/rest/v1/sentencias?${fp.toString()}`, { headers: cab });
    if (!res.ok) return;
    const filas = await res.json();
    for (const f of filas) {
      if (vistos.has(f.id)) continue;
      const texto = ' ' + ((f.ratio_decidendi || '') + ' ' + (f.decision || '')).toLowerCase() + ' ';
      // La ley de ESTE artículo debe estar en la ventana de "artículo N".
      let ok = false;
      let from = 0;
      while (true) {
        const idx = texto.indexOf(numP, from);
        if (idx < 0) break;
        if (nucleos.some((n) => texto.slice(idx, idx + VENTANA).includes(n))) { ok = true; break; }
        from = idx + 1;
      }
      if (!ok) continue;
      vistos.add(f.id);
      resultados.push(f);
    }
  };

  try { await fetchCol('ratio_decidendi'); } catch { /* noop */ }
  if (resultados.length < 5) { try { await fetchCol('decision'); } catch { /* noop */ } }
  resultados.sort((a, b) => parsearFechaRel(b.fecha) - parsearFechaRel(a.fecha));
  return resultados.slice(0, 5).map((s) => ({ id: s.id }));
}

/** Renderiza la lista COMPACTA de sentencias relacionadas (1 línea c/u). */
async function htmlSentenciasRelacionadas(env, ids) {
  if (!ids.length) return '';
  const urlBase = (env.SUPABASE_URL || '').replace(/\/+$/, '');
  const anon = env.SUPABASE_ANON_KEY || '';
  if (!urlBase || !anon) return '';
  try {
    const res = await fetch(
      `${urlBase}/rest/v1/sentencias?select=id,sala,num_sentencia,fecha,procedimiento,r2_html_key&id=in.(${ids.map((x) => x.id).join(',')})`,
      { headers: { apikey: anon, Authorization: 'Bearer ' + anon } }
    );
    if (!res.ok) return '';
    const filas = await res.json();
    const items = filas.map((s) => {
      const key = s.r2_html_key || '';
      const ruta = `/sentencias/${key.replace(/^html\//, '').replace(/\.html$/i, '')}.html`;
      const num = numeroSentenciaRel(s);
      const titulo = num ? `N° ${num}` : 'Sentencia';
      const sala = nombreSalaRel(s.sala);
      const fecha = s.fecha || '';
      return `<li class="sr-item"><a href="${esc(ruta)}">${esc(titulo)} · ${esc(sala)}${fecha ? ' · ' + esc(fecha) : ''}</a></li>`;
    }).join('');
    if (!items) return '';
    return `<section class="sent-rel"><h2>Sentencias relacionadas</h2><ul>${items}</ul></section>`;
  } catch (e) {
    console.error('htmlSentenciasRelacionadas falló:', e.message);
    return '';
  }
}

function pieSitio() {
  return `<footer>Leyes y códigos de Venezuela · Penalex VE</footer>`;
}

function headerComun() {
  return `<header class="hdr">
  <div class="hdr-in">
    <a href="/" class="hdr-logo">
      <img src="/producto/logo-horizontal.png" alt="Penalex VE" class="logo-img"/>
    </a>
    <nav class="hdr-nav" aria-label="Menú principal">
      <a href="/sentencias">Jurisprudencias</a>
      <a href="/leyes">Leyes</a>
      <a href="/articulos">Blog · Nulidad Absoluta</a>
    </nav>
    <div class="hdr-acciones">
      <a class="hdr-link" href="/sentencias">Sentencias</a>
      <a class="hdr-btn" href="/dosimetria">Dosimetría</a>
    </div>
    <button class="hdr-burger" aria-label="Abrir menú" aria-expanded="false">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
    </button>
  </div>
  <nav class="hdr-menu" id="hdrMenu" aria-label="Menú móvil">
    <a href="/sentencias">Jurisprudencias</a>
    <a href="/leyes">Leyes</a>
    <a href="/articulos">Blog · Nulidad Absoluta</a>
    <a class="hdr-link" href="/sentencias">Sentencias</a>
    <a class="hdr-btn" href="/dosimetria">Dosimetría</a>
  </nav>
</header>`;
}

// ── Head SEO ────────────────────────────────────────────────────────────────

function buildHead({ titulo, descripcion, url, jsonLd }) {
  return `
<meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
<title>${esc(titulo)}</title>
<meta name="description" content="${esc(descripcion)}">
<link rel="canonical" href="${esc(url)}">
<meta property="og:type" content="article">
<meta property="og:title" content="${esc(titulo)}">
<meta property="og:description" content="${esc(descripcion)}">
<meta property="og:url" content="${esc(url)}">
<meta property="og:site_name" content="Penalex VE">
<meta property="og:locale" content="es_VE">
<script type="application/ld+json">${JSON.stringify(jsonLd).replace(/undefined/g, 'null')}</script>
`;
}

// ── 4. Índice plano (para la SPA) ───────────────────────────────────────────

export async function servirIndice(env, url) {
  const indice = await cargarIndice(env);
  if (!indice) return new Response('{"error":"indice no encontrado"}', { status: 404, headers: { 'content-type': 'application/json' } });
  return new Response(JSON.stringify(indice), {
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'public, max-age=3600' },
  });
}

// ── 1. SPA índice /leyes (Réplica de RepositorioLeyesScreen) ────────────────

export async function servirPaginaLeyes(env, url) {
  const manifest = await cargarManifest(env);
  const indice = await cargarIndice(env);
  // Conteo real de artículos por ley, desde el índice plano: solo registros
  // con id numérico (los preámbulos y disposiciones tienen id textual como
  // "Única", "Primera", "Preámbulo" y no cuentan).
  const porLey = new Map();
  for (const r of indice || []) {
    const id = String(r.id || '').trim();
    if (!/^\d+$/.test(id)) continue;
    porLey.set(r.slug, (porLey.get(r.slug) || 0) + 1);
  }
  const leyes = (manifest?.leyes || []).map((l) => ({
    slug: l.slug,
    nombre: l.nombre,
    articulos: porLey.get(l.slug) ?? l.articulos ?? 0,
    alias: aliasDe(l.slug)?.alias || [],
  }));

  // SSR: las 53 cards de leyes en el HTML inicial (indexable sin JS).
  const cardsHtml = leyes
    .map(
      (l) =>
        `<a class="ley-card" href="/leyes/${esc(l.slug)}">` +
        `<div class="ley-icono">${ICONO_LIBRO}</div>` +
        `<div class="info"><div class="nombre">${esc(l.nombre)}</div>` +
        `<div class="meta">${l.articulos} artículos</div></div>` +
        `<div class="chev">${ICONO_CHEVRON}</div></a>`
    )
    .join('');

  const host = url.hostname;
  const urlPublica = `https://${host}/leyes`;
  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'ItemList',
        name: 'Leyes de Venezuela',
        numberOfItems: leyes.length,
        itemListElement: leyes.map((l, i) => ({
          '@type': 'ListItem',
          position: i + 1,
          name: l.nombre,
          url: `${urlPublica}/${l.slug}`,
        })),
      },
      {
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Inicio', item: `https://${host}/` },
          { '@type': 'ListItem', position: 2, name: 'Leyes' },
        ],
      },
      { '@type': 'Organization', name: 'Penalex VE', url: `https://${host}` },
    ],
  };

  // Búsqueda client-side: leyes por nombre/alias + artículos sobre el índice.
  const js = `
const leyes = ${JSON.stringify(leyes).replace(/</g, '\\u003c')};
let indice = null; let cargandoIndice = false;
const $ = (id) => document.getElementById(id);
const sinAcentos = (v) => v.normalize('NFD').replace(/[\\u0300-\\u036f]/g, '').toLowerCase();
const limpiar = (v) => sinAcentos(v).replace(/\\s+/g, ' ').trim();

function cardLey(l) {
  const a = document.createElement('a');
  a.className = 'ley-card';
  a.href = '/leyes/' + l.slug;
  a.innerHTML =
    '<div class="ley-icono">${ICONO_LIBRO}</div>' +
    '<div class="info"><div class="nombre">' + l.nombre.replace(/</g, '&lt;') + '</div>' +
    '<div class="meta">' + l.articulos + ' artículos</div></div>' +
    '<div class="chev">${ICONO_CHEVRON}</div>';
  return a;
}

function cardResultado(r) {
  const a = document.createElement('a');
  a.className = 'resultado-card';
  a.href = '/leyes/' + r.slug + '/articulos/' + (r.aid || encodeURIComponent(r.id)) + '/';
  a.innerHTML =
    '<div class="fila1">' +
      '<span class="badge-ley">' + r.ley.replace(/</g, '&lt;') + '</span>' +
      '<span class="titulo-corto">Artículo ' + r.id + '</span>' +
      (r.rubro ? '<span class="encabezado">' + r.rubro.replace(/</g, '&lt;') + '</span>' : '') +
    '</div>' +
    (r.txt ? '<div class="extracto">' + r.txt.replace(/</g, '&lt;') + '</div>' : '') +
    '<div class="ver">Ver artículo →</div>';
  return a;
}

async function pintar() {
  const q = limpiar($('inputLeyes').value || '');
  const cont = $('contenido');
  const est = $('estado');
  if (!q) {
    est.textContent = '';
    cont.innerHTML = '';
    cont.className = 'ley-lista';
    for (const l of leyes) cont.appendChild(cardLey(l));
    return;
  }
  // 1) leyes que coinciden por nombre o alias
  const leyMatches = leyes.filter((l) => l.nombre.toLowerCase().includes(q) || l.slug.includes(q) || (l.alias || []).some((a) => a.toLowerCase().includes(q)));
  // 2) artículos (índice plano)
  if (!indice && !cargandoIndice) {
    cargandoIndice = true;
    est.textContent = 'Buscando en las leyes...';
    try {
      const res = await fetch('/leyes/indice.json');
      if (res.ok) indice = await res.json();
    } catch {}
    cargandoIndice = false;
  }
  const numeros = new Set((q.match(/\\d+/g) || []));
  const palabras = q.split(/[\\s,.;:()\\-–—]+/).filter((t) => t && !/^\\d+$/.test(t));
  let arts = [];
  if (indice) {
    for (const r of indice) {
      let score = 0;
      const id = String(r.id);
      for (const n of numeros) {
        if (id === n) score += 100;
        else if (n.length >= 2 && id.includes(n)) score += 6;
      }
      const enc = sinAcentos(r.rubro || r.enc || '');
      const leyN = sinAcentos(r.ley);
      const txt = sinAcentos(r.txt || '');
      for (const p of palabras) {
        if (enc.includes(p)) score += 4;
        if (leyN.includes(p)) score += 3;
        if (txt.includes(p)) score += 1;
      }
      if (score > 0) arts.push({ r, score });
    }
    arts.sort((a, b) => b.score - a.score);
    arts = arts.slice(0, 50).map((x) => x.r);
  }
  // Si la consulta nombra una ley, priorizar sus artículos
  const total = leyMatches.length + arts.length;
  est.textContent = total + ' resultado' + (total === 1 ? '' : 's');
  cont.innerHTML = '';
  if (total === 0) {
    cont.className = 'vacio';
    cont.innerHTML = '<div class="icono">${ICONO_VACIO}</div><h3>No se encontraron resultados</h3><p>Intenta con otros términos de búsqueda</p>';
    return;
  }
  cont.className = 'resultados';
  for (const l of leyMatches.slice(0, 5)) cont.appendChild(cardLey(l));
  for (const r of arts) cont.appendChild(cardResultado(r));
}

document.addEventListener('DOMContentLoaded', () => {
  $('inputLeyes').addEventListener('input', pintar);
  pintar();
});
`;

  return new Response(`<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
<title>Leyes de Venezuela — Códigos y leyes penales | Penalex</title>
<meta name="description" content="Consulta el texto vigente de las leyes y códigos de Venezuela: Código Orgánico Procesal Penal, Código Penal, Constitución y más. Búsqueda por ley o artículo."/>
<link rel="canonical" href="${esc(urlPublica)}">
<meta property="og:type" content="website">
<meta property="og:title" content="Leyes de Venezuela — Códigos y leyes penales | Penalex">
<meta property="og:description" content="Consulta el texto vigente de las leyes y códigos de Venezuela: Código Orgánico Procesal Penal, Código Penal, Constitución y más. Búsqueda por ley o artículo.">
<meta property="og:url" content="${esc(urlPublica)}">
<meta property="og:site_name" content="Penalex VE">
<meta property="og:locale" content="es_VE">
<script type="application/ld+json">${JSON.stringify(jsonLd).replace(/undefined/g, 'null')}</script>
<link rel="icon" href="/producto/icono.png" sizes="any" type="image/png"/>
<style>${ESTILO}</style>
</head>
<body>
${headerComun()}
<main>
  <div class="busqueda-header">
    <h1>Biblioteca Jurídica</h1>
    <div class="sub">Leyes, códigos y normas de Venezuela con su texto vigente</div>
    <div class="barra">
      <input id="inputLeyes" type="search" placeholder='Busca una ley o un artículo (ej. "250", "homicidio", "COPP")...' autocomplete="off"/>
    </div>
    <div class="hint">${ICONO_AWESOME} <span>Escribe el número de un artículo (ej. "250") o un tema (ej. "homicidio", "drogas")...</span></div>
  </div>
  <div class="estado" id="estado"></div>
  <div id="contenido" class="ley-lista">${cardsHtml}</div>
</main>
${pieSitio()}
<script>${js}</script>
<script>
(function () {
  var b = document.querySelector('.hdr-burger');
  var m = document.getElementById('hdrMenu');
  if (b && m) {
    b.addEventListener('click', function () {
      var abierto = m.classList.toggle('open');
      b.setAttribute('aria-expanded', String(abierto));
    });
    m.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () { m.classList.remove('open'); });
    });
  }
})();
</script>
</body>
</html>`, {
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
    },
  });
}

// ── 2. Página de ley /leyes/{slug} (Réplica de LeyEstructuraScreen) ─────────

/** Construye el árbol jerárquico igual que la app (_construirArbol). */
function construirArbol(ley) {
  const raices = [];
  function findOrAdd(hermanos, nivel, etiqueta) {
    for (const h of hermanos) if (h.nivel === nivel && h.etiqueta === etiqueta) return h;
    const n = { nivel, etiqueta, articulos: [], hijos: [] };
    hermanos.push(n);
    return n;
  }
  for (const b of ley.estructura || []) {
    const path = [
      b.libro ? ['libro', b.libro] : null,
      b.titulo ? ['titulo', b.titulo] : null,
      b.capitulo ? ['capitulo', b.capitulo] : null,
      b.seccion ? ['seccion', b.seccion] : null,
    ].filter(Boolean);
    if (path.length === 0) {
      raices.push({ nivel: 'articulos', etiqueta: '', articulos: b.articulos, hijos: [] });
      continue;
    }
    let hermanos = raices;
    let actual = null;
    for (const [nivel, etiqueta] of path) {
      actual = findOrAdd(hermanos, nivel, etiqueta);
      hermanos = actual.hijos;
    }
    actual.articulos.push(...(b.articulos || []));
  }
  return raices;
}

function rangoArticulos(nodo) {
  const nums = [];
  function recoger(n) {
    for (const a of n.articulos) {
      const num = parseInt(String(a.identificador).trim(), 10);
      if (!Number.isNaN(num)) nums.push(num);
    }
    for (const h of n.hijos) recoger(h);
  }
  recoger(nodo);
  if (!nums.length) return '';
  nums.sort((a, b) => a - b);
  if (nums.length === 1) return `Art. ${nums[0]}`;
  return `Arts. ${nums[0]}-${nums[nums.length - 1]}`;
}

function profundidadNivel(nivel) {
  switch (nivel) {
    case 'libro': return 0;
    case 'titulo': return 1;
    case 'capitulo': return 2;
    case 'seccion': return 3;
    default: return 0;
  }
}

function itemArticuloHtml(slug, art) {
  const esArt = String(art.tipo_norma) === 'Artículo';
  const titulo = esArt ? `Art. ${art.identificador}` : String(art.tipo_norma);
  return `<a class="art-item" href="/leyes/${slug}/articulos/${slugArticulo(art.identificador)}">
    <span class="badge">${esc(titulo)}</span>
    <span class="contenido">
      ${art.encabezado ? `<div class="enc">${esc(art.encabezado)}</div>` : ''}
      <div class="txt">${esc(recortar(art.texto_principal, 200))}</div>
    </span>
    <span class="chev">${ICONO_CHEVRON}</span>
  </a>`;
}

function nodoHtml(slug, nodo, planosPorArt) {
  if (nodo.nivel === 'articulos') {
    return nodo.articulos.map((a) => itemArticuloHtml(slug, a)).join('');
  }
  const prof = profundidadNivel(nodo.nivel);
  const rango = rangoArticulos(nodo);
  const hijos = nodo.hijos.map((h) => nodoHtml(slug, h, planosPorArt)).join('');
  const arts = nodo.articulos.map((a) => itemArticuloHtml(slug, a)).join('');
  return `<details class="nodo n${prof}"${prof === 0 ? ' open' : ''}>
    <summary>
      <span class="tri"></span>
      <span class="etiqueta">${esc(nodo.etiqueta)}</span>
      ${rango ? `<span class="rango">${esc(rango)}</span>` : ''}
    </summary>
    <div class="hijos">${hijos}${arts}</div>
  </details>`;
}

export async function servirPaginaLey(env, url) {
  const slug = (url.pathname.match(/^\/leyes\/([a-z0-9-]+)\/?$/) || [])[1];
  if (!slug) return null;
  const manifest = await cargarManifest(env);
  if (!manifest) return null;
  const meta = (manifest.leyes || []).find((l) => l.slug === slug);
  const ley = await cargarLey(env, slug);
  if (!ley) return new Response('No encontrada', { status: 404 });

  const host = url.hostname;
  const urlPublica = `https://${host}/leyes/${slug}`;
  const nombreLey = tituloLey(ley.ley_nombre || meta?.nombre || slug);
  const alias = aliasDe(slug);
  const nombreTitle = alias?.abrev && alias.abrev !== nombreLey ? `${nombreLey} (${alias.abrev})` : nombreLey;
  const titulo = `${nombreTitle} — Venezuela | Penalex`;
  const artCount = contarArticulos(ley);
  const descripcion = `Texto vigente de ${nombreTitle} de Venezuela, con sus ${artCount} artículos completos y enlaces a cada uno.`;

  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'Legislation',
        name: nombreTitle,
        legislationType: 'https://schema.org/Legislation',
        identifier: slug,
        jurisdiction: { '@type': 'AdministrativeArea', name: 'Venezuela' },
        legalStatus: 'vigente',
        description: descripcion,
        mainEntityOfPage: urlPublica,
      },
      {
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Leyes', item: `https://${host}/leyes` },
          { '@type': 'ListItem', position: 2, name: nombreTitle },
        ],
      },
      { '@type': 'Organization', name: 'Penalex VE', url: `https://${host}` },
    ],
  };

  const arbol = construirArbol(ley);
  const arbolHtml = arbol.map((n) => nodoHtml(slug, n)).join('');

  // Datos planos para el buscador interno (idéntico a _buscarEnLey de la app)
  const planosBusqueda = [];
  for (const bloque of ley.estructura || []) {
    const path = [bloque.libro, bloque.titulo, bloque.capitulo, bloque.seccion].filter(Boolean).join(' → ');
    for (const art of bloque.articulos || []) {
      planosBusqueda.push({
        id: String(art.identificador),
        enc: art.encabezado || '',
        txt: String(art.texto_principal || ''),
        path,
        slug: slugArticulo(art.identificador),
      });
    }
  }

  const jsLey = `
const items = ${JSON.stringify(planosBusqueda).replace(/</g, '\\u003c')};
const sinA = (v) => v.normalize('NFD').replace(/[\\u0300-\\u036f]/g, '').toLowerCase();
const $ = (id) => document.getElementById(id);
let arbolOriginal = null;
function pintarFiltro() {
  const q = sinA($('filtroLey').value || '').trim();
  const cont = $('contenidoLey');
  const est = $('filtroEstado');
  if (!q) {
    if (arbolOriginal) cont.innerHTML = arbolOriginal;
    est.textContent = '';
    return;
  }
  const res = items.filter((it) => {
    const hay = sinA(it.enc + ' ' + it.id + ' ' + it.txt);
    return hay.includes(q);
  });
  est.textContent = res.length ? res.length + ' artículos coinciden con "' + $('filtroLey').value.trim() + '"' : '';
  if (!res.length) {
    cont.innerHTML = '<div class="vacio"><div class="icono">${ICONO_VACIO}</div><h3>No se encontró ningún artículo</h3><p>Intenta con otros términos</p></div>';
    return;
  }
  cont.innerHTML = '<div class="resultados">' + res.map((it) =>
    '<a class="resultado-card" href="/leyes/${slug}/articulos/' + encodeURIComponent(it.slug) + '">' +
      '<div class="fila1"><span class="titulo-corto">' + it.id + '</span>' +
      (it.enc ? '<span class="encabezado">' + it.enc.replace(/</g, '&lt;') + '</span>' : '') + '</div>' +
      (it.path ? '<div class="path">' + it.path.replace(/</g, '&lt;') + '</div>' : '') +
      '<div class="extracto">' + it.txt.slice(0, 200).replace(/</g, '&lt;') + '</div>' +
      '<div class="ver">Ver artículo →</div>' +
    '</a>').join('') + '</div>';
}
document.addEventListener('DOMContentLoaded', () => {
  arbolOriginal = $('contenidoLey').innerHTML;
  $('filtroLey').addEventListener('input', pintarFiltro);
});
`;

  return new Response(`<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link rel="icon" href="/producto/icono.png" sizes="any" type="image/png"/>
<style>${ESTILO}</style>
${buildHead({ titulo, descripcion, url: urlPublica, jsonLd })}
</head>
<body>
${headerComun()}
<main>
  <div class="ley-header">
    <div class="fila1">
      <span class="badge-art">${artCount} artículos</span>
      <span class="hint2">Busca por número de artículo (ej. "400") o tema</span>
    </div>
    <input id="filtroLey" type="search" placeholder='Ej. "400", "homicidio", "medidas"...' autocomplete="off"/>
  </div>
  <div class="migas"><a href="/">Inicio</a> · <a href="/leyes">Leyes</a> · <b>${esc(nombreLey)}</b></div>
  <div class="estado" id="filtroEstado"></div>
  <div id="contenidoLey"><div class="arbol">${arbolHtml}</div></div>
</main>
${pieSitio()}
<script>${jsLey}</script>
<script>
(function () {
  var b = document.querySelector('.hdr-burger');
  var m = document.getElementById('hdrMenu');
  if (b && m) {
    b.addEventListener('click', function () {
      var abierto = m.classList.toggle('open');
      b.setAttribute('aria-expanded', String(abierto));
    });
    m.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () { m.classList.remove('open'); });
    });
  }
})();
</script>
</body>
</html>`, {
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=3600',
    },
  });
}

// ── 3. Página de artículo /leyes/{slug}/articulos/{id} (estilo _ArticuloSheet) ─

export async function servirPaginaArticulo(env, url) {
  const m = url.pathname.match(/^\/leyes\/([a-z0-9-]+)\/articulos\/([a-z0-9-]+)\/?$/);
  if (!m) return null;
  const [, slug, idSlug] = m;
  const ley = await cargarLey(env, slug);
  if (!ley) return new Response('No encontrada', { status: 404 });

  const planos = slugsUnicos(aplanar(ley));
  const idx = planos.findIndex((p) => p.slugFinal === idSlug);
  if (idx < 0) return new Response('No encontrado', { status: 404 });
  const p = planos[idx];
  const art = p.articulo;
  const nombreLey = tituloLey(ley.ley_nombre || slug);
  const alias = aliasDe(slug);
  const host = url.hostname;
  const urlPublica = `https://${host}/leyes/${slug}/articulos/${idSlug}`;

  const esNumerico = /^\d+$/.test(art.identificador);
  const etiqueta = esNumerico ? `Artículo ${art.identificador.replace(/^0+/, '')}` : String(art.identificador);
  const b = p.bloque;
  let rubro = rubroDe(art, b);
  // No duplicar el rubro cuando repite el propio identificador ("Preámbulo — Constitución (Preámbulo)").
  if (!esNumerico && rubro.toLowerCase() === String(art.identificador).toLowerCase()) rubro = '';
  const conRubro = rubro ? ` (${rubro})` : '';
  const nombreTitle = alias?.abrev && alias.abrev !== nombreLey ? alias.abrev : nombreLey;
  const articuloPrep = /^(?:ley|constituci[oó]n)\b/i.test(nombreTitle) ? 'de la' : 'del';
  const titulo = `${etiqueta}${esNumerico ? ` ${articuloPrep} ` : ' — '}${nombreTitle}${conRubro} | Penalex`;
  const descripcion = recortar(art.texto_principal, 158);
  const estado = art.estado === 'vigente' ? 'vigente' : (art.estado || '');

  const migas = [];
  if (b.titulo) migas.push({ n: b.titulo });
  if (b.capitulo) migas.push({ n: b.capitulo });
  if (b.seccion) migas.push({ n: b.seccion });
  const itemList = [
    { '@type': 'ListItem', position: 1, name: 'Leyes', item: `https://${host}/leyes` },
    { '@type': 'ListItem', position: 2, name: nombreLey, item: `https://${host}/leyes/${slug}` },
    ...migas.map((mm, i) => ({ '@type': 'ListItem', position: i + 3, name: mm.n, item: `https://${host}/leyes/${slug}#art-${idSlug}` })),
    { '@type': 'ListItem', position: migas.length + 3, name: etiqueta },
  ];

  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'Legislation',
        name: `${etiqueta}${esNumerico ? ` ${articuloPrep} ` : ' — '}${nombreTitle}${conRubro}`,
        legislationType: 'https://schema.org/Legislation',
        identifier: String(art.identificador),
        isPartOf: { '@type': 'Legislation', name: alias?.abrev || nombreLey, url: `https://${host}/leyes/${slug}` },
        jurisdiction: { '@type': 'AdministrativeArea', name: 'Venezuela' },
        legalStatus: estado || 'vigente',
        description: descripcion,
        text: art.texto_principal,
        mainEntityOfPage: urlPublica,
      },
      { '@type': 'BreadcrumbList', itemListElement: itemList },
      { '@type': 'Organization', name: 'Penalex VE', url: `https://${host}` },
    ],
  };

  // Limpieza editorial segura: no cambia el sentido jurídico, solo
  // espacios y signos sueltos al inicio.
  const limpiarTextoLegal = (valor) =>
    String(valor ?? "")
      .replace(/^\s*[.,;:]\s*/, "")
      .replace(/[ \t]+([.,;:])/g, "$1")
      .replace(/[ \t]{2,}/g, " ")
      .replace(/\n{3,}/g, "\n\n")
      .trim();

  let cuerpo = '';
  if (art.texto_principal) {
    cuerpo += `<div class="cuerpo">${esc(limpiarTextoLegal(art.texto_principal))}</div>`;
  }
  if (art.numerales_literales?.length) {
    cuerpo += `<div class="subtitulo">Numerales</div>`;
    for (const num of art.numerales_literales) cuerpo += `<div class="numeral">${esc(limpiarTextoLegal(num))}</div>`;
  }
  if (art.paragrafos?.length) {
    cuerpo += `<div class="subtitulo">Parágrafos</div>`;
    for (const par of art.paragrafos) cuerpo += `<div class="parrafo">${esc(limpiarTextoLegal(par))}</div>`;
  }
  if (art.nota_jurisprudencial) cuerpo += `<div class="nota">📌 ${esc(art.nota_jurisprudencial)}</div>`;
  if (estado && estado !== 'vigente') cuerpo += `<div class="estado-note">Estado: ${esc(estado.toUpperCase())}</div>`;

  const mismoBloque = planos.filter((q) => q.bloque === b);
  const posBloque = mismoBloque.findIndex((q) => q === p);
  const anterior = posBloque > 0 ? mismoBloque[posBloque - 1] : null;
  const siguiente = posBloque < mismoBloque.length - 1 ? mismoBloque[posBloque + 1] : null;
  const nav = `<div class="nav-art">
    ${anterior ? `<a href="/leyes/${slug}/articulos/${anterior.slugFinal}">← ${anterior.articulo.identificador}</a>` : '<span></span>'}
    ${siguiente ? `<a href="/leyes/${slug}/articulos/${siguiente.slugFinal}">${siguiente.articulo.identificador} →</a>` : '<span></span>'}
  </div>`;

  // Sentencias relacionadas: SOLO las que citan "artículo N de ESTA ley" en
  // su ratio/decision (relación literal verificable) y son de la versión
  // vigente en adelante. Solo artículos numerados.
  let sentRelIds = [];
  try {
    const curadas = Array.isArray(art.sentencias_relacionadas)
      ? art.sentencias_relacionadas.filter(Boolean)
      : [];
    if (curadas.length) {
      sentRelIds = curadas.map((id) => ({ id: String(id) }));
    } else {
      sentRelIds = await sentenciasPorCita(env, art, nombreLey, slug);
    }
  } catch (e) {
    console.error('sentencias relacionadas falló:', e.message);
    sentRelIds = [];
  }
  const htmlSentRel = await htmlSentenciasRelacionadas(env, sentRelIds);

  return new Response(`<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link rel="icon" href="/producto/icono.png" sizes="any" type="image/png"/>
<style>${ESTILO}</style>
${buildHead({ titulo, descripcion, url: urlPublica, jsonLd })}
</head>
<body>
${headerComun()}
<main>
  <div class="migas"><a href="/">Inicio</a> · <a href="/leyes">Leyes</a> · <a href="/leyes/${slug}">${esc(nombreLey)}</a> · <b>${esc(etiqueta)}</b></div>
  <div class="articulo">
    <div class="fila1">
      <span class="badge">${esc(etiqueta)}</span>
      <span class="ley-nombre">${esc(nombreLey)}</span>
    </div>
    ${art.encabezado ? `<h1>${esc(art.encabezado)}</h1>` : ''}
    ${cuerpo}
  </div>
  ${htmlSentRel}
  ${nav}
</main>
${pieSitio()}
<script>
(function () {
  var b = document.querySelector('.hdr-burger');
  var m = document.getElementById('hdrMenu');
  if (b && m) {
    b.addEventListener('click', function () {
      var abierto = m.classList.toggle('open');
      b.setAttribute('aria-expanded', String(abierto));
    });
    m.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () { m.classList.remove('open'); });
    });
  }
})();
</script>
</body>
</html>`, {
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=3600',
    },
  });
}