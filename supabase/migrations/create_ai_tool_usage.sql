-- ============================================================================
-- Tabla: ai_tool_usage
-- Descripción: Tracking de uso de herramientas IA del Asistente Legal
-- Autor: Sistema Penalex
-- Fecha: 2024
-- ============================================================================

-- Crear tabla principal
CREATE TABLE IF NOT EXISTS public.ai_tool_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Información de la herramienta
    tool_name VARCHAR(100) NOT NULL CHECK (tool_name IN (
        'chat_legal',
        'redactor_documentos', 
        'escaner_documentos',
        'comparador_estrategias'
    )),
    
    -- Tipo de acción realizada
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN (
        'query',           -- Consulta/pregunta
        'generation',      -- Generación de contenido
        'analysis',        -- Análisis de documento
        'comparison',      -- Comparación de estrategias
        'scan',           -- Escaneo de documento
        'export'          -- Exportación de resultado
    )),
    
    -- Métricas de rendimiento
    response_time_seconds DECIMAL(10, 3) NOT NULL CHECK (response_time_seconds >= 0),
    success BOOLEAN NOT NULL DEFAULT true,
    
    -- Metadata adicional (JSON flexible)
    metadata JSONB DEFAULT '{}'::jsonb,
    -- Ejemplos de metadata:
    -- {"document_type": "recurso_apelacion", "words_generated": 1250}
    -- {"strategies_compared": 4, "best_score": 0.87}
    -- {"pages_scanned": 3, "ocr_confidence": 0.95}
    
    -- Auditoría
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_response_time CHECK (response_time_seconds < 3600) -- Max 1 hora
);

-- ============================================================================
-- INDEXES para optimizar consultas
-- ============================================================================

-- Index compuesto para consultas por usuario y herramienta
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_user_tool 
ON public.ai_tool_usage(user_id, tool_name);

-- Index para consultas por fecha (análisis temporal)
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_created_at 
ON public.ai_tool_usage(created_at DESC);

-- Index para consultas por herramienta y fecha
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_tool_date 
ON public.ai_tool_usage(tool_name, created_at DESC);

-- Index para análisis de éxito
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_success 
ON public.ai_tool_usage(tool_name, success);

-- Index GIN para búsquedas en metadata
CREATE INDEX IF NOT EXISTS idx_ai_tool_usage_metadata 
ON public.ai_tool_usage USING GIN (metadata);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.ai_tool_usage ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo pueden ver sus propios registros
CREATE POLICY "Users can view own usage data"
ON public.ai_tool_usage
FOR SELECT
USING (auth.uid() = user_id);

-- Política: Los usuarios pueden insertar sus propios registros
CREATE POLICY "Users can insert own usage data"
ON public.ai_tool_usage
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Política: Admins pueden ver todo (opcional, ajustar según rol)
CREATE POLICY "Admins can view all usage data"
ON public.ai_tool_usage
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- ============================================================================
-- FUNCIONES ÚTILES
-- ============================================================================

-- Función: Obtener estadísticas agregadas por herramienta
CREATE OR REPLACE FUNCTION get_tool_stats(
    p_user_id UUID,
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
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        atu.tool_name,
        COUNT(*)::BIGINT as total_uses,
        COUNT(*) FILTER (WHERE atu.success = true)::BIGINT as successful_uses,
        COUNT(*) FILTER (WHERE atu.success = false)::BIGINT as failed_uses,
        ROUND(AVG(atu.response_time_seconds)::numeric, 2) as avg_response_time,
        ROUND((COUNT(*) FILTER (WHERE atu.success = true)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 2) as success_rate
    FROM public.ai_tool_usage atu
    WHERE atu.user_id = p_user_id
        AND (p_tool_name IS NULL OR atu.tool_name = p_tool_name)
        AND atu.created_at >= NOW() - (p_days_ago || ' days')::INTERVAL
    GROUP BY atu.tool_name
    ORDER BY total_uses DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: Obtener tendencia horaria (horas pico de uso)
CREATE OR REPLACE FUNCTION get_hourly_usage_trend(
    p_user_id UUID,
    p_days_ago INTEGER DEFAULT 7
)
RETURNS TABLE (
    hour_of_day INTEGER,
    usage_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(HOUR FROM atu.created_at)::INTEGER as hour_of_day,
        COUNT(*)::BIGINT as usage_count
    FROM public.ai_tool_usage atu
    WHERE atu.user_id = p_user_id
        AND atu.created_at >= NOW() - (p_days_ago || ' days')::INTERVAL
    GROUP BY hour_of_day
    ORDER BY hour_of_day;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: Obtener tendencia semanal
CREATE OR REPLACE FUNCTION get_weekly_usage_trend(
    p_user_id UUID,
    p_weeks INTEGER DEFAULT 12
)
RETURNS TABLE (
    week_start DATE,
    tool_name VARCHAR,
    usage_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE_TRUNC('week', atu.created_at)::DATE as week_start,
        atu.tool_name,
        COUNT(*)::BIGINT as usage_count
    FROM public.ai_tool_usage atu
    WHERE atu.user_id = p_user_id
        AND atu.created_at >= NOW() - (p_weeks || ' weeks')::INTERVAL
    GROUP BY week_start, atu.tool_name
    ORDER BY week_start DESC, usage_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: Obtener herramienta más usada
CREATE OR REPLACE FUNCTION get_most_used_tool(
    p_user_id UUID,
    p_days_ago INTEGER DEFAULT 30
)
RETURNS TABLE (
    tool_name VARCHAR,
    usage_count BIGINT,
    percentage DECIMAL
) AS $$
DECLARE
    total_uses BIGINT;
BEGIN
    -- Calcular total de usos
    SELECT COUNT(*) INTO total_uses
    FROM public.ai_tool_usage
    WHERE user_id = p_user_id
        AND created_at >= NOW() - (p_days_ago || ' days')::INTERVAL;
    
    RETURN QUERY
    SELECT 
        atu.tool_name,
        COUNT(*)::BIGINT as usage_count,
        ROUND((COUNT(*)::DECIMAL / NULLIF(total_uses, 0)) * 100, 2) as percentage
    FROM public.ai_tool_usage atu
    WHERE atu.user_id = p_user_id
        AND atu.created_at >= NOW() - (p_days_ago || ' days')::INTERVAL
    GROUP BY atu.tool_name
    ORDER BY usage_count DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: Validar metadata antes de insertar
CREATE OR REPLACE FUNCTION validate_ai_tool_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Asegurar que metadata sea un objeto JSON válido
    IF NEW.metadata IS NULL THEN
        NEW.metadata := '{}'::jsonb;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_metadata
BEFORE INSERT OR UPDATE ON public.ai_tool_usage
FOR EACH ROW
EXECUTE FUNCTION validate_ai_tool_metadata();

-- ============================================================================
-- DATOS DE EJEMPLO (para testing - comentar en producción)
-- ============================================================================

-- Insertar datos de ejemplo (SOLO PARA DESARROLLO)
-- COMENTAR O ELIMINAR ESTAS LÍNEAS EN PRODUCCIÓN
/*
INSERT INTO public.ai_tool_usage (user_id, tool_name, action_type, response_time_seconds, success, metadata)
SELECT 
    (SELECT id FROM auth.users LIMIT 1),
    tool,
    action,
    (random() * 30 + 1)::decimal(10,3),
    random() > 0.1,
    jsonb_build_object('test_data', true)
FROM unnest(ARRAY['chat_legal', 'redactor_documentos', 'escaner_documentos', 'comparador_estrategias']) AS tool,
     unnest(ARRAY['query', 'generation', 'analysis']) AS action,
     generate_series(1, 100);
*/

-- ============================================================================
-- COMENTARIOS
-- ============================================================================

COMMENT ON TABLE public.ai_tool_usage IS 
'Registro de uso de herramientas IA del Asistente Legal para analytics y métricas';

COMMENT ON COLUMN public.ai_tool_usage.tool_name IS 
'Nombre de la herramienta: chat_legal, redactor_documentos, escaner_documentos, comparador_estrategias';

COMMENT ON COLUMN public.ai_tool_usage.action_type IS 
'Tipo de acción realizada: query, generation, analysis, comparison, scan, export';

COMMENT ON COLUMN public.ai_tool_usage.response_time_seconds IS 
'Tiempo de respuesta en segundos (precisión de milisegundos)';

COMMENT ON COLUMN public.ai_tool_usage.metadata IS 
'Datos adicionales en formato JSON: tipo de documento, palabras generadas, nivel de confianza, etc.';

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
