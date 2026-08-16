# 📊 Sistema de Analytics AI - Supabase

## 🎯 Descripción

Sistema completo de tracking y analytics para las herramientas IA del Asistente Legal de Penalex.

---

## 🚀 Instalación

### **Opción 1: Desde Supabase Dashboard (Recomendada)**

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Navega a **SQL Editor**
3. Crea una nueva query
4. Copia y pega el contenido de `create_ai_tool_usage.sql`
5. Ejecuta la query (Run)
6. ✅ ¡Listo!

### **Opción 2: Usando Supabase CLI**

```bash
# Desde la raíz del proyecto
supabase db push

# O ejecutar la migración específica
supabase db execute --file supabase/migrations/create_ai_tool_usage.sql
```

---

## 📋 Estructura de la Tabla

### **ai_tool_usage**

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | UUID | ID único del registro |
| `user_id` | UUID | ID del usuario (FK a auth.users) |
| `tool_name` | VARCHAR | Herramienta usada (chat_legal, redactor_documentos, etc.) |
| `action_type` | VARCHAR | Tipo de acción (query, generation, analysis, etc.) |
| `response_time_seconds` | DECIMAL | Tiempo de respuesta en segundos |
| `success` | BOOLEAN | Si la operación fue exitosa |
| `metadata` | JSONB | Datos adicionales en JSON |
| `created_at` | TIMESTAMPTZ | Fecha y hora de creación |

---

## 🔧 Funciones SQL Disponibles

### 1. **get_tool_stats(user_id, tool_name?, days_ago?)**
Obtiene estadísticas agregadas de uso por herramienta.

```sql
-- Ejemplo: Estadísticas de todas las herramientas (últimos 30 días)
SELECT * FROM get_tool_stats('user-uuid-here');

-- Ejemplo: Solo Chat Legal (últimos 7 días)
SELECT * FROM get_tool_stats('user-uuid-here', 'chat_legal', 7);
```

**Retorna:**
- `tool_name`: Nombre de la herramienta
- `total_uses`: Total de usos
- `successful_uses`: Usos exitosos
- `failed_uses`: Usos fallidos
- `avg_response_time`: Tiempo promedio de respuesta
- `success_rate`: Tasa de éxito (%)

### 2. **get_hourly_usage_trend(user_id, days_ago?)**
Obtiene tendencia de uso por hora del día.

```sql
-- Ejemplo: Horarios de mayor uso (últimos 7 días)
SELECT * FROM get_hourly_usage_trend('user-uuid-here', 7);
```

**Retorna:**
- `hour_of_day`: Hora (0-23)
- `usage_count`: Cantidad de usos en esa hora

### 3. **get_weekly_usage_trend(user_id, weeks?)**
Obtiene tendencia semanal de uso.

```sql
-- Ejemplo: Tendencia de las últimas 12 semanas
SELECT * FROM get_weekly_usage_trend('user-uuid-here', 12);
```

**Retorna:**
- `week_start`: Inicio de la semana
- `tool_name`: Herramienta
- `usage_count`: Usos en esa semana

### 4. **get_most_used_tool(user_id, days_ago?)**
Obtiene la herramienta más usada.

```sql
-- Ejemplo: Herramienta más usada (últimos 30 días)
SELECT * FROM get_most_used_tool('user-uuid-here', 30);
```

**Retorna:**
- `tool_name`: Herramienta más usada
- `usage_count`: Cantidad de usos
- `percentage`: Porcentaje del total

---

## 📊 Ejemplos de Uso desde Flutter

### **Tracking de uso:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Registrar uso de herramienta
await Supabase.instance.client
  .from('ai_tool_usage')
  .insert({
    'user_id': Supabase.instance.client.auth.currentUser!.id,
    'tool_name': 'chat_legal',
    'action_type': 'query',
    'response_time_seconds': 4.2,
    'success': true,
    'metadata': {
      'message_length': 150,
      'context_used': true,
    },
  });
```

### **Consultar estadísticas:**

```dart
// Obtener estadísticas de una herramienta
final stats = await Supabase.instance.client
  .rpc('get_tool_stats', params: {
    'p_user_id': Supabase.instance.client.auth.currentUser!.id,
    'p_tool_name': 'chat_legal',
    'p_days_ago': 30,
  });
```

---

## 🔐 Seguridad (RLS)

✅ **Row Level Security (RLS) habilitado**

**Políticas activas:**
- Los usuarios solo pueden ver sus propios datos
- Los usuarios solo pueden insertar sus propios datos
- Los admins pueden ver todos los datos

---

## 📈 Métricas Disponibles

### **Por Herramienta:**
- Total de usos
- Tasa de éxito
- Tiempo promedio de respuesta
- Usos exitosos vs fallidos

### **Temporales:**
- Tendencia por hora del día
- Tendencia semanal
- Herramienta más usada

### **Metadata Ejemplos:**

**Chat Legal:**
```json
{
  "message_length": 150,
  "context_articles": ["Art. 453 CP"],
  "response_quality": "high"
}
```

**Redactor:**
```json
{
  "document_type": "recurso_apelacion",
  "words_generated": 1250,
  "fields_completed": 12
}
```

**Comparador:**
```json
{
  "strategies_compared": 4,
  "best_strategy_score": 0.87,
  "case_complexity": "high"
}
```

**Escáner:**
```json
{
  "pages_scanned": 3,
  "ocr_confidence": 0.95,
  "document_type": "sentencia"
}
```

---

## 🧪 Testing

### **Datos de ejemplo (Desarrollo):**

El script incluye una sección comentada con datos de ejemplo. Para activarla:

1. Descomenta la sección `DATOS DE EJEMPLO` al final del SQL
2. Ejecuta el script
3. Se crearán ~400 registros de prueba

⚠️ **¡IMPORTANTE!** Elimina o comenta esta sección antes de desplegar a producción.

---

## 🔄 Mantenimiento

### **Limpiar datos antiguos (opcional):**

```sql
-- Eliminar registros de más de 1 año
DELETE FROM public.ai_tool_usage
WHERE created_at < NOW() - INTERVAL '1 year';
```

### **Reindexar (si el rendimiento baja):**

```sql
REINDEX TABLE public.ai_tool_usage;
```

---

## 📞 Soporte

Si encuentras algún problema con la migración:
1. Verifica los logs de Supabase
2. Asegúrate que la tabla `users` existe con columna `role` (para política de admins)
3. Revisa que RLS esté habilitado correctamente

---

## ✅ Checklist Post-Instalación

- [ ] Tabla `ai_tool_usage` creada
- [ ] Indexes creados correctamente
- [ ] RLS habilitado y políticas activas
- [ ] Funciones SQL disponibles
- [ ] Trigger de validación funcionando
- [ ] Prueba de inserción exitosa desde Flutter
- [ ] Prueba de consulta de estadísticas

---

**¡Sistema de Analytics listo para usar!** 🎉
