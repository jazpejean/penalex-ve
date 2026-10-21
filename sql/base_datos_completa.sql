-- ============================================================================
-- PENALEX VE — Base de datos completa (una sola ejecución, idempotente)
-- ----------------------------------------------------------------------------
-- Arquitectura: Firebase Auth = identidad · Supabase = datos.
--   user_id = UID de Firebase (TEXT), NUNCA UUID REFERENCES auth.users.
--   RLS abierta (USING true) porque Firebase ya validó la autenticación
--   (mismo patrón que user_profiles / sentencias).
-- Puedes re-ejecutarlo sin errores. Ejecutar en Supabase Dashboard → SQL Editor.
--
-- CONTENIDO:
--   SECCIÓN 1: CREAR  sentencias_favoritas, ai_tool_usage (oculta),
--              criterios_dia, agenda_eventos (nueva), calculos_guardados (nuevo)
--   SECCIÓN 2: FIX    user_profiles.id UUID → TEXT  (bug del login con UID Firebase)
--   SECCIÓN 3: DROP   13 tablas sobrantes (basura / vacías / duplicadas)
-- ============================================================================

-- ============================================================================
-- SECCIÓN 1 — CREAR TABLAS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1) sentencias_favoritas — usada por FavoritosService (upsert onConflict
--      user_id, documento_id). La app ya la llama; faltaba en la BD.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sentencias_favoritas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,             -- UID de Firebase
  documento_id TEXT NOT NULL,        -- id del documento en 'sentencias'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sentencias_favoritas_unique
  ON public.sentencias_favoritas(user_id, documento_id);
CREATE INDEX IF NOT EXISTS idx_sentencias_favoritas_user
  ON public.sentencias_favoritas(user_id);

ALTER TABLE public.sentencias_favoritas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fav_select_all" ON public.sentencias_favoritas;
CREATE POLICY "fav_select_all" ON public.sentencias_favoritas
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "fav_insert_all" ON public.sentencias_favoritas;
CREATE POLICY "fav_insert_all" ON public.sentencias_favoritas
  FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "fav_update_all" ON public.sentencias_favoritas;
CREATE POLICY "fav_update_all" ON public.sentencias_favoritas
  FOR UPDATE USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "fav_delete_all" ON public.sentencias_favoritas;
CREATE POLICY "fav_delete_all" ON public.sentencias_favoritas
  FOR DELETE USING (true);

-- ----------------------------------------------------------------------------
-- 1.2) ai_tool_usage — TELEMETRÍA OCULTA (sin pantalla, sin RPC, sin reporte).
--      Registro silencioso del uso de cada herramienta de IA: tiempos, éxito,
--      errores. Usado para métricas de tracción y depuración. La app escribe
--      con trackOperation (falla silenciosamente si algo sale mal).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_tool_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,             -- UID de Firebase
  tool_name VARCHAR(100) NOT NULL CHECK (tool_name IN (
    'chat_legal', 'redactor_documentos', 'escaner_documentos',
    'comparador_estrategias'
  )),
  action_type VARCHAR(50) NOT NULL CHECK (action_type IN (
    'query', 'generation', 'analysis', 'comparison', 'scan', 'export'
  )),
  response_time_seconds DECIMAL(10, 3) NOT NULL
    CHECK (response_time_seconds >= 0 AND response_time_seconds < 3600),
  success BOOLEAN NOT NULL DEFAULT true,
  error_message TEXT,                -- para depuración
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_user_tool
  ON public.ai_tool_usage (user_id, tool_name);
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_created_at
  ON public.ai_tool_usage (created_at DESC);

ALTER TABLE public.ai_tool_usage ENABLE ROW LEVEL SECURITY;
-- El usuario solo PUEDE ESCRIBIR su propio uso (INSERT), nunca LEER:
-- la telemetría queda oculta (sin SELECT para anon/authenticated).
DROP POLICY IF EXISTS "ai_usage_insert_own" ON public.ai_tool_usage;
CREATE POLICY "ai_usage_insert_own" ON public.ai_tool_usage
  FOR INSERT WITH CHECK (user_id = auth.uid()::text);
-- Lectura: solo el service role (bypass RLS). Sin políticas SELECT/UPDATE/DELETE.

-- ----------------------------------------------------------------------------
-- 1.3) criterios_dia — sección "Criterio del día" (L-V, 8 AM)
--      cita_vinculante = ratio_decidendi ÍNTEGRO (textual, del TSJ).
--      interpretacion = 3-4 líneas generadas por IA (nunca toca la cita).
--      RLS: lectura pública · escritura solo admin (service role).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.criterios_dia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL UNIQUE,        -- 1 criterio por día hábil
  sentencia_id TEXT,                 -- FK lógica → sentencias.id
  doctrina_id UUID,                  -- FK lógica → doctrinas.id (opcional)
  titulo TEXT NOT NULL,
  cita_vinculante TEXT NOT NULL,     -- ratio íntegro del TSJ
  interpretacion TEXT,               -- breve, generada por IA
  sala TEXT,                         -- scp / scon
  anio INTEGER,
  categoria TEXT DEFAULT 'penal',
  estado TEXT NOT NULL DEFAULT 'programado'
    CHECK (estado IN ('programado','enviado','editado')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_criterios_dia_fecha
  ON public.criterios_dia (fecha DESC);
CREATE INDEX IF NOT EXISTS idx_criterios_dia_sentencia
  ON public.criterios_dia (sentencia_id);

ALTER TABLE public.criterios_dia ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "criterios_lectura_publica" ON public.criterios_dia;
CREATE POLICY "criterios_lectura_publica" ON public.criterios_dia
  FOR SELECT USING (true);
-- Sin política de INSERT/UPDATE/DELETE: solo el service role (admin) escribe.

-- ----------------------------------------------------------------------------
-- 1.4) agenda_eventos — la agenda judicial migra de Firestore a Supabase.
--      Campos = modelo Audiencia (audiencia.dart) + user_id + recordatorio.
--      La tabla vieja (0 filas) se recrea con este schema correcto.
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.agenda_eventos;

CREATE TABLE public.agenda_eventos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,             -- UID de Firebase (RLS)
  expediente TEXT,
  tribunal TEXT,
  imputado TEXT,
  cedula TEXT,
  fiscalia TEXT,
  delitos TEXT,
  fecha TIMESTAMPTZ,
  hora TEXT,
  tipo TEXT,
  notas TEXT,
  recordatorio_minutos INTEGER NOT NULL DEFAULT 0,  -- minutos antes del push
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agenda_eventos_user_fecha
  ON public.agenda_eventos (user_id, fecha);

ALTER TABLE public.agenda_eventos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "agenda_select_own" ON public.agenda_eventos;
CREATE POLICY "agenda_select_own" ON public.agenda_eventos
  FOR SELECT USING (user_id = auth.uid()::text);
DROP POLICY IF EXISTS "agenda_insert_own" ON public.agenda_eventos;
CREATE POLICY "agenda_insert_own" ON public.agenda_eventos
  FOR INSERT WITH CHECK (user_id = auth.uid()::text);
DROP POLICY IF EXISTS "agenda_update_own" ON public.agenda_eventos;
CREATE POLICY "agenda_update_own" ON public.agenda_eventos
  FOR UPDATE USING (user_id = auth.uid()::text) WITH CHECK (user_id = auth.uid()::text);
DROP POLICY IF EXISTS "agenda_delete_own" ON public.agenda_eventos;
CREATE POLICY "agenda_delete_own" ON public.agenda_eventos
  FOR DELETE USING (user_id = auth.uid()::text);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION public.touch_agenda_eventos()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_agenda_eventos_touch ON public.agenda_eventos;
CREATE TRIGGER trg_agenda_eventos_touch
  BEFORE UPDATE ON public.agenda_eventos
  FOR EACH ROW EXECUTE FUNCTION public.touch_agenda_eventos();

-- ----------------------------------------------------------------------------
-- 1.5) calculos_guardados — la dosimetría migra de Firestore a Supabase.
--      delitos = lista JSONB (serializada igual por Flutter y la web).
--      La tabla vieja (0 filas) se recrea con este schema correcto.
--      ORDEN: primero se elimina reportes_guardados porque tiene FK
--      calculo_id → calculos_guardados.id (es basura, se elimina igual).
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.reportes_guardados;
DROP TABLE IF EXISTS public.calculos_guardados;

CREATE TABLE public.calculos_guardados (
  id TEXT PRIMARY KEY,               -- id que genera CalculationModel
  user_id TEXT NOT NULL,             -- UID de Firebase (RLS)
  nombre TEXT,
  fecha TIMESTAMPTZ,
  delitos JSONB DEFAULT '[]'::jsonb,
  concurso TEXT,                     -- TipoConcurso.index como texto
  admision_hechos BOOLEAN DEFAULT false,
  fraccion_admision NUMERIC,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calculos_guardados_user
  ON public.calculos_guardados (user_id, created_at DESC);

ALTER TABLE public.calculos_guardados ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "calc_select_own" ON public.calculos_guardados;
CREATE POLICY "calc_select_own" ON public.calculos_guardados
  FOR SELECT USING (user_id = auth.uid()::text);
DROP POLICY IF EXISTS "calc_insert_own" ON public.calculos_guardados;
CREATE POLICY "calc_insert_own" ON public.calculos_guardados
  FOR INSERT WITH CHECK (user_id = auth.uid()::text);
DROP POLICY IF EXISTS "calc_update_own" ON public.calculos_guardados;
CREATE POLICY "calc_update_own" ON public.calculos_guardados
  FOR UPDATE USING (user_id = auth.uid()::text) WITH CHECK (user_id = auth.uid()::text);
DROP POLICY IF EXISTS "calc_delete_own" ON public.calculos_guardados;
CREATE POLICY "calc_delete_own" ON public.calculos_guardados
  FOR DELETE USING (user_id = auth.uid()::text);

-- ============================================================================
-- SECCIÓN 2 — FIX user_profiles (bug del login)
-- ----------------------------------------------------------------------------
-- La app inserta el UID de Firebase (TEXT) en user_profiles.id, pero la tabla
-- lo define UUID → error 22P02 al registrarse (verificado en vivo).
-- user_profiles tiene 0 filas → cambio de tipo seguro, sin datos que migrar.
--
-- ORDEN (Postgres no permite ALTER TYPE de una columna usada por una política):
--   1) DROP de TODAS las políticas RLS de user_profiles.
--   2) DROP de TODAS las políticas de CUALQUIER tabla (ej. glosario_terminos)
--      cuya expresión referencie user_profiles (subconsultas a user_profiles.id).
--   3) ALTER user_profiles.id → TEXT.
--   4) Recrear las políticas con auth.uid()::text (el tipo de comparación
--      correcto contra columnas TEXT).
-- ============================================================================

-- 1) Políticas propias de user_profiles
DO $$
DECLARE
  pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'user_profiles'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_profiles', pol);
  END LOOP;
END $$;

-- 2) Políticas de OTRAS tablas que referencian user_profiles (glosario_terminos)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (COALESCE(qual, '') LIKE '%user_profiles%'
        OR COALESCE(with_check, '') LIKE '%user_profiles%')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- 2b) Eliminar FKs que involucran user_profiles:
--   - salientes: user_profiles.id REFERENCES auth.users(id) (del esquema antiguo).
--     La app usa Firebase Auth, no Supabase Auth: el UID de Firebase NO existe en
--     auth.users, así que esa FK rompería el login (error 23503) incluso tras el
--     cambio de tipo. Se elimina.
--   - entrantes: otras tablas con FK hacia user_profiles.id (bloquearían el ALTER).
DO $$
DECLARE
  r RECORD;
BEGIN
  -- FKs entrantes (otras tablas referencian user_profiles)
  FOR r IN
    SELECT conrelid::regclass::text AS tbl, conname
    FROM pg_constraint
    WHERE contype = 'f' AND confrelid = 'public.user_profiles'::regclass
  LOOP
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', r.tbl, r.conname);
  END LOOP;
  -- FKs salientes (user_profiles referencia otras tablas, ej. auth.users)
  FOR r IN
    SELECT conrelid::regclass::text AS tbl, conname
    FROM pg_constraint
    WHERE contype = 'f' AND conrelid = 'public.user_profiles'::regclass
  LOOP
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', r.tbl, r.conname);
  END LOOP;
END $$;

-- 3) Cambio de tipo
ALTER TABLE public.user_profiles
  ALTER COLUMN id TYPE TEXT USING id::text;

-- 4a) Políticas de user_profiles con el tipo correcto.
-- auth.uid() para anon es NULL → NULL = id nunca matchea: un anónimo no ve
-- ni toca perfiles; cada usuario solo su propio perfil (authenticated).
-- Se recrean las 6 originales (create_user_profiles.sql): 3 "own profile",
-- 1 delete y 2 de administradores (con subconsulta a user_profiles).
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid()::text = id);
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid()::text = id);
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid()::text = id) WITH CHECK (auth.uid()::text = id);
DROP POLICY IF EXISTS "Users can delete own profile" ON public.user_profiles;
CREATE POLICY "Users can delete own profile" ON public.user_profiles
  FOR DELETE USING (auth.uid()::text = id);
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
CREATE POLICY "Admins can view all profiles" ON public.user_profiles
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid()::text AND role = 'admin'
  ));
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.user_profiles;
CREATE POLICY "Admins can update all profiles" ON public.user_profiles
  FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid()::text AND role = 'admin'
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid()::text AND role = 'admin'
  ));

-- 4b) Recrear las políticas de glosario_terminos que dependían de user_profiles
-- (mismas reglas del esquema original, con auth.uid()::text en las subconsultas).
DROP POLICY IF EXISTS "Everyone can read glossary" ON public.glosario_terminos;
CREATE POLICY "Everyone can read glossary" ON public.glosario_terminos
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can contribute to glossary" ON public.glosario_terminos;
CREATE POLICY "Authenticated users can contribute to glossary" ON public.glosario_terminos
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "Contributors can update own terms" ON public.glosario_terminos;
CREATE POLICY "Contributors can update own terms" ON public.glosario_terminos
  FOR UPDATE
  USING (auth.uid() = contribuidor_id OR
         EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid()::text AND role = 'admin'));
DROP POLICY IF EXISTS "Admins can delete glossary terms" ON public.glosario_terminos;
CREATE POLICY "Admins can delete glossary terms" ON public.glosario_terminos
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid()::text AND role = 'admin'));

-- (Opcional) fcm_token para notificaciones push de agenda
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ============================================================================
-- SECCIÓN 3 — DROP de tablas sobrantes
-- ----------------------------------------------------------------------------
-- tareas:                3 filas basura de un tutorial ("Configurar Supabase")
-- conversaciones_chat:   duplicada de chat_conversaciones (la real)
-- doctrinas_backup:      322 filas, backup temporal del scraper_juri (cumplió)
-- Las demás (11): vacías y NINGUNA referencia en app ni scraper (auditado).
-- ============================================================================
DROP TABLE IF EXISTS public.tareas;
DROP TABLE IF EXISTS public.conversaciones_chat;
DROP TABLE IF EXISTS public.doctrinas_backup;
DROP TABLE IF EXISTS public.busquedas_semanticas;
DROP TABLE IF EXISTS public.documentos_legales;
DROP TABLE IF EXISTS public.escritos_legales;
DROP TABLE IF EXISTS public.estadisticas_usuario;
DROP TABLE IF EXISTS public.estrategias_comparaciones;
DROP TABLE IF EXISTS public.favoritos_jurisprudencia;
DROP TABLE IF EXISTS public.notificaciones;
-- reportes_guardados ya se eliminó en la sección 1.5 (antes de recrear
-- calculos_guardados, por su FK calculo_id → calculos_guardados.id).
-- DROP TABLE IF EXISTS public.reportes_guardados;

-- ============================================================================
-- FIN. Verificación:
--   select tablename from pg_tables where schemaname='public'
--   and tablename in ('sentencias_favoritas','criterios_dia','agenda_eventos',
--                     'calculos_guardados','tribunales');
--   -- Deben existir las 5. Las 13 eliminadas ya no deben aparecer.
-- ============================================================================