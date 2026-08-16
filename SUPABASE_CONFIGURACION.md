# Configuración de Supabase para Penalex VE

## Problemas actuales detectados:

1. ❌ **Google Sign-In no funciona**: "unsupported provider: provider is not enabled"
2. ❌ **Registro con email/password no funciona**: No se está creando el usuario

---

## Solución 1: Habilitar Google Sign-In

### Paso 1: Ir a Authentication Settings
1. Abre tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Ve a **Authentication** → **Providers**
3. Busca **Google** en la lista

### Paso 2: Configurar Google OAuth
1. Habilita el toggle de **Google**
2. Necesitas crear credenciales en Google Cloud Console:
   - Ve a [Google Cloud Console](https://console.cloud.google.com/)
   - Crea un nuevo proyecto o usa uno existente
   - Ve a **APIs & Services** → **Credentials**
   - Crea **OAuth 2.0 Client ID**
   - Tipo: **Web application**
   - **Authorized redirect URIs**: Copia la URL que Supabase te muestra (formato: `https://[TU-PROJECT-ID].supabase.co/auth/v1/callback`)

3. Copia el **Client ID** y **Client Secret** a Supabase
4. Guarda los cambios

---

## Solución 2: Verificar/Crear tabla user_profiles

El código intenta insertar datos en `user_profiles` al registrarse. Esta tabla debe existir.

### Paso 1: Verificar si existe la tabla
1. Ve a **Table Editor** en Supabase Dashboard
2. Busca la tabla `user_profiles`

### Paso 2: Si NO existe, créala con este SQL

Ve a **SQL Editor** y ejecuta:

```sql
-- Crear tabla user_profiles
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  email_verified BOOLEAN DEFAULT FALSE,
  last_device_id TEXT,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios pueden leer su propio perfil
CREATE POLICY "Usuarios pueden leer su propio perfil"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Política: Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Usuarios pueden actualizar su propio perfil"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Política: Sistema puede insertar perfiles (durante registro)
CREATE POLICY "Sistema puede insertar perfiles"
  ON public.user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## Solución 3: Configurar Email Authentication

### Verificar que Email esté habilitado
1. Ve a **Authentication** → **Providers**
2. Busca **Email**
3. Asegúrate que esté **HABILITADO**
4. Configura:
   - ✅ **Enable email provider**
   - ✅ **Confirm email** (requiere verificación por correo)
   - Configura **Email templates** si lo deseas

---

## Solución 4: Configurar URL de redirección

### Para la app Flutter:
1. Ve a **Authentication** → **URL Configuration**
2. En **Redirect URLs**, agrega:
   ```
   io.supabase.penalex://login-callback
   io.supabase.penalex://reset-password
   ```

### Para web (si aplica):
1. Agrega también:
   ```
   http://localhost:3000/reset-password
   [TU-DOMINIO-PRODUCCION]/reset-password
   ```

---

## Testing después de configurar:

### Test 1: Registro con Email
1. Abre la app
2. Ve a "Regístrate"
3. Completa el formulario
4. Verifica que:
   - ✅ Muestra diálogo "Registro exitoso"
   - ✅ Recibes email de verificación
   - ✅ Se crea el usuario en **Authentication** → **Users**
   - ✅ Se crea el perfil en **Table Editor** → **user_profiles**

### Test 2: Login con Email
1. Ve a tu correo
2. Haz clic en el link de verificación
3. Vuelve a la app
4. Inicia sesión con tu email y contraseña
5. Verifica que entras a la app

### Test 3: Google Sign-In
1. Haz clic en "Iniciar con Google"
2. Se abre navegador con login de Google
3. Selecciona tu cuenta
4. Verifica que:
   - ✅ Te redirige a la app
   - ✅ Estás autenticado
   - ✅ Se crea el usuario en Supabase

---

## Debugging adicional

Si sigue sin funcionar:

### Ver logs en Supabase:
1. Ve a **Logs** → **Auth Logs**
2. Busca errores recientes
3. Los errores te dirán exactamente qué falta

### Ver logs en la app:
1. Ejecuta la app con `flutter run`
2. Busca en la consola mensajes que empiecen con:
   - `❌ Error al registrarse:`
   - `Error en Google Sign-In:`
   - `Error registrando dispositivo:`

---

## Notas importantes:

- **Email de verificación**: El usuario DEBE verificar su correo antes de poder iniciar sesión
- **RLS Policies**: Sin las políticas correctas, el insert a `user_profiles` fallará con "permission denied"
- **Google OAuth**: Requiere configuración en Google Cloud Console (no es instantáneo)

---

## Contacto y soporte

Si después de seguir estos pasos sigue sin funcionar:
1. Revisa los logs de Supabase Dashboard
2. Revisa la consola de Flutter
3. Verifica que el `.env` tenga las credenciales correctas de Supabase
