-- ==============================================================================
-- MIGRACIÓN: Crear tabla de perfiles de usuario y configurar RLS
-- ==============================================================================
-- Descripción: Esta migración crea la tabla user_profiles para almacenar
--              información adicional de los usuarios y configura las políticas
--              de seguridad Row Level Security (RLS)
-- ==============================================================================

-- 1. Crear tabla de perfiles de usuario
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'moderator')),
  email_verified BOOLEAN DEFAULT false,
  last_device_id TEXT,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON public.user_profiles(created_at DESC);

-- 3. Función para actualizar automáticamente el campo updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger para actualizar updated_at en cada modificación
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 5. Habilitar Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 6. Política: Los usuarios pueden ver su propio perfil
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile"
  ON public.user_profiles
  FOR SELECT
  USING (auth.uid() = id);

-- 7. Política: Los usuarios pueden actualizar su propio perfil
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 8. Política: Los usuarios pueden insertar su propio perfil
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 9. Política: Los administradores pueden ver todos los perfiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.user_profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 10. Política: Los administradores pueden actualizar cualquier perfil
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.user_profiles;
CREATE POLICY "Admins can update all profiles"
  ON public.user_profiles
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 11. Comentarios para documentar la tabla y columnas
COMMENT ON TABLE public.user_profiles IS 'Perfiles de usuario con información adicional y metadata';
COMMENT ON COLUMN public.user_profiles.id IS 'ID del usuario (referencia a auth.users)';
COMMENT ON COLUMN public.user_profiles.name IS 'Nombre completo del usuario';
COMMENT ON COLUMN public.user_profiles.email IS 'Correo electrónico del usuario';
COMMENT ON COLUMN public.user_profiles.role IS 'Rol del usuario: user (predeterminado), admin, moderator';
COMMENT ON COLUMN public.user_profiles.email_verified IS 'Indica si el email ha sido verificado';
COMMENT ON COLUMN public.user_profiles.last_device_id IS 'ID del último dispositivo usado para login';
COMMENT ON COLUMN public.user_profiles.last_login IS 'Fecha y hora del último inicio de sesión';
COMMENT ON COLUMN public.user_profiles.created_at IS 'Fecha de creación del perfil';
COMMENT ON COLUMN public.user_profiles.updated_at IS 'Fecha de última actualización del perfil';

-- ==============================================================================
-- FIN DE LA MIGRACIÓN
-- ==============================================================================
