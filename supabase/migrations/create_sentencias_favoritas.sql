-- ==============================================================================
-- MIGRACIÓN: sentencias_favoritas
-- ==============================================================================
-- Tabla de sentencias favoritas compatible con Firebase Auth.
--
-- ⚠️ IMPORTANTE: A diferencia de `favoritos_jurisprudencia` (que usa
-- `user_id UUID REFERENCES auth.users(id)` de Supabase Auth), esta tabla usa
-- `user_id TEXT` con el UID de Firebase, porque la app NO usa Supabase Auth
-- (ver FIREBASE_SUPABASE_SYNC.md). Misma convención que `user_profiles`.
--
-- RLS: políticas abiertas (CHECK true) porque Firebase ya validó la
-- autenticación. El UID de Firebase no es adivinable, mismo patrón que
-- `user_profiles`.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.sentencias_favoritas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,             -- UID de Firebase
  documento_id TEXT NOT NULL,        -- id del documento en la tabla 'documentos'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Un usuario no puede marcar la misma sentencia dos veces
CREATE UNIQUE INDEX IF NOT EXISTS idx_sentencias_favoritas_unique
  ON public.sentencias_favoritas(user_id, documento_id);

CREATE INDEX IF NOT EXISTS idx_sentencias_favoritas_user
  ON public.sentencias_favoritas(user_id);

-- ==============================================================================
-- ROW LEVEL SECURITY
-- ==============================================================================

ALTER TABLE public.sentencias_favoritas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own favorites"
  ON public.sentencias_favoritas
  FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own favorites"
  ON public.sentencias_favoritas
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own favorites"
  ON public.sentencias_favoritas
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete own favorites"
  ON public.sentencias_favoritas
  FOR DELETE
  USING (true);

COMMENT ON TABLE public.sentencias_favoritas IS 'Sentencias favoritas marcadas por usuarios (user_id = UID de Firebase)';
