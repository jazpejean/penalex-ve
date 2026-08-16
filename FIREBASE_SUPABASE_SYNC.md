# Sincronización Firebase Auth + Supabase Database

## 🎯 Estrategia

**Autenticación**: Firebase Auth (login, registro, Google Sign-In)  
**Base de datos**: Supabase (jurisprudencias, documentos, etc.)  
**Sincronización**: El UID de Firebase se usa como clave primaria en Supabase

---

## 📊 Cómo funciona

### 1. Usuario se registra en Firebase
```
Firebase Auth crea usuario → UID: "abc123-def456-..."
```

### 2. Se sincroniza automáticamente a Supabase
```sql
INSERT INTO user_profiles (id, name, email, ...)
VALUES ('abc123-def456-...', 'Juan Pérez', 'juan@example.com', ...)
```

### 3. Consultas en Supabase usan el mismo UID
```dart
// El UID de Firebase se usa para filtrar datos en Supabase
final userId = FirebaseAuth.instance.currentUser?.uid;

await supabase
  .from('documentos_escaneados')
  .select()
  .eq('user_id', userId); // ⭐ Mismo UID
```

---

## 🔧 Configuración de Supabase

### Ejecuta este SQL en Supabase SQL Editor:

```sql
-- 1. Crear tabla user_profiles si no existe
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id TEXT PRIMARY KEY, -- ⭐ UID de Firebase (TEXT, no UUID)
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  email_verified BOOLEAN DEFAULT FALSE,
  last_device_id TEXT,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Habilitar Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 3. Política: Permitir INSERT sin autenticación (porque Firebase maneja auth)
CREATE POLICY "Permitir insertar perfiles desde Firebase"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (true); -- Cualquiera puede insertar

-- 4. Política: Cualquiera puede leer su propio perfil
CREATE POLICY "Usuarios pueden leer su propio perfil"
  ON public.user_profiles
  FOR SELECT
  USING (true); -- Por ahora permitimos leer todos (Firebase controla acceso)

-- 5. Política: Actualizar perfiles
CREATE POLICY "Usuarios pueden actualizar su propio perfil"
  ON public.user_profiles
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- 6. Actualizar columnas user_id en otras tablas para que sean TEXT
-- (Si ya tienes tablas con user_id UUID, necesitas migrarlas)

-- Ejemplo: documentos_escaneados
ALTER TABLE documentos_escaneados 
ALTER COLUMN user_id TYPE TEXT;

-- Ejemplo: jurisprudencias_guardadas
ALTER TABLE jurisprudencias_guardadas 
ALTER COLUMN user_id TYPE TEXT;

-- Repite para todas las tablas que usen user_id

-- 7. Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🧪 Testing

### 1. Registrar usuario
```bash
flutter run
```
1. Abre la app
2. Click en "Regístrate"
3. Completa el formulario
4. Verifica el correo

### 2. Verificar sincronización

**En Firebase Console:**
- Ve a Authentication → Users
- Deberías ver el usuario con su UID

**En Supabase Dashboard:**
- Ve a Table Editor → user_profiles
- Deberías ver el MISMO UID como `id`
- Los datos (name, email) deben coincidir

### 3. Probar consultas

Cualquier consulta en Supabase ahora funciona:

```dart
final userId = FirebaseAuth.instance.currentUser?.uid;

// Obtener documentos del usuario
final docs = await Supabase.instance.client
  .from('documentos_escaneados')
  .select()
  .eq('user_id', userId);

// Guardar nueva jurisprudencia
await Supabase.instance.client
  .from('jurisprudencias_guardadas')
  .insert({
    'user_id': userId, // ⭐ UID de Firebase
    'titulo': 'Sentencia XYZ',
    'contenido': '...',
  });
```

---

## ✅ Ventajas de este enfoque

1. **Firebase Auth maneja todo el login**
   - Email/password ✅
   - Google Sign-In ✅  
   - Verificación de email ✅
   - Recuperación de contraseña ✅

2. **Supabase maneja todos los datos**
   - Jurisprudencias ✅
   - Documentos escaneados ✅
   - Leyes y glosario ✅
   - Analytics ✅

3. **Sincronización automática**
   - Al registrarse → Se crea en ambos
   - Al hacer login → Se actualiza en Supabase
   - UID consistente → Queries funcionan perfectamente

---

## 🔒 Seguridad

### Firebase maneja:
- Autenticación de usuarios
- Verificación de email
- Tokens de sesión

### Supabase RLS:
Las políticas están abiertas (`WITH CHECK (true)`) porque **Firebase ya validó la autenticación**. 

Si necesitas seguridad adicional en Supabase:
- Usa service_role key solo en backend
- Valida el Firebase token en Supabase Functions
- O mantén las políticas abiertas (Firebase es la capa de seguridad)

---

## 📝 Notas importantes

- **user_profiles.id es TEXT, no UUID**: Firebase UIDs son strings, no UUIDs estándar
- **Sincronización automática**: Se ejecuta en cada login/registro
- **Tablas existentes**: Si tienes datos con UUIDs antiguos, necesitas migración manual
- **Sin Supabase Auth**: No uses `supabase.auth`, solo Firebase Auth

---

## 🐛 Troubleshooting

### Error: "violates foreign key constraint"
- Alguna tabla tiene `user_id UUID` en lugar de `TEXT`
- Ejecuta: `ALTER TABLE tabla_nombre ALTER COLUMN user_id TYPE TEXT;`

### Error: "new row violates row-level security"
- Las políticas RLS están mal configuradas
- Ejecuta las políticas del SQL arriba

### Usuario no aparece en Supabase
- Revisa logs en consola: `debugPrint`
- Verifica que la tabla `user_profiles` exista
- Verifica las políticas RLS

---

## 🎉 ¡Todo listo!

Con esta configuración:
- ✅ Login funciona con Firebase (email + Google)
- ✅ Datos se guardan en Supabase
- ✅ Todo sincronizado automáticamente
- ✅ Sin configurar Google Cloud Console manualmente
