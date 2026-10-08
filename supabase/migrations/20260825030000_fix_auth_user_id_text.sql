-- Corrección de estrategia de autenticación:
-- La app usa Firebase Auth y guarda el UID de Firebase como user_id (TEXT).
-- Las tablas de datos usan RLS permisiva (Firebase controla el acceso).

drop table if exists public.documentos_redactados cascade;
drop table if exists public.redactor_mensajes cascade;
drop table if exists public.redactor_conversaciones cascade;
drop table if exists public.chat_messages cascade;
drop table if exists public.chat_conversaciones cascade;
drop table if exists public.documentos_escaneados cascade;

-- ---------------------------------------------------------------------------
-- Escáner
-- ---------------------------------------------------------------------------
create table public.documentos_escaneados (
  id text primary key,
  user_id text not null,
  titulo text not null default 'Documento',
  paginas_urls jsonb not null default '[]'::jsonb,
  texto_ocr text,
  thumbnail_url text,
  fecha_creacion timestamptz not null default now()
);
create index idx_documentos_escaneados_user_id on public.documentos_escaneados (user_id, fecha_creacion desc);

-- ---------------------------------------------------------------------------
-- Chat legal
-- ---------------------------------------------------------------------------
create table public.chat_conversaciones (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  title text not null default 'Nueva conversación',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  message_count integer not null default 0,
  is_pinned boolean not null default false
);
create index idx_chat_conversaciones_user_id on public.chat_conversaciones (user_id, updated_at desc);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversaciones(id) on delete cascade,
  user_id text not null,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  sources jsonb not null default '[]'::jsonb,
  timestamp timestamptz not null default now(),
  model_used text,
  token_count integer,
  attachment_url text,
  attachment_type text
);
create index idx_chat_messages_conversation_id on public.chat_messages (conversation_id, timestamp asc);

create or replace function public.increment_message_count(conv_id uuid)
returns void language plpgsql security definer as $$
begin
  update public.chat_conversaciones
  set message_count = message_count + 1, updated_at = now()
  where id = conv_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Redactor
-- ---------------------------------------------------------------------------
create table public.redactor_conversaciones (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  title text not null default 'Redacción',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_redactor_conv_user on public.redactor_conversaciones (user_id, updated_at desc);

create table public.redactor_mensajes (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.redactor_conversaciones(id) on delete cascade,
  user_id text not null,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  timestamp timestamptz not null default now()
);
create index idx_redactor_msg_conv on public.redactor_mensajes (conversation_id, timestamp asc);

create table public.documentos_redactados (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  titulo text not null default 'Documento',
  tipo text,
  contenido text not null,
  fecha_creacion timestamptz not null default now()
);
create index idx_doc_redactados_user on public.documentos_redactados (user_id, fecha_creacion desc);

-- ---------------------------------------------------------------------------
-- RLS permisiva (la autenticación la controla Firebase; el app filtra por user_id)
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'documentos_escaneados',
    'chat_conversaciones', 'chat_messages',
    'redactor_conversaciones', 'redactor_mensajes', 'documentos_redactados'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "%s_select" on public.%I for select using (true)', t, t);
    execute format('create policy "%s_insert" on public.%I for insert with check (true)', t, t);
    execute format('create policy "%s_update" on public.%I for update using (true)', t, t);
    execute format('create policy "%s_delete" on public.%I for delete using (true)', t, t);
  end loop;
end $$;
