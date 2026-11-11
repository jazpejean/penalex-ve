import { createClient } from "@supabase/supabase-js";

// Claves públicas (anon): la web solo LEE contenido público (leyes del bucket).
// La escritura de datos privados irá por el worker penalex-auth-bridge con RLS.
const url = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

export const supabase = createClient(url, anon, {
  auth: { persistSession: false },
});

// ---------------------------------------------------------------------------
// Tipos del corpus de leyes (mirror de ArticuloLey / estructura del corpus)
// ---------------------------------------------------------------------------

export interface ArticuloLey {
  tipo_norma?: string;
  identificador?: string;
  encabezado?: string | null;
  texto_principal?: string;
  nota_jurisprudencial?: string | null;
}

export interface BloqueLey {
  titulo?: string;
  articulos: ArticuloLey[];
}

export interface LeyEstructura {
  ley_nombre?: string;
  estructura: BloqueLey[];
}

/** Lista las 71 leyes (manifest) ordenadas por relevancia (campo `orden`). */
export async function listarLeyes(): Promise<Array<{ slug: string; nombre: string; orden: number }>> {
  const manifestUrl = `${url}/storage/v1/object/public/leyes/manifest.json`;
  const res = await fetch(manifestUrl, {
    headers: { apikey: anon, authorization: `Bearer ${anon}` },
  });
  if (!res.ok) throw new Error(`manifest HTTP ${res.status}`);
  const data = (await res.json()) as any;
  const leyes = Array.isArray(data?.leyes) ? data.leyes : Array.isArray(data) ? data : [];
  return leyes
    .map((l: any) => ({
      slug: (l?.slug ?? l?.ruta ?? l?.path ?? "").replace(/\.json$/, ""),
      nombre: l?.nombre ?? l?.titulo ?? l?.name ?? "",
      orden: typeof l?.orden === "number" ? l.orden : 999,
    }))
    .sort(
      (a: { orden: number; nombre: string }, b: { orden: number; nombre: string }) =>
        a.orden - b.orden || a.nombre.localeCompare(b.nombre, "es")
    );
}

/** Descarga una ley completa desde el bucket. */
export async function obtenerLey(slug: string): Promise<LeyEstructura> {
  const leyUrl = `${url}/storage/v1/object/public/leyes/${slug}.json`;
  const res = await fetch(leyUrl, {
    headers: { apikey: anon, authorization: `Bearer ${anon}` },
    cache: "force-cache",
  });
  if (!res.ok) throw new Error(`ley ${slug} HTTP ${res.status}`);
  return (await res.json()) as LeyEstructura;
}