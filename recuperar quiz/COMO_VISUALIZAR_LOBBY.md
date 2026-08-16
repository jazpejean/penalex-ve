# 🎨 CÓMO VISUALIZAR EL LOBBY

## Herramienta de Preview Creada

He creado un generador de previews en:
**`lib/tools/lobby_preview_generator.dart`**

---

## 🚀 CÓMO USAR

### **Opción 1: Agregar Ruta Temporal**

En tu `main.dart` o donde tengas las rutas:

```dart
import 'package:penalex_ve/tools/lobby_preview_generator.dart';

// Agregar esta ruta temporal:
MaterialPageRoute(
  builder: (context) => const LobbyPreviewGenerator(),
);
```

### **Opción 2: Botón de Desarrollo**

Agrega un botón flotante en cualquier pantalla:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LobbyPreviewGenerator(),
      ),
    );
  },
  child: const Icon(Icons.preview),
),
```

---

## 🎮 FUNCIONALIDADES DEL PREVIEW

### **1. Control de Nivel**
- Slider para navegar del nivel 1 al 3000
- Botones rápidos: Nivel 1, 100, 500, 1000, 3000

### **2. Vista del Lobby**
**Muestra:**
- ✅ Banner de la región actual (estado, capital, descripción)
- ✅ Camino vertical de mármol
- ✅ Monumentos cercanos (±50 niveles)
- ✅ Medallón del nivel actual (grande, dorado, pulsante)
- ✅ Niveles cercanos (±3 niveles)
- ✅ Colores de la región

### **3. Información de Monumentos**
Cada monumento muestra:
- Icono según tipo
- Nombre del monumento
- Badge "HISTÓRICO" si aplica
- Número de nivel
- Color según tipo:
  - 🔵 Azul: Tribunales
  - 🟡 Dorado: Coloniales
  - 🔴 Rojo: Iglesias
  - 🟢 Verde: Plazas

### **4. Captura de Pantalla**
- Botón de descarga en el AppBar
- Captura en alta resolución (3x)
- Guarda preview del nivel actual

---

## 📸 EJEMPLO DE USO

### **Ver Nivel 100 (Caracas):**
```
1. Abrir LobbyPreviewGenerator
2. Slider → 100
3. Ver:
   - Región: Distrito Capital
   - Monumento: Casa Natal del Libertador
   - Color: Rojo
```

### **Ver Nivel 625 (Maracaibo):**
```
1. Slider → 625
2. Ver:
   - Región: Zulia
   - Monumento: Basílica de Chiquinquirá
   - Color: Azul Rey
```

### **Ver Nivel 3000 (Magistrado):**
```
1. Botón "Nivel 3000"
2. Ver:
   - Región: Distrito Capital (Retorno)
   - Monumento: Magistratura Suprema
   - Color: Dorado
```

---

## 🎨 LO QUE VERÁS

```
┌─────────────────────────────────────────┐
│  🗺️ Zulia                               │
│  Capital: Maracaibo                     │
│  "Capital petrolera del país"           │
│  Niveles 601-750 | Actual: 625          │
├─────────────────────────────────────────┤
│                                         │
│      [Monumento]                        │
│   🏛️ Casa Morales                       │
│      Nivel 650                          │
│                                         │
│         ⚪ 622                          │
│         ⚪ 623                          │
│         ⚪ 624                          │
│      ═══════════                        │
│        🟡 625  ← NIVEL ACTUAL           │
│      ═══════════                        │
│         ⚪ 626                          │
│         ⚪ 627                          │
│         ⚪ 628                          │
│                                         │
│      [Monumento]                        │
│   ⛪ Basílica Chiquinquirá               │
│      Nivel 625 • HISTÓRICO              │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🔧 PERSONALIZACIÓN

### **Cambiar Diseño:**

Edita `lobby_preview_generator.dart`:

```dart
// Cambiar tamaño del medallón actual
width: 150,  // En lugar de 120

// Cambiar espaciado entre niveles
final y = 250.0 + (offsetFromCurrent * 40); // En lugar de 30

// Cambiar rango visible de monumentos
final startLevel = (_selectedLevel - 100).clamp(1, 3000); // En lugar de 50
```

### **Agregar Más Info:**

```dart
// En _buildRegionBanner, agregar:
Text('${region.monumentos.length} monumentos en esta región'),
```

---

## 📊 DATOS QUE MUESTRA

### **Por Región:**
- Nombre del estado
- Capital
- Descripción
- Rango de niveles
- Color distintivo
- Monumentos

### **Por Monumento:**
- Nombre
- Tipo (tribunal/colonial/iglesia/plaza/institución)
- Nivel donde aparece
- Si es histórico o no
- Icono representativo

---

## 🎯 REGIONES PARA PROBAR

| Nivel | Región | Monumentos Destacados |
|-------|--------|----------------------|
| 1-125 | Distrito Capital | TSJ, Panteón Nacional |
| 126-250 | Miranda | Corte de Apelaciones |
| 251-350 | Vargas | Fuerte San Carlos |
| 476-600 | Carabobo | Campo de Carabobo |
| 601-750 | Zulia | Basílica Chiquinquirá |
| 876-1000 | Táchira | Catedral San Cristóbal |
| 1001-1125 | Mérida | Universidad de Los Andes |
| 1126-1250 | Bolívar | Casa del Congreso Angostura |
| 2801-3000 | DC (Retorno) | Magistratura Suprema |

---

## ✅ RESULTADO

Obtendrás una **visualización clara** de:
- Cómo se ve cada región
- Qué monumentos aparecen
- Colores distintivos
- Distribución de niveles
- Estilo visual del lobby

Puedes hacer capturas y compartirlas para validar el diseño.

---

## 🚀 SIGUIENTE PASO

Una vez validado el diseño:
1. Integrar en `quiz_lobby_game.dart` (Flame)
2. Agregar animaciones
3. Cargar sprites reales de monumentos
4. Implementar transiciones entre regiones

---

**Creado:** 2026-08-16  
**Herramienta:** `LobbyPreviewGenerator`  
**Estado:** ✅ Lista para usar
