# 🚧 ESTADO DE IMPLEMENTACIÓN - Repositorio Jurisprudencia

## ✅ COMPLETADO (50%):

### 1. **Servicio actualizado** (`jurisprudencia_service.dart`)
- ✅ Conexión a Supabase (eliminado Firebase)
- ✅ Método `buscarEnSupabase()` con filtros: tipo, sala, fulltext
- ✅ Método `obtenerSalasDisponibles()` 
- ✅ Método `obtenerOGenerarResumen()` con caché en Supabase
- ✅ Método `_descargarTextoR2()` para obtener texto completo

### 2. **Modelo actualizado** (`sentencia_model.dart`)
- ✅ Constructor `fromSupabase()` con todos los campos
- ✅ Campos nuevos: `tipo`, `extracto`, `urlTXT`, `esJurisprudencia`, `tienePDF`
- ✅ Mantiene compatibilidad con Firebase (legacy)

### 3. **IA Service**
- ✅ Método `generarResumenSentencia()` para resúmenes cortos en cards

---

## ⏳ FALTA POR HACER (50%):

### 4. **UI - Dropdowns y filtros**
```dart
// Agregar a repositorio_jurisprudencia_screen.dart

// Variables de estado
String _tipoSeleccionado = 'sentencias'; // predeterminado
String _salaSeleccionada = 'Todas';
List<String> _salasDisponibles = [];

// Dropdowns UI
Row(
  children: [
    // Dropdown Tipo
    DropdownButton<String>(
      value: _tipoSeleccionado,
      items: ['sentencias', 'jurisprudencias', 'resoluciones']
          .map((tipo) => DropdownMenuItem(
                value: tipo,
                child: Text(tipo.capitalize()),
              ))
          .toList(),
      onChanged: (valor) {
        setState(() {
          _tipoSeleccionado = valor!;
          _salaSeleccionada = 'Todas';
        });
        _buscar();
      },
    ),
    
    // Dropdown Sala (solo si tipo != 'resoluciones')
    if (_tipoSeleccionado != 'resoluciones')
      DropdownButton<String>(
        value: _salaSeleccionada,
        items: ['Todas', ..._salasDisponibles]
            .map((sala) => DropdownMenuItem(
                  value: sala,
                  child: Text(sala),
                ))
            .toList(),
        onChanged: (valor) {
          setState(() => _salaSeleccionada = valor!);
          _buscar();
        },
      ),
  ],
)
```

### 5. **Cards con lógica condicional**
```dart
Widget _buildSentenciaCard(SentenciaModel sentencia) {
  // Determinar qué mostrar según filtro
  final mostrarResumenIA = _tipoSeleccionado == 'sentencias';
  final mostrarExtracto = _tipoSeleccionado == 'jurisprudencias' || 
                          _tipoSeleccionado == 'resoluciones';
  
  return Card(
    child: Column(
      children: [
        // Header con sala y número
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: azulMarino,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                sentencia.sala.toUpperCase(),
                style: TextStyle(color: dorado, fontSize: 10),
              ),
            ),
            SizedBox(width: 8),
            
            // Badge VINCULANTE si es jurisprudencia en sección sentencias
            if (_tipoSeleccionado == 'sentencias' && sentencia.esJurisprudencia)
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.gavel, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'VINCULANTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Contenido según tipo
        if (mostrarResumenIA)
          FutureBuilder<String>(
            future: _service.obtenerOGenerarResumen(sentencia),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Generando resumen con IA...'),
                  ],
                );
              }
              return Text(
                snapshot.data ?? 'No disponible',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        
        if (mostrarExtracto)
          Text(
            sentencia.extracto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        
        SizedBox(height: 12),
        
        // Botón "Ver Jurisprudencia" solo si es vinculante en sentencias
        if (_tipoSeleccionado == 'sentencias' && sentencia.esJurisprudencia)
          TextButton.icon(
            onPressed: () {
              // Navegar a la misma sentencia pero en modo jurisprudencia
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleSentenciaScreen(
                    sentencia: sentencia,
                    modoJurisprudencia: true,
                  ),
                ),
              );
            },
            icon: Icon(Icons.arrow_forward, size: 16),
            label: Text('Ver Jurisprudencia'),
          ),
      ],
    ),
  );
}
```

### 6. **Método _buscar() actualizado**
```dart
Future<void> _buscar() async {
  setState(() => _cargando = true);

  final resultados = await _service.buscarEnSupabase(
    textoBusqueda: _searchController.text.trim(),
    tipoFiltro: _tipoSeleccionado,
    salaFiltro: _salaSeleccionada == 'Todas' ? null : _salaSeleccionada,
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

### 7. **Cargar salas al iniciar**
```dart
@override
void initState() {
  super.initState();
  _cargarSalas();
  _buscar();
}

Future<void> _cargarSalas() async {
  final salas = await _service.obtenerSalasDisponibles();
  if (mounted) {
    setState(() => _salasDisponibles = salas);
  }
}
```

---

## 🔧 PASOS FINALES:

1. **Reemplazar** `repositorio_jurisprudencia_screen.dart` con la nueva implementación
2. **Probar** búsqueda por tipo (sentencias/jurisprudencias/resoluciones)
3. **Verificar** que los resúmenes IA se generen y cacheen en Supabase
4. **Probar** filtro por sala
5. **Verificar** badges VINCULANTE y botón "Ver Jurisprudencia"

---

## 📝 NOTAS TÉCNICAS:

### **Estructura R2:**
```
https://pub-9245781c2bca24b4c7e868111ef122f7.r2.dev/
├── {documento_id}.pdf
└── {documento_id}.txt
```

### **Query Supabase:**
```sql
-- Sentencias (incluye vinculantes)
SELECT * FROM documentos WHERE tipo = 'sentencia' ORDER BY fecha DESC;

-- Jurisprudencias
SELECT * FROM documentos WHERE es_jurisprudencia = true ORDER BY fecha DESC;

-- Resoluciones
SELECT * FROM documentos WHERE tipo = 'resoluciones' ORDER BY fecha DESC;
```

### **Caché de resúmenes:**
- Si `resumen_ia` existe → usar directamente
- Si `resumen_ia` IS NULL → generar con IA + UPDATE en Supabase
- Evita gastar tokens en sentencias ya resumidas

---

## ⚠️ ADVERTENCIA:

El método `_descargarTextoR2()` usa una edge function de Supabase (`fetch-r2-text`) que **debe existir**. Si no existe:

**Alternativa 1:** Hacer fetch directo con http (si R2 es público):
```dart
import 'package:http/http.dart' as http;

Future<String> _descargarTextoR2(String documentoId) async {
  final url = 'https://pub-9245781c2bca24b4c7e868111ef122f7.r2.dev/$documentoId.txt';
  final response = await http.get(Uri.parse(url));
  return response.statusCode == 200 ? response.body : '';
}
```

**Alternativa 2:** Guardar el texto completo en columna `texto_completo` de Supabase (más lento, ocupa más espacio)

---

## 🚀 SIGUIENTE PASO:

**Actualiza el archivo `repositorio_jurisprudencia_screen.dart`** con las secciones 4-7 de arriba.

¿Quieres que genere el archivo completo o prefieres hacerlo tú paso a paso?
