-- MIGRACIÓN: es_mero_tramite en sentencias
-- Diferenciar decisiones de mero trámite (autos de mera sustanciación que no
-- sientan doctrina: notificar, colocar a la orden, solicitar información,
-- perención, etc.) de las de fondo, para que el pipeline no gaste IA en ellas.

ALTER TABLE public.sentencias
  ADD COLUMN IF NOT EXISTS es_mero_tramite boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.sentencias.es_mero_tramite
  IS 'true = decisión de mero trámite (sin análisis IA); el pipeline la marca
      automáticamente por extensión (< MIN_CHARS_ANALISIS) o a criterio legal.';