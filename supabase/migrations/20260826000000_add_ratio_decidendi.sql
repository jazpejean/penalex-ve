-- Columna para el ratio decidendi (criterio de la sala) de cada sentencia.
-- El RAG usará SOLO este campo para fundamentar documentos.

alter table public.documentos
  add column if not exists ratio_decidendi text;
