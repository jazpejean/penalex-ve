# 🎯 CÓMO INTEGRAR EL QUIZ EN TU APP

## Opción 1: Desde el Lobby Actual (Recomendada)

Ya tienes `lib/pages/quiz_lobby_screen.dart` en las rutas de `main.dart`. Solo agrega un botón para iniciar el quiz.

### En `lib/pages/quiz_lobby_screen.dart`:

```dart
import 'package:penalex_ve/pages/quiz_game_screen.dart'; // Agregar este import

// Dentro del build(), agregar botón:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizGameScreen(),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFD4AF37), // Dorado
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  ),
  child: const Text(
    'INICIAR QUIZ',
    style: TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

---

## Opción 2: Desde el Dashboard/Menu Principal

### En `lib/pages/page_manager_screen.dart` o donde tengas tu menú:

```dart
// Agregar este import arriba:
import 'package:penalex_ve/pages/quiz_game_screen.dart';

// Agregar un botón/card en tu menú:
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizGameScreen()),
    );
  },
  child: Card(
    child: Column(
      children: [
        Icon(Icons.quiz, size: 48, color: Color(0xFFD4AF37)),
        SizedBox(height: 8),
        Text('Quiz Penal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    ),
  ),
)
```

---

## Opción 3: Usando Rutas Nombradas (Ya Configuradas)

Ya tienes estas rutas en `main.dart`:
- `'/quiz'`
- `'/quiz_lobby'`

Para navegar al lobby y de ahí al quiz:

```dart
// Ir al lobby:
Navigator.pushNamed(context, '/quiz_lobby');

// O si agregas una ruta directa al quiz en main.dart:
'/quiz_game': (context) => const QuizGameScreen(),

// Entonces:
Navigator.pushNamed(context, '/quiz_game');
```

---

## 🎨 Ejemplo Completo: Card en Dashboard

```dart
Container(
  margin: EdgeInsets.all(16),
  child: Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Color(0xFFD4AF37), width: 2),
    ),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuizGameScreen()),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Color(0xFFD4AF37),
            ),
            SizedBox(height: 12),
            Text(
              'Quiz de Derecho Penal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '100 casos hipotéticos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFD4AF37),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'COMENZAR',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
)
```

---

## 🔗 Imports Necesarios

En cualquier archivo donde integres el quiz:

```dart
import 'package:penalex_ve/pages/quiz_game_screen.dart';
```

---

## ⚙️ Requisitos (Ya Satisfechos)

El quiz ya está integrado con:
- ✅ `GameProvider` (niveles, apelaciones, scoring)
- ✅ `UserProvider` (progreso del usuario)
- ✅ Sistema de navegación de Flutter

**No necesitas configuración adicional.**

---

## 🎮 Flujo Completo del Usuario

1. **Dashboard** → Botón "Quiz Penal"
2. **Quiz Lobby** (opcional) → Botón "Iniciar Quiz"
3. **Quiz Game Screen** → Caso hipotético
4. **Selecciona respuesta** → Verifica
5. **Resultado**:
   - ✅ Correcto → Fundamentación legal → Siguiente nivel
   - ❌ Incorrecto → Pista vaga → Reintentar

---

## 💡 Tips de UX

### Para mejor experiencia:

1. **Mostrar progreso antes de entrar**:
```dart
Text('Nivel ${gameProvider.nivelActual}/3000')
```

2. **Mostrar apelaciones disponibles**:
```dart
Text('⚖️ ${gameProvider.apelacionesDisponibles} apelaciones')
```

3. **Badge de notificación**:
```dart
Badge(
  label: Text('${gameProvider.apelacionesDisponibles}'),
  child: Icon(Icons.quiz),
)
```

---

## 🚀 Ejemplo Mínimo (Copy-Paste)

Agrega esto en cualquier pantalla de tu app:

```dart
import 'package:penalex_ve/pages/quiz_game_screen.dart';

// Donde quieras el botón:
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const QuizGameScreen()),
  ),
  icon: Icon(Icons.quiz),
  label: Text('Quiz Penal'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFD4AF37),
    foregroundColor: Colors.black,
  ),
)
```

---

## ✅ Verificar Integración

Después de agregar el botón:

1. Compila: `flutter run`
2. Tap en el botón
3. Deberías ver la pantalla del quiz con un caso hipotético

---

## 📱 Ubicaciones Recomendadas

Según tu estructura, agrega el botón en:

1. **`page_manager_screen.dart`** - Menú principal ⭐ (Recomendado)
2. **`quiz_lobby_screen.dart`** - Lobby del quiz
3. **`dashboard_screen.dart`** - Dashboard principal
4. **`app_drawer.dart`** - Menú lateral

---

**¿Dónde quieres que te ayude a agregarlo?** 

Dime el archivo y te muestro exactamente dónde y cómo.
