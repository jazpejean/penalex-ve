# 🚀 PLAN DE ACCIÓN INMEDIATO - PENALEX

## 🎯 PROBLEMAS CRÍTICOS IDENTIFICADOS

### 1️⃣ **REPOSITORIO DE LEYES** (CRÍTICO) ⚠️
```
Estado actual:
❌ LeyesScreen tiene lista hardcodeada de solo 9 leyes
❌ LeyesService usa FIREBASE (obsoleto)
❌ No está conectado a Supabase
❌ La IA no tiene acceso al texto real de las leyes
❌ Riesgo de "alucinar" artículos inexistentes

Impacto:
🔴 Sin repositorio real, la IA inventa artículos
🔴 Dosimetría puede calcular con artículos incorrectos
🔴 Redactor puede citar leyes que no existen
🔴 Chat legal da respuestas sin fundamento

PRIORIDAD: MÁXIMA
```

### 2️⃣ **CÓMPUTO DE LAPSOS en AGENDA** ✅
```
Estado actual:
✅ lapsos_page.dart existe y funciona
⚠️ Está separado de agenda_screen.dart

Propuesta:
Integrar calculadora de lapsos dentro de Agenda:
  - Al crear evento judicial → opción "calcular plazo"
  - Al ver evento → botón "calcular vencimiento"
  - Lapsos guardados → vinculados a eventos

PRIORIDAD: MEDIA (mejora UX, no crítico)
```

---

## 🔥 ACCIÓN INMEDIATA: Repositorio de Leyes

### **PROBLEMA RAÍZ**:
```dart
// leyes_screen.dart - SOLO UI HARDCODEADA
final List<Map<String, String>> _leyes = const [
  {'titulo': 'Constitución...', 'descripcion': '...'},
  {'titulo': 'Código Penal...', 'descripcion': '...'},
  // Solo 9 leyes, sin contenido real
];

// leyes_service.dart - USA FIREBASE OBSOLETO
FirebaseFirestore _firestore = FirebaseFirestore.instance;
```

### **LO QUE NECESITAS**:
```
Base de datos REAL en Supabase:
  Table: leyes
    - id (uuid)
    - nombre_corto (text)
    - nombre_completo (text)
    - fecha_publicacion (date)
    - gaceta_oficial (text)
    - contenido_completo (text) ← CRÍTICO
    - articulos (jsonb) ← Estructura de artículos
    - embeddings (vector) ← Para búsqueda semántica
```

---

## 📊 ARQUITECTURA CORRECTA

### **Flujo de datos ideal**:

```
1. Usuario consulta IA
   ↓
2. IA consulta repositorio de leyes (Supabase)
   ↓
3. Encuentra artículo específico (ej: Art. 13 CP)
   ↓
4. Cita el texto REAL del artículo
   ↓
5. Usuario confía en la respuesta
```

### **Flujo actual (ROTO)**:
```
1. Usuario consulta IA
   ↓
2. IA solo tiene conocimiento de entrenamiento
   ↓
3. Puede "inventar" o confundir artículos
   ↓
4. Usuario recibe info potencialmente INCORRECTA ⚠️
```

---

## ✅ SOLUCIÓN PROPUESTA

### **FASE 1: Base de datos de Leyes** (Urgente)

#### Paso 1: Crear tabla en Supabase
```sql
-- Tabla principal de leyes
CREATE TABLE leyes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT UNIQUE NOT NULL, -- 'CP', 'COPP', 'CRBV', etc.
  nombre_corto TEXT NOT NULL,
  nombre_completo TEXT NOT NULL,
  fecha_publicacion DATE,
  gaceta_oficial TEXT,
  vigente BOOLEAN DEFAULT true,
  contenido_completo TEXT, -- Texto completo de la ley
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de artículos (estructurado)
CREATE TABLE articulos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ley_id UUID REFERENCES leyes(id) ON DELETE CASCADE,
  numero TEXT NOT NULL, -- '13', '13-A', '13 bis'
  titulo TEXT,
  contenido TEXT NOT NULL,
  notas TEXT,
  derogado BOOLEAN DEFAULT false,
  modificado_por TEXT,
  capitulo TEXT,
  seccion TEXT,
  embedding vector(1536), -- Para búsqueda semántica
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_articulos_ley ON articulos(ley_id);
CREATE INDEX idx_articulos_numero ON articulos(numero);
CREATE INDEX idx_articulos_embedding ON articulos USING ivfflat (embedding vector_cosine_ops);

-- Índice para búsqueda de texto completo
CREATE INDEX idx_articulos_contenido_fts ON articulos USING gin(to_tsvector('spanish', contenido));
```

#### Paso 2: Migrar servicio a Supabase
```dart
// lib/services/leyes_service.dart (NUEVO)
import 'package:supabase_flutter/supabase_flutter.dart';

class LeyesService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Obtiene todas las leyes vigentes
  static Future<List<Ley>> getAll() async {
    final response = await _supabase
        .from('leyes')
        .select()
        .eq('vigente', true)
        .order('nombre_corto');
    
    return (response as List).map((data) => Ley.fromJson(data)).toList();
  }
  
  /// Busca artículo específico
  static Future<Articulo?> buscarArticulo(String codigoLey, String numeroArticulo) async {
    final response = await _supabase
        .from('articulos')
        .select('*, leyes!inner(*)')
        .eq('leyes.codigo', codigoLey)
        .eq('numero', numeroArticulo)
        .eq('derogado', false)
        .maybeSingle();
    
    if (response == null) return null;
    return Articulo.fromJson(response);
  }
  
  /// Búsqueda semántica de artículos
  static Future<List<Articulo>> buscarSemantico(String consulta) async {
    // Genera embedding de la consulta
    final embedding = await _generarEmbedding(consulta);
    
    // Busca por similitud de vectores
    final response = await _supabase.rpc(
      'buscar_articulos_similares',
      params: {
        'query_embedding': embedding,
        'match_threshold': 0.7,
        'match_count': 10,
      }
    );
    
    return (response as List).map((data) => Articulo.fromJson(data)).toList();
  }
}
```

#### Paso 3: Función de búsqueda en Supabase
```sql
-- Función para búsqueda semántica
CREATE OR REPLACE FUNCTION buscar_articulos_similares(
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id uuid,
  ley_id uuid,
  numero text,
  contenido text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    articulos.id,
    articulos.ley_id,
    articulos.numero,
    articulos.contenido,
    1 - (articulos.embedding <=> query_embedding) as similarity
  FROM articulos
  WHERE articulos.derogado = false
    AND 1 - (articulos.embedding <=> query_embedding) > match_threshold
  ORDER BY articulos.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
```

---

### **FASE 2: Integrar con IA** (Crítico)

#### Chat Legal con contexto real
```dart
// lib/services/chat_service.dart (MEJORAR)
Future<String> consultarIA(String pregunta) async {
  // 1. Buscar artículos relevantes
  final articulosRelevantes = await LeyesService.buscarSemantico(pregunta);
  
  // 2. Construir contexto con artículos reales
  final contexto = articulosRelevantes.map((art) =>
    'Artículo ${art.numero} del ${art.ley.nombreCorto}:\n${art.contenido}'
  ).join('\n\n');
  
  // 3. Enviar a IA con contexto
  final prompt = '''
Contexto legal (fuentes verificadas):
$contexto

Pregunta del usuario: $pregunta

Responde citando SOLO los artículos proporcionados arriba.
Si la respuesta no está en el contexto, di "No tengo información suficiente".
''';
  
  return await _enviarADeepseek(prompt);
}
```

#### Dosimetría con validación
```dart
// lib/services/dosimetria_service.dart (MEJORAR)
Future<ResultadoDosimetria> calcularPena(String delito) async {
  // 1. Buscar artículo del delito en base de datos
  final articulo = await LeyesService.buscarArticulo('CP', numeroArticulo);
  
  if (articulo == null) {
    throw Exception('Artículo no encontrado en base de datos');
  }
  
  // 2. Extraer rango de penas del texto real
  final rangosPena = _extraerRangosPena(articulo.contenido);
  
  // 3. Calcular con datos verificados
  return _calcularConRangos(rangosPena);
}
```

---

### **FASE 3: Integrar Lapsos en Agenda** (Mejora UX)

```dart
// lib/pages/agenda_screen.dart (MEJORAR)
class AgendaScreen extends StatefulWidget {
  // ... código existente
}

// Agregar botón flotante secundario
Widget build(BuildContext context) {
  return Scaffold(
    // ... código existente
    
    floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón calculadora de lapsos
        FloatingActionButton(
          heroTag: 'lapsos',
          mini: true,
          onPressed: () => _mostrarCalculadoraLapsos(),
          child: Icon(Icons.calculate),
          tooltip: 'Calcular plazo',
        ),
        SizedBox(height: 8),
        
        // Botón nuevo evento (existente)
        FloatingActionButton(
          heroTag: 'nuevo',
          onPressed: () => _crearEvento(),
          child: Icon(Icons.add),
          tooltip: 'Nuevo evento',
        ),
      ],
    ),
  );
}

void _mostrarCalculadoraLapsos() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => LapsosCalculator(
        onCalculado: (resultado) {
          // Opción: crear evento automático con el resultado
          _crearEventoDesdeCalculo(resultado);
        },
      ),
    ),
  );
}
```

---

## 📋 PRIORIDADES INMEDIATAS

### **HOY** (Crítico):
1. ✅ Limpiar archivos temporales (.bak, .tmp)
2. ✅ Mover scripts a /tools
3. 🔴 Crear estructura de leyes en Supabase
4. 🔴 Migrar LeyesService a Supabase

### **ESTA SEMANA** (Urgente):
1. 🔴 Poblar base de datos con Código Penal completo
2. 🔴 Poblar COPP
3. 🔴 Poblar Constitución
4. 🔴 Integrar repositorio con IA
5. ✅ Integrar calculadora de lapsos en Agenda
6. ✅ Integrar Comparador de Estrategias en dashboard

### **PRÓXIMA SEMANA** (Importante):
1. Agregar resto de leyes penales
2. Generar embeddings de todos los artículos
3. Validar que IA solo cite fuentes reales
4. Testing exhaustivo de dosimetría con artículos verificados

---

## ⚠️ RIESGO ACTUAL

```
SIN repositorio de leyes real:

❌ IA puede inventar artículos
❌ Dosimetría puede usar rangos incorrectos
❌ Redactor puede citar fuentes falsas
❌ Pérdida de credibilidad profesional
❌ Posibles demandas por mala praxis

🔴 ESTO ES CRÍTICO - DEBE RESOLVERSE YA
```

---

## 💡 DATOS NECESARIOS

### ¿Tienes acceso a las leyes en formato digital?

**Opción A**: Tienes PDFs/textos de las leyes
```
→ Podemos parsearlos y estructurarlos
→ Necesitamos: CP, COPP, CRBV, LOSDMVLV, etc.
→ Tiempo: 2-3 días de trabajo
```

**Opción B**: Scraping de fuentes oficiales
```
→ TSJ, Gaceta Oficial, SPIJ
→ Automatizado con scripts Python
→ Tiempo: 1 semana (incluye validación)
```

**Opción C**: Comprar base de datos legal
```
→ Proveedores: Legis, Pandectas, etc.
→ Costo: $500-2000 USD
→ Tiempo: Inmediato
```

---

## ✅ PRÓXIMO PASO

**¿Qué prefieres?**

1. **Empezar limpieza técnica** (10 min) + **Crear estructura DB** (30 min)
2. **Definir fuente de datos legales** (¿tienes PDFs? ¿scrapeamos?)
3. **Poblar base de datos** (manual o automatizado)
4. **Integrar con IA** (2 días)

**Recomendación**: Hacer 1 HOY, discutir 2 mientras tanto, ejecutar 3-4 esta semana.

**¿Arrancamos con la limpieza y estructura DB?** 🚀
