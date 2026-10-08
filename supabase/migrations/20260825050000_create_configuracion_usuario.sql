-- Configuración del usuario (membrete/logo para documentos)

create table if not exists public.configuracion_usuario (
  user_id text primary key,
  membrete_url text,
  updated_at timestamptz not null default now()
);

alter table public.configuracion_usuario enable row level security;

drop policy if exists "config_usuario_select" on public.configuracion_usuario;
drop policy if exists "config_usuario_insert" on public.configuracion_usuario;
drop policy if exists "config_usuario_update" on public.configuracion_usuario;
drop policy if exists "config_usuario_delete" on public.configuracion_usuario;

create policy "config_usuario_select" on public.configuracion_usuario
  for select using (true);
create policy "config_usuario_insert" on public.configuracion_usuario
  for insert with check (true);
create policy "config_usuario_update" on public.configuracion_usuario
  for update using (true);
create policy "config_usuario_delete" on public.configuracion_usuario
  for delete using (true);
