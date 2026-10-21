-- ============================================================================
-- Penalex VE — Migración de la agenda a Supabase (parte 2)
-- Ejecutar en Supabase Dashboard -> SQL Editor (una sola vez; idempotente).
--
-- Qué hace:
--   1) agenda_eventos: añade tribunal_id (FK al catálogo public.tribunales)
--      para vincular cada audiencia con su tribunal real (ficha, mapa, ruta).
--   2) Crea dias_no_despacho (los "userNonWorkingDays" de Firestore) con RLS.
--   3) Asegura índices + RLS para ambas.
-- La identidad llega como auth.uid()::text = UID de Firebase (mismo patrón
-- que el resto del esquema).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) agenda_eventos → columna tribunal_id (FK al catálogo de tribunales)
-- ---------------------------------------------------------------------------
ALTER TABLE public.agenda_eventos
  ADD COLUMN IF NOT EXISTS tribunal_id UUID REFERENCES public.tribunales(id);

-- Índice para el JOIN audiencia→tribunal y para el filtro por tribunal
CREATE INDEX IF NOT EXISTS idx_agenda_eventos_tribunal_id
  ON public.agenda_eventos (tribunal_id);

-- RLS (refuerzo idempotente, por si se recreó la tabla sin políticas)
ALTER TABLE public.agenda_eventos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agenda_select_own" ON public.agenda_eventos;
CREATE POLICY "agenda_select_own" ON public.agenda_eventos
  FOR SELECT USING (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "agenda_insert_own" ON public.agenda_eventos;
CREATE POLICY "agenda_insert_own" ON public.agenda_eventos
  FOR INSERT WITH CHECK (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "agenda_update_own" ON public.agenda_eventos;
CREATE POLICY "agenda_update_own" ON public.agenda_eventos
  FOR UPDATE USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "agenda_delete_own" ON public.agenda_eventos;
CREATE POLICY "agenda_delete_own" ON public.agenda_eventos
  FOR DELETE USING (user_id = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- 2) dias_no_despacho — los "userNonWorkingDays" de Firestore, en Supabase.
--    Por usuario (user_id = UID Firebase), un día marcado como inhábil.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.dias_no_despacho (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,             -- UID de Firebase (RLS)
  fecha TIMESTAMPTZ NOT NULL,
  motivo TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, fecha)
);

CREATE INDEX IF NOT EXISTS idx_dias_no_despacho_user_fecha
  ON public.dias_no_despacho (user_id, fecha);

ALTER TABLE public.dias_no_despacho ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dias_select_own" ON public.dias_no_despacho;
CREATE POLICY "dias_select_own" ON public.dias_no_despacho
  FOR SELECT USING (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "dias_insert_own" ON public.dias_no_despacho;
CREATE POLICY "dias_insert_own" ON public.dias_no_despacho
  FOR INSERT WITH CHECK (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "dias_delete_own" ON public.dias_no_despacho;
CREATE POLICY "dias_delete_own" ON public.dias_no_despacho
  FOR DELETE USING (user_id = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- 3) user_profiles.fcm_token ya existe; solo garantizamos el índice
--    (se usa para empujar recordatorios de audiencias al dispositivo).
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_user_profiles_fcm_token
  ON public.user_profiles (fcm_token);

-- ---------------------------------------------------------------------------
-- 4) Función de búsqueda de tribunales para el selector de la agenda:
--    reutiliza la búsqueda semántica (buscar_tribunales_semanticos) con una
--    variante que además devuelve el id (ya la tenemos; aquí solo aseguramos
--    que existe para la app).
-- ---------------------------------------------------------------------------
-- (no-op: buscar_tribunales_semanticos ya está creada por potenciar_tribunales.sql)