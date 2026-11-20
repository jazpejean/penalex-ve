// Penalex VE — Buscador Jurídico web (igual al Super Buscador de la app
// Flutter: categorías, sala, año/década, modo avanzado campo-operador-valor,
// referencia exacta, ranking por relevancia, tarjetas con resumen).
//
// El navegador consulta Supabase REST con la anon key (pública por diseño,
// igual que la app): ilike sobre el texto real + filtros + condiciones AND.
// Logo y colores del home (logo-horizontal.png, #031F4E, #C5A059).

const ESTILO = `
:root { --azul:#0F172A; --azul-hover:#1E293B; --dorado:#C5A059; --dorado-osc:#9a7a34; --fondo:#f1f5f9; --texto:#0F172A; --texto2:#475569; --texto-tenue:#64748b; --borde:#e2e8f0; --tarjeta:#ffffff; }
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
.hdr-btn:hover { background:var(--azul-hover); }
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
main { max-width:900px; margin:0 auto; padding:24px 16px 80px; }
.hero h1 { font-size:26px; font-weight:800; letter-spacing:-.2px; }
.hero p { margin-top:8px; color:var(--texto2); font-size:14px; line-height:1.55; max-width:720px; }
.barra { display:flex; gap:10px; margin-top:18px; }
.barra input { flex:1; padding:15px 18px; font-size:15.5px; border:1px solid var(--borde); border-radius:12px; background:#fff; outline:none; color:var(--texto); }
.barra input:focus { border-color:var(--azul); box-shadow:0 0 0 3px rgba(3,31,78,.1); }
.barra button { padding:15px 24px; font-size:15px; font-weight:700; border:none; border-radius:12px; background:var(--azul); color:#fff; cursor:pointer; transition:background .15s; }
.barra button:hover { background:var(--azul-hover); }
.barra-orden { margin-top:10px; }
.ayuda-sintaxis { margin-top:10px; font-size:12px; color:var(--texto2); }
.ayuda-sintaxis b { color:var(--azul); }
.btn-orden { padding:8px 16px; font-size:12.5px; font-weight:700; border:1px solid var(--borde); border-radius:999px; background:#fff; color:var(--texto2); cursor:pointer; transition:all .12s; }
.btn-orden:hover { border-color:var(--azul); color:var(--azul); }
.filtros { margin-top:14px; background:var(--tarjeta); border:1px solid var(--borde); border-radius:14px; padding:14px 16px; }
.filtros .grupo { margin-top:12px; }
.filtros .grupo:first-child { margin-top:0; }
.filtros label { display:block; font-size:11.5px; font-weight:700; color:var(--texto2); text-transform:uppercase; letter-spacing:.5px; margin-bottom:8px; }
.chips { display:flex; flex-wrap:wrap; gap:7px; }
.chip { padding:7px 15px; font-size:13px; border-radius:999px; border:1px solid var(--borde); background:#f8fafc; color:var(--texto2); cursor:pointer; transition:all .12s; }
.chip:hover { border-color:var(--azul); color:var(--azul); }
.chip.activo { background:var(--azul); color:#fff; border-color:var(--azul); font-weight:700; }
select.select { padding:9px 12px; font-size:13.5px; border:1px solid var(--borde); border-radius:10px; background:#fff; color:var(--texto); outline:none; }
.select-anio { max-width:150px; }
.avanzado-toggle { margin-top:14px; }
.avanzado-toggle button { width:100%; padding:11px; font-size:13.5px; font-weight:700; border:1px solid var(--borde); border-radius:12px; background:#fff; color:var(--azul); cursor:pointer; }
.avanzado-toggle button:hover { border-color:var(--azul); }
.avanzado { margin-top:10px; display:none; }
.avanzado.abierto { display:block; }
.condicion { margin-top:8px; padding:12px; background:#f8fafc; border:1px solid var(--borde); border-radius:12px; }
.condicion-sup { display:flex; gap:8px; align-items:center; flex-wrap:wrap; }
.condicion-sup .select { flex:0 0 auto; }
.condicion .valor { padding:9px 12px; font-size:13.5px; border:1px solid var(--borde); border-radius:10px; background:#fff; color:var(--texto); outline:none; width:100%; }
.condicion .quitar { border:none; background:#fef2f2; color:#991b1b; border-radius:10px; padding:8px 12px; font-size:13px; cursor:pointer; font-weight:700; }
.lista-valor { margin-top:8px; }
.chips-valores { display:flex; flex-wrap:wrap; gap:6px; margin-bottom:8px; }
.chip-valor { display:inline-flex; align-items:center; gap:6px; padding:5px 10px; background:var(--azul); color:#fff; border-radius:999px; font-size:12px; font-weight:600; }
.chip-valor b { cursor:pointer; font-weight:700; opacity:.75; }
.chip-valor b:hover { opacity:1; }
.chip-valor-vacio { font-size:12px; color:var(--texto-tenue); }
.buscador-lista { margin-bottom:8px; }
.tabla-valores { border:1px solid var(--borde); border-radius:10px; overflow:hidden; background:#fff; max-height:240px; overflow-y:auto; }
.tabla-fila { display:flex; align-items:center; gap:10px; padding:9px 12px; font-size:13px; border-bottom:1px solid var(--borde); cursor:pointer; transition:background .1s; }
.tabla-fila:last-child { border-bottom:none; }
.tabla-fila:hover { background:var(--fondo); }
.tabla-fila.seleccionada { background:rgba(3,31,78,.07); }
.tabla-encabezado { background:var(--fondo); font-size:10.5px; font-weight:800; color:var(--texto2); text-transform:uppercase; letter-spacing:.4px; cursor:default; }
.tabla-encabezado:hover { background:var(--fondo); }
.tabla-fila .marca { width:18px; height:18px; border:1.5px solid var(--borde); border-radius:5px; display:inline-flex; align-items:center; justify-content:center; font-size:11px; color:var(--azul); flex-shrink:0; }
.tabla-fila.seleccionada .marca { border-color:var(--azul); background:var(--azul); color:#fff; }
.tabla-fila .nombre { flex:1; min-width:0; word-break:break-word; }
.tabla-fila .cnt { font-size:11.5px; color:var(--texto2); font-weight:600; flex-shrink:0; }
.tabla-vacio { padding:14px; text-align:center; font-size:13px; color:var(--texto2); }
.tabla-nota { padding:10px 12px; font-size:11.5px; color:var(--texto-tenue); background:#fffbeb; border-top:1px solid var(--borde); }
.btn-condicion { margin-top:10px; padding:9px 16px; font-size:13px; font-weight:700; border:1px solid var(--dorado); border-radius:10px; background:#fff; color:var(--dorado-osc); cursor:pointer; }
.btn-condicion:hover { background:var(--dorado); color:var(--azul); }
.avanzado-pie { display:flex; gap:10px; align-items:center; margin-top:10px; flex-wrap:wrap; }
.btn-aplicar { padding:9px 18px; font-size:13px; font-weight:700; border:none; border-radius:10px; background:var(--azul); color:#fff; cursor:pointer; }
.btn-aplicar:hover { background:var(--azul-hover); }
.estado { margin-top:18px; font-size:13.5px; color:var(--texto2); min-height:20px; display:flex; align-items:center; gap:8px; }
.estado .spinner { width:14px; height:14px; border:2px solid var(--borde); border-top-color:var(--azul); border-radius:50%; animation:girar .7s linear infinite; display:none; }
.estado.cargando .spinner { display:inline-block; }
@keyframes girar { to { transform:rotate(360deg); } }
.resultados { margin-top:8px; }
.card { background:var(--tarjeta); border:1px solid var(--borde); border-radius:14px; padding:16px 18px; margin-top:10px; transition:border-color .15s, box-shadow .15s; cursor:pointer; }
.card:hover { border-color:var(--dorado); box-shadow:0 4px 14px rgba(3,31,78,.07); }
.card .resumen-corto { display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.card details.resumen-det[open] .resumen-corto { display:block; -webkit-line-clamp:unset; overflow:visible; }
.card details.resumen-det summary { list-style:none; cursor:pointer; }
.card details.resumen-det summary::-webkit-details-marker { display:none; }
.card .resumen-toggle { display:inline-block; margin-top:6px; color:var(--dorado); font-weight:700; font-size:12px; }
.card details.resumen-det[open] .resumen-toggle { display:none; }
.card .btn-abrir { display:inline-block; margin-top:10px; background:var(--azul); color:#fff; font-weight:700; font-size:12px; padding:7px 12px; border-radius:6px; text-decoration:none; }
.card .btn-abrir:hover { background:#0a2a5e; }

.card .encabezado { display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.card .titulo { font-weight:700; color:var(--azul); font-size:14.5px; }
.card .badge { padding:3px 8px; background:var(--dorado); color:#fff; border-radius:6px; font-size:9.5px; font-weight:800; letter-spacing:.4px; }
.card .subtitulo { margin-top:3px; font-size:12px; color:var(--texto2); }
.card .resumen { margin-top:7px; font-size:13px; color:#334155; line-height:1.5; display:-webkit-box; -webkit-line-clamp:3; -webkit-box-orient:vertical; overflow:hidden; }
.card .meta { margin-top:9px; display:flex; align-items:center; gap:12px; font-size:11.5px; color:var(--texto-tenue); flex-wrap:wrap; }
.card .meta .item { display:flex; align-items:center; gap:4px; }
.mas { margin-top:18px; text-align:center; }
.mas button { padding:12px 28px; font-size:14px; font-weight:700; border:1px solid var(--azul); border-radius:12px; background:#fff; color:var(--azul); cursor:pointer; }
.mas button:hover { background:var(--azul); color:#fff; }
.aviso { margin-top:16px; padding:12px 16px; background:#fef2f2; border:1px solid #fecaca; border-radius:12px; color:#991b1b; font-size:13px; display:none; }
.vacio { margin-top:16px; text-align:center; color:var(--texto2); font-size:14px; padding:40px 16px; }
footer { margin-top:44px; text-align:center; font-size:12px; color:#94a3b8; }
`;

const NOMBRES_SALA = { scon: 'Sala Constitucional', scp: 'Sala de Casación Penal' };

// Campos del modo avanzado (igual que la app: etiqueta + lista/texto libre,
// más "Fecha" — día exacto — exclusivo de la web, la app no lo tiene).
const CAMPOS_AVANZADOS = [
  { campo: 'ponente', etiqueta: 'Ponente', lista: true },
  { campo: 'procedimiento', etiqueta: 'Materia', lista: true },
  { campo: 'decision', etiqueta: 'Decisión', lista: true },
  { campo: 'expediente', etiqueta: 'Expediente', lista: true },
  { campo: 'fecha', etiqueta: 'Fecha (día exacto)', lista: false, tipo: 'fecha' },
  { campo: 'num_sentencia', etiqueta: 'Nº de sentencia', lista: false },
];

// Algunas filas tienen num_sentencia corrupto: la fecha DDMMYY del nombre
// del archivo (p. ej. "240101") en vez del número real. El número real
// siempre es el primer segmento del r2_html_key (NNNN-DDMMYY-...).
// (Copia SSR de la función del cliente, que vive dentro del template JS.)
function numeroSentenciaSsr(s) {
  const n = String(s.num_sentencia || '').trim();
  const d = Number(n.slice(0, 2));
  const m = Number(n.slice(2, 4));
  if (/^\d{6}$/.test(n) && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
    const key = s.r2_html_key || '';
    const primer = key.split('/').pop().split('-')[0];
    if (/^\d+$/.test(primer)) return primer;
  }
  return n || 'Sin número';
}

export async function paginaBuscador(env) {
  const supabaseUrl = (env.SUPABASE_URL || '').replace(/\/+$/, '');
  const anonKey = env.SUPABASE_ANON_KEY || '';
  const columnas = [
    'id', 'sala', 'tipo', 'num_sentencia', 'fecha', 'anio', 'ponente', 'procedimiento',
    'partes', 'decision', 'extracto', 'ratio_decidendi', 'expediente',
    'es_jurisprudencia', 'r2_html_key',
  ].join(',');

  // Ruta pública canónica de una sentencia (igual que el cliente).
  const rutaSentenciaSsr = (s) => '/sentencias/' + String(s.r2_html_key || '').replace(/^html\//, '');

  // SSR: listado inicial indexable (10 sentencias recientes, sin JS). Si la
  // consulta falla, la página se sirve igual como buscador funcional.
  let cardsSsr = '';
  try {
    const fp = new URLSearchParams();
    fp.set('select', columnas);
    fp.set('es_mero_tramite', 'eq.false');
    fp.set('tipo', 'eq.sentencia');
    fp.set('order', 'id.desc');
    fp.set('limit', '10');
    const res = await fetch(`${supabaseUrl}/rest/v1/sentencias?${fp.toString()}`, {
      headers: { apikey: anonKey, Authorization: 'Bearer ' + anonKey },
    });
    if (res.ok) {
      const filas = await res.json();
      cardsSsr = filas
        .map((s) => {
          const ruta = rutaSentenciaSsr(s);
          const sala = NOMBRES_SALA[s.sala] || s.sala || '';
          const num = numeroSentenciaSsr(s);
          const titulo = [num && num !== 'Sin número' && `Sentencia Nº ${num}`, sala].filter(Boolean).join(' · ');
          const subtitulo = [s.fecha, s.ponente && `Ponente: ${s.ponente}`, s.procedimiento].filter(Boolean).join(' · ');
          const extrac = s.extracto ? String(s.extracto).replace(/</g, '&lt;') : '';
          return `<div class="card">
            <div class="encabezado"><span class="titulo">${titulo.replace(/</g, '&lt;')}</span></div>
            ${subtitulo ? `<div class="subtitulo">${subtitulo.replace(/</g, '&lt;')}</div>` : ''}
            ${extrac ? `<details class="resumen-det"><summary><span class="resumen-corto">${extrac}</span><span class="resumen-toggle">Leer resumen completo</span></summary></details>` : ''}
            <a class="btn-abrir" href="${ruta.replace(/</g, '&lt;')}">Abrir sentencia</a>
          </div>`;
        })
        .join('');
    }
  } catch (e) {
    console.error('SSR sentencias falló:', e.message);
  }

  const js = `
const SUPABASE_URL = ${JSON.stringify(supabaseUrl)};
const ANON = ${JSON.stringify(anonKey)};
const COLUMNAS = ${JSON.stringify(columnas)};
const NOMBRES_SALA = ${JSON.stringify(NOMBRES_SALA)};
const CAMPOS = ${JSON.stringify(CAMPOS_AVANZADOS)};
const CATEGORIAS = ['Sentencias', 'Jurisprudencias', 'Resoluciones', 'Doctrinas'];
const ANIO_MIN = 2000, ANIO_MAX = ${new Date().getFullYear()};

const state = {
  texto: '', categoria: 'Sentencias', sala: null, anio: null, decada: null,
  condiciones: [{ campo: 'ponente', operador: 'es', valores: [], textoValor: '', tipo: undefined }], // {campo, operador, valores[]}
  offset: 0, limit: 20, cargando: false, fin: false, hayBusqueda: false,
  generacion: 0, // token de cancelación: cada buscar() invalida la anterior
  // Navegación cronológica (sin texto): las primeras sentencias deben ser
  // de enero del 2000. Se carga el año completo por chunks y se ordena por
  // fecha real en el cliente (la columna fecha es texto; el orden del
  // servidor no respeta el mes).
  crono: { activo: false, asc: true, anio: 2000, lista: [], idx: 0, offset: 0 },
};

const $ = (id) => document.getElementById(id);
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const normalizar = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[\\u0300-\\u036f]/g, '');

function nombreSala(cod) { return NOMBRES_SALA[cod] || cod || 'TSJ'; }
function rutaSentencia(s) { return '/sentencias/' + String(s.r2_html_key || '').replace(/^html\\//, ''); }

// ---- Detección de referencia exacta (igual que la app Flutter) ----
// La columna fecha guarda texto en español ("9 de septiembre de 2004", día
// sin cero inicial). Para buscar por DÍA exacto se filtra con eq sobre ese
// texto. Estas funciones normalizan fechas escritas de cualquier forma
// (español, dd/mm/aaaa, aaaa-mm-dd) al formato de la BD.
const NOMBRES_MES = { enero: 1, febrero: 2, marzo: 3, abril: 4, mayo: 5, junio: 6, julio: 7, agosto: 8, septiembre: 9, octubre: 10, noviembre: 11, diciembre: 12 };
const MESES_ABREV = ['', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
function fechaTexto(dia, mes, anio) {
  return Number(dia) + ' de ' + MESES_ABREV[Number(mes)] + ' de ' + anio;
}
// Devuelve { fecha, anio, raw } si el texto contiene una fecha válida, o null.
function detectarFechaConsulta(q) {
  const t = q.trim();
  if (!t) return null;
  // 1) Español: "9 de septiembre de 2004"
  let m = t.match(/(\\d{1,2})\\s+de\\s+([a-záéíóú]+)\\s+de\\s+(\\d{4})/i);
  if (m && NOMBRES_MES[String(m[2]).toLowerCase()]) {
    const mes = NOMBRES_MES[String(m[2]).toLowerCase()];
    return { fecha: fechaTexto(m[1], mes, m[3]), anio: m[3], raw: m[0] };
  }
  // 2) Numérico dd/mm/aaaa o dd-mm-aaaa al final de la consulta
  m = t.match(/(\\d{1,2})[\\/\\-](\\d{1,2})[\\/\\-](\\d{4})$/);
  if (m && Number(m[2]) >= 1 && Number(m[2]) <= 12) {
    return { fecha: fechaTexto(m[1], m[2], m[3]), anio: m[3], raw: m[0] };
  }
  // 3) ISO aaaa-mm-dd (como el input date del modo avanzado)
  m = t.match(/(\\d{4})-(\\d{1,2})-(\\d{1,2})$/);
  if (m && Number(m[2]) >= 1 && Number(m[2]) <= 12) {
    return { fecha: fechaTexto(m[3], m[2], m[1]), anio: m[1], raw: m[0] };
  }
  return null;
}
function detectarReferencia(q) {
  const t = q.trim();
  if (!t) return null;
  const urlMatch = t.match(/https?:\\/\\/historico\\.tsj\\.gob\\.ve\\/decisiones\\/[^\\s]+\\/[^\\s]+\\/([^\\s]+)\\.(?:HTM|HTML|htm|html)\\b/i);
  if (urlMatch) {
    const id = urlMatch[1].replace(/[\\s.]+$/, '');
    if (/^[A-Za-z0-9][A-Za-z0-9\\-]{2,40}$/.test(id)) return { id };
  }
  if (/^\\d{1,4}-\\d{4,6}-[A-Za-z0-9\\-]+$/.test(t)) return { id: t };
  if (/^[A-Za-z]{1,4}[\\d]{1,4}-[A-Za-z]{0,2}[\\d-]{2,12}$/.test(t)) return { expediente: t };
  // Fecha exacta, sola o con número de sentencia:
  //   "9 de septiembre de 2004"                → fecha exacta
  //   "318 del 9 de septiembre de 2004"        → número + fecha
  //   "sentencia 318 de fecha 09-09-2004"      → número + fecha
  //   "318 09/09/2004"                         → número + fecha
  const fe = detectarFechaConsulta(t);
  if (fe) {
    const resto = t.replace(fe.raw, ' ').replace(/sentencia|fecha|del|de|la|el|n[°ºo]|numero|núm|día|dia|año/gi, ' ').replace(/\\s+/g, ' ').trim();
    const numM = resto.match(/^\\d{1,4}$/);
    if (numM) return { num_sentencia: numM[0], fecha: fe.fecha };
    if (resto === '') return { fecha: fe.fecha };
  }
  const num = t.match(/(?:sentencia\\s*(?:n[°ºo]?|numero|núm\\.?)?\\s*)?(\\d{1,4})/i);
  if (num && t.replace(/\\d|\\s|sentencia|n[°ºo]|numero|núm|de|del|la|el|sala|casación|constitucional|penal|año|de/gi, '').trim() === '') {
    const ref = { num_sentencia: num[1] };
    // "142 de 2011" → número + año (igual que la app)
    const anioEnTexto = t.match(/\\b(19\\d{2}|20\\d{2})\\b/);
    if (anioEnTexto) ref.anio = anioEnTexto[1];
    return ref;
  }
  return null;
}

// ---- Búsqueda con operadores (AND/OR/frase/exclusión) ----
// Sintaxis:
//   amparo constitucional      → AND: ambas palabras en alguna columna
//   amparo OR tutela           → OR: cualquiera de las dos
//   "amparo constitucional"    → frase exacta (orden y palabras juntas)
//   -violencia                 → excluye sentencias con esa palabra
// Columnas de texto donde se busca.
const COLS_BUSQUEDA = ['decision', 'partes', 'extracto', 'ponente', 'procedimiento'];

function analizarConsulta(texto) {
  const frases = [];
  // 1) Frases exactas entre comillas
  const resto = texto.replace(/"[^"]*"/g, (m) => {
    const f = m.slice(1, -1).trim();
    if (f) frases.push(f);
    return ' ';
  });
  // 2) Tokens: -exclusión, OR, palabras
  const tokens = resto.split(/\\s+/).filter(Boolean);
  const excluir = [];
  const grupos = []; // grupos AND; dentro de un grupo, OR
  let actual = [];
  const terminosPositivos = [];
  for (const tok of tokens) {
    if (tok.length > 1 && tok[0] === '-') { excluir.push(tok.slice(1)); continue; }
    if (/^OR$/i.test(tok)) {
      if (actual.length) grupos.push(actual);
      actual = [];
      continue;
    }
    const limpio = tok.replace(/^["']|["']$/g, '');
    if (!limpio) continue;
    actual.push(limpio);
    terminosPositivos.push(limpio);
  }
  if (actual.length) grupos.push(actual);

  // 3) Construir parámetros PostgREST:
  //    - cada frase → or=(col1.ilike.%frase%,col2.ilike.%frase%,...)
  //    - cada grupo de 1 término → un or con ese término en todas las columnas
  //    - grupo de N (OR) → un or con todos los términos × columnas
  //    - exclusión → cada columna con not.ilike (AND implícito entre params)
  const params = [];
  for (const f of frases) {
    params.push(['or', '(' + COLS_BUSQUEDA.map((c) => c + '.ilike.%' + f + '%').join(',') + ')']);
  }
  for (const g of grupos) {
    if (!g.length) continue;
    const or = g.flatMap((t) => COLS_BUSQUEDA.map((c) => c + '.ilike.%' + t + '%')).join(',');
    params.push(['or', '(' + or + ')']);
  }
  for (const ex of excluir) {
    for (const c of COLS_BUSQUEDA) params.push([c, 'not.ilike.%' + ex + '%']);
  }
  // Términos para el ranking de relevancia
  const todos = [...terminosPositivos, ...frases];
  return { params, todos, frases, grupos, excluir };
}

// Construye un tsquery español a partir del análisis, replicando la semántica
// actual: frases exactas, grupos AND (OR interno), exclusión. El search_vector
// está en español (stemming), por eso se pasa el config (spanish) al operador.
// Devuelve '' si no hay nada buscable.
function construirTsQuery(an) {
  const limpiar = (t) => String(t || '').replace(/["'&|!():*\\\\]/g, ' ').trim();
  const partes = [];
  for (const f of an.frases || []) {
    const terms = String(f || '').split(/\\s+/).map(limpiar).filter(Boolean);
    if (!terms.length) continue;
    // Frase exacta: adyacencia <-> (las comillas dobles rompen la sintaxis de
    // to_tsquery vía PostgREST). "dolo eventual" → dolo <-> eventual.
    partes.push(terms.length > 1 ? '(' + terms.join(' <-> ') + ')' : terms[0]);
  }
  for (const g of an.grupos || []) {
    const terms = g.map(limpiar).filter(Boolean);
    if (!terms.length) continue;
    partes.push(terms.length > 1 ? '(' + terms.join(' | ') + ')' : terms[0]);
  }
  for (const ex of an.excluir || []) {
    const limpia = limpiar(ex);
    if (limpia) partes.push('!' + limpia);
  }
  return partes.join(' & ');
}

// ---- Ranking por relevancia (misma idea que _scoreRelevancia de la app) ----
function scoreRelevancia(s, terminos) {
  if (!terminos.length) return 0;
  const texto = normalizar([s.extracto, s.decision, s.ratio_decidendi, s.procedimiento, s.partes, s.ponente, s.expediente, s.num_sentencia, s.sala].join(' '));
  let score = 0;
  for (const t of terminos) {
    if (t.length >= 3 && texto.includes(normalizar(t))) score++;
  }
  return score;
}

const MESES = { enero: 1, febrero: 2, marzo: 3, abril: 4, mayo: 5, junio: 6, julio: 7, agosto: 8, septiembre: 9, octubre: 10, noviembre: 11, diciembre: 12 };
function parsearFecha(txt) {
  const m = String(txt || '').match(/(\\d{1,2}) de ([a-záéíóú]+) de (\\d{4})/i);
  if (!m) return [0, 0, 0];
  return [Number(m[3]), MESES[String(m[2]).toLowerCase()] || 0, Number(m[1])];
}
function cmpFecha(a, b) {
  const A = parsearFecha(a), B = parsearFecha(b);
  for (let i = 0; i < 3; i++) { if (A[i] !== B[i]) return B[i] - A[i]; }
  return 0;
}

async function consultaSupabase(fp) {
  let ultimo;
  for (let intento = 0; intento < 2; intento++) {
    try {
      const res = await fetch(SUPABASE_URL + '/rest/v1/sentencias?' + fp.toString(), {
        headers: { apikey: ANON, Authorization: 'Bearer ' + ANON },
      });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      return await res.json();
    } catch (e) {
      ultimo = e;
      await new Promise((r) => setTimeout(r, 800));
    }
  }
  throw ultimo;
}

// Autocompletado de valores de lista (modo avanzado). Si la vista de conteos
// existe (v_conteos_<campo>), devuelve {valor, total} ordenado por total
// (ej. la tabla de magistrados: Ponente → "Pedro Rafael Rondón Haaz 4372").
// El ilike sobre la vista falla (500), así que con texto se cae al ilike sobre
// la tabla (sin conteos). El timeout frío (57014) se absorbe con reintento.
const VISTAS_CONTEO = { ponente: 'v_conteos_ponente', procedimiento: 'v_conteos_procedimiento', decision: 'v_conteos_decision', expediente: 'v_conteos_expediente' };

async function sugerirValores(campo, texto) {
  const vista = VISTAS_CONTEO[campo];
  const sinTexto = !(texto || '').trim();
  if (vista && sinTexto) {
    // Top N con conteos: la vista ya ordena por total desc
    for (let intento = 0; intento < 2; intento++) {
      try {
        const fp = new URLSearchParams();
        fp.set('select', 'valor,total');
        fp.set('limit', '30');
        fp.set('order', 'total.desc');
        const res = await fetch(SUPABASE_URL + '/rest/v1/' + vista + '?' + fp.toString(), {
          headers: { apikey: ANON, Authorization: 'Bearer ' + ANON },
        });
        if (res.ok) {
          const d = await res.json();
          if (Array.isArray(d) && d.length) return d.map((x) => ({ valor: x.valor, total: x.total }));
        }
        throw new Error('HTTP ' + res.status);
      } catch (e) {
        if (intento === 0) await new Promise((r) => setTimeout(r, 800));
      }
    }
    // La vista no responde → caer a la tabla
  }
  // Con texto (o sin vista): ilike sobre la tabla, sin conteos
  const fp = new URLSearchParams();
  fp.set('select', campo);
  fp.set('es_mero_tramite', 'eq.false');
  fp.set('limit', '8');
  if (texto) fp.set(campo, 'ilike.%' + texto + '%');
  const d = await consultaSupabase(fp);
  return [...new Set(d.map((x) => x[campo]).filter(Boolean))].map((v) => ({ valor: v, total: null }));
}

async function buscar() {
  // Nueva generación: cancela cualquier carga anterior (crono o búsqueda)
  state.generacion++;
  const gen = state.generacion;
  state.cargando = false;
  state.offset = 0; state.fin = false;
  state.hayBusqueda = state.texto.trim().length > 0 || state.condiciones.some((c) => (c.valores || []).length);
  // El orden cronológico (Antiguas/Recientes) solo aplica a la navegación
  // sin texto; con búsqueda el orden es por relevancia.
  document.getElementById('btnOrden').style.display = state.hayBusqueda ? 'none' : 'inline-block';
  const lista = $('resultados'); lista.innerHTML = '';
  const est = $('estado'); est.textContent = 'Buscando…'; est.classList.add('cargando');
  $('vacio').style.display = 'none';
  $('aviso').style.display = 'none';
  $('mas').style.display = 'none';
  try {
    // Navegación cronológica cuando NO hay texto ni condiciones (categoría
    // de sentencias): las primeras sentencias son de enero del 2000.
    const navegacion = !state.hayBusqueda && state.categoria !== 'Doctrinas';
    state.crono.activo = navegacion;
    if (navegacion) {
      if (state.anio) { state.crono.anio = state.anio; }
      else if (state.decada) { state.crono.anio = state.decada; }
      else { state.crono.anio = state.crono.asc ? ANIO_MIN : ANIO_MAX; }
      state.crono.lista = [];
      state.crono.idx = 0;
      state.crono.offset = 0;
      await cargarPaginaCrono(true, gen);
    } else {
      await cargarPagina(true, gen);
    }
  } catch (e) {
    est.classList.remove('cargando');
    est.textContent = '';
    $('aviso').style.display = 'block';
    $('aviso').textContent = 'No se pudo consultar la base. Verifica tu conexión.';
  }
}

// Navegación cronológica: las primeras sentencias son de enero del 2000.
// Carga UN año completo en chunks ligeros (id, fecha) — límite de 1000 por
// respuesta de PostgREST —, ordena por fecha real en el cliente y pagina
// dentro de esa lista. Al agotar el año, carga el siguiente (asc) o el
// anterior (desc).
async function cargarPaginaCrono(reemplazar, gen) {
  if (state.cargando) return;
  state.cargando = true;
  $('estado').classList.add('cargando');

  const limiteAnioSup = state.anio ? state.anio : (state.decada ? state.decada + 9 : ANIO_MAX);
  const limiteAnioInf = state.anio ? state.anio : (state.decada ? state.decada : ANIO_MIN);

  // Cargar el año completo si la lista actual está agotada
  while (state.crono.idx >= state.crono.lista.length) {
    if (state.crono.anio < limiteAnioInf || state.crono.anio > limiteAnioSup) {
      state.fin = true;
      break;
    }
    state.crono.lista = [];
    state.crono.offset = 0;
    // Chunks de 1000 hasta agotar el año
    while (true) {
      const fp = new URLSearchParams();
      fp.set('select', 'id,fecha,anio');
      fp.set('es_mero_tramite', 'eq.false');
      if (state.categoria === 'Jurisprudencias') fp.set('es_jurisprudencia', 'eq.true');
      else if (state.categoria === 'Resoluciones') fp.set('tipo', 'eq.resoluciones');
      else fp.set('tipo', 'eq.sentencia');
      if (state.sala) fp.set('sala', 'eq.' + state.sala);
      fp.set('anio', 'eq.' + state.crono.anio);
      fp.set('limit', '1000');
      fp.set('offset', String(state.crono.offset));
      fp.set('order', 'id.asc'); // paginación estable; el orden real se hace en el cliente
      const chunk = await consultaSupabase(fp);
      if (gen !== state.generacion) { state.cargando = false; return; } // cancelada
      state.crono.lista = state.crono.lista.concat(chunk);
      state.crono.offset += chunk.length;
      if (chunk.length < 1000) break; // año agotado
    }
    // Ordenar por fecha real (el servidor no respeta el mes: fecha es texto).
    // Ojo: cmpFecha(a,b) devuelve B-A (descendente por diseño); para el modo
    // asc (enero 2000 primero) hay que negar el resultado.
    state.crono.lista.sort((a, b) => {
      const c = cmpFecha(a.fecha, b.fecha);
      return state.crono.asc ? -c : c;
    });
    state.crono.idx = 0;
    if (state.crono.lista.length === 0) {
      // Año sin resultados con los filtros → siguiente año
      state.crono.anio += state.crono.asc ? 1 : -1;
    }
  }

  const ids = state.crono.lista.slice(state.crono.idx, state.crono.idx + state.limit).map((x) => x.id);
  state.crono.idx += ids.length;
  if (state.crono.idx >= state.crono.lista.length) {
    // Preparar el siguiente año para la próxima carga
    state.crono.anio += state.crono.asc ? 1 : -1;
  }
  if (ids.length < state.limit) state.fin = true;

  let data = [];
  if (ids.length) {
    const fp = new URLSearchParams();
    fp.set('select', COLUMNAS);
    fp.set('es_mero_tramite', 'eq.false');
    fp.set('id', 'in.(' + ids.join(',') + ')');
    fp.set('limit', String(state.limit));
    const filas = await consultaSupabase(fp);
    if (gen !== state.generacion) { state.cargando = false; return; } // cancelada
    // Reordenar según ids (la consulta IN no garantiza el orden)
    const mapa = new Map(filas.map((f) => [f.id, f]));
    data = ids.map((i) => mapa.get(i)).filter(Boolean);
  }
  if (gen !== state.generacion) { state.cargando = false; return; } // cancelada
  pintar(data, reemplazar, []);
  // Estado informativo de la navegación
  if (reemplazar) {
    const est = $('estado');
    if (data.length) {
      est.textContent = 'Mostrando sentencias desde ' + data[0].fecha + (state.fin ? ' (fin)' : '');
    } else {
      est.textContent = 'Sin resultados';
    }
  }
  state.cargando = false;
  $('estado').classList.remove('cargando');
}

async function cargarPagina(reemplazar, gen) {
  if (state.cargando || state.fin) return;
  state.cargando = true;
  $('estado').classList.add('cargando');

  const params = new URLSearchParams();
  params.set('select', COLUMNAS);
  params.set('es_mero_tramite', 'eq.false');
  params.set('limit', String(state.limit));
  params.set('offset', String(state.offset));
  // Tie-breaker determinista (id) para que LIMIT/OFFSET sea estable: muchas
  // sentencias comparten fecha (p. ej. "1 de enero de 2000"); sin un segundo
  // criterio Postgres no garantiza el mismo orden entre páginas y los
  // resultados se repiten al paginar.
  params.set('order', 'fecha.desc,id.desc');

  // Categoría
  if (state.categoria === 'Jurisprudencias') params.set('es_jurisprudencia', 'eq.true');
  else if (state.categoria === 'Resoluciones') params.set('tipo', 'eq.resoluciones');
  else if (state.categoria !== 'Doctrinas') params.set('tipo', 'eq.sentencia');

  // Sala / Año / Década (columna anio numérica: rápida)
  if (state.sala) params.set('sala', 'eq.' + state.sala);
  if (state.anio) params.set('anio', 'eq.' + state.anio);
  else if (state.decada) {
    // PostgREST: dos filtros sobre la misma columna = AND (anio >= d y < d+10)
    params.append('anio', 'gte.' + state.decada);
    params.append('anio', 'lt.' + (state.decada + 10));
  }

  // Modo avanzado: condiciones campo-operador-valor(es) (AND), replicando
  // CondicionBusqueda.aplicar de la app:
  //   es         → eq (1 valor) | in.(a,b,c) (2+)
  //   no es      → neq (1) | not.in.(a,b,c) (2+)
  //   contiene   → ilike.%v%
  //   no contiene→ not.ilike.%v%
  for (const c of state.condiciones) {
    const vals = (c.valores || []).map((v) => String(v).trim()).filter(Boolean);
    if (!vals.length) continue;
    const campo = c.campo;
    if (campo === 'fecha') {
      // El input type=date da YYYY-MM-DD; la columna guarda "d de mes de año"
      // sin cero inicial. Se convierte y se filtra con eq exacto.
      const m = String(vals[0]).match(/^(\\d{4})-(\\d{2})-(\\d{2})$/);
      if (!m) continue;
      const [yy, mm, dd] = [Number(m[1]), Number(m[2]), Number(m[3])];
      const MESES2 = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
      const fechaTxt = dd + ' de ' + (MESES2[mm - 1] || '') + ' de ' + yy;
      params.set('fecha', c.operador === 'es' ? 'eq.' + fechaTxt : 'neq.' + fechaTxt);
      continue;
    }
    if (c.operador === 'es') {
      if (vals.length === 1) params.set(campo, 'eq.' + vals[0]);
      else params.set(campo, 'in.(' + vals.join(',') + ')');
    } else if (c.operador === 'no es') {
      if (vals.length === 1) params.set(campo, 'neq.' + vals[0]);
      else params.set(campo, 'not.in.(' + vals.join(',') + ')');
    } else if (c.operador === 'contiene') {
      params.set(campo, 'ilike.%' + vals[0] + '%');
    } else {
      params.set(campo, 'not.ilike.%' + vals[0] + '%');
    }
  }

  const texto = state.texto.trim();
  let data = [];
  let terminos = [];

  if (state.categoria === 'Doctrinas') {
    // Doctrinas académicas: FTS en su search_vector + ilike de respaldo
    const fp = new URLSearchParams();
    fp.set('select', 'id,sentencia_id,autor,obra,pagina,parrafo_evidencia');
    fp.set('limit', String(state.limit));
    fp.set('offset', String(state.offset));
    const term = texto.split(/\\s+/).filter((t) => t.length > 2);
    if (texto && term.length) {
      fp.set('search_vector', 'wfts.' + term.join(' OR '));
      try { data = await consultaSupabase(fp); } catch (e) { data = []; }
      if (gen !== state.generacion) { state.cargando = false; return; }
      if (data.length < 5) {
        const or = term.map((t) =>
          ['autor', 'obra', 'parrafo_evidencia'].map((c) => c + '.ilike.%' + t + '%').join(',')
        ).join(',');
        const fp2 = new URLSearchParams(fp);
        fp2.delete('search_vector');
        // Conservar offset: el respaldo ilike debe paginar, no reiniciar.
        fp2.set('order', 'id.desc');
        fp2.set('or', '(' + or + ')');
        try { data = await consultaSupabase(fp2); } catch (e) { /* noop */ }
        if (gen !== state.generacion) { state.cargando = false; return; }
      }
    } else {
      data = await consultaSupabase(fp);
      if (gen !== state.generacion) { state.cargando = false; return; }
    }
    state.offset += data.length;
    state.fin = data.length < state.limit;
    pintarDoctrinas(data, reemplazar);
    state.cargando = false;
    $('estado').classList.remove('cargando');
    return;
  }

  if (texto) {
    // Referencia exacta (id/expediente/número) → eq exacto
    const ref = detectarReferencia(texto);
    if (ref) {
      for (const [k, v] of Object.entries(ref)) params.set(k, 'eq.' + v);
      data = await consultaSupabase(params);
      if (gen !== state.generacion) { state.cargando = false; return; }
    } else {
      // Búsqueda con operadores: AND (espacio), OR, frase exacta ("..."),
      // exclusión (-palabra). El FTS con search_vector (config español) es
      // rápido y evita el timeout del ilike multi-columna; si da pocos
      // resultados se hace respaldo con ilike.
      const analisis = analizarConsulta(texto);
      terminos = analisis.todos;
      const fp = new URLSearchParams(params);
      fp.delete('search_vector');
      // NO borrar 'offset' ni 'order': la paginación debe ser estable en FTS,
      // ilike de respaldo y búsqueda normal; si se borran, "Cargar más"
      // repite siempre los primeros resultados (infinito).
      let ftsData = null;
      const tsq = construirTsQuery(analisis);
      if (tsq) {
        const fpF = new URLSearchParams(fp);
        fpF.set('search_vector', 'fts(spanish).' + tsq);
        // Order estable para que LIMIT/OFFSET no repita filas entre páginas.
        fpF.set('order', 'fecha.desc,id.desc');
        try {
          ftsData = await consultaSupabase(fpF);
          if (gen !== state.generacion) { state.cargando = false; return; }
        } catch (e) { ftsData = null; }
      }
      if (ftsData && ftsData.length >= 5) {
        data = ftsData;
      } else if (analisis.params.length) {
        for (const [k, v] of analisis.params) fp.append(k, v);
        try {
          data = await consultaSupabase(fp);
          if (gen !== state.generacion) { state.cargando = false; return; }
        } catch (e) { data = ftsData || []; }
      } else {
        data = ftsData || [];
      }
      if (data.length) {
        data.sort((a, b) => {
          const sa = scoreRelevancia(a, terminos), sb = scoreRelevancia(b, terminos);
          if (sa !== sb) return sb - sa;
          return cmpFecha(a.fecha, b.fecha);
        });
      }
    }
  } else {
    data = await consultaSupabase(params);
    if (gen !== state.generacion) { state.cargando = false; return; }
  }

  state.offset += data.length;
  state.fin = data.length < state.limit;
  pintar(data, reemplazar, terminos);
  state.cargando = false;
  $('estado').classList.remove('cargando');
}

// Algunas filas tienen num_sentencia corrupto: la fecha DDMMYY del nombre
// del archivo (p. ej. "240101") en vez del número real. El número real
// siempre es el primer segmento del r2_html_key (NNNN-DDMMYY-...).
function numeroSentencia(s) {
  const n = String(s.num_sentencia || '').trim();
  const d = Number(n.slice(0, 2));
  const m = Number(n.slice(2, 4));
  if (/^(\\d{6})$/.test(n) && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
    const key = s.r2_html_key || '';
    const primer = key.split('/').pop().split('-')[0];
    if (/^\\d+$/.test(primer)) return primer;
  }
  return n || 'Sin número';
}

function pintar(data, reemplazar, terminos) {
  const lista = $('resultados');
  if (reemplazar) lista.innerHTML = '';
  const frag = document.createDocumentFragment();
  for (const s of data) {
    const div = document.createElement('div');
    div.className = 'card';
    const ruta = rutaSentencia(s);
    const titulo = 'Sentencia N° ' + numeroSentencia(s);
    const sala = nombreSala(s.sala);
    let resumen = s.extracto || s.ratio_decidendi || s.decision || '';
    if (terminos.length && resumen) {
      const hay = terminos.filter((t) => normalizar(resumen).includes(normalizar(t)));
      if (hay.length && resumen.length > 260) {
        const idx = resumen.toLowerCase().indexOf(hay[0].toLowerCase());
        if (idx > 60) resumen = '…' + resumen.slice(Math.max(0, idx - 60));
        resumen = resumen.slice(0, 260) + '…';
      }
    } else if (resumen.length > 260) {
      resumen = resumen.slice(0, 260) + '…';
    }
    const items = [];
    items.push('<span class="item">📅 ' + esc(s.fecha || '') + '</span>');
    if (s.ponente) items.push('<span class="item">⚖️ ' + esc(s.ponente) + '</span>');
    if (s.expediente) items.push('<span class="item">📁 Exp. ' + esc(s.expediente) + '</span>');
    if (s.procedimiento) items.push('<span class="item">⚙️ ' + esc(s.procedimiento) + '</span>');
    div.innerHTML =
      '<div class="encabezado">' +
        '<span class="titulo">' + esc(titulo) + '</span>' +
        (s.es_jurisprudencia ? '<span class="badge">VINCULANTE</span>' : '') +
      '</div>' +
      '<div class="subtitulo">' + esc(sala) + '</div>' +
      '<div class="meta">' + items.join('') + '</div>' +
      (resumen ? '<details class="resumen-det"><summary><span class="resumen-corto">' + esc(resumen) + '</span><span class="resumen-toggle">Leer resumen completo</span></summary></details>' : '') +
      '<a class="btn-abrir" href="' + esc(ruta) + '">Abrir sentencia</a>';
    frag.appendChild(div);
  }
  lista.appendChild(frag);
  const est = $('estado');
  if (reemplazar || state.offset === state.limit) {
    est.textContent = data.length
      ? data.length + ' resultado' + (data.length === 1 ? '' : 's')
      : (state.hayBusqueda ? 'Sin resultados para la búsqueda actual' : 'Sin resultados');
  }
  $('mas').style.display = state.fin ? 'none' : 'block';
}

function pintarDoctrinas(data, reemplazar) {
  const lista = $('resultados');
  if (reemplazar) lista.innerHTML = '';
  const frag = document.createDocumentFragment();
  for (const d of data) {
    const div = document.createElement('div');
    div.className = 'card';
    const autor = d.autor || 'Autor no indicado';
    const obra = d.obra || '';
    let resumen = d.parrafo_evidencia || '';
    if (resumen.length > 260) resumen = resumen.slice(0, 260) + '…';
    const items = [];
    if (d.pagina) items.push('<span class="item">📄 pág. ' + esc(d.pagina) + '</span>');
    div.innerHTML =
      '<div class="encabezado"><span class="titulo">' + esc(autor) + '</span><span class="badge">DOCTRINA</span></div>' +
      (obra ? '<div class="subtitulo">' + esc(obra) + '</div>' : '') +
      (resumen ? '<div class="resumen">' + esc(resumen) + '</div>' : '') +
      (items.length ? '<div class="meta">' + items.join('') + '</div>' : '');
    frag.appendChild(div);
  }
  lista.appendChild(frag);
  const est = $('estado');
  if (reemplazar || state.offset === state.limit) {
    est.textContent = data.length
      ? data.length + ' resultado' + (data.length === 1 ? '' : 's')
      : (state.hayBusqueda ? 'Sin resultados para la búsqueda actual' : 'Sin resultados');
  }
  $('mas').style.display = state.fin ? 'none' : 'block';
}

// ---- Filtros: años completos + décadas ----
function pintarFiltros() {
  // Sala
  const salaChips = document.getElementById('salaChips');
  salaChips.innerHTML = '';
  for (const [val, label] of [['', 'Todas'], ['scp', 'Penal'], ['scon', 'Constitucional']]) {
    const c = document.createElement('span');
    c.className = 'chip' + (state.sala === val ? ' activo' : '');
    c.textContent = label;
    c.dataset.val = val;
    c.onclick = () => { state.sala = val || null; marcarChips(); buscar(); };
    salaChips.appendChild(c);
  }
  // Décadas
  const decChips = document.getElementById('decadaChips');
  decChips.innerHTML = '';
  const tds = document.createElement('span');
  tds.className = 'chip' + (state.decada === null && state.anio === null ? ' activo' : '');
  tds.textContent = 'Todos';
  tds.dataset.val = '';
  tds.onclick = () => { state.decada = null; state.anio = null; marcarChips(); buscar(); };
  decChips.appendChild(tds);
  for (let d = 2000; d <= ANIO_MAX; d += 10) {
    const c = document.createElement('span');
    c.className = 'chip' + (state.decada === d ? ' activo' : '');
    c.textContent = d + 's';
    c.dataset.val = String(d);
    c.onclick = () => { state.decada = d; state.anio = null; marcarChips(); buscar(); };
    decChips.appendChild(c);
  }
  // Año: selector completo 2000–actual
  const selAnio = document.getElementById('selectAnio');
  selAnio.innerHTML = '';
  const opTodo = document.createElement('option');
  opTodo.value = ''; opTodo.textContent = 'Todos los años';
  selAnio.appendChild(opTodo);
  for (let a = ANIO_MAX; a >= ANIO_MIN; a--) {
    const o = document.createElement('option');
    o.value = String(a); o.textContent = String(a);
    selAnio.appendChild(o);
  }
  selAnio.onchange = () => {
    state.anio = selAnio.value ? Number(selAnio.value) : null;
    if (state.anio) state.decada = null;
    marcarChips();
    buscar();
  };
  selAnio.value = state.anio ? String(state.anio) : '';
}

function marcarChips() {
  document.querySelectorAll('#categoriaChips .chip').forEach((c) => {
    c.classList.toggle('activo', c.dataset.val === state.categoria);
  });
  document.querySelectorAll('#salaChips .chip').forEach((c) => {
    c.classList.toggle('activo', c.dataset.val === state.sala);
  });
  document.querySelectorAll('#decadaChips .chip').forEach((c) => {
    c.classList.toggle('activo', c.dataset.val === String(state.decada));
  });
  const sel = document.getElementById('selectAnio');
  if (sel) sel.value = state.anio ? String(state.anio) : '';
}

// ---- Modo avanzado ----
// Cada condición: campo + operador + valores (multi-selección en campos de
// lista, texto libre en num_sentencia). Los campos de lista muestran una
// tabla de valores con su conteo si la vista v_conteos_* existe (ej. la
// tabla de magistrados: Ponente → "Levis Ignacio Zerpa 8625").
let _listaAbierta = null; // {indice, campo, texto}

function renderCondiciones() {
  const cont = document.getElementById('condiciones');
  cont.innerHTML = '';
  state.condiciones.forEach((c, i) => {
    const esLista = CAMPOS.find((x) => x.campo === c.campo)?.lista;
    const row = document.createElement('div');
    row.className = 'condicion';

    // Fila superior: campo + operador + quitar
    const filaSup = document.createElement('div');
    filaSup.className = 'condicion-sup';

    // Campo
    const selCampo = document.createElement('select');
    selCampo.className = 'select';
    for (const cm of CAMPOS) {
      const o = document.createElement('option');
      o.value = cm.campo; o.textContent = cm.etiqueta;
      selCampo.appendChild(o);
    }
    selCampo.value = c.campo;
    selCampo.onchange = () => {
      c.campo = selCampo.value;
      c.valores = [];
      c.textoValor = '';
      c.tipo = CAMPOS.find((x) => x.campo === c.campo)?.tipo;
      const esListaNuevo = CAMPOS.find((x) => x.campo === c.campo)?.lista;
      if (esListaNuevo || c.tipo === 'fecha') c.operador = 'es';
      renderCondiciones();
    };

    // Operador
    const selOp = document.createElement('select');
    selOp.className = 'select';
    const tipoCampo = CAMPOS.find((x) => x.campo === c.campo)?.tipo;
    const ops = esLista
      ? [['es', 'es'], ['no es', 'no es']]
      : tipoCampo === 'fecha'
        ? [['es', 'es'], ['no es', 'no es']]
        : [['es', 'es'], ['no es', 'no es'], ['contiene', 'contiene'], ['no contiene', 'no contiene']];
    for (const [v, lbl] of ops) {
      const o = document.createElement('option');
      o.value = v; o.textContent = lbl;
      selOp.appendChild(o);
    }
    selOp.value = c.operador;
    selOp.onchange = () => { c.operador = selOp.value; };

    // Valor
    let valorUI;
    if (esLista) {
      valorUI = crearSelectorLista(c, i);
    } else if (c.tipo === 'fecha') {
      valorUI = document.createElement('input');
      valorUI.type = 'date';
      valorUI.className = 'valor valor-fecha';
      if (c.valores[0]) valorUI.value = c.valores[0];
      valorUI.onchange = () => { c.valores = valorUI.value ? [valorUI.value] : []; };
    } else {
      valorUI = document.createElement('input');
      valorUI.className = 'valor';
      valorUI.placeholder = 'Valor…';
      valorUI.value = c.valores[0] || '';
      valorUI.onchange = () => { c.valores = valorUI.value ? [valorUI.value] : []; };
    }

    const btnQ = document.createElement('button');
    btnQ.className = 'quitar';
    btnQ.textContent = '✕';
    btnQ.title = 'Quitar condición';
    btnQ.onclick = () => { state.condiciones.splice(i, 1); renderCondiciones(); };

    row.appendChild(filaSup);
    filaSup.appendChild(selCampo);
    filaSup.appendChild(selOp);
    filaSup.appendChild(btnQ);
    if (valorUI) row.appendChild(valorUI);
    cont.appendChild(row);
  });
  const btnAdd = document.getElementById('btnAgregarCondicion');
  btnAdd.onclick = () => {
    state.condiciones.push({ campo: 'ponente', operador: 'es', valores: [], textoValor: '', tipo: undefined });
    renderCondiciones();
  };
}

// Selector de valores para campos de lista (Ponente, Materia, Decisión,
// Expediente): chips de los seleccionados + buscador + tabla de valores con
// conteo (si la vista v_conteos_* existe).
function crearSelectorLista(c, i) {
  const caja = document.createElement('div');
  caja.className = 'lista-valor';

  // Chips de valores ya elegidos
  const chips = document.createElement('div');
  chips.className = 'chips-valores';
  caja.appendChild(chips);
  const pintarChips = () => {
    chips.innerHTML = '';
    for (const v of c.valores || []) {
      const ch = document.createElement('span');
      ch.className = 'chip-valor';
      ch.textContent = v;
      const x = document.createElement('b');
      x.textContent = '✕';
      x.onclick = () => {
        c.valores = c.valores.filter((y) => y !== v);
        pintarChips();
        pintarLista();
      };
      ch.appendChild(x);
      chips.appendChild(ch);
    }
    if (!(c.valores || []).length) {
      const vacio = document.createElement('span');
      vacio.className = 'chip-valor-vacio';
      vacio.textContent = 'Ninguno seleccionado';
      chips.appendChild(vacio);
    }
  };

  // Buscador + tabla
  const buscador = document.createElement('input');
  buscador.className = 'valor buscador-lista';
  buscador.placeholder = 'Buscar ' + (CAMPOS.find((x) => x.campo === c.campo)?.etiqueta || 'valor') + '…';
  buscador.value = c.textoValor || '';
  buscador.oninput = () => {
    c.textoValor = buscador.value;
    pintarLista();
  };

  const tabla = document.createElement('div');
  tabla.className = 'tabla-valores';
  caja.appendChild(buscador);
  caja.appendChild(tabla);

  let pintando = false;
  let cache = null; // {valores, conVista}
  const pintarLista = async () => {
    if (pintando) return;
    pintando = true;
    const texto = (c.textoValor || '').trim();
    const t0 = Date.now();
    if (!cache) {
      cache = await sugerirValores(c.campo, texto);
      if (cache && cache.length && cache[0].total != null) caja.dataset.conVista = '1';
      else delete caja.dataset.conVista;
    }
    const items = cache
      .filter((v) => !texto || String(v.valor).toLowerCase().includes(texto.toLowerCase()))
      .slice(0, 30);
    tabla.innerHTML = '';
    if (!items.length) {
      tabla.innerHTML = '<div class="tabla-vacio">Sin coincidencias</div>';
    } else {
      const enc = document.createElement('div');
      enc.className = 'tabla-fila tabla-encabezado';
      enc.innerHTML = '<span>Valor</span>' + (caja.dataset.conVista ? '<span class="cnt">Sentencias</span>' : '');
      tabla.appendChild(enc);
      for (const it of items) {
        const fila = document.createElement('div');
        fila.className = 'tabla-fila' + ((c.valores || []).includes(it.valor) ? ' seleccionada' : '');
        const sel = document.createElement('span');
        sel.className = 'sel';
        const marca = document.createElement('span');
        marca.className = 'marca';
        marca.textContent = (c.valores || []).includes(it.valor) ? '✓' : '';
        fila.appendChild(marca);
        const nombre = document.createElement('span');
        nombre.className = 'nombre';
        nombre.textContent = it.valor;
        sel.appendChild(nombre);
        fila.appendChild(sel);
        if (caja.dataset.conVista) {
          const cnt = document.createElement('span');
          cnt.className = 'cnt';
          cnt.textContent = Number(it.total).toLocaleString('es-VE');
          fila.appendChild(cnt);
        }
        fila.onclick = () => {
          const pos = (c.valores || []).indexOf(it.valor);
          if (pos >= 0) c.valores.splice(pos, 1);
          else c.valores = [...(c.valores || []), it.valor];
          pintarChips();
          pintarLista();
        };
        tabla.appendChild(fila);
      }
    }
    if (!caja.dataset.conVista && !texto) {
      const nota = document.createElement('div');
      nota.className = 'tabla-nota';
      nota.textContent = 'Sin conteos: la vista de conteos no respondió (reintenta o verifica vistas_conteos_super_buscador.sql).';
      tabla.appendChild(nota);
    }
    pintando = false;
  };

  pintarChips();
  pintarLista();
  return caja;
}

function init() {
  pintarFiltros();
  renderCondiciones();
  // Categorías
  const cats = document.getElementById('categoriaChips');
  for (const c of CATEGORIAS) {
    const el = document.createElement('span');
    el.className = 'chip' + (state.categoria === c ? ' activo' : '');
    el.textContent = c;
    el.dataset.val = c;
    el.onclick = () => { state.categoria = c; if (c !== 'Sentencias') state.sala = null; marcarChips(); buscar(); };
    cats.appendChild(el);
  }
  document.getElementById('btnBuscar').onclick = () => {
    state.texto = document.getElementById('inputTexto').value;
    buscar();
  };
  document.getElementById('inputTexto').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      state.texto = e.target.value;
      buscar();
    }
  });
  document.getElementById('btnMas').onclick = () => {
    if (state.crono.activo) cargarPaginaCrono(false, state.generacion);
    else cargarPagina(false, state.generacion);
  };
  document.getElementById('btnOrden').onclick = () => {
    state.crono.asc = !state.crono.asc;
    document.getElementById('btnOrden').textContent = state.crono.asc ? '⬆ Antiguas primero (2000→)' : '⬇ Recientes primero (←2026)';
    buscar();
  };
  document.getElementById('btnAplicarCondiciones').onclick = () => {
    buscar();
  };
  document.getElementById('btnAvanzado').onclick = () => {
    document.getElementById('panelAvanzado').classList.toggle('abierto');
  };
  buscar();
}
document.addEventListener('DOMContentLoaded', init);
`;

  const hostSsr = (env.SITIO_JURISPRUDENCIA || 'https://penalexve.com').replace(/\/+$/, '');
  const urlRaiz = `${hostSsr}/sentencias`;
  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'CollectionPage',
        name: 'Buscador de Jurisprudencia | Sentencias del TSJ | Penalex',
        description: 'Buscador de sentencias del Tribunal Supremo de Justicia de Venezuela: Sala Constitucional y Sala de Casación Penal.',
        mainEntityOfPage: urlRaiz,
      },
      {
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Inicio', item: `${hostSsr}/` },
          { '@type': 'ListItem', position: 2, name: 'Sentencias' },
        ],
      },
      { '@type': 'Organization', name: 'Penalex VE', url: hostSsr },
    ],
  };

  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large"/>
<title>Buscador de Jurisprudencia | Sentencias del TSJ | Penalex</title>
<meta name="description" content="Buscador de sentencias del Tribunal Supremo de Justicia de Venezuela: Sala Constitucional y Sala de Casación Penal. Busca por texto, número, expediente, ponente, sala, año o materia."/>
<link rel="canonical" href="${urlRaiz}">
<meta property="og:type" content="website">
<meta property="og:title" content="Buscador de Jurisprudencia | Sentencias del TSJ | Penalex">
<meta property="og:description" content="Buscador de sentencias del Tribunal Supremo de Justicia de Venezuela: Sala Constitucional y Sala de Casación Penal.">
<meta property="og:url" content="${urlRaiz}">
<meta property="og:site_name" content="Penalex VE">
<meta property="og:locale" content="es_VE">
<script type="application/ld+json">${JSON.stringify(jsonLd).replace(/undefined/g, 'null')}</script>
<link rel="icon" href="/producto/icono.png" sizes="any" type="image/png"/>
<style>${ESTILO}</style>
</head>
<body>
<header>
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
      <a class="hdr-link" href="/login">Iniciar sesión</a>
      <a class="hdr-btn" href="/login?modo=registro">Crear cuenta</a>
    </div>
    <button class="hdr-burger" aria-label="Abrir menú" aria-expanded="false">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
    </button>
  </div>
  <nav class="hdr-menu" id="hdrMenu" aria-label="Menú móvil">
    <a href="/sentencias">Jurisprudencias</a>
    <a href="/leyes">Leyes</a>
    <a href="/articulos">Blog · Nulidad Absoluta</a>
    <a class="hdr-link" href="/login">Iniciar sesión</a>
    <a class="hdr-btn" href="/login?modo=registro">Crear cuenta</a>
  </nav>
</header>
<main>
  <div class="hero">
    <h1>Buscador de Jurisprudencia</h1>
    <p>Más de 55.000 sentencias de fondo del Tribunal Supremo de Justicia de Venezuela, con texto completo. Busca por número, expediente, ponente, sala, año, materia o contenido.</p>
  </div>

  <div class="barra">
    <input id="inputTexto" type="search" placeholder="Escribe aquí para empezar a buscar…" autocomplete="off"/>
    <button id="btnBuscar">Buscar</button>
  </div>
  <div class="ayuda-sintaxis">AND (espacio) · OR · <b>"frase exacta"</b> · <b>-excluir</b> · número o expediente exacto</div>
  <div class="barra-orden">
    <button id="btnOrden" class="btn-orden">⬆ Antiguas primero (2000 →)</button>
  </div>

  <div class="filtros">
    <div class="grupo">
      <label>Tipo</label>
      <div class="chips" id="categoriaChips"></div>
    </div>
    <div class="grupo">
      <label>Sala</label>
      <div class="chips" id="salaChips"></div>
    </div>
    <div class="grupo">
      <label>Período</label>
      <div class="chips" id="decadaChips" style="margin-bottom:8px"></div>
      <div class="chips"><select id="selectAnio" class="select select-anio"></select></div>
    </div>
  </div>

  <div class="avanzado-toggle">
    <button id="btnAvanzado">🎛️ Modo avanzado (campo · operador · valor)</button>
  </div>
  <div class="avanzado" id="panelAvanzado">
    <div id="condiciones"></div>
    <div class="avanzado-pie">
      <button class="btn-condicion" id="btnAgregarCondicion">+ Añadir condición</button>
      <button class="btn-aplicar" id="btnAplicarCondiciones">Aplicar condiciones</button>
    </div>
  </div>

  <div class="estado" id="estado"><span class="spinner"></span></div>
  <div class="aviso" id="aviso"></div>
  <div class="vacio" id="vacio" style="display:none"></div>
  <div class="resultados" id="resultados">${cardsSsr}</div>
  <div class="mas" id="mas" style="display:none"><button id="btnMas">Cargar más</button></div>
  <footer>Sentencias del Tribunal Supremo de Justicia · Penalex VE</footer>
</main>
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
</html>`;
}