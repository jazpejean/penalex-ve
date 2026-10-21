-- ============================================================================
-- Penalex VE — Tablas faltantes + RPC (corregidas al patrón Firebase)
-- ---------------------------------------------------------------------------
-- Arquitectura real de la app: Firebase Auth como identidad, Supabase como
-- datos. user_id = UID de Firebase (TEXT), NUNCA UUID REFERENCES auth.users.
-- RLS abierta (USING true / WITH CHECK true) porque Firebase ya validó la
-- autenticación (mismo patrón que user_profiles y sentencias_favoritas).
-- Idempotente: se puede re-ejecutar sin errores.
-- Ejecutar en Supabase Dashboard -> SQL Editor.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) sentencias_favoritas (usada por FavoritosService)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sentencias_favoritas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,             -- UID de Firebase
  documento_id TEXT NOT NULL,        -- id del documento en 'sentencias'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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

-- ---------------------------------------------------------------------------
-- 2) ai_tool_usage (usada por AIAnalyticsService)
--    user_id TEXT (UID Firebase), no UUID — corregido respecto a la migración
--    original create_ai_tool_usage.sql.
-- ---------------------------------------------------------------------------
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
  response_time_seconds DECIMAL(10, 3) NOT NULL CHECK (response_time_seconds >= 0 AND response_time_seconds < 3600),
  success BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_user_tool
  ON public.ai_tool_usage(user_id, tool_name);
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_created_at
  ON public.ai_tool_usage(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_metadata
  ON public.ai_tool_usage USING GIN (metadata);

ALTER TABLE public.ai_tool_usage ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ai_usage_select_all" ON public.ai_tool_usage;
CREATE POLICY "ai_usage_select_all" ON public.ai_tool_usage
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "ai_usage_insert_all" ON public.ai_tool_usage;
CREATE POLICY "ai_usage_insert_all" ON public.ai_tool_usage
  FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "ai_usage_update_all" ON public.ai_tool_usage;
CREATE POLICY "ai_usage_update_all" ON public.ai_tool_usage
  FOR UPDATE USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "ai_usage_delete_all" ON public.ai_tool_usage;
CREATE POLICY "ai_usage_delete_all" ON public.ai_tool_usage
  FOR DELETE USING (true);

-- ---------------------------------------------------------------------------
-- 3) RPC analytics (firma p_user_id TEXT, no UUID)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_tool_stats(
  p_user_id TEXT,
  p_tool_name VARCHAR DEFAULT NULL,
  p_days_ago INTEGER DEFAULT 30
)
RETURNS TABLE (
  tool_name VARCHAR,
  total_uses BIGINT,
  successful_uses BIGINT,
  failed_uses BIGINT,
  avg_response_time DECIMAL,
  success_rate DECIMAL
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    atu.tool_name,
    COUNT(*)::BIGINT AS total_uses,
    COUNT(*) FILTER (WHERE atu.success = true)::BIGINT AS successful_uses,
    COUNT(*) FILTER (WHERE atu.success = false)::BIGINT AS failed_uses,
    ROUND(AVG(atu.response_time_seconds)::numeric, 2) AS avg_response_time,
    ROUND((COUNT(*) FILTER (WHERE atu.success = true)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 2) AS success_rate
  FROM public.ai_tool_usage atu
  WHERE atu.user_id = p_user_id
    AND (p_tool_name IS NULL OR atu.tool_name = p_tool_name)
    AND atu.created_at >= NOW() - (p_days_ago || ' days')::INTERVAL
  GROUP BY atu.tool_name
  ORDER BY total_uses DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_hourly_usage_trend(
  p_user_id TEXT,
  p_days_ago INTEGER DEFAULT 7
)
RETURNS TABLE (hour_of_day INTEGER, usage_count BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT EXTRACT(HOUR FROM atu.created_at)::INTEGER AS hour_of_day,
         COUNT(*)::BIGINT AS usage_count
  FROM public.ai_tool_usage atu
  WHERE atu.user_id = p_user_id
    AND atu.created_at >= NOW() - (p_days_ago || ' days')::INTERVAL
  GROUP BY hour_of_day
  ORDER BY hour_of_day;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_weekly_usage_trend(
  p_user_id TEXT,
  p_weeks INTEGER DEFAULT 12
)
RETURNS TABLE (week_start DATE, tool_name VARCHAR, usage_count BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT DATE_TRUNC('week', atu.created_at)::DATE AS week_start,
         atu.tool_name,
         COUNT(*)::BIGINT AS usage_count
  FROM public.ai_tool_usage atu
  WHERE atu.user_id = p_user_id
    AND atu.created_at >= NOW() - (p_weeks || ' weeks')::INTERVAL
  GROUP BY week_start, atu.tool_name
  ORDER BY week_start DESC, usage_count DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_most_used_tool(
  p_user_id TEXT,
  p_days_ago INTEGER DEFAULT 30
)
RETURNS TABLE (tool_name VARCHAR, usage_count BIGINT, percentage DECIMAL)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  total_uses BIGINT;
BEGIN
  SELECT COUNT(*) INTO total_uses
  FROM public.ai_tool_usage
  WHERE user_id = p_user_id
    AND created_at >= NOW() - (p_days_ago || ' days')::INTERVAL;

  RETURN QUERY
  SELECT atu.tool_name,
         COUNT(*)::BIGINT AS usage_count,
         ROUND((COUNT(*)::DECIMAL / NULLIF(total_uses, 0)) * 100, 2) AS percentage
  FROM public.ai_tool_usage atu
  WHERE atu.user_id = p_user_id
    AND atu.created_at >= NOW() - (p_days_ago || ' days')::INTERVAL
  GROUP BY atu.tool_name
  ORDER BY usage_count DESC
  LIMIT 1;
END;
$$;

-- ---------------------------------------------------------------------------
-- 4) RPC increment_message_count — tabla REAL: chat_conversaciones
--    (la migración original apuntaba a chat_conversations, que NO existe)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.increment_message_count(conv_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.chat_conversaciones
  SET message_count = message_count + 1, updated_at = NOW()
  WHERE id = conv_id;
END;
$$;

-- ============================================================================
-- FIN. Verificar: select tablename from pg_tables
-- where schemaname='public' and tablename in ('sentencias_favoritas','ai_tool_usage');
-- ============================================================================