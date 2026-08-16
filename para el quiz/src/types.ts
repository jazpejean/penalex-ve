export interface Pregunta {
  id: number;
  nivel: number;
  pregunta: string;
  opciones: [string, string, string, string];
  respuesta_correcta: number; // 0, 1, 2, 3
  fundamentacion: string;
  articulo_referencia?: string;
  categoria?: 'Parte General' | 'Delitos contra las Personas' | 'Delitos contra la Propiedad' | 'Delitos contra la Cosa Pública' | 'COPP y Procedimiento' | 'Drogas y Leyes Especiales' | 'Jurisprudencia TSJ' | string;
  activo?: boolean;
  fecha_carga?: string;
}

export interface BoostersInventory {
  mazo5050: number;
  relojExtra: number;
  doctrinaTSJ: number;
  escudo: number;
}

export interface UserProfile {
  id: string;
  nombre: string;
  email?: string;
  nivel_actual: number;
  puntos_totales: number;
  rango_actual: string;
  apelaciones: number; // 0 to 5
  ultima_regeneracion: string; // ISO string
  racha_actual: number;
  max_racha: number;
  logros: string[];
  pdf_generados: CertificateData[];
  fecha_registro: string;
  estrellas_por_nivel?: Record<number, number>; // level -> 1, 2, or 3 stars
  cofres_reclamados?: number[]; // list of claimed milestone chest levels
  boosters?: BoostersInventory;
}

export interface JudicialRank {
  minLevel: number;
  maxLevel: number;
  title: string;
  sala: string;
  badgeIcon: string;
  description: string;
  color: string;
  isMilestoneCertificate?: boolean;
}

export interface Logro {
  id: string;
  nombre: string;
  descripcion: string;
  nivel_requerido?: number;
  racha_requerida?: number;
  puntos_requeridos?: number;
  icono: string;
  categoria: 'nivel' | 'racha' | 'puntos' | 'especial';
}

export interface RankingUser {
  id: string;
  user_id: string;
  nombre: string;
  nivel: number;
  xp: number;
  rango: string;
  avatar?: string;
  updated_at?: string;
}

export interface CertificateData {
  id: string;
  user_id?: string;
  nombre: string;
  nivel: number;
  rango: string;
  fecha: string;
  codigo_verificacion: string;
  pdf_url?: string;
}
