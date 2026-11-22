/**
 * Penalex VE — SEO de jurisprudencia servida desde R2.
 *
 * El bucket público de R2 (penalex-jurisprudencia) contiene los HTML
 * íntegros de las sentencias (HTML de Word, sin metadatos). Este módulo
 * inyecta al vuelo (HTMLRewriter): <title>, meta description, canonical,
 * OpenGraph y JSON-LD LegalCase, tomando los metadatos de chunks en R2
 * (seo_chunks/NNN.json, generados por scripts/generar_chunks_seo.mjs).
 *
 * Ruta:  GET /html/sala/anio/EXPEDIENTE.html  →  HTML enriquecido
 * Env:   R2_JURISPRUDENCIA  (binding R2 al bucket penalex-jurisprudencia)
 *        SITIO_JURISPRUDENCIA (https://penalexve.com, para canonical)
 */

const N_CHUNKS = 100;
const cacheChunks = new Map(); // chunkIdx -> objeto {id: meta}

/** Hash FNV-1a estable → chunk 0..N-1 (igual que el generador). */
function chunkDe(id, n) {
  let h = 2166136261;
  for (let i = 0; i < id.length; i++) {
    h ^= id.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return (((h >>> 0) % n) + n) % n;
}

async function cargarChunk(env, idx) {
  if (cacheChunks.has(idx)) return cacheChunks.get(idx);
  const key = `seo_chunks/${String(idx).padStart(3, '0')}.json`;
  const obj = await env.R2_JURISPRUDENCIA.get(key);
  if (!obj) return null;
  const texto = await obj.text();
  const datos = JSON.parse(texto);
  cacheChunks.set(idx, datos);
  return datos;
}

const NOMBRES_SALAS = {
  scp: 'Sala de Casación Penal del Tribunal Supremo de Justicia',
  scon: 'Sala Constitucional del Tribunal Supremo de Justicia',
  scs: 'Sala de Casación Social del Tribunal Supremo de Justicia',
  sca: 'Sala Político-Administrativa del Tribunal Supremo de Justicia',
  scc: 'Sala de Casación Civil del Tribunal Supremo de Justicia',
  se: 'Sala Electoral del Tribunal Supremo de Justicia',
};


// Mapa de sentencias clave → artículo del blog (enlaces internos para SEO:
// Google sigue estos enlaces desde páginas ya indexadas hacia los artículos).
const BLOG_POR_SENTENCIA = {
  // Dolo eventual
  '490-12411-2011-10-0681': ['dolo-eventual-venezuela.html', 'Dolo eventual en Venezuela: la frontera entre 5 y 18 años'],
  '356650-397-12626-2026-C26-178': ['dolo-eventual-venezuela.html', 'Dolo eventual en Venezuela: la frontera entre 5 y 18 años'],
  '554-291009-2009-C09-097': ['dolo-eventual-venezuela.html', 'Dolo eventual en Venezuela: la frontera entre 5 y 18 años'],
  '176980-242-4515-2015-C14-158': ['dolo-eventual-venezuela.html', 'Dolo eventual en Venezuela: la frontera entre 5 y 18 años'],
  '1463-091100-C00997': ['dolo-eventual-venezuela.html', 'Dolo eventual en Venezuela: la frontera entre 5 y 18 años'],
  '1703-211200-C000859': ['dolo-eventual-venezuela.html', 'Dolo eventual en Venezuela: la frontera entre 5 y 18 años'],
  '302-14813-2013-C13-48': ['dolo-eventual-venezuela.html', 'Dolo eventual en Venezuela: la frontera entre 5 y 18 años'],
  // Nulidad absoluta
  '357475-446-21026-2026-C26-181': ['la-nulidad-como-garantia.html', 'Nulidad absoluta en el proceso penal venezolano'],
  '354868-0416-9426-2026-25-0400': ['la-nulidad-como-garantia.html', 'Nulidad absoluta en el proceso penal venezolano'],
  '338062-510-231024-2024-C24-364': ['la-nulidad-como-garantia.html', 'Nulidad absoluta en el proceso penal venezolano'],
};

function bloqueBlog(id, sitioRaiz) {
  const e = BLOG_POR_SENTENCIA[id];
  if (!e) return null;
  const [archivo, titulo] = e;
  const href = `${sitioRaiz}/articulos/${archivo}`;
  return `<div style="margin:18px 0;padding:14px 16px;background:#f6f4ec;border-left:4px solid #C5A059;border-radius:6px;font-family:-apple-system,'Segoe UI',Roboto,sans-serif;font-size:14px;line-height:1.5;">
    <strong style="color:#031F4E;">Análisis completo en Nulidad Absoluta:</strong>
    <a href="${href}" style="color:#031F4E;font-weight:600;text-decoration:underline;">${titulo} →</a>
  </div>`;
}

function nombreSala(codigo) {
  return NOMBRES_SALAS[String(codigo || '').toLowerCase()] ||
    'Tribunal Supremo de Justicia de Venezuela';
}

function fechaIso(fecha) {
  if (!fecha) return '';
  const f = String(fecha).trim();
  const num = f.match(/^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$/);
  if (num) return `${num[3]}-${num[2].padStart(2, '0')}-${num[1].padStart(2, '0')}`;
  const es = f.toLowerCase().match(/^(\d{1,2})\s+de\s+([a-záéíóúñ]+)\s+de\s+(\d{4})$/);
  const MESES = {
    enero: '01', febrero: '02', marzo: '03', abril: '04', mayo: '05',
    junio: '06', julio: '07', agosto: '08', septiembre: '09',
    octubre: '10', noviembre: '11', diciembre: '12',
  };
  if (es && MESES[es[2]]) return `${es[3]}-${MESES[es[2]]}-${es[1].padStart(2, '0')}`;
  const iso = f.match(/^(\d{4})-(\d{2})-(\d{2})/);
  return iso ? iso[0] : f;
}

function recortar(texto, max) {
  const limpio = String(texto || '').replace(/\s+/g, ' ').trim();
  if (limpio.length <= max) return limpio;
  const corte = limpio.slice(0, max);
  const esp = corte.lastIndexOf(' ');
  return `${corte.slice(0, esp > 0 ? esp : max).trim()}…`;
}

/**
 * Número real de la sentencia para SEO. Algunas filas traen num_sentencia
 * corrupto: la fecha DDMMYY del nombre del archivo (p. ej. "230501") en vez
 * del número real. El número real siempre es el primer segmento del nombre
 * del archivo (NNNN-DDMMYY-...), p. ej. "0348" de "0348-230501-C010100.html".
 */
function numeroSentenciaSeo(meta, id) {
  const n = String(meta?.n || '').trim();
  const d = Number(n.slice(0, 2));
  const m = Number(n.slice(2, 4));
  if (/^\d{6}$/.test(n) && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
    const primer = String(id || '').split('-')[0];
    if (/^\d+$/.test(primer)) return primer;
  }
  return n || meta?.x || id;
}

/** Inyecta el bloque <head> enriquecido antes de </head>. */
function buildHead(meta, id, urlPublica, sitioRaiz) {
  const sala = nombreSala(meta?.s);
  const numero = numeroSentenciaSeo(meta, id);
  const titulo = `Sentencia ${numero ? `Nº ${numero} · ` : ''}${sala} | Penalex`;
  // Descripción SIN nombres de personas (privacidad): extracto o ratio ya
  // vienen anonimizados desde el generador de chunks; si no hay ninguno,
  // se construye una estructura segura con procedimiento/año/decisión.
  const fallback = `Sentencia de la ${sala}${meta?.y ? ` (${meta.y})` : ''}${meta?.m ? `: ${meta.m}` : ''}${meta?.d ? `. ${String(meta.d).replace(/\.$/, '')}` : ''}.`;
  const descripcion = recortar(meta?.e || meta?.r || fallback, 158);
  const fecha = fechaIso(meta?.f);
  // El canonical usa la URL pública REAL (raíz con /sentencias/...):
  // así Google no ve duplicados entre hosts ni rutas.
  const url = urlPublica;

  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'LegalCase',
        name: `Sentencia ${numero} · ${sala}`,
        court: { '@type': 'Court', name: sala },
        judge: meta?.p ? { '@type': 'Person', name: meta.p } : undefined,
        datePublished: fecha || undefined,
        legalStatus: meta?.j === 'true' ? 'Jurisprudencia' : 'Sentencia',
        caseNumber: numero,
        description: descripcion,
        mainEntityOfPage: url,
      },
      {
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Jurisprudencia', item: `${sitioRaiz}/sentencias` },
          { '@type': 'ListItem', position: 2, name: numero },
        ],
      },
      {
        '@type': 'Organization',
        name: 'Penalex VE',
        url: sitioRaiz,
      },
    ],
  };

  return `
<meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
<title>${titulo.replace(/</g, '&lt;')}</title>
<meta name="description" content="${descripcion.replace(/"/g, '&quot;')}">
<link rel="canonical" href="${url}">
<meta property="og:type" content="article">
<meta property="og:title" content="${titulo.replace(/</g, '&lt;')}">
<meta property="og:description" content="${descripcion.replace(/"/g, '&quot;')}">
<meta property="og:url" content="${url}">
<meta property="og:site_name" content="Penalex VE">
<meta property="og:locale" content="es_VE">
<script type="application/ld+json">${JSON.stringify(jsonLd).replace(/undefined/g, 'null')}</script>
`;
}

/** GET /sentencias/... o /html/... → HTML enriquecido.
 *  /sentencias/scon/2004/x.html → key html/scon/2004/x.html
 *  /html/scon/2004/x.html       → key scon/2004/x.html (compatibilidad) */
export async function servirHtmlConSeo(env, url) {
  const path = decodeURIComponent(url.pathname); // decodifica %20 (nombres con espacio)
  let key = null;
  let rutaPublica = '';
  let m = path.match(/^\/sentencias\/(.+)$/);
  if (m) {
    key = `html/${m[1]}`;
    rutaPublica = path; // /sentencias/... es la URL pública canónica
  } else {
    m = path.match(/^\/html\/(.+)$/);
    if (m) {
      key = m[1];
      rutaPublica = `/sentencias/${m[1]}`;
    }
  }
  if (!key) return null;

  const nombreArchivo = key.split('/').pop() || '';
  const id = nombreArchivo.replace(/\.html$/i, '');

  const obj = await env.R2_JURISPRUDENCIA.get(key);
  if (!obj) return new Response('No encontrada', { status: 404 });

  // Sentencias en blanco/defectuosas de la fuente TSJ: archivos diminutos
  // (0-2 KB, solo markup sin contenido). Se rechazan con 404 para que
  // Google no las indexe. Un HTML de Word real supera siempre los 2 KB.
  if (obj.size < 2048) {
    return new Response('No encontrada (contenido vacío)', { status: 404 });
  }

  const sitioRaiz = (env.SITIO_JURISPRUDENCIA || 'https://penalexve.com').replace(/\/+$/, '');
  const host = url.hostname; // penalexve.com (raíz) o sentencias.penalexve.com
  const urlPublica = `https://${host}${rutaPublica}`;

  // Metadatos: chunk por id (solo ~200 KB por request).
  let meta = null;
  try {
    const idx = chunkDe(id, N_CHUNKS);
    const chunk = await cargarChunk(env, idx);
    meta = chunk ? chunk[id] : null;
  } catch (e) {
    console.error('chunk metadatos falló:', e.message);
  }

  const head = buildHead(meta, id, urlPublica, sitioRaiz);
  const body = await obj.arrayBuffer();

  // HTMLRewriter: inyecta el head antes de </head>.
  // Los HTML de Word traen su propio <title> (el nombre del archivo); se
  // eliminan para que quede UN solo <title>, el del SEO, y el bloque se
  // antepone al head (así Google nunca ve el título del archivo).
  const rewriter = new HTMLRewriter()
    .on('body', {
      element(el) {
        const bloque = bloqueBlog(id, sitioRaiz);
        if (bloque) el.prepend(bloque, { html: true });
      },
    })
    .on('title', {
      element(el) {
        el.remove();
      },
    })
    .on('head', {
      element(el) {
        el.prepend(head, { html: true });
      },
    });

  const response = new Response(body, {
    headers: { 'content-type': 'text/html; charset=utf-8' },
  });
  return rewriter.transform(response);
}