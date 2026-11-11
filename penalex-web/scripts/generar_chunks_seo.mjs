#!/usr/bin/env node
/**
 * Penalex VE — Genera chunks de metadatos SEO para el Worker de
 * jurisprudencia (worker-auth-bridge / ruta /html/*).
 *
 * Lee data/sentencias.json (export completo) y produce N chunks compactos:
 *   data/seo_chunks/000.json … 099.json
 *   cada uno: { "<id>": { p, s, f, n, e, j, x, d, m, y } }
 *     p = ponente, s = sala, f = fecha, n = num_sentencia,
 *     e = extracto ANONIMIZADO (recortado; "" si no pasa validación),
 *     r = ratio_decidendi ANONIMIZADO (recortado; "" si no pasa validación),
 *     j = es_jurisprudencia, x = expediente,
 *     d = decisión (anónima), m = procedimiento (anónimo), y = año
 *
 * PRIVACIDAD: las meta descriptions NO deben exponer nombres de personas.
 * e/r/d pasan por anonimización + validación estricta (lista blanca de
 * términos legales/institucionales); si no quedan limpios → "" y el Worker
 * construye la descripción desde m/y (estructura, sin nombres).
 *
 * El Worker calcula el chunk de un id con un hash estable y lee SOLO ese
 * chunk (~140 KB) desde R2 — sin cargar 14 MB por request.
 *
 * Uso: node scripts/generar_chunks_seo.mjs [N=100]
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const N = Number(process.argv[2] ?? 100);

/** Hash estable (FNV-1a) → chunk 0..N-1 para un id dado. */
function chunkDe(id, n) {
  let h = 2166136261;
  for (let i = 0; i < id.length; i++) {
    h ^= id.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return ((h >>> 0) % n + n) % n;
}

function recortar(texto, max) {
  const limpio = String(texto ?? "").replace(/\s+/g, " ").trim();
  if (limpio.length <= max) return limpio;
  const corte = limpio.slice(0, max);
  const esp = corte.lastIndexOf(" ");
  return `${corte.slice(0, esp > 0 ? esp : max).trim()}…`;
}

/* ---------- Anonimización de nombres de personas (misma lógica que la
 * validación hecha en Python sobre el corpus completo; ver data/blanca_seo.json) */
const BLANCA = new Set(JSON.parse(readFileSync(join(ROOT, "data", "blanca_seo.json"), "utf8")));

const CAP = "[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}";
const SEQ = `${CAP}(?:\\s+(?:de|la|del|los|las|y|de la|de los|de las|van|von)?\\s+${CAP}){0,3}`;
const LISTA = `${SEQ}(?:\\s+(?:y|,|o|con)\\s+${SEQ})?`;
const RE_MAYUS = /\b(?:[A-ZÁÉÍÓÚÑ]{3,}\s+){2,}[A-ZÁÉÍÓÚÑ]{3,}\b/g;
const RE_PREP = new RegExp(`\\b(?:de|del|a|al|por|entre|contra|ante|para|hacia|desde|sin|según|segun)\\s+(${LISTA})\\b`, "g");
const ROLES = "abogado|abogada|ciudadano|ciudadana|defensor|defensora|recurrente|accionante|demandante|demandada|actor|actora|imputado|imputada|acusado|acusada|víctima|victima|agraviado|agraviada|magistrado|magistrada|juez|testigo|denunciante|querellante|apoderado|apoderada|reo|sentenciado|sentenciada|condenado|condenada|procesado|procesada|ofendido|ofendida|representante|funcionario|funcionaria|director|directora|presidente|presidenta|gerente|supervisor|supervisora|parte";
const RE_ROL = new RegExp(`\\b(${ROLES})\\s+(${LISTA})\\b`, "g");
const RE_RESID = new RegExp(`\\b(?:${CAP}\\s+){2,}${CAP}\\b`, "g");
const RE_PARTE_SUELTA = /\bla parte\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}/i;
const RE_ROL_SUELTO = new RegExp(`\\b(?:abogado|ciudadano|defensor|demandante|accionante|imputado|acusado|recurrente|apoderado|representante|magistrado|ponente)\\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}`, "i");

function esPersona(seq) {
  const pal = seq.match(/[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+/g) || [];
  return pal.length > 0 && pal.every((p) => !BLANCA.has(p.toLowerCase()));
}

/** Sustituye nombres de personas por "la parte" (anónimo). */
function anonimizar(texto) {
  let t = String(texto ?? "").replace(RE_MAYUS, "la parte");
  t = t.replace(RE_PREP, (m, g1) => (esPersona(g1) ? "la parte" : m));
  t = t.replace(RE_ROL, (m, rol, g2) => (esPersona(g2) ? rol : m));
  t = t.replace(/\bla parte\s+(?:la parte\s+)+/gi, "la parte ");
  return t.replace(/\s{2,}/g, " ").trim();
}

/** Validación estricta: sin nombres residuales ni frases rotas. */
function esLimpio(t) {
  for (const m of t.matchAll(RE_RESID)) {
    const pal = m[0].match(/[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+/g) || [];
    if (pal.length > 0 && pal.every((p) => !BLANCA.has(p.toLowerCase()))) return false;
  }
  if (RE_PARTE_SUELTA.test(t)) return false;
  if (RE_ROL_SUELTO.test(t)) return false;
  return true;
}

/** Devuelve el texto anonimizado si pasa la validación y tiene longitud útil. */
function limpioO(txt, minLen = 40) {
  const an = anonimizar(txt);
  return esLimpio(an) && an.length >= minLen ? an : "";
}

const payload = JSON.parse(readFileSync(join(ROOT, "data", "sentencias.json"), "utf8"));
const chunks = Array.from({ length: N }, () => ({}));

for (const s of payload.sentencias) {
  const meta = {
    p: String(s.ponente ?? ""),
    s: String(s.sala ?? ""),
    f: String(s.fecha ?? ""),
    n: String(s.num_sentencia ?? ""),
    e: recortar(limpioO(s.extracto), 420),
    r: recortar(limpioO(s.ratio_decidendi), 420),
    j: String(s.es_jurisprudencia ?? ""),
    x: String(s.expediente ?? ""),
    d: recortar(limpioO(s.decision, 30), 420),
    m: recortar(limpioO(s.procedimiento, 5), 420),
    y: String(s.anio ?? ""),
  };
  chunks[chunkDe(s.id, N)][s.id] = meta;
}

const salida = join(ROOT, "data", "seo_chunks");
mkdirSync(salida, { recursive: true });
let bytes = 0;
let conExtracto = 0;
let soloEstructura = 0;
for (let i = 0; i < N; i++) {
  const nombre = join(salida, `${String(i).padStart(3, "0")}.json`);
  const buf = Buffer.from(JSON.stringify(chunks[i]));
  writeFileSync(nombre, buf);
  bytes += buf.length;
}
for (const c of chunks) {
  for (const id in c) {
    if (c[id].e || c[id].r) conExtracto++;
    else soloEstructura++;
  }
}
console.log(`✅ ${N} chunks → ${salida} (${Math.round((bytes / 1024 / 1024) * 10) / 10} MB total)`);
console.log(`Ejemplo chunk 000: ${Object.keys(chunks[0]).length} ids`);
console.log(`Con extracto/ratio anónimo: ${conExtracto} | solo estructura: ${soloEstructura}`);