-- ==============================================================================
-- RLS: lectura anónima para el buscador y el RAG
-- ------------------------------------------------------------------------------
-- La app consulta con la anon key las tablas de corpus público que alimentan el
-- buscador de jurisprudencias y el RAG (Ulpiano): sentencias, doctrinas,
-- articulos y glosario_terminos.
--
-- - sentencias / doctrinas / articulos: corpus público de referencia -> SELECT
--   para anon + authenticated (USING (true)).
-- - glosario_terminos: solo términos aprobados se exponen públicamente.
--
-- Los escritos administrativos (pipeline del scraper) usan la service key, que
-- ignora RLS. Patrón consistente con las demás migraciones del repo
-- (drop policy if exists + create policy + enable row level security).
-- ==============================================================================

-- 1. sentencias (buscador de jurisprudencia + RAG)
alter table public.sentencias enable row level security;

drop policy if exists "sentencias_select_publico" on public.sentencias;
create policy "sentencias_select_publico" on public.sentencias
  for select
  to anon, authenticated
  using (true);

-- 2. doctrinas (criterios de la Sala extraídos por IA)
alter table public.doctrinas enable row level security;

drop policy if exists "doctrinas_select_publico" on public.doctrinas;
create policy "doctrinas_select_publico" on public.doctrinas
  for select
  to anon, authenticated
  using (true);

-- 3. articulos (citas de leyes del corpus)
alter table public.articulos enable row level security;

drop policy if exists "articulos_select_publico" on public.articulos;
create policy "articulos_select_publico" on public.articulos
  for select
  to anon, authenticated
  using (true);

-- 4. glosario_terminos (solo términos aprobados)
alter table public.glosario_terminos enable row level security;

drop policy if exists "glosario_terminos_select_publico" on public.glosario_terminos;
create policy "glosario_terminos_select_publico" on public.glosario_terminos
  for select
  to anon, authenticated
  using (aprobado = true);