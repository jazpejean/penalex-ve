-- Chat legal: conversaciones y mensajes (Penalex VE)

create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Nueva conversación',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  message_count integer not null default 0,
  is_pinned boolean not null default false
);

create index if not exists idx_chat_conversations_user_id
  on public.chat_conversations (user_id);
create index if not exists idx_chat_conversations_updated_at
  on public.chat_conversations (updated_at desc);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  sources jsonb not null default '[]'::jsonb,
  timestamp timestamptz not null default now(),
  model_used text,
  token_count integer,
  attachment_url text,
  attachment_type text
);

create index if not exists idx_chat_messages_conversation_id
  on public.chat_messages (conversation_id);
create index if not exists idx_chat_messages_timestamp
  on public.chat_messages (timestamp asc);

create or replace function public.increment_message_count(conv_id uuid)
returns void language plpgsql security definer as $$
begin
  update public.chat_conversations
  set message_count = message_count + 1, updated_at = now()
  where id = conv_id;
end;
$$;

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "chat_conv_select_own" on public.chat_conversations;
drop policy if exists "chat_conv_insert_own" on public.chat_conversations;
drop policy if exists "chat_conv_update_own" on public.chat_conversations;
drop policy if exists "chat_conv_delete_own" on public.chat_conversations;

create policy "chat_conv_select_own" on public.chat_conversations
  for select using (auth.uid() = user_id);
create policy "chat_conv_insert_own" on public.chat_conversations
  for insert with check (auth.uid() = user_id);
create policy "chat_conv_update_own" on public.chat_conversations
  for update using (auth.uid() = user_id);
create policy "chat_conv_delete_own" on public.chat_conversations
  for delete using (auth.uid() = user_id);

drop policy if exists "chat_msg_select_own" on public.chat_messages;
drop policy if exists "chat_msg_insert_own" on public.chat_messages;
drop policy if exists "chat_msg_delete_own" on public.chat_messages;

create policy "chat_msg_select_own" on public.chat_messages
  for select using (
    exists (
      select 1 from public.chat_conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );
create policy "chat_msg_insert_own" on public.chat_messages
  for insert with check (
    exists (
      select 1 from public.chat_conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );
create policy "chat_msg_delete_own" on public.chat_messages
  for delete using (
    exists (
      select 1 from public.chat_conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );

-- Realtime (tolerante si no hay permisos para alterar la publicación)
do $$
begin
  begin
    alter publication supabase_realtime add table public.chat_conversations;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table public.chat_messages;
  exception when others then null;
  end;
end $$;
