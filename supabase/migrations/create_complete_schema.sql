-- ==============================================================================
-- MIGRACIÓN COMPLETA: Esquema de Base de Datos para Penalex VE
-- ==============================================================================
-- Descripción: Crea todas las tablas necesarias para la aplicación incluyendo:
--   - Cálculos de dosimetría guardados
--   - Agenda y eventos
--   - Reportes guardados
--   - Documentos legales
--   - Escritos legales
--   - Conversaciones de chat
--   - Búsquedas guardadas
--   - Historial de búsquedas semánticas
--   - Glosario de términos legales
--   - Estadísticas de usuario
-- ==============================================================================

-- ==============================================================================
-- 1. TABLA: calculos_guardados
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.calculos_guardados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  descripcion TEXT,
  delitos JSONB NOT NULL, -- Array de delitos con sus datos
  tipo_concurso TEXT NOT NULL CHECK (tipo_concurso IN ('ideal', 'real', 'continuado')),
  admision_hechos BOOLEAN DEFAULT false,
  fraccion_admision DOUBLE PRECISION DEFAULT 0,
  pena_total DOUBLE PRECISION NOT NULL,
  pena_minima DOUBLE PRECISION,
  pena_maxima DOUBLE PRECISION,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_calculos_user ON public.calculos_guardados(user_id);
CREATE INDEX idx_calculos_created ON public.calculos_guardados(created_at DESC);

COMMENT ON TABLE public.calculos_guardados IS 'Cálculos de dosimetría penal guardados por los usuarios';

-- ==============================================================================
-- 2. TABLA: agenda_eventos
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.agenda_eventos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  descripcion TEXT,
  fecha_inicio TIMESTAMP WITH TIME ZONE NOT NULL,
  fecha_fin TIMESTAMP WITH TIME ZONE,
  todo_el_dia BOOLEAN DEFAULT false,
  ubicacion TEXT,
  tipo_evento TEXT CHECK (tipo_evento IN ('audiencia', 'reunion', 'vencimiento', 'otro')),
  color TEXT DEFAULT '#0F172A',
  recordatorio_minutos INTEGER, -- Minutos antes del evento para recordar
  completado BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_agenda_user ON public.agenda_eventos(user_id);
CREATE INDEX idx_agenda_fecha_inicio ON public.agenda_eventos(fecha_inicio);
CREATE INDEX idx_agenda_completado ON public.agenda_eventos(completado);

COMMENT ON TABLE public.agenda_eventos IS 'Eventos y citas en la agenda del usuario';

-- ==============================================================================
-- 3. TABLA: reportes_guardados
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.reportes_guardados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  calculo_id UUID REFERENCES public.calculos_guardados(id) ON DELETE SET NULL,
  titulo TEXT NOT NULL,
  tipo_reporte TEXT NOT NULL CHECK (tipo_reporte IN ('dosimetria', 'computo', 'completo')),
  contenido_html TEXT,
  contenido_json JSONB,
  archivo_url TEXT, -- URL del PDF generado en Storage
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_reportes_user ON public.reportes_guardados(user_id);
CREATE INDEX idx_reportes_created ON public.reportes_guardados(created_at DESC);

COMMENT ON TABLE public.reportes_guardados IS 'Reportes PDF generados y guardados';

-- ==============================================================================
-- 4. TABLA: documentos_legales
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.documentos_legales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  tipo_documento TEXT CHECK (tipo_documento IN ('sentencia', 'acta', 'contrato', 'escrito', 'otro')),
  archivo_url TEXT NOT NULL, -- URL en Supabase Storage
  archivo_size BIGINT, -- Tamaño en bytes
  archivo_mime_type TEXT,
  texto_extraido TEXT, -- OCR/texto extraído del documento
  etiquetas TEXT[], -- Tags para organización
  fecha_documento DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_documentos_user ON public.documentos_legales(user_id);
CREATE INDEX idx_documentos_tipo ON public.documentos_legales(tipo_documento);
CREATE INDEX idx_documentos_etiquetas ON public.documentos_legales USING GIN(etiquetas);
CREATE INDEX idx_documentos_texto ON public.documentos_legales USING GIN(to_tsvector('spanish', texto_extraido));

COMMENT ON TABLE public.documentos_legales IS 'Documentos legales escaneados/subidos por usuarios';

-- ==============================================================================
-- 5. TABLA: escritos_legales
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.escritos_legales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  tipo_escrito TEXT NOT NULL CHECK (tipo_escrito IN ('demanda', 'contestacion', 'recurso', 'alegatos', 'otro')),
  contenido TEXT NOT NULL,
  plantilla_usada TEXT,
  variables JSONB, -- Variables usadas en la plantilla
  archivo_url TEXT, -- URL del DOCX generado
  estado TEXT DEFAULT 'borrador' CHECK (estado IN ('borrador', 'finalizado', 'enviado')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_escritos_user ON public.escritos_legales(user_id);
CREATE INDEX idx_escritos_tipo ON public.escritos_legales(tipo_escrito);
CREATE INDEX idx_escritos_estado ON public.escritos_legales(estado);

COMMENT ON TABLE public.escritos_legales IS 'Escritos legales generados por los usuarios';

-- ==============================================================================
-- 6. TABLA: conversaciones_chat
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.conversaciones_chat (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo TEXT,
  tipo_asistente TEXT NOT NULL CHECK (tipo_asistente IN ('legal', 'dosimetria', 'general')),
  mensajes JSONB NOT NULL DEFAULT '[]', -- Array de mensajes {role, content, timestamp}
  contexto JSONB, -- Contexto adicional de la conversación
  activa BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chat_user ON public.conversaciones_chat(user_id);
CREATE INDEX idx_chat_activa ON public.conversaciones_chat(activa);
CREATE INDEX idx_chat_updated ON public.conversaciones_chat(updated_at DESC);

COMMENT ON TABLE public.conversaciones_chat IS 'Conversaciones con asistentes de IA';

-- ==============================================================================
-- 7. TABLA: busquedas_semanticas
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.busquedas_semanticas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  query TEXT NOT NULL,
  resultados JSONB NOT NULL, -- Array de resultados con scores
  filtros JSONB, -- Filtros aplicados (fecha, sala, etc)
  num_resultados INTEGER NOT NULL,
  tiempo_busqueda_ms INTEGER,
  guardada BOOLEAN DEFAULT false,
  nombre_guardado TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_busquedas_user ON public.busquedas_semanticas(user_id);
CREATE INDEX idx_busquedas_guardada ON public.busquedas_semanticas(guardada);
CREATE INDEX idx_busquedas_created ON public.busquedas_semanticas(created_at DESC);

COMMENT ON TABLE public.busquedas_semanticas IS 'Historial de búsquedas semánticas de jurisprudencia';

-- ==============================================================================
-- 8. TABLA: glosario_terminos
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.glosario_terminos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  termino TEXT NOT NULL UNIQUE,
  definicion TEXT NOT NULL,
  ejemplos TEXT[],
  categorias TEXT[],
  referencias TEXT[], -- URLs o citas
  contribuidor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  aprobado BOOLEAN DEFAULT false,
  vistas INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_glosario_termino ON public.glosario_terminos(termino);
CREATE INDEX idx_glosario_categorias ON public.glosario_terminos USING GIN(categorias);
CREATE INDEX idx_glosario_aprobado ON public.glosario_terminos(aprobado);
CREATE INDEX idx_glosario_texto ON public.glosario_terminos USING GIN(to_tsvector('spanish', termino || ' ' || definicion));

COMMENT ON TABLE public.glosario_terminos IS 'Glosario de términos legales';

-- ==============================================================================
-- 9. TABLA: favoritos_jurisprudencia
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.favoritos_jurisprudencia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  documento_id TEXT NOT NULL, -- ID del documento en la tabla 'documentos'
  notas TEXT,
  etiquetas TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_favoritos_unique ON public.favoritos_jurisprudencia(user_id, documento_id);
CREATE INDEX idx_favoritos_user ON public.favoritos_jurisprudencia(user_id);
CREATE INDEX idx_favoritos_etiquetas ON public.favoritos_jurisprudencia USING GIN(etiquetas);

COMMENT ON TABLE public.favoritos_jurisprudencia IS 'Sentencias favoritas marcadas por usuarios';

-- ==============================================================================
-- 10. TABLA: estadisticas_usuario
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.estadisticas_usuario (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  calculos_realizados INTEGER DEFAULT 0,
  documentos_escaneados INTEGER DEFAULT 0,
  busquedas_realizadas INTEGER DEFAULT 0,
  escritos_generados INTEGER DEFAULT 0,
  tiempo_total_app_minutos INTEGER DEFAULT 0,
  racha_dias INTEGER DEFAULT 0,
  ultimo_acceso DATE,
  xp_total INTEGER DEFAULT 0,
  nivel INTEGER DEFAULT 1,
  logros JSONB DEFAULT '[]', -- Array de logros obtenidos
  preferencias JSONB DEFAULT '{}', -- Preferencias del usuario
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.estadisticas_usuario IS 'Estadísticas y gamificación del usuario';

-- ==============================================================================
-- 11. TABLA: notificaciones
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('evento', 'actualizacion', 'logro', 'sistema')),
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  datos JSONB, -- Datos adicionales según el tipo
  leida BOOLEAN DEFAULT false,
  accion_url TEXT, -- Deep link a una pantalla específica
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notif_user ON public.notificaciones(user_id);
CREATE INDEX idx_notif_leida ON public.notificaciones(leida);
CREATE INDEX idx_notif_created ON public.notificaciones(created_at DESC);

COMMENT ON TABLE public.notificaciones IS 'Notificaciones para los usuarios';

-- ==============================================================================
-- TRIGGERS: Actualizar updated_at automáticamente
-- ==============================================================================

-- Función ya existe de la migración anterior
-- CREATE OR REPLACE FUNCTION public.update_updated_at_column() ...

CREATE TRIGGER update_calculos_updated_at BEFORE UPDATE ON public.calculos_guardados
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_agenda_updated_at BEFORE UPDATE ON public.agenda_eventos
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_documentos_updated_at BEFORE UPDATE ON public.documentos_legales
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_escritos_updated_at BEFORE UPDATE ON public.escritos_legales
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_chat_updated_at BEFORE UPDATE ON public.conversaciones_chat
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_glosario_updated_at BEFORE UPDATE ON public.glosario_terminos
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_stats_updated_at BEFORE UPDATE ON public.estadisticas_usuario
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS): Habilitar para todas las tablas
-- ==============================================================================

ALTER TABLE public.calculos_guardados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_eventos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reportes_guardados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentos_legales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escritos_legales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversaciones_chat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.busquedas_semanticas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.glosario_terminos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favoritos_jurisprudencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estadisticas_usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- POLÍTICAS RLS: Los usuarios solo ven/modifican sus propios datos
-- ==============================================================================

-- CALCULOS GUARDADOS
CREATE POLICY "Users can manage own calculations"
  ON public.calculos_guardados
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- AGENDA EVENTOS
CREATE POLICY "Users can manage own events"
  ON public.agenda_eventos
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- REPORTES GUARDADOS
CREATE POLICY "Users can manage own reports"
  ON public.reportes_guardados
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DOCUMENTOS LEGALES
CREATE POLICY "Users can manage own documents"
  ON public.documentos_legales
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ESCRITOS LEGALES
CREATE POLICY "Users can manage own writings"
  ON public.escritos_legales
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- CONVERSACIONES CHAT
CREATE POLICY "Users can manage own chats"
  ON public.conversaciones_chat
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- BUSQUEDAS SEMANTICAS
CREATE POLICY "Users can manage own searches"
  ON public.busquedas_semanticas
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- GLOSARIO (Público para lectura, solo admins/contribuidores pueden escribir)
CREATE POLICY "Everyone can read glossary"
  ON public.glosario_terminos
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can contribute to glossary"
  ON public.glosario_terminos
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Contributors can update own terms"
  ON public.glosario_terminos
  FOR UPDATE
  USING (auth.uid() = contribuidor_id OR 
         EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can delete glossary terms"
  ON public.glosario_terminos
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin'));

-- FAVORITOS JURISPRUDENCIA
CREATE POLICY "Users can manage own favorites"
  ON public.favoritos_jurisprudencia
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ESTADISTICAS USUARIO
CREATE POLICY "Users can view own stats"
  ON public.estadisticas_usuario
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own stats"
  ON public.estadisticas_usuario
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "System can insert user stats"
  ON public.estadisticas_usuario
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- NOTIFICACIONES
CREATE POLICY "Users can view own notifications"
  ON public.notificaciones
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON public.notificaciones
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "System can create notifications"
  ON public.notificaciones
  FOR INSERT
  WITH CHECK (true);

-- ==============================================================================
-- FUNCIONES AUXILIARES
-- ==============================================================================

-- Función para incrementar estadísticas
CREATE OR REPLACE FUNCTION public.increment_user_stat(
  p_user_id UUID,
  p_stat_name TEXT,
  p_increment INTEGER DEFAULT 1
)
RETURNS void AS $$
BEGIN
  INSERT INTO public.estadisticas_usuario (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;
  
  EXECUTE format(
    'UPDATE public.estadisticas_usuario SET %I = %I + $1, updated_at = NOW() WHERE user_id = $2',
    p_stat_name, p_stat_name
  ) USING p_increment, p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear notificación
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_tipo TEXT,
  p_titulo TEXT,
  p_mensaje TEXT,
  p_datos JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO public.notificaciones (user_id, tipo, titulo, mensaje, datos)
  VALUES (p_user_id, p_tipo, p_titulo, p_mensaje, p_datos)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- STORAGE BUCKETS
-- ==============================================================================

-- Nota: Los buckets de Storage se deben crear desde el Dashboard de Supabase
-- o con comandos específicos. Aquí documentamos los necesarios:

-- BUCKETS NECESARIOS:
-- 1. 'profile-pictures' - Fotos de perfil (público)
-- 2. 'documents' - Documentos legales escaneados (privado por usuario)
-- 3. 'reports' - Reportes PDF generados (privado por usuario)
-- 4. 'writings' - Escritos DOCX generados (privado por usuario)

-- ==============================================================================
-- FIN DE LA MIGRACIÓN
-- ==============================================================================
