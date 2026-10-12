#!/usr/bin/env node
/**
 * upload_equivalencias.mjs
 * ------------------------
 * Carga las equivalencias de artículos derogados -> vigentes (ej. CEC -> COPP)
 * en la tabla `equivalencias_articulos` desde un JSON validado.
 *
 * - El JSON debe tener la forma del borrador: { "equivalencias": [{ ... }] }.
 * - Se cargan SOLO las entradas con articulo_vigente no nulo (las marcadas
 *   "por verificar" se omiten y se reportan).
 * - Upsert sobre el par único (instrumento_derogado, articulo_derogado,
 *   instrumento_vigente, articulo_vigente) — sin duplicados.
 * - RLS: lectura pública; escritura con service key (ignora RLS).
 *
 * Uso: node upload_equivalencias.mjs [ruta_json]
 * Env: SUPABASE_URL, SUPABASE_SERVICE_KEY (o .env junto al script).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

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
const URL_BASE = (env.SUPABASE_URL || '').replace(/\/$/, '');
const SERVICE_KEY = env.SUPABASE_SERVICE_KEY || '';
if (!URL_BASE || !SERVICE_KEY) {
  console.error('Faltan SUPABASE_URL / SUPABASE_SERVICE_KEY');
  process.exit(1);
}

const DRY_RUN = process.argv.includes('--dry-run');
const argRuta = process.argv.slice(2).find((a) => !a.startsWith('--'));
const RUTA = argRuta || path.join(__dirname, 'supabase', 'borrador_equivalencias_cec_copp.json');
const datos = JSON.parse(fs.readFileSync(RUTA, 'utf8'));
const lista = datos.equivalencias ?? [];
console.log(`Total entradas en ${RUTA}: ${lista.length}`);

const aCargar = [];
const omitidas = [];
for (const e of lista) {
  if (e.articulo_vigente && e.instrumento_vigente) {
    aCargar.push({
      instrumento_derogado: e.instrumento_derogado,
      articulo_derogado: e.articulo_derogado,
      instrumento_vigente: e.instrumento_vigente,
      articulo_vigente: e.articulo_vigente,
      nota: e.nota ?? null,
      verificado_por: e.verificado_por ?? null,
    });
  } else {
    omitidas.push(`${e.articulo_derogado} (${e.confianza ?? '?'})`);
  }
}
console.log(`A cargar: ${aCargar.length} | Omitidas (por verificar): ${omitidas.length} -> ${omitidas.join(', ')}`);
if (!aCargar.length) { console.log('Nada que cargar.'); process.exit(0); }

if (DRY_RUN) {
  console.log('DRY-RUN: no se escribe. Primer registro:', JSON.stringify(aCargar[0], null, 2));
  process.exit(0);
}

const COLUMNAS_PAR = ['instrumento_derogado', 'articulo_derogado', 'instrumento_vigente', 'articulo_vigente'];
const r = await fetch(`${URL_BASE}/rest/v1/equivalencias_articulos?on_conflict=${COLUMNAS_PAR.join(',')}`, {
  method: 'POST',
  headers: {
    apikey: SERVICE_KEY,
    Authorization: `Bearer ${SERVICE_KEY}`,
    'Content-Type': 'application/json',
    Prefer: 'resolution=merge-duplicates,return=representation',
  },
  body: JSON.stringify(aCargar),
});

const cuerpo = await r.text();
if (!r.ok) {
  console.error(`ERROR ${r.status}: ${cuerpo.slice(0, 500)}`);
  process.exit(1);
}
console.log(`OK: ${JSON.parse(cuerpo).length} equivalencias cargadas/actualizadas en equivalencias_articulos.`);