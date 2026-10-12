#!/usr/bin/env node
/**
 * registrar_leyes_supabase.mjs
 * ----------------------------
 * Registra las leyes con SUPABASE STORAGE como fuente de verdad (sin depender
 * de la carpeta local tool/):
 *
 *   1. Lista el bucket público `leyes` (POST /object/list).
 *   2. Descarga cada JSON y VALIDA la estructura que espera la app:
 *        ley_nombre + estructura[] -> articulos[] -> identificador,
 *        texto_principal / encabezado / numerales_literales / paragrafos.
 *      Los archivos con estructura rota se REPORTAN, nunca se borran.
 *   3. Regenera manifest.json desde el bucket (orden de relevancia, total,
 *      artículos, tamaño, URL) y lo sube (x-upsert).
 *   4. Reporta: nuevas, actualizadas, eliminadas y advertencias.
 *
 * Uso local:  node registrar_leyes_supabase.mjs
 * En CI:      SUPABASE_URL y SUPABASE_SERVICE_KEY como env (GitHub Actions).
 * Automático: .github/workflows/leyes_sync.yml (cada 4 h + manual).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BUCKET = 'leyes';

// --- Configuración: env primero; si no, lee .env (uso local) -------------
function leerEnv(archivo) {
  const out = {};
  try {
    for (const linea of fs.readFileSync(archivo, 'utf8').split('\n')) {
      const m = linea.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
      if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  } catch { /* sin .env */ }
  return out;
}

const env = { ...leerEnv(path.join(__dirname, '.env')), ...process.env };
const SUPABASE_URL = (env.SUPABASE_URL || '').replace(/\/+$/, '');
const SERVICE_KEY = env.SUPABASE_SERVICE_KEY || '';
if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('❌ Faltan SUPABASE_URL y/o SUPABASE_SERVICE_KEY (env o .env)');
  process.exit(1);
}

// --- Orden de relevancia (mismo que upload_leyes_supabase.mjs) ------------
const ORDEN = [
  'crbv', 'copp', 'codigo-penal', 'ley-de-violencia',
  'proteccion-de-ninos-ninas-y-adolescentes', 'organica-de-drogas',
  'delincuencia-organizada', 'secuestro-y-la-extorsion', 'delitos-informaticos',
  'contra-la-corrupcion', 'discriminacion-racial', 'prevenir-y-sancionar-la-tortura',
  'desarme-y-control-de-armas', 'penal-del-ambiente', 'ganadera', 'estafa-inmobiliaria',
  'abuso-sexual', 'crimenes-desapariciones', 'contra-el-odio',
  'privacidad-de-las-comunicaciones', 'registro-de-antecedentes-penales',
  'telefonia-celular', 'extinsion-de-dominio', 'amparo-a-la-libertad',
  'amparo-sobre-derechos', 'organico-penitenciario', 'justicia-militar',
  'proteccion-de-victimas', 'estatuto-de-la-funcion-policial',
  'estatuto-de-la-funcion-publica',
  'estatuto-de-la-funcion-de-la-policia-de-investigacion',
  'servicio-de-policia-de-investigacion', 'ministerio-publico',
  'defensa-publica', 'tribunal-supremo-de-justicia', 'jurisdiccion-contencioso',
  'ley-de-abogados', 'juramento-publico', 'publicaciones-oficiales',
  'respeto-de-los-derechos-humanos',
];

const ordenDe = (slug) => {
  for (let i = 0; i < ORDEN.length; i++) if (slug.includes(ORDEN[i])) return i + 1;
  return 999;
};

async function api(ruta, opts = {}) {
  const res = await fetch(`${SUPABASE_URL}${ruta}`, {
    ...opts,
    headers: {
      Authorization: `Bearer ${SERVICE_KEY}`,
      apikey: SERVICE_KEY,
      ...(opts.headers || {}),
    },
  });
  const texto = await res.text();
  let json;
  try { json = JSON.parse(texto); } catch { json = texto; }
  return { res, json, texto };
}

// --- Validación de estructura ---------------------------------------------
function validarEstructura(raw, nombreArchivo) {
  const problemas = [];
  let data;
  try {
    data = JSON.parse(raw);
  } catch (e) {
    return { ok: false, problemas: [`JSON inválido: ${e.message}`], nombre: nombreArchivo, articulos: 0 };
  }
  const nombre = typeof data.ley_nombre === 'string' && data.ley_nombre.trim()
    ? data.ley_nombre.trim()
    : nombreArchivo.replace(/\.json$/i, '');

  // Metadatos de vigencia (opcionales): las leyes derogadas entran al corpus
  // con vigencia='derogada' + fecha_derogacion + sustituida_por (ej. el
  // Código de Enjuiciamiento Criminal, sustituido por el COPP en 1999).
  let vigencia = null;
  if (data.vigencia === 'derogada' || data.vigencia === 'vigente') vigencia = data.vigencia;
  const fechaDerogacion = typeof data.fecha_derogacion === 'string' ? data.fecha_derogacion : null;
  const sustituidaPor = typeof data.sustituida_por === 'string' ? data.sustituida_por : null;
  if (data.vigencia !== undefined && !vigencia) problemas.push(`vigencia inválida: ${data.vigencia}`);
  if (vigencia === 'derogada' && !sustituidaPor) problemas.push('vigencia=derogada requiere sustituida_por');

  if (!Array.isArray(data.estructura)) {
    return { ok: false, problemas: ['falta estructura[] (esperado: array de bloques)'], nombre, articulos: 0 };
  }
  let n = 0;
  for (const bloque of data.estructura) {
    const arts = Array.isArray(bloque?.articulos) ? bloque.articulos : [];
    for (const a of arts) {
      n++;
      if (!a || typeof a !== 'object') { problemas.push('artículo sin objeto'); continue; }
      if (!String(a.identificador || '').trim()) problemas.push('artículo sin identificador');
      const tieneTexto =
        String(a.texto_principal || '').trim() ||
        String(a.encabezado || '').trim() ||
        String(a.texto || '').trim();
      if (!tieneTexto) problemas.push(`art. ${a.identificador || '?'} sin texto`);
    }
  }
  return { ok: problemas.length === 0, problemas: problemas.slice(0, 10), nombre, articulos: n, vigencia, fechaDerogacion, sustituidaPor };
}

// --- Flujo principal --------------------------------------------------------
const { res: listRes, json: lista } = await api(`/storage/v1/object/list/${BUCKET}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ prefix: '', limit: 1000, offset: 0 }),
});
if (!listRes.ok) {
  console.error(`❌ No se pudo listar el bucket: HTTP ${listRes.status} ${JSON.stringify(lista).slice(0, 150)}`);
  process.exit(1);
}

const archivos = (Array.isArray(lista) ? lista : [])
  .filter((o) => typeof o?.name === 'string' && o.name.endsWith('.json') && o.name !== 'manifest.json');

console.log(`📦 Bucket "${BUCKET}": ${archivos.length} leyes encontradas\n`);

const leyes = [];
const advertencias = [];
for (const o of archivos) {
  const { res, texto } = await api(`/storage/v1/object/public/${BUCKET}/${o.name}`);
  if (!res.ok) { advertencias.push(`${o.name}: no se pudo leer (HTTP ${res.status})`); continue; }
  const v = validarEstructura(texto, o.name);
  if (!v.ok) advertencias.push(`⚠️ ${o.name} — ${v.problemas.join('; ')}`);
  const slug = o.name.replace(/\.json$/i, '');
  leyes.push({
    slug,
    archivo: o.name,
    nombre: v.nombre,
    orden: ordenDe(slug),
    articulos: v.articulos,
    tamano: (o.metadata?.size) ?? Buffer.byteLength(texto),
    url: `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${o.name}`,
    // Solo se incluyen cuando la ley declara vigencia (las vigentes actuales
    // conservan exactamente la forma anterior del manifest).
    ...(v.vigencia ? {
      vigencia: v.vigencia,
      fecha_derogacion: v.fechaDerogacion,
      sustituida_por: v.sustituidaPor,
    } : {}),
    _ok: v.ok,
  });
}

leyes.sort((a, b) => a.orden - b.orden || a.nombre.localeCompare(b.nombre));

// Comparar con el manifest anterior
const anterior = await api(`/storage/v1/object/public/${BUCKET}/manifest.json`);
const prevNombres = anterior.res.ok && Array.isArray(anterior.json?.leyes)
  ? new Set(anterior.json.leyes.map((l) => l.slug))
  : new Set();
const nuevos = leyes.filter((l) => !prevNombres.has(l.slug));
const eliminados = [...prevNombres].filter((s) => !leyes.some((l) => l.slug === s));

const manifest = {
  generado: new Date().toISOString(),
  total: leyes.length,
  leyes: leyes.map(({ _ok, ...l }) => l),
};

const { res: manRes } = await api(`/storage/v1/object/${BUCKET}/manifest.json`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'x-upsert': 'true' },
  body: JSON.stringify(manifest),
});

// Copia local informativa (no es fuente de verdad)
fs.writeFileSync(path.join(__dirname, 'leyes_manifest.json'), JSON.stringify(manifest, null, 1));

console.log(`✅ manifest.json: HTTP ${manRes.status} — total ${manifest.total}`);
if (nuevos.length) console.log(`🆕 Nuevas: ${nuevos.map((l) => l.nombre).join(', ')}`);
if (eliminados.length) console.log(`🗑️ Ya no en el bucket (quitadas del manifest): ${eliminados.join(', ')}`);
const sinOrden = leyes.filter((l) => l.orden === 999);
if (sinOrden.length) console.log(`ℹ️ Sin orden asignado (aparecen al final): ${sinOrden.map((l) => l.slug).join(', ')}`);
if (advertencias.length) {
  console.log(`\n⚠️ ADVERTENCIAS (${advertencias.length}):`);
  advertencias.slice(0, 15).forEach((a) => console.log('  ' + a));
} else {
  console.log('\n✅ Estructura de todas las leyes validada correctamente.');
}