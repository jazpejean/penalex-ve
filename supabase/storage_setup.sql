-- ==============================================================================
-- CONFIGURACIÓN DE STORAGE BUCKETS PARA PENALEX VE
-- ==============================================================================
-- Este script configura los buckets de almacenamiento y sus políticas
-- ==============================================================================

-- ==============================================================================
-- 1. BUCKET: profile-pictures (Fotos de perfil)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-pictures',
  'profile-pictures',
  true, -- Público para que las imágenes se puedan ver sin auth
  5242880, -- 5 MB máximo
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- Política: Cualquiera puede ver las fotos de perfil
CREATE POLICY "Public profile pictures are viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-pictures');

-- Política: Los usuarios pueden subir/actualizar su propia foto
CREATE POLICY "Users can upload own profile picture"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-pictures' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update own profile picture"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profile-pictures' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own profile picture"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-pictures' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

-- ==============================================================================
-- 2. BUCKET: documents (Documentos legales escaneados)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  false, -- Privado, solo el dueño puede ver
  52428800, -- 50 MB máximo
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];

-- Política: Solo el usuario puede ver sus propios documentos
CREATE POLICY "Users can view own documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'documents' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can upload own documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'documents' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update own documents"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'documents' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own documents"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'documents' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

-- ==============================================================================
-- 3. BUCKET: reports (Reportes PDF generados)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'reports',
  'reports',
  false, -- Privado
  10485760, -- 10 MB máximo
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['application/pdf'];

-- Políticas similares a documents
CREATE POLICY "Users can view own reports"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'reports' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can upload own reports"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'reports' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own reports"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'reports' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

-- ==============================================================================
-- 4. BUCKET: writings (Escritos DOCX generados)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'writings',
  'writings',
  false, -- Privado
  10485760, -- 10 MB máximo
  ARRAY['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword'];

-- Políticas similares
CREATE POLICY "Users can view own writings"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'writings' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can upload own writings"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'writings' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own writings"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'writings' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

-- ==============================================================================
-- ESTRUCTURA DE CARPETAS RECOMENDADA
-- ==============================================================================
-- Cada bucket debe organizar archivos por usuario:
-- 
-- profile-pictures/
--   {user_id}/
--     avatar.jpg
-- 
-- documents/
--   {user_id}/
--     {document_id}.pdf
--     {document_id}_page1.jpg
-- 
-- reports/
--   {user_id}/
--     {report_id}.pdf
-- 
-- writings/
--   {user_id}/
--     {writing_id}.docx
-- ==============================================================================
