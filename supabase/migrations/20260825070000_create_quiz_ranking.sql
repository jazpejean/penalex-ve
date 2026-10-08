-- Ranking global del quiz (tabla diminuta; no afecta el límite de storage).
-- Los datos masivos (preguntas y progreso) viven en Storage.

create table if not exists public.quiz_ranking (
  user_id text primary key,
  nombre text not null default 'Usuario',
  xp integer not null default 0,
  nivel_actual integer not null default 1,
  rango_actual text not null default 'Alguacil de Sala',
  updated_at timestamptz not null default now()
);

create index if not exists idx_quiz_ranking_xp
  on public.quiz_ranking (xp desc);

alter table public.quiz_ranking enable row level security;

drop policy if exists "quiz_ranking_select" on public.quiz_ranking;
drop policy if exists "quiz_ranking_insert" on public.quiz_ranking;
drop policy if exists "quiz_ranking_update" on public.quiz_ranking;

create policy "quiz_ranking_select" on public.quiz_ranking
  for select using (true);
create policy "quiz_ranking_insert" on public.quiz_ranking
  for insert with check (true);
create policy "quiz_ranking_update" on public.quiz_ranking
  for update using (true);
