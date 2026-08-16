# 📂 Sistema de "Documentos Guardados" - Implementación Completa

## 🎯 Objetivo

Permitir que las 3 herramientas principales (Chat Legal, Redactor de Documentos, Comparador de Estrategias) puedan **importar documentos guardados** desde otras partes de la app.

---

## ✅ Herramientas Implementadas

### **1. Chat Legal** ✅
- Botón adjuntar con opciones:
  - 📷 Galería
  - 📸 Cámara
  - 📄 Documento externo
  - 📂 **Documentos Guardados** (NUEVO)

### **2. Redactor de Documentos** ✅
- Botón adjuntar con opciones:
  - 📷 Galería
  - 📸 Cámara
  - 📄 Archivo externo
  - 📂 **Documentos Guardados** (NUEVO)

### **3. Comparador de Estrategias** ⏳ PENDIENTE
- Misma estructura que las anteriores

---

## 📂 Categorías de "Documentos Guardados"

Cuando el usuario presiona **"Documentos Guardados"**, se muestra un segundo modal con 5 categorías:

```
📂 Documentos Guardados
├─ 📝 Documentos Escaneados
│  └─ Textos extraídos con OCR (desde Supabase Storage)
│
├─ 📊 Reportes de Calculadora
│  └─ Dosimetrías y cómputos guardados (desde Supabase Storage)
│
├─ 💬 Conversaciones del Chat Legal (solo Redactor/Comparador)
│  └─ Historial de consultas (desde Supabase Database)
│
├─ ⚖️ Comparaciones de Estrategias
│  └─ Análisis comparativos guardados (desde Supabase Storage)
│
└─ ⭐ Sentencias Favoritas
   └─ Jurisprudencias marcadas (desde Supabase Database + Storage)
```

**NOTA:** En Chat Legal NO aparece "Conversaciones del Chat Legal" (no tiene sentido importar conversaciones en la misma herramienta).

---

## 🗄️ Arquitectura de Storage (Supabase)

### **Firebase:**
- ✅ **Solo autenticación** (Firebase Auth)
- UID único por usuario

### **Supabase:**
- ✅ **Database (PostgreSQL):** Metadatos de documentos
- ✅ **Storage:** Archivos (PDFs, imágenes, etc.)

### **Estructura de Supabase Storage:**

```
📦 Supabase Storage Buckets:

documentos_escaneados/
└─ {firebase_uid}/
   ├─ escaneo_001_20250116_143022.pdf
   ├─ escaneo_002_20250116_150134.jpg
   └─ ...

reportes_calculadora/
└─ {firebase_uid}/
   ├─ dosimetria_homicidio_20250115.pdf
   ├─ computo_pena_20250116.pdf
   └─ ...

documentos_redactor/
└─ {firebase_uid}/
   ├─ escrito_acusatorio_001.pdf
   ├─ recurso_apelacion_002.pdf
   └─ ...

comparaciones/
└─ {firebase_uid}/
   ├─ comparacion_estrategias_001.pdf
   └─ ...

sentencias_favoritas/
└─ {firebase_uid}/
   ├─ tsj_sentencia_2024_001.pdf
   └─ ...

chat_attachments/
└─ {firebase_uid}/
   └─ {conversacion_id}/
      ├─ attachment_001.pdf
      └─ attachment_002.jpg
```

---

## 🔄 Flujo de Usuario

### **Ejemplo: Usuario en Chat Legal quiere adjuntar reporte de calculadora**

1. Usuario presiona botón clip (📎)
2. Se abre modal con opciones:
   - Galería
   - Cámara
   - Documento
   - **Documentos Guardados** ← Usuario presiona aquí
3. Se abre segundo modal con categorías
4. Usuario selecciona **"Reportes de Calculadora"**
5. App consulta Supabase:
   ```dart
   final client = Supabase.instance.client;
   final reportes = await client
       .from('reportes_calculadora')
       .select('*')
       .eq('firebase_uid', currentUserUid)
       .order('created_at', ascending: false);
   ```
6. Se muestra lista de reportes guardados
7. Usuario selecciona uno o varios reportes
8. App obtiene URLs públicas de Supabase Storage:
   ```dart
   final publicUrl = client.storage
       .from('reportes_calculadora')
       .getPublicUrl(reporte['storage_path']);
   ```
9. Reportes se adjuntan como chips en el input del chat
10. Usuario envía mensaje con adjuntos

---

## 📋 Schema de Supabase Database

### **Tabla: usuarios**
```sql
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  nombre TEXT,
  foto_perfil_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### **Tabla: documentos_escaneados**
```sql
CREATE TABLE documentos_escaneados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES usuarios(id),
  firebase_uid TEXT NOT NULL,
  nombre_archivo TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  texto_extraido TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### **Tabla: reportes_calculadora**
```sql
CREATE TABLE reportes_calculadora (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES usuarios(id),
  firebase_uid TEXT NOT NULL,
  nombre TEXT NOT NULL,
  tipo TEXT, -- 'dosimetria', 'computo', 'concurso'
  datos_json JSONB,
  pdf_path TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### **Tabla: documentos_redactor**
```sql
CREATE TABLE documentos_redactor (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES usuarios(id),
  firebase_uid TEXT NOT NULL,
  nombre TEXT NOT NULL,
  tipo_documento TEXT, -- 'escrito_acusatorio', 'recurso', etc.
  contenido TEXT,
  pdf_path TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### **Tabla: comparaciones**
```sql
CREATE TABLE comparaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES usuarios(id),
  firebase_uid TEXT NOT NULL,
  nombre TEXT NOT NULL,
  estrategia_a TEXT,
  estrategia_b TEXT,
  analisis TEXT,
  pdf_path TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### **Tabla: sentencias_favoritas**
```sql
CREATE TABLE sentencias_favoritas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES usuarios(id),
  firebase_uid TEXT NOT NULL,
  numero_sentencia TEXT NOT NULL,
  sala TEXT,
  delito TEXT,
  fecha_sentencia DATE,
  resumen TEXT,
  pdf_path TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### **Tabla: conversaciones_chat**
```sql
CREATE TABLE conversaciones_chat (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES usuarios(id),
  firebase_uid TEXT NOT NULL,
  titulo TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### **Tabla: mensajes_chat**
```sql
CREATE TABLE mensajes_chat (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversacion_id UUID REFERENCES conversaciones_chat(id) ON DELETE CASCADE,
  contenido TEXT NOT NULL,
  es_usuario BOOLEAN NOT NULL,
  attachment_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔐 Seguridad (Supabase RLS - Row Level Security)

### **Storage Policies:**

```sql
-- Permitir que cada usuario solo acceda a sus propios archivos
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
WITH CHECK (
  (storage.foldername(name))[1] = auth.jwt()->>'firebase_uid'
);

CREATE POLICY "Users can read their own files"
ON storage.objects FOR SELECT
USING (
  (storage.foldername(name))[1] = auth.jwt()->>'firebase_uid'
);

CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
USING (
  (storage.foldername(name))[1] = auth.jwt()->>'firebase_uid'
);
```

### **Database Policies:**

```sql
-- Ejemplo para tabla documentos_escaneados
CREATE POLICY "Users can view their own documents"
ON documentos_escaneados FOR SELECT
USING (firebase_uid = auth.jwt()->>'firebase_uid');

CREATE POLICY "Users can insert their own documents"
ON documentos_escaneados FOR INSERT
WITH CHECK (firebase_uid = auth.jwt()->>'firebase_uid');

CREATE POLICY "Users can update their own documents"
ON documentos_escaneados FOR UPDATE
USING (firebase_uid = auth.jwt()->>'firebase_uid');

CREATE POLICY "Users can delete their own documents"
ON documentos_escaneados FOR DELETE
USING (firebase_uid = auth.jwt()->>'firebase_uid');
```

---

## 📝 TODOs Pendientes

### **Fase 1: Setup Supabase**
- [ ] Crear proyecto en Supabase
- [ ] Crear tablas (SQL schema arriba)
- [ ] Crear buckets de Storage
- [ ] Configurar RLS policies
- [ ] Obtener API keys y agregar a `.env`

### **Fase 2: Implementar Métodos de Carga**
- [ ] `_cargarDocumentosEscaneados()` en Chat Legal
- [ ] `_cargarReportesCalculadora()` en Chat Legal
- [ ] `_cargarDocumentosRedactor()` en Chat Legal
- [ ] `_cargarComparaciones()` en Chat Legal
- [ ] `_cargarSentenciasFavoritas()` en Chat Legal
- [ ] Repetir para Redactor de Documentos
- [ ] Repetir para Comparador de Estrategias

### **Fase 3: Implementar Guardado de Documentos**
- [ ] Escáner: guardar en Supabase al procesar documento
- [ ] Calculadora: guardar reportes al generar PDF
- [ ] Redactor: guardar documentos al finalizar redacción
- [ ] Comparador: guardar comparaciones al finalizar análisis

### **Fase 4: UI/UX**
- [ ] Modal de selección de documentos guardados con thumbnails
- [ ] Búsqueda en documentos guardados
- [ ] Ordenar por fecha/nombre
- [ ] Permitir eliminar documentos guardados
- [ ] Indicador de progreso al cargar

### **Fase 5: Testing**
- [ ] Probar carga de documentos escaneados
- [ ] Probar carga de reportes de calculadora
- [ ] Probar carga de sentencias favoritas
- [ ] Verificar RLS (intentar acceder a archivos de otro usuario)
- [ ] Probar con conexión lenta

---

## 🎯 Estado Actual

✅ **Chat Legal:** Implementado (estructura completa con placeholders)
✅ **Redactor de Documentos:** Implementado (estructura completa con placeholders)
⏳ **Comparador de Estrategias:** Pendiente
⏳ **Métodos de carga:** Todos con placeholder (esperando setup de Supabase)
⏳ **Setup Supabase:** Pendiente

---

## 📚 Referencias

- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [Supabase RLS Docs](https://supabase.com/docs/guides/auth/row-level-security)
- [Firebase Auth + Supabase Integration](https://supabase.com/docs/guides/auth/social-login/firebase)

---

**Última actualización:** 16 de Enero de 2025
