-- ============================================================================
-- ESQUEMA SUPABASE PARA SISTEMA DE QUIZ
-- ============================================================================

-- Tabla de casos hipotéticos (preguntas del quiz)
CREATE TABLE IF NOT EXISTS casos_hipoteticos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nivel INT NOT NULL,
  pool_id INT NOT NULL DEFAULT 1,
  delito_base TEXT NOT NULL,
  agravante TEXT,
  contexto_narrativo TEXT NOT NULL,
  opciones JSONB NOT NULL, -- Array de strings
  respuesta_correcta INT NOT NULL CHECK (respuesta_correcta >= 0 AND respuesta_correcta <= 3),
  dificultad INT DEFAULT 3 CHECK (dificultad >= 1 AND dificultad <= 5),
  tasa_exito DECIMAL(5,2),
  intentos_totales INT DEFAULT 0,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para búsqueda eficiente
CREATE INDEX IF NOT EXISTS idx_casos_nivel ON casos_hipoteticos(nivel) WHERE activo = true;
CREATE INDEX IF NOT EXISTS idx_casos_delito ON casos_hipoteticos(delito_base) WHERE activo = true;
CREATE INDEX IF NOT EXISTS idx_casos_dificultad ON casos_hipoteticos(dificultad, nivel) WHERE activo = true;

-- Tabla de fundamentaciones legales
CREATE TABLE IF NOT EXISTS fundamentaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caso_id UUID REFERENCES casos_hipoteticos(id) ON DELETE CASCADE,
  explicacion TEXT NOT NULL,
  articulos JSONB NOT NULL, -- Array de {codigo, articulo, texto}
  sentencias_ids TEXT[], -- Array de IDs de sentencias
  jurisprudencias_ids TEXT[], -- Array de IDs de jurisprudencias
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fundamentaciones_caso ON fundamentaciones(caso_id);

-- Tabla de pistas (hints para respuestas incorrectas)
CREATE TABLE IF NOT EXISTS pistas_casos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caso_id UUID REFERENCES casos_hipoteticos(id) ON DELETE CASCADE,
  nivel_pista INT NOT NULL CHECK (nivel_pista >= 1 AND nivel_pista <= 3),
  texto_pista TEXT NOT NULL,
  articulos_sugeridos TEXT[],
  busqueda_sugerida TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pistas_caso ON pistas_casos(caso_id, nivel_pista);

-- Tabla de progreso del usuario en el quiz
CREATE TABLE IF NOT EXISTS user_quiz_progress (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nivel_actual INT DEFAULT 1,
  puntos_totales INT DEFAULT 0,
  puntuacion_maxima INT DEFAULT 0,
  racha_actual INT DEFAULT 0,
  racha_maxima INT DEFAULT 0,
  apelaciones INT DEFAULT 5 CHECK (apelaciones >= 0 AND apelaciones <= 5),
  ultima_regeneracion_apelaciones TIMESTAMPTZ DEFAULT now(),
  preguntas_respondidas INT DEFAULT 0,
  preguntas_correctas INT DEFAULT 0,
  tiempo_promedio_respuesta DECIMAL(6,2) DEFAULT 0,
  xp INT DEFAULT 0,
  rango_actual TEXT DEFAULT 'Alguacil',
  region_actual TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de casos fallados por usuario (sistema anti-trampa)
CREATE TABLE IF NOT EXISTS user_casos_fallados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  caso_id UUID REFERENCES casos_hipoteticos(id) ON DELETE CASCADE,
  veces_fallado INT DEFAULT 1,
  ultima_vez_fallado TIMESTAMPTZ DEFAULT now(),
  bloqueado BOOLEAN DEFAULT false,
  estudiado BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, caso_id)
);

CREATE INDEX IF NOT EXISTS idx_casos_fallados_user ON user_casos_fallados(user_id, bloqueado);

-- Tabla de historial de respuestas
CREATE TABLE IF NOT EXISTS user_respuestas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  caso_id UUID REFERENCES casos_hipoteticos(id) ON DELETE CASCADE,
  nivel INT NOT NULL,
  respuesta_seleccionada INT NOT NULL,
  correcta BOOLEAN NOT NULL,
  tiempo_respuesta DECIMAL(6,2), -- En segundos
  racha_actual INT DEFAULT 0,
  puntos_ganados INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_respuestas_user ON user_respuestas(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_respuestas_caso ON user_respuestas(caso_id);

-- Tabla de ranking global
CREATE TABLE IF NOT EXISTS ranking_global (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  nivel_actual INT DEFAULT 1,
  puntos_totales INT DEFAULT 0,
  puntuacion_maxima INT DEFAULT 0,
  racha_maxima INT DEFAULT 0,
  rango_actual TEXT DEFAULT 'Alguacil',
  preguntas_respondidas INT DEFAULT 0,
  preguntas_correctas INT DEFAULT 0,
  tiempo_promedio_respuesta DECIMAL(6,2) DEFAULT 0,
  fecha_registro TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ranking_puntuacion ON ranking_global(puntuacion_maxima DESC, nivel_actual DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Casos hipotéticos: lectura pública, escritura solo admin
ALTER TABLE casos_hipoteticos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Casos son públicos para lectura" ON casos_hipoteticos
  FOR SELECT USING (activo = true);

-- Fundamentaciones: lectura pública
ALTER TABLE fundamentaciones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Fundamentaciones son públicas" ON fundamentaciones
  FOR SELECT USING (true);

-- Pistas: lectura pública
ALTER TABLE pistas_casos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pistas son públicas" ON pistas_casos
  FOR SELECT USING (true);

-- Progreso de usuario: solo el usuario puede ver/editar su progreso
ALTER TABLE user_quiz_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven solo su progreso" ON user_quiz_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuarios actualizan solo su progreso" ON user_quiz_progress
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Usuarios crean solo su progreso" ON user_quiz_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Casos fallados: solo el usuario ve sus errores
ALTER TABLE user_casos_fallados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven solo sus casos fallados" ON user_casos_fallados
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuarios gestionan sus casos fallados" ON user_casos_fallados
  FOR ALL USING (auth.uid() = user_id);

-- Historial de respuestas: solo el usuario ve su historial
ALTER TABLE user_respuestas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven solo sus respuestas" ON user_respuestas
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuarios crean solo sus respuestas" ON user_respuestas
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ranking: lectura pública, actualización automática
ALTER TABLE ranking_global ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ranking es público" ON ranking_global
  FOR SELECT USING (true);

-- ============================================================================
-- FUNCIONES Y TRIGGERS
-- ============================================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para user_quiz_progress
CREATE TRIGGER update_user_quiz_progress_updated_at
  BEFORE UPDATE ON user_quiz_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para ranking_global
CREATE TRIGGER update_ranking_global_updated_at
  BEFORE UPDATE ON ranking_global
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Función para regenerar apelaciones automáticamente
CREATE OR REPLACE FUNCTION regenerar_apelaciones()
RETURNS void AS $$
BEGIN
  UPDATE user_quiz_progress
  SET 
    apelaciones = LEAST(5, apelaciones + FLOOR(EXTRACT(EPOCH FROM (now() - ultima_regeneracion_apelaciones)) / 1800)::int),
    ultima_regeneracion_apelaciones = CASE 
      WHEN apelaciones < 5 THEN now()
      ELSE ultima_regeneracion_apelaciones
    END
  WHERE apelaciones < 5 
    AND EXTRACT(EPOCH FROM (now() - ultima_regeneracion_apelaciones)) >= 1800;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- DATOS INICIALES (10 casos de prueba)
-- ============================================================================

INSERT INTO casos_hipoteticos (nivel, pool_id, delito_base, contexto_narrativo, opciones, respuesta_correcta, dificultad) VALUES
(1, 1, 'Tentativa de Hurto', 'José intenta robar un celular de una mesa en un café, pero el dueño lo ve y lo detiene antes de que pueda salir del local. ¿Cuál es la calificación jurídica correcta?', 
  '["Hurto consumado (Art. 453 CP)", "Tentativa de hurto (Art. 80 + 453 CP)", "Apropiación indebida (Art. 470 CP)", "Acto preparatorio impune"]', 1, 1),

(2, 1, 'Legítima Defensa', 'María es atacada con un cuchillo en la calle. Para defenderse, toma una piedra y golpea al agresor causándole lesiones leves. ¿Cuál es su situación jurídica?',
  '["Homicidio intencional (Art. 405 CP)", "Lesiones personales graves (Art. 413 CP)", "Legítima defensa eximente (Art. 65.3 CP)", "Riña mutua (Art. 424 CP)"]', 2, 1),

(3, 1, 'Homicidio Calificado', 'Luis planea durante 2 semanas el asesinato de su enemigo, comprando armas y vigilándolo. Finalmente lo ejecuta. ¿Cuál es la calificación?',
  '["Homicidio simple (Art. 405 CP)", "Homicidio calificado por premeditación (Art. 406.1 CP)", "Homicidio culposo (Art. 409 CP)", "Homicidio en riña (Art. 424 CP)"]', 1, 2),

(4, 1, 'Robo Agravado', 'Tres sujetos armados asaltan una farmacia de madrugada llevándose dinero y medicinas. ¿Calificación jurídica?',
  '["Hurto calificado (Art. 454 CP)", "Robo simple (Art. 455 CP)", "Robo agravado (Art. 458 CP)", "Extorsión (Art. 16 LOCDO)"]', 2, 2),

(5, 1, 'Femicidio', 'Roberto mata a su expareja por celos y control. Hay antecedentes de violencia doméstica. ¿Qué delito configura?',
  '["Homicidio simple (Art. 405 CP)", "Homicidio calificado (Art. 406 CP)", "Femicidio (Art. 15 LODMVLV)", "Parricidio (Art. 406 CP)"]', 2, 2),

(6, 1, 'Flagrancia', 'Policía detiene a sujeto 20 minutos después del robo con objetos robados y señalado por víctima. ¿Hay flagrancia?',
  '["No hay flagrancia (necesita orden)", "Flagrancia inmediata (Art. 234 COPP)", "Cuasi-flagrancia (Art. 234 COPP)", "Detención ilegal"]', 2, 2),

(7, 1, 'Tráfico de Drogas', 'Interceptan a María en aeropuerto con 2kg de cocaína en maleta. Es su primer delito. ¿Calificación?',
  '["Microtráfico (Art. 151 LOD)", "Tráfico agravado (Art. 149 LOD)", "Posesión para consumo (Art. 152 LOD)", "Tráfico internacional (Art. 149 LOD)"]', 3, 3),

(8, 1, 'Estafa', 'Juan vende un vehículo falseando documentos y haciendo creer que es legítimo propietario. ¿Qué delito comete?',
  '["Hurto (Art. 453 CP)", "Apropiación indebida (Art. 470 CP)", "Estafa (Art. 462 CP)", "Falsificación (Art. 321 CP)"]', 2, 2),

(9, 1, 'Secuestro', 'Grupo armado retiene a empresario por 5 días exigiendo rescate de 100.000 USD. ¿Calificación?',
  '["Privación de libertad (Art. 174 CP)", "Extorsión (Art. 16 LOCDO)", "Secuestro (Art. 3 Ley Contra Secuestro)", "Detención ilegal (Art. 180 CP)"]', 2, 3),

(10, 1, 'Corrupción', 'Funcionario público exige dinero para agilizar trámite legal. ¿Qué delito comete?',
  '["Extorsión (Art. 16 LOCDO)", "Peculado (Art. 52 LAC)", "Concusión (Art. 54 LAC)", "Estafa (Art. 462 CP)"]', 2, 2);

-- ============================================================================
-- COMENTARIOS
-- ============================================================================

COMMENT ON TABLE casos_hipoteticos IS 'Casos hipotéticos de Derecho Penal Venezolano para el quiz';
COMMENT ON TABLE user_quiz_progress IS 'Progreso individual de cada usuario en el quiz';
COMMENT ON TABLE ranking_global IS 'Ranking público de todos los jugadores';
COMMENT ON TABLE user_respuestas IS 'Historial completo de todas las respuestas de los usuarios';
