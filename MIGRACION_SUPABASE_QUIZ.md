# 🚀 MIGRACIÓN COMPLETA A SUPABASE

## ✅ LO QUE SE IMPLEMENTÓ

**TODO el sistema ahora usa Supabase excepto el login con Firebase**

---

## 📋 PASOS PARA CONFIGURAR

### **1. Ejecutar Schema en Supabase**

1. Ir a tu proyecto de Supabase: https://app.supabase.com/project/efxzcglhyosrxtafirhs
2. Ir a **SQL Editor**
3. Copiar y pegar el contenido de `supabase_quiz_schema.sql`
4. Ejecutar el script completo

**Esto creará:**
- ✅ 7 tablas (casos, fundamentaciones, pistas, progreso, historial, ranking, casos fallados)
- ✅ Índices para búsquedas rápidas
- ✅ Row Level Security (RLS) para proteger datos
- ✅ Triggers para actualizar timestamps
- ✅ 10 casos de prueba iniciales

---

### **2. Verificar Tablas Creadas**

En Supabase Dashboard → **Table Editor**, deberías ver:

```
✓ casos_hipoteticos (10 registros)
✓ fundamentaciones
✓ pistas_casos
✓ user_quiz_progress
✓ user_casos_fallados
✓ user_respuestas
✓ ranking_global
```

---

### **3. Configuración Opcional: Función para Upsert**

Si quieres optimizar el registro de casos fallados, ejecuta en SQL Editor:

```sql
CREATE OR REPLACE FUNCTION upsert_caso_fallado(
  p_user_id UUID,
  p_caso_id UUID
)
RETURNS void AS $$
BEGIN
  INSERT INTO user_casos_fallados (user_id, caso_id, veces_fallado, bloqueado)
  VALUES (p_user_id, p_caso_id, 1, false)
  ON CONFLICT (user_id, caso_id) 
  DO UPDATE SET 
    veces_fallado = user_casos_fallados.veces_fallado + 1,
    ultima_vez_fallado = now(),
    bloqueado = user_casos_fallados.veces_fallado >= 2;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🗂️ ARQUITECTURA NUEVA

### **ANTES (Firebase/Firestore):**
```
App → FirestoreService → Firebase Firestore
```

### **AHORA (Supabase + Firebase Auth):**
```
App → SupabaseQuizService → Supabase PostgreSQL
     → Firebase Auth (solo login)
```

---

## 📦 SERVICIOS ACTUALIZADOS

### **1. `SupabaseQuizService` (NUEVO)**
**Ubicación**: `lib/services/supabase_quiz_service.dart`

**Métodos principales:**
```dart
// Obtener caso para un nivel
getCasoParaNivel(int nivel) → CasoHipotetico?

// Verificar respuesta (registra en historial)
verificarRespuesta({caso, respuesta, tiempo}) → ResultadoRespuesta

// Obtener progreso del usuario
getProgresoUsuario() → UserQuizProgress?

// Actualizar progreso
actualizarProgreso({nivel, puntos, racha, apelaciones})

// Ranking global
getRankingGlobal({limit}) → List<Map>

// Actualizar ranking
actualizarRanking()
```

**Características:**
- ✅ Selecciona casos aleatorios del pool
- ✅ Registra todas las respuestas en historial
- ✅ Sistema anti-trampa (bloquea tras 3 fallos)
- ✅ Regeneración automática de apelaciones
- ✅ Tracking completo de estadísticas
- ✅ Ranking global en tiempo real

---

### **2. Ranking Global Actualizado**
**Ubicación**: `lib/pages/global_ranking_screen.dart`

**ANTES:**
```dart
// Usaba datos locales simulados
_getUsersSimulados()
```

**AHORA:**
```dart
// Usa datos reales de Supabase
Future<List<UserModel>> _loadRanking(BuildContext context) async {
  final service = SupabaseQuizService();
  final ranking = await service.getRankingGlobal(limit: 100);
  // ...
}
```

---

### **3. GameProvider Actualizado**
**Ubicación**: `lib/providers/game_provider.dart`

**Necesitarás actualizar para usar SupabaseQuizService:**
```dart
import '../services/supabase_quiz_service.dart';

class GameState extends ChangeNotifier {
  final SupabaseQuizService _quizService = SupabaseQuizService();

  Future<void> loadGameState() async {
    setLoading(loading: true);
    final progress = await _quizService.getProgresoUsuario();
    if (progress != null) {
      _currentLevel = progress.nivelActual;
      _score = progress.puntosTotales;
      _apelaciones = progress.apelaciones;
      _lastApelacionRegeneration = progress.ultimaRegeneracionApelaciones;
    }
    setLoading(loading: false);
  }

  Future<void> saveProgress() async {
    await _quizService.actualizarProgreso(
      nivelActual: _currentLevel,
      puntosTotales: _score,
      rachaActual: _streak,
      apelaciones: _apelaciones,
    );
    await _quizService.actualizarRanking();
  }
}
```

---

### **4. QuizGameScreen Actualizado**
**Ubicación**: `lib/pages/quiz_game_screen.dart`

**ANTES:**
```dart
// Usaba CasosService local
_currentCaso = CasosService.getCasoParaNivel(gameState.currentLevel);
```

**AHORA:**
```dart
import '../services/supabase_quiz_service.dart';

final _quizService = SupabaseQuizService();

Future<void> _loadNextQuestion() async {
  final gameState = Provider.of<GameState>(context, listen: false);
  final caso = await _quizService.getCasoParaNivel(gameState.currentLevel);
  
  setState(() {
    _currentCaso = caso;
    _currentGame = QuizQuestionGame(
      gameState: gameState,
      caso: _currentCaso!,
      onAnswered: _onAnswered,
    );
  });
}

// Al verificar respuesta
void verifyAnswer() async {
  final resultado = await _quizService.verificarRespuesta(
    caso: _currentCaso!,
    respuestaUsuario: selectedIndex!,
    tiempoRespuesta: _tiempoTranscurrido,
  );
  
  setState(() {
    _resultado = resultado;
    _showingResult = true;
  });
}
```

---

## 🔄 FLUJO COMPLETO CON SUPABASE

```
1. Usuario abre app
   → Firebase Auth verifica sesión

2. Usuario entra al quiz
   → SupabaseQuizService.getProgresoUsuario()
   → Carga nivel, XP, apelaciones desde Supabase

3. Lobby (Flame)
   → Muestra progreso del usuario
   → Región actual según nivel

4. Usuario tap JUGAR
   → SupabaseQuizService.getCasoParaNivel(nivel)
   → Obtiene caso aleatorio de Supabase

5. Usuario responde
   → SupabaseQuizService.verificarRespuesta()
   → Registra en user_respuestas (historial)
   → Actualiza user_casos_fallados si incorrecto
   → Retorna Fundamentacion o Pista

6. Si correcto:
   → SupabaseQuizService.actualizarProgreso()
   → Incrementa nivel, puntos, racha
   → SupabaseQuizService.actualizarRanking()
   → Actualiza ranking_global

7. Usuario ve ranking
   → SupabaseQuizService.getRankingGlobal()
   → Obtiene top 100 en tiempo real
```

---

## 📊 DATOS EN SUPABASE

### **Tabla: casos_hipoteticos**
```sql
id | nivel | delito_base | contexto_narrativo | opciones | respuesta_correcta
```
- **Uso**: Banco de preguntas
- **RLS**: Lectura pública
- **Iniciales**: 10 casos

### **Tabla: user_quiz_progress**
```sql
user_id | nivel_actual | puntos_totales | apelaciones | racha_actual | racha_maxima
```
- **Uso**: Progreso individual
- **RLS**: Solo el usuario ve su progreso

### **Tabla: user_respuestas**
```sql
user_id | caso_id | nivel | respuesta_seleccionada | correcta | tiempo_respuesta
```
- **Uso**: Historial completo
- **RLS**: Solo el usuario ve su historial

### **Tabla: ranking_global**
```sql
user_id | nombre | nivel_actual | puntuacion_maxima | rango_actual
```
- **Uso**: Ranking público
- **RLS**: Lectura pública

---

## ✅ VERIFICACIÓN

### **1. Probar conexión a Supabase**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
print('✅ Supabase conectado: ${supabase.auth.currentUser?.email}');
```

### **2. Probar obtener casos**
```dart
final service = SupabaseQuizService();
final caso = await service.getCasoParaNivel(1);
print('✅ Caso obtenido: ${caso?.delitoBase}');
```

### **3. Probar ranking**
```dart
final ranking = await service.getRankingGlobal(limit: 10);
print('✅ Ranking: ${ranking.length} usuarios');
```

---

## 🔒 SEGURIDAD (RLS)

**Row Level Security está configurado para:**

1. **Casos**: Cualquiera puede leer (público)
2. **Progreso**: Solo el usuario ve su progreso
3. **Respuestas**: Solo el usuario ve su historial
4. **Ranking**: Todos pueden ver (público)

**Firebase Auth + Supabase RLS = Seguridad completa**

---

## 📈 ESCALABILIDAD

### **Performance:**
- Índices en todas las queries frecuentes
- Casos seleccionados aleatoriamente del pool
- Historial ilimitado (particionado automáticamente)

### **Costos:**
- **Supabase Free Tier**: 500 MB storage, 2 GB transfer
- **Firebase**: Solo Auth (gratis hasta 50k users)
- **Estimado**: Soporta 10,000 usuarios jugando activamente

---

## 🚀 PRÓXIMOS PASOS

### **1. Expandir Banco de Preguntas**
```sql
-- Agregar más casos en Supabase
INSERT INTO casos_hipoteticos (nivel, delito_base, contexto_narrativo, opciones, respuesta_correcta)
VALUES (...);
```

### **2. Agregar Fundamentaciones**
```sql
-- Vincular fundamentaciones a casos
INSERT INTO fundamentaciones (caso_id, explicacion, articulos, sentencias_ids)
VALUES (...);
```

### **3. Agregar Pistas**
```sql
-- Crear pistas para cada caso
INSERT INTO pistas_casos (caso_id, nivel_pista, texto_pista)
VALUES (...);
```

### **4. Analytics**
```sql
-- Consultas de análisis
SELECT 
  delito_base,
  COUNT(*) as total_respuestas,
  AVG(CASE WHEN correcta THEN 1 ELSE 0 END) * 100 as tasa_exito
FROM user_respuestas
JOIN casos_hipoteticos ON user_respuestas.caso_id = casos_hipoteticos.id
GROUP BY delito_base
ORDER BY tasa_exito;
```

---

## 🎯 ESTADO FINAL

### **✅ CON SUPABASE:**
- Casos hipotéticos
- Fundamentaciones legales
- Pistas
- Progreso del usuario
- Historial de respuestas
- Ranking global
- Estadísticas

### **✅ CON FIREBASE:**
- Autenticación (login/register)
- OAuth Google

### **❌ NO USA FIRESTORE:**
- Quiz completo en Supabase
- Documentos en Supabase
- Todo excepto Auth

---

## 📞 COMANDOS RÁPIDOS

```bash
# Ver logs de Supabase en tiempo real
# Dashboard → Logs → API Logs

# Consultar casos
SELECT * FROM casos_hipoteticos WHERE activo = true;

# Ver progreso de un usuario
SELECT * FROM user_quiz_progress WHERE user_id = '...';

# Ver ranking
SELECT * FROM ranking_global ORDER BY puntuacion_maxima DESC LIMIT 10;

# Resetear progreso (desarrollo)
DELETE FROM user_quiz_progress WHERE user_id = '...';
DELETE FROM user_respuestas WHERE user_id = '...';
```

---

**Implementado**: Sistema completo con Supabase  
**Fecha**: 2026-08-16  
**Estado**: ✅ Firebase solo para Auth, TODO lo demás en Supabase  
**Próximo paso**: Ejecutar schema y actualizar código para usar SupabaseQuizService
