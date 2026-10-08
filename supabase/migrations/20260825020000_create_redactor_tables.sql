-- Redactor de documentos: conversaciones, mensajes y documentos generados

create table if not exists public.redactor_conversaciones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Redacción',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_redactor_conv_user
  on public.redactor_conversaciones (user_id, updated_at desc);

create table if not exists public.redactor_mensajes (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.redactor_conversaciones(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  timestamp timestamptz not null default now()
);
create index if not exists idx_redactor_msg_conv
  on public.redactor_mensajes (conversation_id, timestamp asc);

create table if not exists public.documentos_redactados (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  titulo text not null default 'Documento',
  tipo text,
  contenido text not null,
  fecha_creacion timestamptz not null default now()
);
create index if not exists idx_doc_redactados_user
  on public.documentos_redactados (user_id, fecha_creacion desc);

alter table public.redactor_conversaciones enable row level security;
alter table public.redactor_mensajes enable row level security;
alter table public.documentos_redactados enable row level security;

drop policy if exists "redactor_conv_select_own" on public.redactor_conversaciones;
drop policy if exists "redactor_conv_insert_own" on public.redactor_conversaciones;
drop policy if exists "redactor_conv_update_own" on public.redactor_conversaciones;
drop policy if exists "redactor_conv_delete_own" on public.redactor_conversaciones;

create policy "redactor_conv_select_own" on public.redactor_conversaciones
  for select using (auth.uid() = user_id);
create policy "redactor_conv_insert_own" on public.redactor_conversaciones
  for insert with check (auth.uid() = user_id);
create policy "redactor_conv_update_own" on public.redactor_conversaciones
  for update using (auth.uid() = user_id);
create policy "redactor_conv_delete_own" on public.redactor_conversaciones
  for delete using (auth.uid() = user_id);

drop policy if exists "redactor_msg_select_own" on public.redactor_mensajes;
drop policy if exists "redactor_msg_insert_own" on public.redactor_mensajes;
drop policy if exists "redactor_msg_delete_own" on public.redactor_mensajes;

create policy "redactor_msg_select_own" on public.redactor_mensajes
  for select using (
    exists (
      select 1 from public.redactor_conversaciones c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );
create policy "redactor_msg_insert_own" on public.redactor_mensajes
  for insert with check (
    exists (
      select 1 from public.redactor_conversaciones c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );
create policy "redactor_msg_delete_own" on public.redactor_mensajes
  for delete using (
    exists (
      select 1 from public.redactor_conversaciones c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );

drop policy if exists "doc_redactados_select_own" on public.documentos_redactados;
drop policy if exists "doc_redactados_insert_own" on public.documentos_redactados;
drop policy if exists "doc_redactados_delete_own" on public.documentos_redactados;

create policy "doc_redactados_select_own" on public.documentos_redactados
  for select using (auth.uid() = user_id);
create policy "doc_redactados_insert_own" on public.documentos_redactados
  for insert with check (auth.uid() = user_id);
create policy "doc_redactados_delete_own" on public.documentos_redactados
  for delete using (auth.uid() = user_id);
