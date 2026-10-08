-- Tabla de documentos escaneados (repositorio de escaneos del asistente legal)
create table if not exists public.documentos_escaneados (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  titulo text not null default 'Documento',
  paginas_urls jsonb not null default '[]'::jsonb,
  texto_ocr text,
  thumbnail_url text,
  fecha_creacion timestamptz not null default now()
);

create index if not exists documentos_escaneados_user_id_idx
  on public.documentos_escaneados (user_id, fecha_creacion desc);

alter table public.documentos_escaneados enable row level security;

drop policy if exists "documentos_escaneados_select_own" on public.documentos_escaneados;
drop policy if exists "documentos_escaneados_insert_own" on public.documentos_escaneados;
drop policy if exists "documentos_escaneados_update_own" on public.documentos_escaneados;
drop policy if exists "documentos_escaneados_delete_own" on public.documentos_escaneados;

create policy "documentos_escaneados_select_own" on public.documentos_escaneados
  for select using (auth.uid() = user_id);
create policy "documentos_escaneados_insert_own" on public.documentos_escaneados
  for insert with check (auth.uid() = user_id);
create policy "documentos_escaneados_update_own" on public.documentos_escaneados
  for update using (auth.uid() = user_id);
create policy "documentos_escaneados_delete_own" on public.documentos_escaneados
  for delete using (auth.uid() = user_id);
