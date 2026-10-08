-- Políticas de Storage para los buckets quiz y membres (no existían).
-- El banco de preguntas es contenido COMPARTIDO (no por usuario), por eso se
-- permite lectura y escritura públicas (consistente con el enfoque permisivo
-- del resto de la app, que autentica con Firebase y no tiene sesión Supabase).

create policy "Quiz bank select" on storage.objects
  for select using (bucket_id = 'quiz');
create policy "Quiz bank insert" on storage.objects
  for insert with check (bucket_id = 'quiz');
create policy "Quiz bank update" on storage.objects
  for update using (bucket_id = 'quiz');
create policy "Quiz bank delete" on storage.objects
  for delete using (bucket_id = 'quiz');

create policy "Membretes select" on storage.objects
  for select using (bucket_id = 'membretes');
create policy "Membretes insert" on storage.objects
  for insert with check (bucket_id = 'membretes');
create policy "Membretes update" on storage.objects
  for update using (bucket_id = 'membretes');
create policy "Membretes delete" on storage.objects
  for delete using (bucket_id = 'membretes');
