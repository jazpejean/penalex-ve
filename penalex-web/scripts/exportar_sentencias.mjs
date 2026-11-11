#!/usr/bin/env node
/**
 * Penalex VE — Exporta las sentencias indexables a data/sentencias.json.
 *
 * Solo sentencias DE FONDO (es_mero_tramite = false): las de mero trámite
 * son autos interlocutorios sin decisión de fondo y no generan retención.
 *
 * Se pagina con Range (1000 filas por request, ~56 requests) para NO
 * golpear el rate-limit del free tier de Supabase (la web NO hace llamadas
 * por página en build: todo sale de este JSON local).
 *
 * Uso:  node scripts/exportar_sentencias.mjs
 * Env:  SUPABASE_URL, SUPABASE_ANON_KEY (lee de penalex-web/.env.local o
 *       ../.env si no están en el entorno).
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const TAMANO_PAGINA = 1000;

// ---------------------------------------------------------------------------
// Env: variables de entorno → penalex-web/.env.local → ../.env
// ---------------------------------------------------------------------------
function leerEnv(path) {
  try {
    return fsLeer(path)
      .split("\n")
      .filter((l) => l.trim() && !l.trim().startsWith("#"))
      .reduce((acc, l) => {
        const eq = l.indexOf("=");
        if (eq <= 0) return acc;
        acc[l.slice(0, eq).trim()] = l.slice(eq + 1).trim().replace(/^["']|["']$/g, "");
        return acc;
      }, {});
  } catch {
    return {};
  }
}

function fsLeer(path) {
  return readFileSync(path, "utf8");
}

const env = {
  ...leerEnv(join(ROOT, ".env.local")),
  ...leerEnv(join(ROOT, "..", ".env")),
  ...process.env,
};

const URL_BASE = (env.SUPABASE_URL ?? env.NEXT_PUBLIC_SUPABASE_URL ?? "").replace(/\/+$/, "");
const ANON = env.SUPABASE_ANON_KEY ?? env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

if (!URL_BASE || !ANON) {
  console.error("❌ Falta SUPABASE_URL / SUPABASE_ANON_KEY (penalex-web/.env.local o ../.env)");
  process.exit(1);
}

// Columnas necesarias para la landing SEO (nada de search_vector ni
// contenido pesado: el texto íntegro se sirve desde R2).
const COLUMNAS =
  "id,tipo,sala,num_sentencia,fecha,ponente,procedimiento,partes,decision,extracto,ratio_decidendi,es_jurisprudencia,anio,expediente,r2_html_key,created_at";

const FILTROS = "es_mero_tramite=eq.false";

// ---------------------------------------------------------------------------
// Paginación con reintentos
// ---------------------------------------------------------------------------
async function descargarPagina(offset) {
  const url =
    `${URL_BASE}/rest/v1/sentencias?select=${encodeURIComponent(COLUMNAS)}` +
    `&${FILTROS}&order=fecha.desc` +
    `&offset=${offset}&limit=${TAMANO_PAGINA}`;
  const headers = {
    apikey: ANON,
    authorization: `Bearer ${ANON}`,
    prefer: "count=exact",
  };
  for (let intento = 1; intento <= 3; intento++) {
    try {
      const res = await fetch(url, {
        headers,
        // La conexión a Supabase desde VE es lenta (~8s a veces): timeout
        // generoso para no abortar consultas legítimas.
        signal: AbortSignal.timeout(45000),
      });
      if (res.status === 429 || res.status === 500 || res.status === 503) {
        const espera = 2000 * intento + Math.floor(Math.random() * 1000);
        console.warn(`⚠️ HTTP ${res.status} en offset ${offset}; reintento ${intento} en ${espera}ms`);
        await new Promise((r) => setTimeout(r, espera));
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status} en offset ${offset}`);
      const total = Number((res.headers.get("content-range") ?? "").split("/")[1] ?? 0);
      const filas = await res.json();
      return { filas, total };
    } catch (e) {
      if (intento === 3) throw e;
      const espera = 2000 * intento;
      console.warn(`⚠️ ${e.message}; reintento ${intento} en ${espera}ms`);
      await new Promise((r) => setTimeout(r, espera));
    }
  }
  throw new Error(`No se pudo descargar offset ${offset}`);
}

// ---------------------------------------------------------------------------
// Slug: URL amigable y estable por sentencia. El id del TSJ puede traer
// puntos, espacios o ".HTM" (7/1000 casos): se normaliza a [a-z0-9-] y se
// guarda el mapa slug -> id para el lookup exacto en build.
// ---------------------------------------------------------------------------
function normalizarSlug(id) {
  return String(id)
    .trim()
    .toLowerCase()
    .replace(/\.htm$/, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-{2,}/g, "-")
    .replace(/^-|-$/g, "");
}

async function main() {
  console.log(`🔍 Exportando sentencias de fondo desde ${URL_BASE}…`);

  // Primera página para conocer el total.
  const primera = await descargarPagina(0);
  const total = primera.total || 0;
  console.log(`📊 Total indexable: ${total} sentencias (es_mero_tramite=false)`);

  const todas = [...primera.filas];
  const paginas = Math.ceil(total / TAMANO_PAGINA);
  for (let p = 1; p < paginas; p++) {
    const offset = p * TAMANO_PAGINA;
    const { filas } = await descargarPagina(offset);
    todas.push(...filas);
    if (p % 10 === 0 || p === paginas - 1) {
      console.log(`  … ${todas.length}/${total} (${Math.round((todas.length / total) * 100)}%)`);
    }
    // Espacio entre páginas para no saturar el rate-limit.
    await new Promise((r) => setTimeout(r, 120));
  }

  // Normalización mínima: strings, sin nulos + slug único.
  const vistos = new Map();
  const sentencias = todas.map((f) => {
    const s = {};
    for (const k of COLUMNAS.split(",")) {
      const v = f[k];
      s[k] = v == null ? "" : typeof v === "object" ? JSON.stringify(v) : String(v);
    }
    let slug = normalizarSlug(s.id);
    // Garantizar unicidad del slug (colisión improbable, pero segura).
    if (vistos.has(slug)) {
      let n = 2;
      const base = slug;
      while (vistos.has(`${base}-${n}`)) n++;
      slug = `${base}-${n}`;
    }
    vistos.set(slug, true);
    s.slug = slug;
    return s;
  });

  const payload = {
    generado: new Date().toISOString(),
    total: sentencias.length,
    filtro: FILTROS,
    sentencias,
  };

  const salida = join(ROOT, "data", "sentencias.json");
  mkdirSync(dirname(salida), { recursive: true });
  writeFileSync(salida, JSON.stringify(payload));
  console.log(`✅ ${sentencias.length} sentencias → ${salida} (${Math.round(Buffer.byteLength(JSON.stringify(payload)) / 1024 / 1024 * 10) / 10} MB)`);
}

main().catch((e) => {
  console.error("❌", e);
  process.exit(1);
});