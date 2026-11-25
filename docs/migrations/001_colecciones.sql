-- Colecciones de sentencias (estilo redes sociales).
-- Cada usuario agrupa sentencias en colecciones con nombre.
-- Aplicar en Supabase (SQL editor) antes de usar la función.

create table if not exists public.colecciones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  descripcion text,
  color text not null default '#0F172A',
  creada_en timestamptz not null default now(),
  actualizada_en timestamptz not null default now()
);

create table if not exists public.coleccion_sentencias (
  id uuid primary key default gen_random_uuid(),
  coleccion_id uuid not null references public.colecciones(id) on delete cascade,
  sentencia_id text not null,
  agregada_en timestamptz not null default now(),
  unique (coleccion_id, sentencia_id)
);

create index if not exists idx_colecciones_user on public.colecciones(user_id);
create index if not exists idx_coleccion_sentencias on public.coleccion_sentencias(coleccion_id);

alter table public.colecciones enable row level security;
alter table public.coleccion_sentencias enable row level security;

drop policy if exists "dueno_colecciones" on public.colecciones;
create policy "dueno_colecciones" on public.colecciones
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "dueno_items" on public.coleccion_sentencias;
create policy "dueno_items" on public.coleccion_sentencias
  for all
  using (
    exists (
      select 1 from public.colecciones c
      where c.id = coleccion_id and c.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.colecciones c
      where c.id = coleccion_id and c.user_id = auth.uid()
    )
  );
