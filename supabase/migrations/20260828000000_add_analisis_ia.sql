-- Módulo de Jurisprudencia: análisis profundo generado por IA (lazy).
-- Se guarda una sola vez para no gastar tokens en futuras consultas.
alter table public.documentos add column if not exists analisis_ia text;
