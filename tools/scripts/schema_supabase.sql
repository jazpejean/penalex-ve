-- ============================================================================
-- SCHEMA SUPABASE PARA PENALEX - REPOSITORIO DE LEYES VENEZOLANAS
-- ============================================================================

-- Habilitar extensión para vectores (búsqueda semántica)
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- TABLA: leyes
-- ============================================================================
CREATE TABLE IF NOT EXISTS leyes (
  id BIGSERIAL PRIMARY KEY,
  codigo TEXT NOT NULL UNIQUE, -- 'CP', 'COPP', etc.
  nombre TEXT NOT NULL,
  num_articulos INT NOT NULL DEFAULT 0,
  num_secciones INT NOT NULL DEFAULT 0,
  caracteres_totales INT NOT NULL DEFAULT 0,
  url_fuente TEXT, -- Link a IAJuriss o fuente original
  vigente BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_leyes_codigo ON leyes(codigo);
CREATE INDEX IF NOT EXISTS idx_leyes_vigente ON leyes(vigente);

-- Comentarios
COMMENT ON TABLE leyes IS 'Leyes venezolanas del repositorio PENALEX';
COMMENT ON COLUMN leyes.codigo IS 'Código único de la ley (CP, COPP, LOPNNA, etc.)';
COMMENT ON COLUMN leyes.num_articulos IS 'Total de artículos en la ley';

-- ============================================================================
-- TABLA: secciones (Jerarquía: LIBRO → TÍTULO → CAPÍTULO → SECCIÓN)
-- ============================================================================
CREATE TABLE IF NOT EXISTS secciones (
  id TEXT PRIMARY KEY, -- 'CP_S1', 'COPP_S25', etc.
  ley_id BIGINT NOT NULL REFERENCES leyes(id) ON DELETE CASCADE,
  parent_id TEXT REFERENCES secciones(id) ON DELETE CASCADE, -- NULL si es raíz
  
  tipo TEXT NOT NULL, -- 'LIBRO', 'TITULO', 'CAPITULO', 'SECCION'
  numero TEXT, -- '1', 'I', 'ÚNICO', etc.
  titulo TEXT NOT NULL,
  
  nivel INT NOT NULL, -- 1=LIBRO, 2=TÍTULO, 3=CAPÍTULO, 4=SECCIÓN
  orden INT NOT NULL, -- Para mantener secuencia
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_secciones_ley ON secciones(ley_id);
CREATE INDEX IF NOT EXISTS idx_secciones_parent ON secciones(parent_id);
CREATE INDEX IF NOT EXISTS idx_secciones_nivel ON secciones(nivel);
CREATE INDEX IF NOT EXISTS idx_secciones_orden ON secciones(ley_id, orden);

-- Comentarios
COMMENT ON TABLE secciones IS 'Jerarquía flexible de secciones (Libros, Títulos, Capítulos, Secciones)';
COMMENT ON COLUMN secciones.parent_id IS 'ID de la sección padre (jerarquía anidada)';
COMMENT ON COLUMN secciones.nivel IS '1=LIBRO, 2=TÍTULO, 3=CAPÍTULO, 4=SECCIÓN';

-- ============================================================================
-- TABLA: articulos
-- ============================================================================
CREATE TABLE IF NOT EXISTS articulos (
  id BIGSERIAL PRIMARY KEY,
  ley_id BIGINT NOT NULL REFERENCES leyes(id) ON DELETE CASCADE,
  seccion_id TEXT REFERENCES secciones(id) ON DELETE SET NULL, -- Puede ser NULL
  
  numero TEXT NOT NULL, -- '1', '405', '493-A', 'ÚNICO'
  titulo TEXT, -- Opcional
  contenido TEXT NOT NULL,
  
  embedding vector(1536), -- OpenAI text-embedding-3-small (1536 dim)
  keywords TEXT[], -- Palabras clave extraídas
  
  orden INT NOT NULL,
  vigente BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_articulos_ley ON articulos(ley_id);
CREATE INDEX IF NOT EXISTS idx_articulos_seccion ON articulos(seccion_id);
CREATE INDEX IF NOT EXISTS idx_articulos_numero ON articulos(ley_id, numero);
CREATE INDEX IF NOT EXISTS idx_articulos_vigente ON articulos(vigente);
CREATE INDEX IF NOT EXISTS idx_articulos_keywords ON articulos USING GIN(keywords);

-- Índice vectorial para búsqueda semántica (HNSW es más rápido que IVFFlat)
CREATE INDEX IF NOT EXISTS idx_articulos_embedding ON articulos 
USING hnsw (embedding vector_cosine_ops);

-- Comentarios
COMMENT ON TABLE articulos IS 'Artículos de las leyes con embeddings para búsqueda semántica';
COMMENT ON COLUMN articulos.embedding IS 'Vector de 1536 dimensiones para búsqueda semántica (OpenAI)';
COMMENT ON COLUMN articulos.keywords IS 'Palabras clave extraídas del contenido';

-- ============================================================================
-- FUNCIONES ÚTILES
-- ============================================================================

-- Función: Búsqueda semántica de artículos
CREATE OR REPLACE FUNCTION buscar_articulos_similares(
  query_embedding vector(1536),
  limite INT DEFAULT 10,
  umbral_similitud FLOAT DEFAULT 0.5
)
RETURNS TABLE (
  articulo_id BIGINT,
  ley_codigo TEXT,
  articulo_numero TEXT,
  articulo_titulo TEXT,
  articulo_contenido TEXT,
  similitud FLOAT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    l.codigo,
    a.numero,
    a.titulo,
    LEFT(a.contenido, 500) AS contenido_preview,
    1 - (a.embedding <=> query_embedding) AS similitud
  FROM articulos a
  JOIN leyes l ON a.ley_id = l.id
  WHERE a.vigente = true
    AND a.embedding IS NOT NULL
    AND (1 - (a.embedding <=> query_embedding)) > umbral_similitud
  ORDER BY a.embedding <=> query_embedding
  LIMIT limite;
END;
$$;

-- Función: Obtener jerarquía completa de un artículo
CREATE OR REPLACE FUNCTION obtener_jerarquia_articulo(articulo_id BIGINT)
RETURNS TABLE (
  nivel INT,
  tipo TEXT,
  numero TEXT,
  titulo TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  seccion_actual TEXT;
BEGIN
  -- Obtener la sección del artículo
  SELECT seccion_id INTO seccion_actual
  FROM articulos
  WHERE id = articulo_id;
  
  -- Retornar jerarquía recursiva
  RETURN QUERY
  WITH RECURSIVE jerarquia AS (
    -- Caso base: sección del artículo
    SELECT s.nivel, s.tipo, s.numero, s.titulo, s.parent_id
    FROM secciones s
    WHERE s.id = seccion_actual
    
    UNION ALL
    
    -- Recursión: padres
    SELECT s.nivel, s.tipo, s.numero, s.titulo, s.parent_id
    FROM secciones s
    INNER JOIN jerarquia j ON s.id = j.parent_id
  )
  SELECT j.nivel, j.tipo, j.numero, j.titulo
  FROM jerarquia j
  ORDER BY j.nivel ASC;
END;
$$;

-- Función: Actualizar contador de artículos en tabla leyes
CREATE OR REPLACE FUNCTION actualizar_contadores_ley()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE leyes
  SET 
    num_articulos = (SELECT COUNT(*) FROM articulos WHERE ley_id = NEW.ley_id),
    updated_at = NOW()
  WHERE id = NEW.ley_id;
  
  RETURN NEW;
END;
$$;

-- Trigger: Actualizar contadores automáticamente
CREATE TRIGGER trigger_actualizar_contadores
AFTER INSERT OR DELETE ON articulos
FOR EACH ROW
EXECUTE FUNCTION actualizar_contadores_ley();

-- ============================================================================
-- POLÍTICAS RLS (Row Level Security) - OPCIONAL
-- ============================================================================

-- Habilitar RLS
ALTER TABLE leyes ENABLE ROW LEVEL SECURITY;
ALTER TABLE secciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE articulos ENABLE ROW LEVEL SECURITY;

-- Política: Lectura pública (todos pueden leer)
CREATE POLICY "Lectura pública de leyes" ON leyes
  FOR SELECT USING (true);

CREATE POLICY "Lectura pública de secciones" ON secciones
  FOR SELECT USING (true);

CREATE POLICY "Lectura pública de artículos" ON articulos
  FOR SELECT USING (true);

-- Políticas de escritura solo para usuarios autenticados (opcional)
-- Descomenta si quieres restringir la escritura
/*
CREATE POLICY "Solo admin puede insertar leyes" ON leyes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Solo admin puede actualizar leyes" ON leyes
  FOR UPDATE USING (auth.role() = 'authenticated');
*/

-- ============================================================================
-- DATOS DE EJEMPLO (Opcional)
-- ============================================================================

-- Insertar una ley de ejemplo
/*
INSERT INTO leyes (codigo, nombre, num_articulos, num_secciones, vigente)
VALUES ('CP', 'Código Penal', 627, 121, true);
*/

-- ============================================================================
-- GRANTS Y PERMISOS
-- ============================================================================

-- Dar permisos al usuario anon (lectura pública)
GRANT SELECT ON leyes TO anon;
GRANT SELECT ON secciones TO anon;
GRANT SELECT ON articulos TO anon;

-- Dar permisos al usuario autenticado
GRANT ALL ON leyes TO authenticated;
GRANT ALL ON secciones TO authenticated;
GRANT ALL ON articulos TO authenticated;

-- ============================================================================
-- FIN DEL SCHEMA
-- ============================================================================

-- Verificar instalación
SELECT 'Schema de PENALEX instalado correctamente' AS status;
