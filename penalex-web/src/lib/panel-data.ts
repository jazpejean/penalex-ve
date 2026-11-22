"use client";

// Datos reales del panel: perfil (Firestore), expedientes y favoritos
// (Supabase con token puente del worker). Nunca lanza: si algo falla,
// devuelve lo que se pudo cargar y un aviso.
import { doc, getDoc } from "firebase/firestore";
import { getDb, idTokenActual } from "./firebase";

const WORKER =
  process.env.NEXT_PUBLIC_WORKER_URL ??
  "https://penalex-auth-bridge.ignaciojazpe47.workers.dev";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const ANON = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

export interface Perfil {
  nombre: string | null;
  email: string | null;
  foto: string | null;
  nivel: number;
  xp: number;
  rol: string;
}

export interface ExpedienteResumen {
  id: string | number | null;
  numero: string;
  imputado: string;
  delitos: string;
  creado: string;
}

export interface FavoritoResumen {
  documentoId: string;
}

export interface PanelData {
  perfil: Perfil | null;
  expedientes: ExpedienteResumen[];
  favoritos: FavoritoResumen[];
  totalExpedientes: number;
  totalFavoritos: number;
  aviso: string;
}

/** Token de Supabase minteado a partir del idToken de Firebase. */
async function tokenSupabase(): Promise<string | null> {
  const idToken = await idTokenActual();
  if (!idToken) return null;
  try {
    const res = await fetch(`${WORKER}/auth/bridge`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken }),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as { token?: string };
    return data.token ?? null;
  } catch {
    return null;
  }
}

async function consultar(
  tabla: string,
  query: string,
  jwt: string,
): Promise<unknown[]> {
  if (!SUPABASE_URL || !ANON) return [];
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${tabla}?${query}`, {
    headers: {
      apikey: ANON,
      Authorization: `Bearer ${jwt}`,
      Prefer: "count=exact",
    },
  });
  if (!res.ok) return [];
  const data = await res.json();
  return Array.isArray(data) ? data : [];
}

function texto(v: unknown): string {
  return typeof v === "string" ? v : "";
}

export async function cargarPanel(uid: string, email: string | null): Promise<PanelData> {
  const resultado: PanelData = {
    perfil: null,
    expedientes: [],
    favoritos: [],
    totalExpedientes: 0,
    totalFavoritos: 0,
    aviso: "",
  };

  // 1) Perfil desde Firestore (mismo documento que escribe la app).
  try {
    const snap = await getDoc(doc(getDb(), "users", uid));
    const d = snap.exists() ? (snap.data() as Record<string, unknown>) : {};
    resultado.perfil = {
      nombre: texto(d.displayName) || (email ? email.split("@")[0] : null),
      email: texto(d.email) || email,
      foto: texto(d.photoUrl) || null,
      nivel: typeof d.nivel_actual === "number" ? d.nivel_actual : 1,
      xp: typeof d.xp_total === "number" ? d.xp_total : 0,
      rol:
        texto(d.rol) ||
        (email && email.toLowerCase().includes("jazpejean")
          ? "Administrador"
          : "Asistente Judicial"),
    };
  } catch {
    resultado.aviso = "No se pudo leer el perfil completo.";
  }

  // 2) Datos de Supabase con token puente.
  const jwt = await tokenSupabase();
  if (!jwt) {
    resultado.aviso =
      "No se pudo verificar la sesión con el servidor: los expedientes y favoritos no se pudieron cargar.";
    return resultado;
  }

  try {
    const [exp, fav] = await Promise.all([
      consultar(
        "expedientes",
        "select=*&order=created_at.desc&limit=5",
        jwt,
      ),
      consultar(
        "sentencias_favoritas",
        "select=documento_id&order=created_at.desc&limit=6",
        jwt,
      ),
    ]);

    resultado.expedientes = exp.map((fila) => {
      const f = fila as Record<string, unknown>;
      return {
        id: (f.id as string | number) ?? null,
        numero:
          texto(f.numero_expediente) ||
          texto(f.numero) ||
          texto(f.codigo) ||
          "Sin número",
        imputado: texto(f.imputado) || "Sin imputado",
        delitos: texto(f.delitos) || "",
        creado: texto(f.created_at) || "",
      };
    });

    resultado.favoritos = fav.map((fila) => {
      const f = fila as Record<string, unknown>;
      return { documentoId: texto(f.documento_id) };
    });
    resultado.totalExpedientes = resultado.expedientes.length;
    resultado.totalFavoritos = resultado.favoritos.length;
  } catch {
    resultado.aviso =
      "No se pudieron cargar expedientes y favoritos en este momento.";
  }

  return resultado;
}
