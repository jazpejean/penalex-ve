-- ========================================
-- PORTAFOLIO DE EXPEDIENTES EN SUPABASE
-- ========================================
-- Un expediente (portafolio) se crea automáticamente al agendar una
-- audiencia con número de expediente. Agrupa: datos de la causa,
-- tribunal, estado procesal y los documentos del caso (vínculo con
-- documentos_escaneados). RLS por usuario (auth.uid() = user_id).

-- 1. Tabla de expedientes
CREATE TABLE IF NOT EXISTS expedientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    numero_expediente TEXT NOT NULL,
    imputado TEXT NOT NULL,
    cedula TEXT,
    delitos TEXT,
    tribunal_id TEXT,
    tribunal_nombre TEXT,
    estado_procesal TEXT,
    fecha_audiencia TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_expedientes_user_id ON expedientes(user_id);
CREATE INDEX IF NOT EXISTS idx_expedientes_numero ON expedientes(numero_expediente);

-- 2. Vínculo documentos -> expediente (columna nueva en documentos_escaneados)
ALTER TABLE documentos_escaneados
    ADD COLUMN IF NOT EXISTS expediente_id UUID REFERENCES expedientes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_documentos_expediente
    ON documentos_escaneados(expediente_id);

-- 3. Row Level Security
ALTER TABLE expedientes ENABLE ROW LEVEL SECURITY;

-- Políticas para expedientes
CREATE POLICY "Usuarios pueden ver sus propios expedientes"
    ON expedientes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden crear sus propios expedientes"
    ON expedientes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden actualizar sus propios expedientes"
    ON expedientes FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden eliminar sus propios expedientes"
    ON expedientes FOR DELETE
    USING (auth.uid() = user_id);