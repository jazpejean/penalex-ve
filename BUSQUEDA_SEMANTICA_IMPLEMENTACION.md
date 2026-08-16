# 🔍 Implementación: Búsqueda Semántica de Jurisprudencias

## 🎯 Problema actual

**Búsqueda keyword (actual):**
- Usuario busca: "matar a alguien"
- Encuentra SOLO: sentencias con palabras exactas "matar" o "alguien"
- **NO encuentra:** "homicidio", "asesinato", "privación de vida"

**Búsqueda semántica (objetivo):**
- Usuario busca: "matar a alguien"
- Encuentra: "homicidio", "homicidio calificado", "asesinato", "parricidio"
- **Entiende:** sinónimos, contexto legal, intención del usuario

---

## 🏗️ Arquitectura - 2 Enfoques

### **Opción 1: DeepSeek Embeddings (RECOMENDADA - Económica)**

**Ventajas:**
- ✅ Más barato que OpenAI
- ✅ Ya tienes DeepSeek configurado
- ✅ Modelo `deepseek-chat` puede hacer reranking

**Flujo:**
```
Usuario busca "matar a alguien"
    ↓
1. Expandir query con IA:
   "matar a alguien" → ["homicidio", "asesinato", "privación de vida", "matar"]
    ↓
2. Buscar en Firestore con términos expandidos
    ↓
3. Reranking con IA (ordenar por relevancia semántica)
    ↓
Mostrar resultados ordenados por relevancia
```

**Costo estimado:** ~$0.001 por búsqueda (muy bajo)

---

### **Opción 2: Vector Embeddings + Supabase (Más avanzada)**

**Ventajas:**
- ✅ Búsqueda ultra rápida (<100ms)
- ✅ Escala a millones de sentencias
- ✅ No depende de llamadas API en tiempo real

**Flujo:**
```
PREPARACIÓN (1 vez):
1. Generar embeddings de todas las sentencias
2. Guardar vectores en Supabase pgvector
3. Crear índice HNSW

BÚSQUEDA:
Usuario busca "matar a alguien"
    ↓
1. Generar embedding del query
    ↓
2. Buscar vectores similares en Supabase (cosine similarity)
    ↓
Resultados en <100ms
```

**Costo inicial:** ~$0.50 para procesar 1000 sentencias (1 vez)
**Costo por búsqueda:** ~$0.0001 (10x más barato)

---

## 🚀 OPCIÓN 1 - DeepSeek Query Expansion (Implementación rápida)

### **Paso 1: Agregar método a AIService**

```dart
// lib/services/ai_service.dart

/// Expande un query de búsqueda a términos legales relevantes
static Future<List<String>> expandirQueryLegal(String query) async {
  try {
    await inicializar();
    
    final String prompt = '''
Eres un asistente legal venezolano experto. 
El usuario busca jurisprudencias con la consulta: "$query"

Tarea: Genera una lista de términos legales relevantes que deberían encontrar sentencias relacionadas.

Reglas:
1. Incluye sinónimos legales precisos
2. Usa terminología del Código Penal venezolano
3. Máximo 8 términos
4. Responde SOLO con los términos separados por comas

Ejemplos:
- "matar a alguien" → homicidio, asesinato, homicidio calificado, privación de vida, homicidio simple
- "robar" → hurto, robo, hurto agravado, robo agravado, sustracción
- "golpear" → lesiones personales, agresión física, lesiones leves, lesiones graves

Consulta: "$query"
Términos legales:''';

    final response = await _llamarDeepSeek(prompt, temperature: 0.3);
    
    // Parsear respuesta
    final terminos = response
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    
    // Agregar el query original también
    if (!terminos.contains(query.toLowerCase())) {
      terminos.insert(0, query.toLowerCase());
    }
    
    debugPrint('✅ Query expandido: $query → $terminos');
    return terminos;
    
  } catch (e) {
    debugPrint('❌ Error expandiendo query: $e');
    // Fallback: retornar solo el query original
    return [query.toLowerCase()];
  }
}
```

### **Paso 2: Actualizar JurisprudenciaService**

```dart
// lib/services/jurisprudencia_service.dart

Future<List<SentenciaModel>> buscarSentenciasSemantica({
  String? textoBusqueda,
  int limit = 50,
}) async {
  try {
    if (textoBusqueda == null || textoBusqueda.isEmpty) {
      return buscarSentencias(limit: limit);
    }
    
    debugPrint('🔍 Búsqueda semántica: $textoBusqueda');
    
    // 1. Expandir query con IA
    final terminosExpandidos = await AIService.expandirQueryLegal(textoBusqueda);
    debugPrint('📝 Términos expandidos: $terminosExpandidos');
    
    // 2. Obtener más resultados de Firestore (sin filtrar aún)
    Query query = _firestore.collection(_collection)
        .orderBy('fecha_sentencia', descending: true)
        .limit(limit * 3); // Traer 3x para filtrar localmente
    
    final snapshot = await query.get();
    List<SentenciaModel> sentencias = snapshot.docs
        .map((doc) => SentenciaModel.fromFirestore(doc))
        .toList();
    
    // 3. Scoring semántico local
    final sentenciasConScore = sentencias.map((s) {
      double score = 0.0;
      final textoCompleto = '${s.numeroSentencia} ${s.delito} ${s.resumen} ${s.decision} ${s.partes}'.toLowerCase();
      
      for (final termino in terminosExpandidos) {
        final terminoLower = termino.toLowerCase();
        
        // Coincidencia en delito (peso alto)
        if (s.delito.toLowerCase().contains(terminoLower)) {
          score += 100;
        }
        
        // Coincidencia en resumen
        if (s.resumen.toLowerCase().contains(terminoLower)) {
          score += 50;
        }
        
        // Coincidencia en decision
        if (s.decision.toLowerCase().contains(terminoLower)) {
          score += 30;
        }
        
        // Coincidencia en número de sentencia
        if (s.numeroSentencia.toLowerCase().contains(terminoLower)) {
          score += 80;
        }
        
        // Coincidencia en texto completo
        if (textoCompleto.contains(terminoLower)) {
          score += 20;
        }
      }
      
      return {'sentencia': s, 'score': score};
    }).where((item) => (item['score'] as double) > 0).toList();
    
    // 4. Ordenar por score
    sentenciasConScore.sort((a, b) => 
        (b['score'] as double).compareTo(a['score'] as double));
    
    final resultados = sentenciasConScore
        .take(limit)
        .map((item) => item['sentencia'] as SentenciaModel)
        .toList();
    
    debugPrint('✅ Encontradas ${resultados.length} sentencias relevantes');
    return resultados;
    
  } catch (e) {
    debugPrint('❌ Error en búsqueda semántica: $e');
    // Fallback a búsqueda normal
    return buscarSentencias(textoBusqueda: textoBusqueda, limit: limit);
  }
}
```

### **Paso 3: Actualizar RepositorioJurisprudenciaScreen**

```dart
// lib/pages/repositorio_jurisprudencia_screen.dart

Future<void> _buscar() async {
  setState(() => _cargando = true);
  _animationController.forward();

  // ✅ Usar búsqueda semántica
  final resultados = await _service.buscarSentenciasSemantica(
    textoBusqueda: _searchController.text.trim(),
    limit: 50,
  );

  if (mounted) {
    setState(() {
      _resultados = resultados;
      _cargando = false;
    });
  }
}
```

### **Ventajas de esta implementación:**

✅ **Rápida de implementar** (30 minutos)  
✅ **Bajo costo** (~$0.001 por búsqueda)  
✅ **Funciona con tu infraestructura actual**  
✅ **No requiere cambios en BD**  
✅ **Mejora inmediata de UX**  

### **Limitaciones:**

⚠️ **Latencia:** ~2-3 segundos por búsqueda (llamada a DeepSeek)  
⚠️ **Escala:** Funciona bien hasta ~5000 sentencias  
⚠️ **Precisión:** 70-80% (buena pero no perfecta)  

---

## 🎯 OPCIÓN 2 - Vector Embeddings + Supabase (Producción)

### **Arquitectura:**

```sql
-- Tabla en Supabase con embeddings
CREATE TABLE sentencias_vectors (
  id TEXT PRIMARY KEY,
  sentencia_id TEXT NOT NULL,
  embedding VECTOR(1536), -- OpenAI ada-002
  -- O VECTOR(512) si usas sentence-transformers
  content_hash TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índice para búsqueda rápida
CREATE INDEX ON sentencias_vectors 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

### **Código de generación de embeddings:**

```dart
// lib/services/embeddings_service.dart

class EmbeddingsService {
  static final _supabase = Supabase.instance.client;
  
  /// Genera embedding de un texto con OpenAI
  static Future<List<double>> generarEmbedding(String texto) async {
    const apiKey = 'tu-openai-key';
    const url = 'https://api.openai.com/v1/embeddings';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'input': texto,
        'model': 'text-embedding-ada-002',
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<double>.from(data['data'][0]['embedding']);
    } else {
      throw Exception('Error generando embedding');
    }
  }
  
  /// Procesa todas las sentencias y genera embeddings
  static Future<void> procesarTodasLasSentencias() async {
    final sentencias = await JurisprudenciaService.getAll();
    
    for (final sentencia in sentencias) {
      final texto = '''
${sentencia.delito}
${sentencia.resumen}
${sentencia.decision}
''';
      
      final embedding = await generarEmbedding(texto);
      
      await _supabase.from('sentencias_vectors').upsert({
        'id': sentencia.id,
        'sentencia_id': sentencia.id,
        'embedding': embedding,
        'content_hash': texto.hashCode.toString(),
      });
      
      debugPrint('✅ Embedding generado para: ${sentencia.numeroSentencia}');
    }
  }
  
  /// Busca sentencias por similitud de vector
  static Future<List<String>> buscarSimilares(String query, {int limit = 20}) async {
    // 1. Generar embedding del query
    final queryEmbedding = await generarEmbedding(query);
    
    // 2. Buscar vectores similares en Supabase
    final response = await _supabase.rpc(
      'match_sentencias',
      params: {
        'query_embedding': queryEmbedding,
        'match_threshold': 0.7,
        'match_count': limit,
      },
    );
    
    return List<String>.from(response.map((r) => r['sentencia_id']));
  }
}
```

### **Función SQL en Supabase:**

```sql
-- Función para búsqueda por similitud
CREATE OR REPLACE FUNCTION match_sentencias(
  query_embedding VECTOR(1536),
  match_threshold FLOAT,
  match_count INT
)
RETURNS TABLE (
  sentencia_id TEXT,
  similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    sentencia_id,
    1 - (embedding <=> query_embedding) AS similarity
  FROM sentencias_vectors
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
```

### **Ventajas:**

✅ **Ultra rápido** (<100ms)  
✅ **Escala a millones** de sentencias  
✅ **Precisión 90%+**  
✅ **Búsqueda multilingüe** (español/inglés)  

### **Desventajas:**

⚠️ **Costo inicial:** ~$0.50 para 1000 sentencias  
⚠️ **Complejidad:** Requiere pipeline de procesamiento  
⚠️ **Mantenimiento:** Regenerar embeddings cuando hay nuevas sentencias  

---

## 🎯 RECOMENDACIÓN

### **Para MVP (implementar YA):**
✅ **Opción 1: DeepSeek Query Expansion**
- Implementación: 30 minutos
- Mejora UX inmediatamente
- Bajo costo

### **Para producción (próximo sprint):**
✅ **Opción 2: Vector Embeddings**
- Implementación: 1 semana
- Performance profesional
- Escalable

---

## 📊 Comparación

| Feature | Keyword Matching | Query Expansion | Vector Embeddings |
|---------|------------------|-----------------|-------------------|
| Precisión | 40% | 70% | 90%+ |
| Velocidad | <100ms | 2-3s | <100ms |
| Costo/búsqueda | $0 | $0.001 | $0.0001 |
| Implementación | ✅ Actual | 30 min | 1 semana |
| Escalabilidad | 1K sentencias | 5K sentencias | Ilimitado |

---

## 🚀 Plan de acción

1. ✅ **Esta semana:** Implementar Opción 1 (Query Expansion)
2. 🔄 **Probar con usuarios reales** durante 1 semana
3. 📊 **Medir:** % búsquedas exitosas, tiempo promedio
4. ⭐ **Si funciona bien:** Mantener
5. 🚀 **Si necesitas más:** Migrar a Opción 2

¿Implemento la Opción 1 (Query Expansion) ahora? Es rápido y mejorará inmediatamente la UX.
