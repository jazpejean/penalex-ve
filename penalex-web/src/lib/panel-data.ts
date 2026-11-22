"use client";

// Datos reales del panel sin Firestore: perfil, nivel y XP desde Supabase
// (user_profiles y quiz_ranking), expedientes y favoritos con el token puente
// del worker. Nunca lanza: devuelve lo que se pudo cargar y un aviso.
import { idTokenActual } from "./firebase";

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
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${tabla}?${query}`, {
      headers: { apikey: ANON, Authorization: `Bearer ${jwt}` },
    });
    if (!res.ok) return [];
    const data = await res.json();
    return Array.isArray(data) ? data : [];
  } catch {
    return [];
  }
}

function texto(v: unknown): string {
  return typeof v === "string" ? v : "";
}

function fotoUrl(uid: string, version: string): string {
  if (!SUPABASE_URL) return "";
  const base = `${SUPABASE_URL}/storage/v1/object/public/profile-pictures/${uid}/avatar.jpg`;
  return version ? `${base}?v=${encodeURIComponent(version)}` : base;
}

export async function cargarPanel(
  uid: string,
  email: string | null,
): Promise<PanelData> {
  const resultado: PanelData = {
    perfil: {
      nombre: email ? email.split("@")[0] : null,
      email,
      foto: fotoUrl(uid, ""),
      nivel: 1,
      xp: 0,
      rol: "Asistente Judicial",
    },
    expedientes: [],
    favoritos: [],
    totalExpedientes: 0,
    totalFavoritos: 0,
    aviso: "",
  };

  const jwt = await tokenSupabase();
  if (!jwt) {
    resultado.aviso =
      "No se pudo verificar la sesión con el servidor. Vuelve a iniciar sesión.";
    return resultado;
  }

  const [perfiles, ranking, exp, fav] = await Promise.all([
    consultar("user_profiles", `select=name,email,role,updated_at&id=eq.${uid}`, jwt),
    consultar("quiz_ranking", `select=xp,nivel_actual&user_id=eq.${uid}`, jwt),
    consultar("expedientes", "select=*&order=created_at.desc&limit=5", jwt),
    consultar(
      "sentencias_favoritas",
      "select=documento_id&order=created_at.desc&limit=6",
      jwt,
    ),
  ]);

  const p = perfiles[0] as Record<string, unknown> | undefined;
  if (p) {
    const version = texto(p.updated_at);
    resultado.perfil = {
      nombre: texto(p.name) || resultado.perfil?.nombre || null,
      email: texto(p.email) || email,
      foto: fotoUrl(uid, version),
      nivel: resultado.perfil?.nivel ?? 1,
      xp: resultado.perfil?.xp ?? 0,
      rol: texto(p.role) === "admin" ? "Administrador" : "Asistente Judicial",
    };
  }

  const r = ranking[0] as Record<string, unknown> | undefined;
  if (r && resultado.perfil) {
    resultado.perfil.nivel =
      typeof r.nivel_actual === "number" ? r.nivel_actual : 1;
    resultado.perfil.xp = typeof r.xp === "number" ? r.xp : 0;
  }

  resultado.expedientes = exp.map((fila) => {
    const f = fila as Record<string, unknown>;
    return {
      id: (f.id as string | number) ?? null,
      numero: texto(f.numero_expediente) || "Sin número",
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

  if (!p && !r) {
    resultado.aviso =
      "Tu perfil se está sincronizando. Los expedientes y favoritos aparecerán en cuanto la app los registre.";
  }

  return resultado;
}
