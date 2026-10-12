-- ==============================================================================
-- equivalencias_articulos: artículos DEROGADOS -> VIGENTES
-- ------------------------------------------------------------------------------
-- Las sentencias antiguas citan normas derogadas (ej. Código de Enjuiciamiento
-- Criminal, sustituido por el Código Orgánico Procesal Penal en 1999). Esta
-- tabla permite al RAG y al buscador resolver "art. 123 CEC" -> "art. X COPP"
-- y advertir al usuario "artículo derogado" con su equivalente vigente.
--
-- La tabla se llena con revisión humana (perfil jurídico): el borrador inicial
-- se genera por IA y lo valida el responsable indicado en verificado_por.
-- ==============================================================================

create table if not exists public.equivalencias_articulos (
  id uuid primary key default gen_random_uuid(),
  instrumento_derogado text not null,  -- ej. 'Código de Enjuiciamiento Criminal'
  articulo_derogado text not null,     -- ej. '123' (admite 'Único', '123-A', ...)
  instrumento_vigente text not null,   -- ej. 'Código Orgánico Procesal Penal'
  articulo_vigente text not null,      -- ej. '123'
  nota text,                           -- matiz jurídico de la equivalencia
  verificado_por text,                 -- responsable de la validación
  created_at timestamptz not null default now(),
  constraint equivalencias_articulos_derogado_ck
    check (instrumento_derogado <> '' and articulo_derogado <> ''),
  constraint equivalencias_articulos_vigente_ck
    check (instrumento_vigente <> '' and articulo_vigente <> '')
);

-- Índices: par único (evita duplicados) y búsquedas por cada lado del mapeo.
create unique index if not exists idx_equivalencias_articulos_par
  on public.equivalencias_articulos
  (instrumento_derogado, articulo_derogado, instrumento_vigente, articulo_vigente);
create index if not exists idx_equivalencias_articulos_derogado
  on public.equivalencias_articulos (instrumento_derogado, articulo_derogado);
create index if not exists idx_equivalencias_articulos_vigente
  on public.equivalencias_articulos (instrumento_vigente, articulo_vigente);

-- RLS: lectura pública (buscador/RAG con anon key); escritura solo service key.
alter table public.equivalencias_articulos enable row level security;

drop policy if exists "equivalencias_articulos_select_publico" on public.equivalencias_articulos;
create policy "equivalencias_articulos_select_publico" on public.equivalencias_articulos
  for select
  to anon, authenticated
  using (true);

comment on table public.equivalencias_articulos is
  'Equivalencias de artículos derogados -> vigentes (ej. CEC -> COPP) para resolver citas de sentencias antiguas';