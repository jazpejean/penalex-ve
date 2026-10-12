-- ============================================================================
-- Penalex VE — Políticas RLS (Row Level Security)
-- Ejecutar en Supabase Dashboard -> SQL Editor (una sola vez).
-- idempotente: se puede re-ejecutar sin errores.
--
-- Arquitectura:
--  * Contenido PÚBLICO (jurisprudencia, leyes, doctrina, ranking):
--      lectura para anon + authenticated.
--  * Contenido PRIVADO (por usuario): solo el dueño (user_id = auth.uid()).
-- La identidad llega vía el worker penalex-auth-bridge (Firebase -> Supabase).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) CONTENIDO PÚBLICO — lectura para todos
-- ---------------------------------------------------------------------------
alter table public.sentencias             enable row level security;
alter table public.documentos_legales     enable row level security;
alter table public.articulos              enable row level security;
alter table public.glosario_terminos      enable row level security;
alter table public.doctrinas              enable row level security;
alter table public.quiz_ranking           enable row level security;

drop policy if exists "publico_select" on public.sentencias;
create policy "publico_select" on public.sentencias
  for select to anon, authenticated using (true);

drop policy if exists "publico_select" on public.documentos_legales;
create policy "publico_select" on public.documentos_legales
  for select to anon, authenticated using (true);

drop policy if exists "publico_select" on public.articulos;
create policy "publico_select" on public.articulos
  for select to anon, authenticated using (true);

drop policy if exists "publico_select" on public.glosario_terminos;
create policy "publico_select" on public.glosario_terminos
  for select to anon, authenticated using (true);

drop policy if exists "publico_select" on public.doctrinas;
create policy "publico_select" on public.doctrinas
  for select to anon, authenticated using (true);

drop policy if exists "ranking_select_publico" on public.quiz_ranking;
create policy "ranking_select_publico" on public.quiz_ranking
  for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------------
-- 2) CONTENIDO PRIVADO — por usuario (user_id = auth.uid())
--    select/insert/update/delete solo del propio usuario.
-- ---------------------------------------------------------------------------
alter table public.user_profiles             enable row level security;
alter table public.configuracion_usuario     enable row level security;
alter table public.favoritos_jurisprudencia  enable row level security;
alter table public.calculos_guardados        enable row level security;
alter table public.estadisticas_usuario      enable row level security;
alter table public.busquedas_semanticas      enable row level security;
alter table public.chat_conversaciones       enable row level security;
alter table public.chat_messages             enable row level security;
alter table public.conversaciones_chat       enable row level security;
alter table public.redactor_conversaciones   enable row level security;
alter table public.redactor_mensajes         enable row level security;
alter table public.documentos_redactados     enable row level security;
alter table public.documentos_escaneados     enable row level security;
alter table public.escritos_legales          enable row level security;
alter table public.estrategias_comparaciones enable row level security;
alter table public.reportes_guardados        enable row level security;
alter table public.notificaciones            enable row level security;
alter table public.tareas                    enable row level security;
alter table public.agenda_eventos            enable row level security;

-- Aplica las 4 políticas (select/insert/update/delete) a cada tabla privada.
do $$
declare
  t text;
begin
  foreach t in array array[
    'user_profiles',
    'configuracion_usuario',
    'favoritos_jurisprudencia',
    'calculos_guardados',
    'estadisticas_usuario',
    'busquedas_semanticas',
    'chat_conversaciones',
    'chat_messages',
    'conversaciones_chat',
    'redactor_conversaciones',
    'redactor_mensajes',
    'documentos_redactados',
    'documentos_escaneados',
    'escritos_legales',
    'estrategias_comparaciones',
    'reportes_guardados',
    'notificaciones',
    'tareas',
    'agenda_eventos'
  ] loop
    execute format('drop policy if exists "propio_select" on public.%I', t);
    execute format('drop policy if exists "propio_insert" on public.%I', t);
    execute format('drop policy if exists "propio_update" on public.%I', t);
    execute format('drop policy if exists "propio_delete" on public.%I', t);
    execute format(
      'create policy "propio_select" on public.%I for select to authenticated using (user_id = auth.uid())',
      t);
    execute format(
      'create policy "propio_insert" on public.%I for insert to authenticated with check (user_id = auth.uid())',
      t);
    execute format(
      'create policy "propio_update" on public.%I for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())',
      t);
    execute format(
      'create policy "propio_delete" on public.%I for delete to authenticated using (user_id = auth.uid())',
      t);
  end loop;
end $$;

-- user_profiles: además, lectura del propio perfil (ya incluida arriba) y
-- escritura solo del dueño (ya incluida). No se exponen perfiles ajenos.

-- ---------------------------------------------------------------------------
-- 3) RANKING: cualquiera lee; el propio usuario inserta/actualiza su marca.
-- ---------------------------------------------------------------------------
drop policy if exists "ranking_insert_propio" on public.quiz_ranking;
create policy "ranking_insert_propio" on public.quiz_ranking
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "ranking_update_propio" on public.quiz_ranking;
create policy "ranking_update_propio" on public.quiz_ranking
  for update to authenticated using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 4) ADMINISTRATIVO (solo service_role): se deja sin políticas públicas.
--    scraper_checkpoints, doctrinas_backup, documentos_legales (escritura)
--    quedan reservados al service_role (el worker del quiz / ingesta).
-- ---------------------------------------------------------------------------

-- Fin. Verificar con: select tablename, policyname from pg_policies
-- where tablename in ('sentencias','favoritos_jurisprudencia','quiz_ranking');