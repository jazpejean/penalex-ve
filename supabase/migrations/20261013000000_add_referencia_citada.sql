-- Migración: referencia de la sentencia del TSJ citada como fuente de cada
-- criterio jurisprudencial (anti-alucinación del redactor).
-- Una sentencia analizada puede citar OTRAS sentencias del TSJ (ej: "Sentencia
-- Nº 397, de fecha 21-06-2005, Sala de Casación Penal, ponente ..."). Antes esta
-- referencia se perdía y el redactor inventaba número/fecha/ponente. Ahora se
-- guarda literal (validado contra el texto fuente en el scraper).

ALTER TABLE doctrinas
  ADD COLUMN IF NOT EXISTS referencia_citada text;

COMMENT ON COLUMN doctrinas.referencia_citada IS
  'Identificación literal de la sentencia del TSJ citada como fuente del criterio (ej: "Sentencia Nº 142, 26-04-2011, Sala de Casación Penal, ponente Blanca Rosa Mármol de León"). NULL si el criterio es de la propia sentencia analizada.';

-- Índice para futuras búsquedas por sentencia citada
CREATE INDEX IF NOT EXISTS idx_doctrinas_referencia_citada
  ON doctrinas (referencia_citada)
  WHERE referencia_citada IS NOT NULL;