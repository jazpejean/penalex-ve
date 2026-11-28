import { supabase } from "./supabase";

export interface Tribunal {
  id: string;
  codigo: string;
  nombre: string;
  sede?: string | null;
  estado: string;
  municipio?: string | null;
  parroquia?: string | null;
  latitud?: number | null;
  longitud?: number | null;
  instancia: string;
  funcion?: string | null;
  seccion?: string | null;
  tipo_sede?: string | null;
  despacho?: string;
  url_foto?: string | null;
}

/** Catálogo público de tribunales penales (tabla publica, RLS lectura pública). */
export async function listarTribunalesConUbicacion(): Promise<Tribunal[]> {
  const { data, error } = await supabase
    .from("tribunales")
    .select(
      "id, codigo, nombre, sede, estado, municipio, parroquia, latitud, longitud, materia, instancia, funcion, seccion, tipo_sede, condicion_sede, url_foto",
    )
    .not("latitud", "is", null)
    .not("longitud", "is", null)
    .order("estado")
    .order("nombre");

  if (error) throw error;
  return (data as Tribunal[]) ?? [];
}

export async function listarEstadosTribunales(): Promise<string[]> {
  const { data, error } = await supabase
    .from("tribunales")
    .select("estado")
    .order("estado");

  if (error) throw error;
  return [...new Set((data ?? []).map((r: any) => r.estado as string))].sort();
}
/** Slug URL-safe para el estado (ej. "Nueva Esparta" → "nueva-esparta"). */
export function slugEstado(estado: string): string {
  return estado
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

/** Todos los tribunales (sin filtro de coordenadas) — para listados SEO. */
export async function listarTribunales(): Promise<Tribunal[]> {
  const { data, error } = await supabase
    .from("tribunales")
    .select()
    .order("estado")
    .order("nombre");
  if (error) throw error;
  return (data as Tribunal[]) ?? [];
}

/** Tribunales de un estado, ordenados por municipio y nombre. */
export async function listarTribunalesPorEstado(
  estado: string,
): Promise<Tribunal[]> {
  const { data, error } = await supabase
    .from("tribunales")
    .select()
    .eq("estado", estado)
    .order("municipio")
    .order("nombre");
  if (error) throw error;
  return (data as Tribunal[]) ?? [];
}

/** Conteo de tribunales por estado (para el directorio indexable). */
export async function contarPorEstado(): Promise<Record<string, number>> {
  const { data, error } = await supabase.from("tribunales").select("estado");
  if (error) throw error;
  const conteo: Record<string, number> = {};
  for (const r of data ?? []) {
    const e = (r as { estado: string }).estado;
    conteo[e] = (conteo[e] ?? 0) + 1;
  }
  return conteo;
}

/** Nombre legible del estado ("BOLIVARIANO DE MIRANDA" → "Bolivariano de Miranda"). */
export function tituloEstado(estado: string): string {
  const menores = new Set(["de", "del", "la", "el", "los", "las", "y", "e"]);
  return estado
    .toLowerCase()
    .split(/\s+/)
    .map((w, i) =>
      i > 0 && menores.has(w) ? w : w.charAt(0).toUpperCase() + w.slice(1),
    )
    .join(" ");
}

/** Circunscripción judicial / sede de agrupación.
 *
 * - Si la sede menciona "CIRCUITO", se usa el circuito (ej. "Circuito Judicial
 *   Penal del Estado Miranda - Extensión Barlovento").
 * - Si no, se usa la SEDE (ej. "Palacio de Justicia Los Teques"), que es el
 *   grupo natural de tribunales de un mismo edificio (Los Teques = 15).
 * - Sin sede, cae al estado.
 */
export function circunscripcionJudicial(t: Tribunal): string {
  const sede = (t.sede ?? "").trim().replace(/\s+/g, " ");
  if (!sede) return t.estado;
  const idx = sede.search(/CIR?CUITO/i);
  if (idx >= 0) {
    let c = sede.slice(idx).replace(/[.\s]+$/g, "").trim();
    c = c.replace(/^[(\s,]+|[),\s]+$/g, "");
    return c;
  }
  return tituloSede(sede);
}

/** Nombre legible de una sede ("PALACIO DE JUSTICIA LOS TEQUES"). */
export function tituloSede(sede: string): string {
  const menores = new Set(["de", "del", "la", "el", "los", "las", "y", "e", "en"]);
  return sede
    .toLowerCase()
    .split(/\s+/)
    .map((w, i) => (i > 0 && menores.has(w) ? w : w.charAt(0).toUpperCase() + w.slice(1)))
    .join(" ");
}
