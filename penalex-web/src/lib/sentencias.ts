import { readFileSync } from "node:fs";
import { join } from "node:path";

/**
 * Carga data/sentencias.json generado por scripts/exportar_sentencias.mjs.
 *
 * El archivo (~50 MB) se lee UNA vez en el proceso de build y se cachea en
 * memoria: generateStaticParams y las 55K páginas lo comparten, sin volver
 * a golpear Supabase ni re-leer el disco.
 */

export interface SentenciaIndexable {
  id: string;
  slug: string;
  tipo: string;
  sala: string;
  num_sentencia: string;
  fecha: string;
  ponente: string;
  procedimiento: string;
  partes: string;
  decision: string;
  extracto: string;
  ratio_decidendi: string;
  es_jurisprudencia: string;
  anio: string;
  expediente: string;
  r2_html_key: string;
  created_at: string;
}

interface Payload {
  generado: string;
  total: number;
  sentencias: SentenciaIndexable[];
}

let cache: Payload | null = null;

export function cargarSentencias(): Payload {
  if (cache) return cache;
  const ruta = join(process.cwd(), "data", "sentencias.json");
  const raw = readFileSync(ruta, "utf8");
  cache = JSON.parse(raw) as Payload;
  return cache;
}

/** Todos los slugs indexables (para generateStaticParams). */
export function listarSlugs(): string[] {
  return cargarSentencias().sentencias.map((s) => s.slug);
}

/** Busca por slug. Devuelve null si no existe. */
export function buscarPorSlug(slug: string): SentenciaIndexable | null {
  const datos = cargarSentencias();
  const s = datos.sentencias.find((x) => x.slug === slug);
  return s ?? null;
}

const MESES_ES: Record<string, string> = {
  enero: "01", febrero: "02", marzo: "03", abril: "04", mayo: "05",
  junio: "06", julio: "07", agosto: "08", septiembre: "09",
  octubre: "10", noviembre: "11", diciembre: "12",
};

/** Convierte una fecha TSJ a ISO (aaaa-mm-dd) para el schema. */
export function fechaIso(fecha: string): string {
  if (!fecha) return "";
  const f = fecha.trim();
  // "28/02/2008" o "28-02-2008" -> 2008-02-28
  const num = f.match(/^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$/);
  if (num) {
    return `${num[3]}-${num[2].padStart(2, "0")}-${num[1].padStart(2, "0")}`;
  }
  // "9 de septiembre de 2004" -> 2004-09-09
  const es = f.toLowerCase().match(/^(\d{1,2})\s+de\s+([a-záéíóúñ]+)\s+de\s+(\d{4})$/);
  if (es) {
    const mes = MESES_ES[es[2]];
    if (mes) return `${es[3]}-${mes}-${es[1].padStart(2, "0")}`;
  }
  // Ya es ISO (aaaa-mm-dd)
  const iso = f.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (iso) return iso[0];
  return f;
}

const NOMBRES_SALAS: Record<string, string> = {
  scp: "Sala de Casación Penal del Tribunal Supremo de Justicia",
  scon: "Sala Constitucional del Tribunal Supremo de Justicia",
  scs: "Sala de Casación Social del Tribunal Supremo de Justicia",
  sca: "Sala Político-Administrativa del Tribunal Supremo de Justicia",
  scc: "Sala de Casación Civil del Tribunal Supremo de Justicia",
  se: "Sala Electoral del Tribunal Supremo de Justicia",
};

export function nombreSala(codigo: string): string {
  return NOMBRES_SALAS[codigo.toLowerCase()] ?? "Tribunal Supremo de Justicia de Venezuela";
}

/** Recorta un texto a N caracteres sin cortar palabras (para meta description). */
export function recortar(texto: string, max: number): string {
  const limpio = texto.replace(/\s+/g, " ").trim();
  if (limpio.length <= max) return limpio;
  const corte = limpio.slice(0, max);
  const ultimoEspacio = corte.lastIndexOf(" ");
  return `${corte.slice(0, ultimoEspacio > 0 ? ultimoEspacio : max).trim()}…`;
}