# 📌 CONTEXTO DE TRABAJO — Módulo "Repositorio de Leyes con RAG"

> Documento de contexto para retomar la conversación en cualquier momento.
> Fecha de creación: sesión actual.

---

## 🎯 OBJETIVO DEL USUARIO

Crear un **Repositorio de Leyes** que:

1. **Alimente con RAG** los tres módulos existentes:
   - Chat Legal (`chat_legal_screen.dart`)
   - Redactor de Documentos (`redactor_documentos_screen.dart`)
   - Comparador de Estrategias (`comparador_estrategias_screen.dart`)

2. **Divida las leyes por secciones** siguiendo la estructura real de cada ley:
   - TÍTULO I (con su nombre) → Art. 1–200
   - TÍTULO II → Art. 201–300
   - Capítulos con su nombre, y luego los artículos uno a uno.

3. **Búsqueda semántica + interpretación con IA y ejemplos.**

4. **El JSON de "cotejo"** (verificación) es **exclusivamente** para marcar artículos como:
   - **Derogados** o **sustituidos** por leyes especiales.
   - Caso adúlterio: por decisiones de tribunales (sentencias).

5. **Cada artículo debe mostrar las 5 sentencias relacionadas más relevantes** del
   repositorio de jurisprudencia, de forma **sutil** (como la IA cita URLs), y que
   **redirijan a la sentencia dentro del repositorio** (`DetalleSentenciaScreen`).

6. **Listado de leyes ordenado de mayor a menor relevancia**:
   Constitución → COPP → Código Penal → Ley de Violencia → LOPNNA → Ley de Drogas → resto.
   Con **caja de búsqueda** para no tener que hacer scroll.

7. **Colores iguales al repositorio de jurisprudencia**:
   - `azulMarino = Color(0xFF0F172A)`
   - `dorado = Color(0xFFC5A059)`
   - `fondoGris = Color(0xFFF1F5F9)`

8. **Las leyes están en Word** en una carpeta en la raíz: **"Leyes en word"**
   (el usuario dijo "Leyes word") con **dos subcarpetas** dentro.
   ⚠️ *Pendiente de confirmar la ubicación/estructura exacta de esta carpeta.*

---

## ⚠️ FEEDBACK DEL USUARIO

> "Eso no es lo que quiero."

El enfoque anterior fue rechazado. Lo que se debe hacer ahora es lo descrito arriba.
Puntos clave del rechazo:
- No se trata solo de una lista de leyes hardcodeada ni de Firebase.
- Los datos reales deben venir de los **documentos Word** de la carpeta raíz.
- El JSON de cotejo NO debe mezclarse con el contenido; es SOLO para marcas de derogación.

---

## 🧭 ARQUITECTURA EXISTENTE (descubierta hasta ahora)

### Colores / Tema
- `azulMarino = Color(0xFF0F172A)`, `dorado = Color(0xFFC5A059)`, `fondoGris = Color(0xFFF1F5F9)`
- Usados en `repositorio_jurisprudencia_screen.dart`.

### Pantalla de leyes actual
- `lib/pages/leyes_screen.dart` → `LeyesScreen` (título "Biblioteca Legal").
  - Lista hardcodeada de leyes + `CodigoPenalDetailScreen` que carga
    `rootBundle.loadString('leyes_json/codigo penal.json')`.
  - ⚠️ **`leyes_json/` NO existe en el repo** (está en pubspec.yaml como asset pero
    la carpeta no está presente en el workspace actual).
- Ruta en main.dart: `'/leyes': (context) => const LeyesScreen(),`
- Ya importa `../widgets/sentencias_relacionadas_widget.dart`.

### Widget de sentencias relacionadas (YA EXISTE)
- `lib/widgets/sentencias_relacionadas_widget.dart` → `SentenciasRelacionadasWidget`
  - Usa `RAGService.buscarJurisprudenciaRelevante(consulta, limit: 3)`.
  - Muestra tarjetas clicables que abren `DetalleSentenciaScreen`.
  - Tiene `darkMode` (para fondos oscuros de chat IA).
  - ⚠️ Actualmente `limit: 3`; el usuario pide **5** sentencias por artículo.

### Servicios
- `lib/services/rag_service.dart` → `RAGService`
  - `buscarJurisprudenciaRelevante({consulta, limit, salaFiltro})` → `List<SentenciaModel>`
  - `construirContextoJurisprudencial(sentencias)` → bloque de contexto para prompts
  - `construirFuentes(sentencias)` → `List<MessageSource>` (fuentes citables del chat)
  - `obtenerContextoYFuentes(...)` → todo en una llamada.
  - Nunca lanza excepción (devuelve lista vacía ante error).
- `lib/services/jurisprudencia_service.dart` → `JurisprudenciaService`
  - `buscarEnSupabase({textoBusqueda, tipoFiltro, salaFiltro, anioFiltro, limit})`
    desde tabla **Supabase `documentos`** con fulltext + expansión semántica DeepSeek
    + fallback `ilike`.
  - `buscarDocumentos(...)` alias de compatibilidad.
- `lib/services/leyes_service.dart` → **OBSOLETO: usa Firebase Firestore** (`coleccion('leyes')`).
  - Según `PLAN_ACCION_INMEDIATO.md`: "LeyesService usa FIREBASE (obsoleto), No está
    conectado a Supabase".
- `lib/services/busqueda_semantica_service.dart` → búsqueda semántica local por keywords
  (Firestore, `Sentencia` viejo, `Ley` de Firebase). Probablemente NO es el camino.

### Modelos
- `lib/models/sentencia_model.dart` → `SentenciaModel` (usado por repositorio + RAG).
- `lib/models/ley.dart` → `Ley`/`Capitulo`/`Articulo` (Firestore). Probablemente hay que
  adaptarlo o crear modelo nuevo para el JSON local.

### Datos de leyes existentes (NO en runtime del app todavía)
- `tools/data/leyes/textos/*.json` → metadatos (codigo, nombre, url, pdf_path...).
- `tools/data/leyes/estructurado/*.json` → **16 leyes, 2891 artículos, 480 secciones**.
  - `_resumen.json` → listado de las 16 leyes con `codigo`, `nombre`, `num_articulos`,
    `num_secciones`, `caracteres`.
  - ⚠️ **Estructura inconsistente** entre leyes:
    - `CP.json`: artículos con `{numero, titulo, contenido, libro, titulo_seccion, capitulo}` (tiene jerarquía completa).
    - `COPP.json`, `LOSDMVLV.json`: `{numero, titulo, contenido, es_derogado}` (SIN jerarquía).
    - `LOPNNA.json`: `{numero, numero_raw, titulo, contenido, es_derogado}`.
    - `CRBV.json`: artículos con `{numero, contenido}`.
    - `LOD.json`: `{numero, contenido}`.
- Leyes en estructurado/ (16): CEA, COP, COPP, CP, CRBV, LCDOFT, LCSE, LDCAM, LECDI,
  LHRVA, LOA, LOCC, LOD, LOPNNA, LOSDMVLV, LPVT.
  - Mapa abreviaturas → nombres (según `_resumen.json`), ej.:
    - CRBV = Constitución de la República Bolivariana de Venezuela
    - CP = Código Penal
    - COPP = Código Orgánico Procesal Penal
    - LOSDMVLV = Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia
    - LOPNNA = Ley Orgánica para la Protección de Niños, Niñas y Adolescentes
    - LOD = Ley Orgánica de Drogas (por confirmar)
    - LCDOFT = Ley contra la Delincuencia Organizada y Financiamiento al Terrorismo
  - Orden pedido por usuario (mayor a menor relevancia):
    Constitución → COPP → Código Penal → Ley Violencia → LOPNNA → Drogas → resto.

### Pendiente por explorar
- **Carpeta raíz "Leyes en word"** (o "Leyes word") con 2 subcarpetas → fuente de datos
  principal según el usuario. ❌ La búsqueda de `.docx` fue cancelada; hay que retomarla.
- `chat_legal_screen.dart`, `redactor_documentos_screen.dart`,
  `comparador_estrategias_screen.dart` → ver CÓMO consumen RAG hoy (para conectar leyes).
- `tools/data/leyes/estructurado/*.json` completo → contenido de todas las leyes.
- `PLAN_ACCION_INMEDIATO.md` y `LEYES_FALTANTES_ANALISIS.md` → estado/plan del proyecto.
- Scripts Python en `tools/data/leyes/pdfs/convertir_leyes.py` (conversión PDF→JSON).

---

## ✅ DECISIONES / PLAN PROPUESTO (para retomar)

1. **Confirmar ubicación** de la carpeta "Leyes en word" y sus 2 subcarpetas
   (`find . -iname "*.docx"`). Si no está, usar `tools/data/leyes/estructurado/*.json`.

2. **Estructurar el JSON por secciones**:
   ```
   {
     "codigo": "CP",
     "nombre": "Código Penal",
     "orden": 3,
     "gaceta": "...",
     "secciones": [
       { "tipo": "TITULO", "numero": "I", "nombre": "De la Aplicación de la Ley Penal",
         "capitulos": [ { "nombre": "...", "articulos": [...] } ] }
     ]
   }
   ```
   Para leyes sin jerarquía extraída, derivar títulos/capítulos con heurística o IA.

3. **JSON de cotejo** (separado) SOLO para marcas de derogación/sustitución:
   - `derogado_por`, `sustituido_por` (ley especial), `anulado_por_sentencia` (adúlterio).

4. **Servicio nuevo** `LeyesRepositoryService` (o similar) que:
   - Cargue JSONs locales (assets) con `rootBundle`.
   - Ofrezca: listar leyes (ordenado), buscar artículo, búsqueda semántica por sección,
     construir contexto RAG (bloque de texto para prompts) tipo `construirContextoJurisprudencial`.
   - Exponer función `obtenerContextoLegal(consulta)` para Chat/Redactor/Comparador.

5. **Pantalla `LeyesScreen` rediseñada** (estilo jurisprudencia):
   - AppBar azul marino/dorado, caja de búsqueda arriba.
   - Lista de leyes con orden de relevancia.
   - Detalle de ley → secciones (TÍTULOS + Capítulos) → artículos.
   - Detalle de artículo → texto + interpretación IA con ejemplos + **5 sentencias
     relacionadas** (reusar `SentenciasRelacionadasWidget` con `limit: 5` o crear
     variante sutil tipo "citas de IA") que redirigen a `DetalleSentenciaScreen`.

6. **Conectar RAG de leyes** en chat/redactor/comparador (aún por revisar su código).

---

## 🔗 REFERENCIAS CLAVE DE ARCHIVOS

| Archivo | Rol |
|---|---|
| `lib/pages/leyes_screen.dart` | Pantalla actual (a rehacer) |
| `lib/widgets/sentencias_relacionadas_widget.dart` | Widget de sentencias relacionadas (existe, limit:3) |
| `lib/services/rag_service.dart` | RAG para jurisprudencia (referencia de patrón) |
| `lib/services/jurisprudencia_service.dart` | Búsqueda en Supabase `documentos` |
| `lib/services/leyes_service.dart` | OBSOLETO (Firebase) |
| `lib/models/sentencia_model.dart` | Modelo de sentencia |
| `lib/models/ley.dart` | Modelo Ley (Firebase, a revisar/adaptar) |
| `lib/pages/repositorio_jurisprudencia_screen.dart` | Pantalla de jurisprudencia (estilo a imitar) + `DetalleSentenciaScreen` |
| `tools/data/leyes/estructurado/*.json` | Datos estructurados de 16 leyes (2891 artículos) |
| `tools/data/leyes/estructurado/_resumen.json` | Resumen de las 16 leyes |
| `tools/data/leyes/textos/*.json` | Metadatos de cada ley |
| `pubspec.yaml` | Assets: `leyes_json/` declarado pero carpeta ausente |
| `PLAN_ACCION_INMEDIATO.md` | Plan previo (LeyesScreen hardcodeada, LeyesService obsoleto) |

---

## 🛑 PRÓXIMOS PASOS INMEDIATOS (al retomar)

1. Localizar carpeta "Leyes en word" / `.docx` en la raíz.
2. Leer `chat_legal_screen.dart`, `redactor_documentos_screen.dart`,
   `comparador_estrategias_screen.dart` (integración RAG actual).
3. Definir modelo local de ley/sección/artículo.
4. Crear servicio de leyes con RAG.
5. Rediseñar `LeyesScreen` + detalle de ley + detalle de artículo con 5 sentencias relacionadas.
6. Conectar RAG de leyes en chat/redactor/comparador.
