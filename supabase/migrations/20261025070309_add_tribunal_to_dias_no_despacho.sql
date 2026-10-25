-- Días sin despacho asociados a un tribunal del catálogo (opcional).
-- Decisión del usuario: al agregar un día sin despacho se busca el
-- tribunal (igual que al agendar una audiencia). Si tribunal_id es NULL,
-- el día aplica a toda la agenda personal (comportamiento anterior).
ALTER TABLE public.dias_no_despacho
  ADD COLUMN IF NOT EXISTS tribunal_id text,
  ADD COLUMN IF NOT EXISTS tribunal_nombre text;

-- Índice opcional para filtrar días sin despacho por tribunal.
CREATE INDEX IF NOT EXISTS idx_dias_no_despacho_tribunal
  ON public.dias_no_despacho (user_id, tribunal_id);