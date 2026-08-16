# 🎯 IMPLEMENTACIÓN DEL SISTEMA DE QUIZ - 100 PREGUNTAS DE PRUEBA

## ✅ Archivos Creados

### 1. **`lib/data/quiz_questions_data.dart`**
- ✅ Banco de 100 preguntas generadas automáticamente
- ✅ Organizadas por categorías:
  - **Niveles 1-20**: Parte General del Derecho Penal
  - **Niveles 21-40**: Delitos contra las Personas
  - **Niveles 41-60**: Delitos contra la Propiedad
  - **Niveles 61-80**: COPP y Procedimiento Penal
  - **Niveles 81-100**: Drogas y Leyes Especiales

### 2. **`lib/services/casos_service.dart`**
- ✅ Servicio para gestionar casos y respuestas
- ✅ Sistema anti-trampa implementado:
  - **Respuesta correcta**: Devuelve fundamentación completa con artículos
  - **Respuesta incorrecta**: Devuelve pista vaga (NO revela respuesta)
- ✅ Bloqueo de casos tras 3 intentos fallidos

### 3. **`lib/pages/quiz_game_screen.dart`**
- ✅ Interfaz de quiz con diseño profesional
- ✅ Sistema de 4 opciones (A, B, C, D)
- ✅ Muestra caso hipotético narrativo
- ✅ Feedback diferenciado:
  - Verde con fundamentación si correcto
  - Naranja con pista vaga si incorrecto
- ✅ Integrado con `GameProvider`

---

## 📊 ESTRUCTURA DE DATOS

### CasoHipotetico (Modelo)
```dart
{
  id: 'caso_1',
  nivel: 1,
  poolId: 1,
  delitoBase: 'Tentativa de Hurto',
  contextoNarrativo: 'José intenta robar un celular...',
  opciones: ['Opción A', 'Opción B', 'Opción C', 'Opción D'],
  respuestaCorrecta: 1, // Índice 0-3
  dificultad: 1,
}
```

### Fundamentación (Solo si correcto)
```dart
{
  explicacion: 'La tentativa se configura cuando...',
  articulos: [
    {codigo: 'CP', articulo: 'Art. 80', texto: '...'},
    {codigo: 'CP', articulo: 'Art. 453', texto: '...'},
  ],
  sentencias: ['TSJ-SCP-2015-0234'],
  jurisprudencias: [],
}
```

### Pista (Solo si incorrecto)
```dart
{
  nivelPista: 1,
  textoPista: 'Analiza si el delito se consumó o quedó en fase de ejecución.',
  busquedaSugerida: 'Revisa: Tentativa de Hurto en CP',
}
```

---

## 🎮 CÓMO USAR

### Opción 1: Probar Directamente
```dart
// En tu main.dart o navegación
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const QuizGameScreen()),
);
```

### Opción 2: Desde el Lobby
```dart
// En quiz_lobby_screen_flame.dart, agregar botón:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizGameScreen()),
    );
  },
  child: const Text('INICIAR QUIZ'),
)
```

---

## 🧪 TESTING - Casos de Ejemplo

### Ejemplo 1: Nivel 1 - Tentativa de Hurto
**Pregunta**: José intenta robar un celular de una mesa en un café pero el dueño lo detiene antes de salir. ¿Calificación jurídica?

**Opciones**:
- A) Hurto consumado
- **B) Tentativa de hurto** ✅ CORRECTA
- C) Apropiación indebida
- D) Acto preparatorio impune

**Fundamentación (si correcto)**:
> La tentativa se configura cuando el autor inicia la ejecución del delito pero no lo consuma por causas ajenas a su voluntad. José realizó actos de apoderamiento pero fue interrumpido.
> - **Art. 80 CP**: Tentativa
> - **Art. 453 CP**: Hurto

**Pista (si incorrecto)**:
> Analiza si el delito se consumó o quedó en fase de ejecución.

### Ejemplo 2: Nivel 2 - Legítima Defensa
**Pregunta**: María es atacada con cuchillo y se defiende con piedra causando lesiones al agresor. ¿Su situación jurídica?

**Opciones**:
- A) Lesiones graves
- **B) Legítima defensa** ✅ CORRECTA
- C) Exceso en defensa
- D) Riña mutua

---

## 🔄 FLUJO DEL SISTEMA

1. **Usuario entra al quiz** → Carga caso del nivel actual
2. **Lee caso hipotético** → Selecciona una de 4 opciones
3. **Verifica respuesta**:
   - ✅ **Correcta**: Muestra fundamentación legal + avanza nivel
   - ❌ **Incorrecta**: Muestra pista vaga + permite reintentar
4. **Tras 3 intentos fallidos**: Bloquea caso, requiere apelación
5. **Continuar** → Carga siguiente nivel

---

## 📈 ESTADÍSTICAS DEL SISTEMA

- ✅ **100 preguntas de prueba** generadas
- ✅ **5 categorías** de derecho penal venezolano
- ✅ **Sistema anti-trampa**: Pistas vagas, NO revela respuesta
- ✅ **Fundamentaciones legales**: 5 casos con artículos reales del CP
- ✅ **Escalado**: Plantillas replicables hasta 3000 niveles

---

## 🚀 PRÓXIMOS PASOS

### Fase 1: Testing (ACTUAL)
- [x] Crear 100 preguntas de prueba
- [x] Implementar servicio de casos
- [x] Crear interfaz de quiz
- [ ] Probar flujo completo en app

### Fase 2: Expansión
- [ ] Agregar 150 fundamentaciones legales completas
- [ ] Crear sistema de variaciones (5 casos por nivel)
- [ ] Implementar generación procedural de casos

### Fase 3: Producción
- [ ] Migrar a Supabase (tabla `casos_hipoteticos`)
- [ ] Implementar cache local con Hive
- [ ] Agregar analytics de tasa de éxito por caso

---

## 🛠 PERSONALIZACIÓN

### Agregar Nueva Categoría de Preguntas

1. En `quiz_questions_data.dart`, agregar template:
```dart
static final List<Map<String, dynamic>> _miNuevaCategoriaTemplates = [
  {
    'delito': 'Nombre del Delito',
    'contexto': 'Descripción del caso...',
    'opciones': ['A', 'B', 'C', 'D'],
    'correcta': 0, // Índice 0-3
  },
];
```

2. En `_generateTestCases()`, agregar loop:
```dart
for (int i = 0; i < 20; i++) {
  cases.add(_createCase(
    caseId++,
    'Mi Nueva Categoría',
    _miNuevaCategoriaTemplates[i % _miNuevaCategoriaTemplates.length],
  ));
}
```

### Agregar Fundamentación Legal

En `casos_service.dart`, agregar a `_fundamentacionesMap`:
```dart
'Mi Delito': {
  'explicacion': 'Explicación doctrinal...',
  'articulos': [
    {'codigo': 'CP', 'articulo': 'Art. X', 'texto': '...'},
  ],
  'sentencias': ['TSJ-SCP-XXXX-XXXX'],
  'jurisprudencias': [],
},
```

---

## 📱 CAPTURAS ESPERADAS

### Vista de Pregunta
```
┌──────────────────────────────────┐
│   NIVEL: 1    APELACIONES: 5     │
├──────────────────────────────────┤
│  [TENTATIVA DE HURTO]            │
│                                  │
│  CASO HIPOTÉTICO:                │
│  José intenta robar un celular...│
│                                  │
│  ○ A) Hurto consumado            │
│  ● B) Tentativa de hurto         │
│  ○ C) Apropiación indebida       │
│  ○ D) Acto preparatorio          │
│                                  │
│  [ VERIFICAR RESPUESTA ]         │
└──────────────────────────────────┘
```

### Vista de Resultado Correcto
```
┌──────────────────────────────────┐
│          ✓ ¡CORRECTO!            │
│                                  │
│  ⚖️ FUNDAMENTACIÓN LEGAL         │
│  La tentativa se configura...    │
│  • Art. 80 CP: Tentativa         │
│  • Art. 453 CP: Hurto            │
│                                  │
│  [ CONTINUAR ]                   │
└──────────────────────────────────┘
```

### Vista de Resultado Incorrecto
```
┌──────────────────────────────────┐
│          ✗ INCORRECTO            │
│                                  │
│  💡 PISTA                        │
│  Analiza si el delito se         │
│  consumó o quedó en fase         │
│  de ejecución.                   │
│                                  │
│  [ INTENTAR DE NUEVO ]           │
└──────────────────────────────────┘
```

---

## 🎓 CRÉDITOS

**Sistema de Quiz Gamificado**
- Arquitectura: Sistema anti-trampa con rotación de casos
- Fundamentaciones: Código Penal Venezolano + TSJ
- Diseño: Profesional institucional venezolano

**Versión**: 1.0.0 (100 preguntas de prueba)
**Fecha**: 2026
**Framework**: Flutter + Flame Engine

---

## 📞 SOPORTE

Para agregar más preguntas, modificar fundamentaciones o ajustar dificultad:
1. Editar `quiz_questions_data.dart` (templates)
2. Editar `casos_service.dart` (fundamentaciones y pistas)
3. Recargar app

**¡El sistema está listo para probar! 🚀⚖️🇻🇪**
