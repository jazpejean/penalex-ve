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
    .select()
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