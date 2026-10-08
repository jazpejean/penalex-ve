-- Comparador de estrategias: persistencia en Supabase (UID de Firebase como user_id)

create table if not exists public.estrategias_comparaciones (
  id text primary key,
  user_id text not null,
  titulo text not null default 'Comparación',
  caso_id text,
  estrategias jsonb not null default '[]'::jsonb,
  notas text,
  fecha_creacion timestamptz not null default now()
);
create index if not exists idx_comp_estrategias_user
  on public.estrategias_comparaciones (user_id, fecha_creacion desc);

alter table public.estrategias_comparaciones enable row level security;

drop policy if exists "estrategias_comp_select" on public.estrategias_comparaciones;
drop policy if exists "estrategias_comp_insert" on public.estrategias_comparaciones;
drop policy if exists "estrategias_comp_update" on public.estrategias_comparaciones;
drop policy if exists "estrategias_comp_delete" on public.estrategias_comparaciones;

create policy "estrategias_comp_select" on public.estrategias_comparaciones
  for select using (true);
create policy "estrategias_comp_insert" on public.estrategias_comparaciones
  for insert with check (true);
create policy "estrategias_comp_update" on public.estrategias_comparaciones
  for update using (true);
create policy "estrategias_comp_delete" on public.estrategias_comparaciones
  for delete using (true);
