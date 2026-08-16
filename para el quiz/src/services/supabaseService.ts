import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { UserProfile, Pregunta, RankingUser, CertificateData, BoostersInventory } from '../types';
import { getRankByLevel } from '../data/judicialRanks';
import { getQuestionByLevel } from '../data/questionsData';

const LOCAL_STORAGE_USER_KEY = 'iurispenal_user_profile_v1';
const LOCAL_STORAGE_SUPABASE_CONFIG = 'iurispenal_supabase_config_v1';

export interface SupabaseSettings {
  url: string;
  anonKey: string;
  connected: boolean;
}

const DEFAULT_BOOSTERS: BoostersInventory = {
  mazo5050: 3,
  relojExtra: 3,
  doctrinaTSJ: 2,
  escudo: 2,
};

class SupabaseService {
  private client: SupabaseClient | null = null;
  private settings: SupabaseSettings = {
    url: '',
    anonKey: '',
    connected: false
  };

  constructor() {
    this.loadSavedConfig();
  }

  private loadSavedConfig() {
    try {
      const saved = localStorage.getItem(LOCAL_STORAGE_SUPABASE_CONFIG);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed.url && parsed.anonKey) {
          this.initClient(parsed.url, parsed.anonKey);
        }
      }
    } catch (e) {
      console.warn('Error loading Supabase config from localStorage:', e);
    }
  }

  public initClient(url: string, anonKey: string): boolean {
    try {
      if (!url || !anonKey) {
        this.client = null;
        this.settings = { url: '', anonKey: '', connected: false };
        localStorage.removeItem(LOCAL_STORAGE_SUPABASE_CONFIG);
        return false;
      }

      this.client = createClient(url, anonKey, {
        auth: {
          persistSession: true,
          autoRefreshToken: true
        }
      });
      this.settings = { url, anonKey, connected: true };
      localStorage.setItem(LOCAL_STORAGE_SUPABASE_CONFIG, JSON.stringify(this.settings));
      return true;
    } catch (err) {
      console.error('Supabase initialization failed:', err);
      this.settings.connected = false;
      return false;
    }
  }

  public getSettings(): SupabaseSettings {
    return this.settings;
  }

  public isConnected(): boolean {
    return !!this.client && this.settings.connected;
  }

  public getClient(): SupabaseClient | null {
    return this.client;
  }

  // --- USER PROFILE & GAMIFICATION PERSISTENCE ---

  public getInitialProfile(): UserProfile {
    // 1. Try local storage first
    try {
      const stored = localStorage.getItem(LOCAL_STORAGE_USER_KEY);
      if (stored) {
        const parsed: UserProfile = JSON.parse(stored);
        if (!parsed.estrellas_por_nivel) parsed.estrellas_por_nivel = {};
        if (!parsed.cofres_reclamados) parsed.cofres_reclamados = [];
        if (!parsed.boosters) parsed.boosters = { ...DEFAULT_BOOSTERS };
        
        // Auto-seed stars for already completed levels if empty
        for (let lvl = 1; lvl < parsed.nivel_actual; lvl++) {
          if (!parsed.estrellas_por_nivel[lvl]) {
            parsed.estrellas_por_nivel[lvl] = 3;
          }
        }

        return this.calculateRegeneratedAppeals(parsed);
      }
    } catch (e) {
      console.error('Failed to parse local user profile:', e);
    }

    // Default new user profile
    const defaultProfile: UserProfile = {
      id: 'usr_' + Math.random().toString(36).substring(2, 9),
      nombre: 'Abogado(a) Penalista',
      nivel_actual: 1,
      puntos_totales: 0,
      rango_actual: getRankByLevel(1).title,
      apelaciones: 5, // 5 pergaminos
      ultima_regeneracion: new Date().toISOString(),
      racha_actual: 0,
      max_racha: 0,
      logros: [],
      pdf_generados: [],
      fecha_registro: new Date().toISOString(),
      estrellas_por_nivel: {},
      cofres_reclamados: [],
      boosters: { ...DEFAULT_BOOSTERS }
    };

    this.saveProfileLocally(defaultProfile);
    return defaultProfile;
  }

  /**
   * Calculates apelaciones regeneration:
   * 1 apelación (pergamino) every 30 minutes until 5 are reached.
   */
  public calculateRegeneratedAppeals(profile: UserProfile): UserProfile {
    if (profile.apelaciones >= 5) {
      return profile;
    }

    const lastTime = new Date(profile.ultima_regeneracion).getTime();
    const now = Date.now();
    const diffMinutes = Math.floor((now - lastTime) / (1000 * 60));
    const REGEN_INTERVAL_MIN = 30;

    const gained = Math.floor(diffMinutes / REGEN_INTERVAL_MIN);

    if (gained > 0) {
      const newAppeals = Math.min(5, profile.apelaciones + gained);
      const remainingMinutes = diffMinutes % REGEN_INTERVAL_MIN;
      const newLastRegen = new Date(now - remainingMinutes * 60 * 1000).toISOString();

      const updated = {
        ...profile,
        apelaciones: newAppeals,
        ultima_regeneracion: newAppeals === 5 ? new Date().toISOString() : newLastRegen
      };
      this.saveProfileLocally(updated);
      return updated;
    }

    return profile;
  }

  public async saveProfile(profile: UserProfile): Promise<void> {
    this.saveProfileLocally(profile);

    // If Supabase is connected, sync to PostgreSQL table `profiles`
    if (this.client) {
      try {
        await this.client.from('profiles').upsert({
          id: profile.id,
          nombre: profile.nombre,
          nivel_actual: profile.nivel_actual,
          puntos_totales: profile.puntos_totales,
          rango_actual: profile.rango_actual,
          apelaciones: profile.apelaciones,
          ultima_regeneracion: profile.ultima_regeneracion,
          racha_actual: profile.racha_actual,
          max_racha: profile.max_racha,
          logros: profile.logros,
          pdf_generados: profile.pdf_generados,
          estrellas_por_nivel: profile.estrellas_por_nivel,
          cofres_reclamados: profile.cofres_reclamados,
          boosters: profile.boosters,
          updated_at: new Date().toISOString()
        });

        // Also update ranking table
        await this.client.from('ranking').upsert({
          user_id: profile.id,
          nombre: profile.nombre,
          nivel: profile.nivel_actual,
          xp: profile.puntos_totales,
          rango: profile.rango_actual,
          updated_at: new Date().toISOString()
        });
      } catch (err) {
        console.warn('Supabase remote sync warning (offline fallback active):', err);
      }
    }
  }

  private saveProfileLocally(profile: UserProfile) {
    try {
      localStorage.setItem(LOCAL_STORAGE_USER_KEY, JSON.stringify(profile));
    } catch (e) {
      console.error('LocalStorage write error:', e);
    }
  }

  // --- QUESTIONS API ---

  public async getQuestion(level: number): Promise<Pregunta> {
    // If Supabase is connected, attempt to fetch from `preguntas` table
    if (this.client) {
      try {
        const { data, error } = await this.client
          .from('preguntas')
          .select('*')
          .eq('nivel', level)
          .single();

        if (data && !error) {
          return {
            id: data.id,
            nivel: data.nivel,
            pregunta: data.pregunta,
            opciones: Array.isArray(data.opciones) ? data.opciones : JSON.parse(data.opciones),
            respuesta_correcta: data.respuesta_correcta,
            fundamentacion: data.fundamentacion,
            articulo_referencia: data.articulo_referencia || 'Código Penal Venezolano',
            categoria: data.categoria || 'Jurisprudencia TSJ',
            activo: data.activo ?? true,
            fecha_carga: data.fecha_carga
          };
        }
      } catch (e) {
        console.warn('Supabase remote question fetch error, using local generator:', e);
      }
    }

    // Default high-fidelity local generator
    return getQuestionByLevel(level);
  }

  // --- CERTIFICATES ---

  public async saveCertificate(cert: CertificateData): Promise<void> {
    if (this.client) {
      try {
        await this.client.from('certificados').insert({
          id: cert.id,
          user_id: cert.user_id,
          nivel: cert.nivel,
          rango: cert.rango,
          nombre: cert.nombre,
          fecha: cert.fecha,
          codigo_verificacion: cert.codigo_verificacion
        });
      } catch (e) {
        console.warn('Could not sync certificate to Supabase:', e);
      }
    }
  }

  // --- RANKING LEADERBOARD ---

  public async getLeaderboard(limit: number = 50): Promise<RankingUser[]> {
    if (this.client) {
      try {
        const { data, error } = await this.client
          .from('ranking')
          .select('*')
          .order('xp', { ascending: false })
          .limit(limit);

        if (data && !error && data.length > 0) {
          return data;
        }
      } catch (err) {
        console.warn('Leaderboard fetch fallback to local:', err);
      }
    }

    // Mock local competitors around user
    const current = this.getInitialProfile();
    return [
      { id: '1', user_id: 'u1', nombre: 'Dr. René Molina (Magistrado)', nivel: 2450, xp: 48900, rango: 'Presidente de Sala Penal' },
      { id: '2', user_id: 'u2', nombre: 'Dra. Carmen Mendoza', nivel: 1980, xp: 39500, rango: 'Magistrada Principal TSJ' },
      { id: '3', user_id: 'u3', nombre: 'Juez Carlos Vallenilla', nivel: 1200, xp: 24000, rango: 'Juez de Corte de Apelaciones' },
      { id: '4', user_id: current.id, nombre: `${current.nombre} (Tú)`, nivel: current.nivel_actual, xp: current.puntos_totales, rango: current.rango_actual },
      { id: '5', user_id: 'u5', nombre: 'Abg. Sofia Briceño', nivel: 85, xp: 1700, rango: 'Juez de Primera Instancia' },
      { id: '6', user_id: 'u6', nombre: 'Escribiente Roberto Gil', nivel: 12, xp: 240, rango: 'Escribiente Judicial' }
    ].sort((a, b) => b.xp - a.xp);
  }
}

export const supabaseService = new SupabaseService();
