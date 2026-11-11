#!/usr/bin/env node
/**
 * Penalex VE — Genera el índice plano de artículos para el buscador web de
 * /leyes (equivalente al penalex_indice_leyes_v3.json de la app Flutter).
 *
 * Lee data/leyes/{slug}.json y produce data/leyes/indice.json con un registro
 * ligero por artículo: { slug, ley, id, enc, txt } donde txt son los primeros
 * caracteres del texto (el buscador filtra; el artículo completo se abre en
 * su propia página indexable).
 *
 * Uso: node scripts/generar_indice_leyes.mjs
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DIR = join(ROOT, "data", "leyes");

/** Slug de un identificador de artículo: "100" → "100"; "Preámbulo" → "preambulo". */
function slugArticulo(id) {
  const t = String(id || "").trim();
  if (/^\d+$/.test(t)) return t.replace(/^0+/, "") || "0";
  return t
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

const manifest = JSON.parse(readFileSync(join(DIR, "manifest.json"), "utf8"));
const registros = [];
const LIMITE_TEXTO = 300;

/** Rubro temático sin inventar texto: encabezado real, o derivado del título
 *  de sección/capítulo/título/libro del propio documento (materia real). */
const REG_PREFIJO_NIVEL = /^(?:T[IÍ]TULO|CAP[IÍ]TULO|SECCI[OÓ]N|LIBRO)\b[^:.]*[.:—–-]\s*/i;
const MAX_RUBRO = 64;
function normalizarCaps(t) {
  if (t !== t.toUpperCase()) return t;
  return t
    .toLowerCase()
    .split(/\s+/)
    .map((w) => (w === w.toUpperCase() && w.length <= 4 ? w : w.charAt(0).toUpperCase() + w.slice(1)))
    .join(" ");
}
function rubroDe(art, bloque) {
  const propio = String(art?.encabezado || "").trim();
  if (propio) return propio;
  const b = bloque || {};
  const candidatos = [b.seccion, b.capitulo, b.titulo, b.libro];
  for (const raw of candidatos) {
    if (!raw) continue;
    let t = String(raw).trim().replace(/\s+/g, " ");
    t = t.replace(REG_PREFIJO_NIVEL, "").trim();
    if (!t) continue;
    const corte = t.search(/[.,](?=\s)/);
    if (corte > 12) t = t.slice(0, corte).trim();
    t = normalizarCaps(t);
    t = t.charAt(0).toUpperCase() + t.slice(1);
    if (t.length > MAX_RUBRO) {
      const cortePalabra = t.lastIndexOf(" ", MAX_RUBRO);
      t = (cortePalabra > 24 ? t.slice(0, cortePalabra) : t.slice(0, MAX_RUBRO)).trim() + "…";
    }
    return t;
  }
  return "";
}

for (const meta of manifest.leyes) {
  let ley;
  try {
    ley = JSON.parse(readFileSync(join(DIR, `${meta.slug}.json`), "utf8"));
  } catch {
    console.warn(`⚠️ No se pudo leer ${meta.slug}.json`);
    continue;
  }
  // Deduplicación de slugs dentro de la misma ley (mismo orden que el worker:
  // primera aparición sin sufijo, luego -2, -3…). Garantiza que el enlace del
  // buscador apunte a la URL real servida por el worker.
  const usados = new Map();
  for (const bloque of ley.estructura || []) {
    for (const art of bloque.articulos || []) {
      const txt = String(art.texto_principal || "").replace(/\s+/g, " ").trim();
      let aid = slugArticulo(art.identificador);
      const n = usados.get(aid) || 0;
      usados.set(aid, n + 1);
      if (n > 0) aid = `${aid}-${n + 1}`;
      registros.push({
        slug: meta.slug,
        ley: meta.nombre,
        id: String(art.identificador || ""),
        aid,
        enc: art.encabezado || "",
        rubro: rubroDe(art, bloque),
        txt: txt.slice(0, LIMITE_TEXTO),
      });
    }
  }
}

writeFileSync(join(DIR, "indice.json"), JSON.stringify(registros));
const KB = (Buffer.byteLength(JSON.stringify(registros)) / 1024).toFixed(0);
console.log(`✅ indice.json: ${registros.length} artículos · ${KB} KB → data/leyes/indice.json`);