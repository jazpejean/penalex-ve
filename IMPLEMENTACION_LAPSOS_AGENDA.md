# 📆⏱️ Implementación: Calculadora de Lapsos en Agenda

## 🎯 Objetivo
Integrar calculadora de lapsos procesales directamente en la Agenda Judicial, permitiendo al usuario:
1. Calcular lapsos desde cualquier fecha
2. Marcar visualmente en el calendario inicio, transcurso y vencimiento
3. Excluir días inhábiles (fines de semana, feriados, días sin despacho)

---

## 🏗️ Arquitectura

### **Modelo de datos**

```dart
// lib/models/lapso_procesal.dart

class TipoLapso {
  final String nombre;
  final int diasHabiles;
  final String articulo; // Referencia legal
  
  const TipoLapso({
    required this.nombre,
    required this.diasHabiles,
    required this.articulo,
  });
}

class LapsoCalculado {
  final String id;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;
  final TipoLapso tipo;
  final int diasHabilesTranscurridos;
  final int diasInhabilesExcluidos;
  final List<DateTime> diasDelLapso;
  final String? notas;
  final DateTime fechaCalculo;
  
  LapsoCalculado({
    required this.id,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.tipo,
    required this.diasHabilesTranscurridos,
    required this.diasInhabilesExcluidos,
    required this.diasDelLapso,
    this.notas,
    required this.fechaCalculo,
  });
}

// Catálogo de lapsos comunes COPP
const List<TipoLapso> LAPSOS_COPP = [
  TipoLapso(
    nombre: 'Apelación de sentencia definitiva',
    diasHabiles: 5,
    articulo: 'Art. 440 COPP',
  ),
  TipoLapso(
    nombre: 'Contestación de apelación',
    diasHabiles: 5,
    articulo: 'Art. 447 COPP',
  ),
  TipoLapso(
    nombre: 'Promoción de pruebas',
    diasHabiles: 10,
    articulo: 'Art. 313 COPP',
  ),
  TipoLapso(
    nombre: 'Evacuación de pruebas',
    diasHabiles: 15,
    articulo: 'Art. 316 COPP',
  ),
  TipoLapso(
    nombre: 'Recurso de casación',
    diasHabiles: 15,
    articulo: 'Art. 451 COPP',
  ),
  TipoLapso(
    nombre: 'Recurso de revisión',
    diasHabiles: 15,
    articulo: 'Art. 470 COPP',
  ),
];
```

---

## 🎨 UI/UX - Diseño propuesto

### **AgendaScreen con botón flotante**

```dart
// En AgendaScreen agregar:
floatingActionButton: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    // Botón calculadora de lapsos
    FloatingActionButton.extended(
      heroTag: 'lapsos',
      onPressed: _mostrarCalculadoraLapsos,
      backgroundColor: dorado,
      icon: const Icon(Icons.timer, color: azulMarino),
      label: const Text(
        'Calcular lapsos',
        style: TextStyle(color: azulMarino, fontWeight: FontWeight.bold),
      ),
    ),
    const SizedBox(height: 12),
    // Botones existentes (día sin despacho, nueva audiencia)
    // ...
  ],
),
```

### **Modal/BottomSheet de calculadora**

```dart
void _mostrarCalculadoraLapsos() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: grisOscuro,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CalculadoraLapsosWidget(
          fechaSeleccionada: _selectedDay ?? DateTime.now(),
          onLapsoCalculado: (LapsoCalculado lapso) {
            // Guardar lapso y actualizar calendario
            setState(() {
              _lapsosActivos.add(lapso);
            });
            Navigator.pop(context);
          },
        ),
      ),
    ),
  );
}
```

---

## 🧮 Lógica de cálculo

### **Servicio de cálculo de lapsos**

```dart
// lib/services/lapsos_service.dart

class LapsosService {
  /// Calcula un lapso procesal excluyendo días inhábiles
  static LapsoCalculado calcularLapso({
    required DateTime fechaInicio,
    required TipoLapso tipo,
    required List<NonWorkingDay> diasInhabiles,
    bool excluirFinSemana = true,
  }) {
    final List<DateTime> diasDelLapso = [];
    int diasHabilesContados = 0;
    DateTime fechaActual = fechaInicio;
    
    // Contar días hábiles hasta completar el lapso
    while (diasHabilesContados < tipo.diasHabiles) {
      fechaActual = fechaActual.add(const Duration(days: 1));
      
      // Verificar si es día hábil
      final bool esFinDeSemana = excluirFinSemana && 
          (fechaActual.weekday == DateTime.saturday || 
           fechaActual.weekday == DateTime.sunday);
      
      final bool esFeriado = diasInhabiles.any(
        (nwd) => isSameDay(nwd.date, fechaActual)
      );
      
      if (!esFinDeSemana && !esFeriado) {
        diasHabilesContados++;
        diasDelLapso.add(fechaActual);
      }
    }
    
    return LapsoCalculado(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fechaInicio: fechaInicio,
      fechaVencimiento: fechaActual,
      tipo: tipo,
      diasHabilesTranscurridos: diasHabilesContados,
      diasInhabilesExcluidos: 
          _contarDiasEntre(fechaInicio, fechaActual) - diasHabilesContados,
      diasDelLapso: diasDelLapso,
      fechaCalculo: DateTime.now(),
    );
  }
  
  /// Guarda un lapso calculado en Supabase
  static Future<void> guardarLapso(LapsoCalculado lapso) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await Supabase.instance.client.from('lapsos_procesales').insert({
      'id': lapso.id,
      'user_id': userId,
      'fecha_inicio': lapso.fechaInicio.toIso8601String(),
      'fecha_vencimiento': lapso.fechaVencimiento.toIso8601String(),
      'tipo_lapso': lapso.tipo.nombre,
      'dias_habiles': lapso.tipo.diasHabiles,
      'articulo': lapso.tipo.articulo,
      'notas': lapso.notas,
      'created_at': lapso.fechaCalculo.toIso8601String(),
    });
  }
  
  /// Carga lapsos guardados del usuario
  static Future<List<LapsoCalculado>> cargarLapsos() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];
    
    final response = await Supabase.instance.client
        .from('lapsos_procesales')
        .select()
        .eq('user_id', userId)
        .order('fecha_inicio', ascending: false);
    
    return (response as List).map((json) => 
        LapsoCalculado.fromMap(json)).toList();
  }
  
  static int _contarDiasEntre(DateTime inicio, DateTime fin) {
    return fin.difference(inicio).inDays;
  }
}
```

---

## 🎨 Visualización en calendario

### **Builders personalizados para TableCalendar**

```dart
// Dentro de AgendaScreen, en TableCalendar:

calendarBuilders: CalendarBuilders(
  // ... builders existentes (audiencias, días sin despacho)
  
  // Builder para días dentro de lapsos
  defaultBuilder: (context, day, focusedDay) {
    // Verificar si el día pertenece a algún lapso activo
    final lapsoDelDia = _lapsosActivos.firstWhereOrNull(
      (lapso) => _esDiaDelLapso(day, lapso),
    );
    
    if (lapsoDelDia != null) {
      final esInicio = isSameDay(day, lapsoDelDia.fechaInicio);
      final esVencimiento = isSameDay(day, lapsoDelDia.fechaVencimiento);
      
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: esInicio 
              ? Colors.blue.withValues(alpha: 0.2)
              : esVencimiento
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: esInicio
                ? Colors.blue
                : esVencimiento
                    ? Colors.red
                    : Colors.amber,
            width: esInicio || esVencimiento ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: azulMarino,
                  fontWeight: esInicio || esVencimiento 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
            ),
            // Icono en esquina superior derecha
            if (esInicio || esVencimiento)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  esInicio ? Icons.play_arrow : Icons.flag,
                  size: 12,
                  color: esInicio ? Colors.blue : Colors.red,
                ),
              ),
          ],
        ),
      );
    }
    
    return null; // Usar builder por defecto
  },
  
  // Marcadores para días con lapsos
  markerBuilder: (context, day, events) {
    final markers = <Widget>[];
    
    // Marcador de audiencias (existente)
    if (events.isNotEmpty) {
      markers.add(
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: dorado,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    
    // Marcador de lapsos activos
    final tienelapso = _lapsosActivos.any(
      (lapso) => _esDiaDelLapso(day, lapso),
    );
    
    if (tienelapso) {
      markers.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
            border: Border.all(color: azulMarino, width: 1),
          ),
        ),
      );
    }
    
    return markers.isNotEmpty 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: markers,
          )
        : null;
  },
),
```

---

## 📊 SQL - Tabla en Supabase

```sql
-- Crear tabla para lapsos procesales
CREATE TABLE lapsos_procesales (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  fecha_inicio TIMESTAMP NOT NULL,
  fecha_vencimiento TIMESTAMP NOT NULL,
  tipo_lapso TEXT NOT NULL,
  dias_habiles INTEGER NOT NULL,
  articulo TEXT,
  notas TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Índices
  CONSTRAINT fk_user FOREIGN KEY (user_id) 
    REFERENCES user_profiles(id) ON DELETE CASCADE
);

-- Políticas RLS
ALTER TABLE lapsos_procesales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own lapsos"
  ON lapsos_procesales
  FOR ALL
  USING (user_id = auth.uid());
```

---

## ✅ Checklist de implementación

### Fase 1: Backend
- [ ] Crear modelo `LapsoCalculado` y `TipoLapso`
- [ ] Implementar `LapsosService` con lógica de cálculo
- [ ] Crear tabla `lapsos_procesales` en Supabase
- [ ] Configurar políticas RLS

### Fase 2: UI
- [ ] Agregar botón flotante "Calcular lapsos" en AgendaScreen
- [ ] Crear widget `CalculadoraLapsosWidget` (modal)
- [ ] Diseñar formulario con:
  - Date picker para fecha inicio
  - Dropdown de tipos de lapso
  - Checkbox "Excluir fines de semana"
  - Campo de notas opcional

### Fase 3: Visualización
- [ ] Implementar `calendarBuilders` personalizados
- [ ] Colorear días del lapso en calendario
- [ ] Agregar leyenda explicativa
- [ ] Mostrar tooltip al tocar día con lapso

### Fase 4: Gestión
- [ ] Lista de "Lapsos activos" (bottom sheet)
- [ ] Opción para eliminar lapso
- [ ] Notificación 1 día antes del vencimiento
- [ ] Exportar lapso a PDF

---

## 🎯 Resultado esperado

El usuario podrá:
1. ✅ Calcular cualquier lapso procesal del COPP
2. ✅ Ver visualmente en calendario: inicio (azul), transcurso (amarillo), vencimiento (rojo)
3. ✅ Respetar días inhábiles automáticamente
4. ✅ Guardar lapsos para referencia futura
5. ✅ Recibir notificación cercana al vencimiento

**Integración perfecta:** Agenda + Lapsos en una sola pantalla, sin necesidad de navegar a otra herramienta.
