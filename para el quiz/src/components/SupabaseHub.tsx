import React, { useState } from 'react';
import { supabaseService, SupabaseSettings } from '../services/supabaseService';
import { sounds } from '../services/soundEffects';
import { 
  Database, 
  CheckCircle2, 
  Copy, 
  ShieldCheck, 
  Server, 
  Key, 
  Globe, 
  Code2, 
  Check,
  Zap,
  Terminal
} from 'lucide-react';

export const SupabaseHub: React.FC = () => {
  const currentSettings = supabaseService.getSettings();
  const [url, setUrl] = useState(currentSettings.url);
  const [anonKey, setAnonKey] = useState(currentSettings.anonKey);
  const [connected, setConnected] = useState(supabaseService.isConnected());
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  const [activeSnippetTab, setActiveSnippetTab] = useState<'sql' | 'edge' | 'node'>('sql');

  const handleSaveConnection = (e: React.FormEvent) => {
    e.preventDefault();
    sounds.playClick();
    const success = supabaseService.initClient(url.trim(), anonKey.trim());
    setConnected(success);
    if (success) {
      sounds.playCorrect();
    }
  };

  const handleDisconnect = () => {
    sounds.playClick();
    supabaseService.initClient('', '');
    setUrl('');
    setAnonKey('');
    setConnected(false);
  };

  const copyToClipboard = (text: string, id: string) => {
    sounds.playClick();
    navigator.clipboard.writeText(text);
    setCopiedCode(id);
    setTimeout(() => setCopiedCode(null), 3000);
  };

  const SQL_SCHEMA = `-- ==============================================================================
-- IURISPENAL: ESQUEMA DE BASE DE DATOS SUPABASE (POSTGRESQL)
-- DERECHO PENAL VENEZOLANO & COPP
-- ==============================================================================

-- 1. EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABLA DE PREGUNTAS (Banco de 3000 casos penales)
CREATE TABLE IF NOT EXISTS public.preguntas (
    id BIGSERIAL PRIMARY KEY,
    nivel INT NOT NULL UNIQUE,
    pregunta TEXT NOT NULL,
    opciones JSONB NOT NULL,
    respuesta_correcta INT NOT NULL CHECK (respuesta_correcta BETWEEN 0 AND 3),
    fundamentacion TEXT NOT NULL,
    articulo_referencia TEXT,
    categoria TEXT DEFAULT 'Parte General',
    activo BOOLEAN DEFAULT TRUE,
    fecha_carga TIMESTAMPTZ DEFAULT NOW()
);

-- Índices de búsqueda por nivel y categoría
CREATE INDEX IF NOT EXISTS idx_preguntas_nivel ON public.preguntas(nivel);
CREATE INDEX IF NOT EXISTS idx_preguntas_categoria ON public.preguntas(categoria);

-- 3. TABLA DE PERFILES DE USUARIOS (Extiende auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL DEFAULT 'Abogado(a) Penalista',
    nivel_actual INT DEFAULT 1 CHECK (nivel_actual BETWEEN 1 AND 3000),
    puntos_totales INT DEFAULT 0,
    rango_actual TEXT DEFAULT 'Practicante de Tribunal',
    apelaciones INT DEFAULT 5 CHECK (apelaciones BETWEEN 0 AND 5),
    ultima_regeneracion TIMESTAMPTZ DEFAULT NOW(),
    racha_actual INT DEFAULT 0,
    max_racha INT DEFAULT 0,
    logros JSONB DEFAULT '[]'::jsonb,
    pdf_generados JSONB DEFAULT '[]'::jsonb,
    fecha_registro TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABLA DE RANKING NACIONAL
CREATE TABLE IF NOT EXISTS public.ranking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    nivel INT NOT NULL DEFAULT 1,
    xp INT NOT NULL DEFAULT 0,
    rango TEXT NOT NULL,
    avatar TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ranking_xp ON public.ranking(xp DESC);

-- 5. TABLA DE LOGROS Y CONDECORACIONES
CREATE TABLE IF NOT EXISTS public.logros (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    nivel_requerido INT,
    icono TEXT NOT NULL
);

-- 6. TABLA DE CERTIFICADOS PDF
CREATE TABLE IF NOT EXISTS public.pdf_generados (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    nivel INT NOT NULL,
    rango_obtenido TEXT NOT NULL,
    fecha_emision TEXT NOT NULL,
    codigo_verificacion TEXT NOT NULL UNIQUE,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- POLÍTICAS DE SEGURIDAD ROW LEVEL SECURITY (RLS)
-- ==============================================================================
ALTER TABLE public.preguntas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ranking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pdf_generados ENABLE ROW LEVEL SECURITY;

-- Preguntas: Lectura pública para usuarios autenticados y anónimos
CREATE POLICY "Lectura pública de preguntas" 
ON public.preguntas FOR SELECT 
USING (activo = true);

-- Profiles: Cada usuario puede ver y actualizar solo su perfil
CREATE POLICY "Usuarios gestionan su propio perfil" 
ON public.profiles FOR ALL 
USING (auth.uid() = id);

-- Ranking: Lectura pública de la tabla de posiciones
CREATE POLICY "Lectura pública del ranking" 
ON public.ranking FOR SELECT 
TO authenticated, anon 
USING (true);

CREATE POLICY "Usuarios actualizan su propia fila de ranking" 
ON public.ranking FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios actualizan su fila existente de ranking" 
ON public.ranking FOR UPDATE 
USING (auth.uid() = user_id);

-- Storage bucket para certificados PDF
INSERT INTO storage.buckets (id, name, public) 
VALUES ('certificados_judiciales', 'certificados_judiciales', true)
ON CONFLICT (id) DO NOTHING;
`;

  const EDGE_FUNCTION_CODE = `// supabase/functions/regenerate-appeals/index.ts
// Función Edge para regeneración automática de apelaciones (pergaminos) cada 30 minutos
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  // Seleccionar usuarios con menos de 5 apelaciones
  const { data: users, error } = await supabase
    .from("profiles")
    .select("id, apelaciones, ultima_regeneracion")
    .lt("apelaciones", 5);

  if (error) return new Response(JSON.stringify({ error }), { status: 500 });

  const now = Date.now();
  const updates = [];

  for (const user of users) {
    const last = new Date(user.ultima_regeneracion).getTime();
    const diffMinutes = Math.floor((now - last) / (1000 * 60));
    const gained = Math.floor(diffMinutes / 30);

    if (gained > 0) {
      const newAppeals = Math.min(5, user.apelaciones + gained);
      updates.push(
        supabase
          .from("profiles")
          .update({
            apelaciones: newAppeals,
            ultima_regeneracion: new Date().toISOString()
          })
          .eq("id", user.id)
      );
    }
  }

  await Promise.all(updates);

  return new Response(
    JSON.stringify({ status: "ok", updated_users: updates.length }),
    { headers: { "Content-Type": "application/json" } }
  );
});
`;

  const NODE_SEED_CODE = `// scripts/seed_questions_supabase.js
// Script en Node.js para cargar las 3000 preguntas masivamente a Supabase
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://xyzcompany.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'TU_SERVICE_KEY';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function seed() {
  console.log('Iniciando carga masiva de preguntas de Derecho Penal Venezolano...');
  
  const rawData = fs.readFileSync('./banco_preguntas_derecho_penal.json', 'utf8');
  const questions = JSON.parse(rawData);

  // Carga en lotes de 100 para optimizar rendimiento de PostgreSQL
  const BATCH_SIZE = 100;
  for (let i = 0; i < questions.length; i += BATCH_SIZE) {
    const batch = questions.slice(i, i + BATCH_SIZE);
    const { error } = await supabase.from('preguntas').upsert(batch, { onConflict: 'nivel' });
    
    if (error) {
      console.error('Error insertando lote', i, error);
    } else {
      console.log(\`Insertadas preguntas del nivel \${i + 1} al \${Math.min(i + BATCH_SIZE, questions.length)}\`);
    }
  }

  console.log('¡Carga masiva completada con éxito!');
}

seed();
`;

  return (
    <div className="max-w-6xl mx-auto px-3 sm:px-6 pb-24">
      
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-8">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-950/80 border border-amber-500/40 mb-3 shadow-lg shadow-amber-950/60">
          <Database className="w-8 h-8 text-amber-400" />
        </div>
        <h2 className="font-judicial text-2xl sm:text-4xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600 mb-2">
          Centro de Control Supabase Backend
        </h2>
        <p className="text-sm text-slate-300">
          Arquitectura PostgreSQL completa, autenticación, Storage para certificados y funciones Edge para el juego.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        
        {/* Connection Form */}
        <div className="bg-[#0c1220] border-2 border-amber-800/60 rounded-3xl p-6 shadow-xl flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Server className="w-5 h-5 text-amber-400" />
                <h3 className="font-judicial text-base font-bold text-slate-100">
                  Credenciales Supabase
                </h3>
              </div>
              <span className={`text-[10px] font-mono px-2 py-0.5 rounded-full border ${
                connected
                  ? 'bg-emerald-950/80 border-emerald-500 text-emerald-300'
                  : 'bg-slate-900 border-slate-700 text-slate-400'
              }`}>
                {connected ? 'Conectado' : 'Offline'}
              </span>
            </div>

            <p className="text-xs text-slate-300 mb-4 leading-relaxed">
              Ingresa el URL y Anon Key de tu proyecto Supabase para sincronizar automáticamente el progreso, ranking y preguntas en tiempo real.
            </p>

            <form onSubmit={handleSaveConnection} className="space-y-3">
              <div>
                <label className="text-[11px] font-mono text-slate-400 flex items-center gap-1 mb-1">
                  <Globe className="w-3.5 h-3.5 text-amber-400" />
                  Project URL:
                </label>
                <input
                  type="text"
                  placeholder="https://xyzproject.supabase.co"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2 text-xs font-mono text-slate-200 focus:outline-none focus:border-amber-500"
                />
              </div>

              <div>
                <label className="text-[11px] font-mono text-slate-400 flex items-center gap-1 mb-1">
                  <Key className="w-3.5 h-3.5 text-amber-400" />
                  Anon / Public Key:
                </label>
                <input
                  type="password"
                  placeholder="eyJhbGciOiJIUzI1NiIsIn..."
                  value={anonKey}
                  onChange={(e) => setAnonKey(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2 text-xs font-mono text-slate-200 focus:outline-none focus:border-amber-500"
                />
              </div>

              <div className="pt-2 flex gap-2">
                <button
                  type="submit"
                  className="flex-1 py-2.5 px-4 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:brightness-110 text-slate-950 font-bold text-xs shadow-lg cursor-pointer"
                >
                  Guardar y Vincular
                </button>
                {connected && (
                  <button
                    type="button"
                    onClick={handleDisconnect}
                    className="py-2.5 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold cursor-pointer"
                  >
                    Desconectar
                  </button>
                )}
              </div>
            </form>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-800 text-[11px] text-slate-400 flex items-center gap-1.5">
            <ShieldCheck className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>Si no introduces credenciales, el juego almacena tu progreso localmente sin interrupciones.</span>
          </div>
        </div>

        {/* Database Architecture Schema Overview */}
        <div className="lg:col-span-2 bg-[#0c1220] border-2 border-amber-800/60 rounded-3xl p-6 shadow-xl flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Code2 className="w-5 h-5 text-amber-400" />
                <h3 className="font-judicial text-base font-bold text-slate-100">
                  Estructura de Tablas & SQL DDL
                </h3>
              </div>
              <div className="flex gap-1 bg-slate-950 p-1 rounded-xl border border-slate-800 text-xs font-mono">
                <button
                  onClick={() => setActiveSnippetTab('sql')}
                  className={`px-3 py-1 rounded-lg transition-colors cursor-pointer ${
                    activeSnippetTab === 'sql' ? 'bg-amber-500 text-slate-950 font-bold' : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  SQL Schema
                </button>
                <button
                  onClick={() => setActiveSnippetTab('edge')}
                  className={`px-3 py-1 rounded-lg transition-colors cursor-pointer ${
                    activeSnippetTab === 'edge' ? 'bg-amber-500 text-slate-950 font-bold' : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  Edge Function
                </button>
                <button
                  onClick={() => setActiveSnippetTab('node')}
                  className={`px-3 py-1 rounded-lg transition-colors cursor-pointer ${
                    activeSnippetTab === 'node' ? 'bg-amber-500 text-slate-950 font-bold' : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  Node Seed
                </button>
              </div>
            </div>

            <p className="text-xs text-slate-300 mb-3">
              {activeSnippetTab === 'sql'
                ? 'Ejecuta este script en el Editor SQL de tu panel de Supabase para crear todas las tablas, índices y políticas RLS.'
                : activeSnippetTab === 'edge'
                ? 'Función Edge programable vía Cron para la regeneración de apelaciones cada 30 minutos.'
                : 'Script para cargar masivamente las 3000 preguntas en lotes optimizados.'}
            </p>

            {/* Code Snippet Box */}
            <div className="relative bg-[#070b13] border border-slate-800 rounded-2xl overflow-hidden">
              <button
                onClick={() => copyToClipboard(
                  activeSnippetTab === 'sql' ? SQL_SCHEMA : activeSnippetTab === 'edge' ? EDGE_FUNCTION_CODE : NODE_SEED_CODE,
                  activeSnippetTab
                )}
                className="absolute top-3 right-3 px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-mono flex items-center gap-1.5 border border-slate-700 shadow cursor-pointer z-10"
              >
                {copiedCode === activeSnippetTab ? (
                  <>
                    <Check className="w-3.5 h-3.5 text-emerald-400" />
                    <span className="text-emerald-400">¡Copiado!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3.5 h-3.5 text-amber-400" />
                    <span>Copiar</span>
                  </>
                )}
              </button>

              <pre className="p-4 text-xs font-mono text-slate-300 overflow-x-auto max-h-72 leading-relaxed">
                <code>
                  {activeSnippetTab === 'sql' && SQL_SCHEMA}
                  {activeSnippetTab === 'edge' && EDGE_FUNCTION_CODE}
                  {activeSnippetTab === 'node' && NODE_SEED_CODE}
                </code>
              </pre>
            </div>
          </div>
        </div>

      </div>

    </div>
  );
};
