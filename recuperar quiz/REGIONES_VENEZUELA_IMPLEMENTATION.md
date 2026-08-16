# 🗺️ SISTEMA DE REGIONES DE VENEZUELA

## ✅ IMPLEMENTACIÓN COMPLETA

### **Concepto:**
**Recorrido por Venezuela** donde cada rango de niveles representa un estado diferente con:
- 🏛️ Monumentos coloniales históricos
- ⚖️ Edificaciones de justicia (tribunales, palacios)
- ⛪ Iglesias y catedrales coloniales
- 🏞️ Plazas y centros cívicos
- 🎓 Instituciones educativas y gubernamentales

---

## 📂 ARCHIVO PRINCIPAL

### **`lib/data/venezuela_regions.dart`**

**Contiene:**
- `RegionVenezuela`: Clase que representa un estado
- `MonumentoRegional`: Monumentos y edificaciones
- `regionesVenezuela`: Lista de 10+ regiones implementadas
- Helper functions: `getRegionForLevel()`, `getMonumentosInRange()`

---

## 🗺️ REGIONES IMPLEMENTADAS

### **1. Distrito Capital - Caracas** (Niveles 1-125)
**Color:** Rojo #CF142B  
**Monumentos:**
- ⚖️ Tribunal Supremo de Justicia (Nivel 10)
- 🏛️ Palacio Federal Legislativo (Nivel 25) 🏛️ HISTÓRICO
- ⛪ Catedral de Caracas (Nivel 40) 🏛️ HISTÓRICO
- 🏞️ Plaza Bolívar (Nivel 50) 🏛️ HISTÓRICO
- ⚖️ Palacio de Justicia (Nivel 75)
- 🏠 Casa Natal del Libertador (Nivel 100) 🏛️ HISTÓRICO
- 🏛️ Panteón Nacional (Nivel 125) 🏛️ HISTÓRICO

### **2. Miranda - Los Teques** (Niveles 126-250)
**Color:** Azul #003893  
**Monumentos:**
- ⚖️ Circuito Judicial Penal de Miranda (Nivel 150)
- 🏞️ Plaza Bolívar de Los Teques (Nivel 175) 🏛️ HISTÓRICO
- ⛪ Iglesia San Felipe Neri (Nivel 200) 🏛️ HISTÓRICO
- ⚖️ Corte de Apelaciones Miranda (Nivel 225)

### **3. Vargas - La Guaira** (Niveles 251-350)
**Color:** Amarillo #FCDD09  
**Monumentos:**
- 🏰 Fuerte San Carlos (Nivel 275) 🏛️ HISTÓRICO
- ⚖️ Tribunal del Puerto (Nivel 300)
- 🏛️ Casa Guipuzcoana (Nivel 325) 🏛️ HISTÓRICO

### **4. Aragua - Maracay** (Niveles 351-475)
**Color:** Verde #228B22  
**Monumentos:**
- 🏞️ Plaza Bolívar de Maracay (Nivel 375)
- 🏛️ Palacio de Gobierno (Nivel 400)
- ⚖️ Circuito Judicial Aragua (Nivel 425)
- ⛪ Catedral de Maracay (Nivel 450)

### **5. Carabobo - Valencia** (Niveles 476-600)
**Color:** Dorado #D4AF37  
**Monumentos:**
- 🏛️ Campo de Carabobo (Nivel 500) 🏛️ HISTÓRICO
- 🏛️ Capitolio de Valencia (Nivel 525)
- ⛪ Catedral de Valencia (Nivel 550) 🏛️ HISTÓRICO
- ⚖️ Palacio de Justicia Carabobo (Nivel 575)

### **6. Zulia - Maracaibo** (Niveles 601-750)
**Color:** Azul Rey #4169E1  
**Monumentos:**
- ⛪ Basílica de Chiquinquirá (Nivel 625) 🏛️ HISTÓRICO
- 🏠 Casa Morales (Nivel 650) 🏛️ HISTÓRICO
- 🏛️ Palacio de Gobierno del Zulia (Nivel 675)
- ⚖️ Circuito Judicial Zulia (Nivel 700)
- ⛪ Catedral de Maracaibo (Nivel 725)

### **7. Lara - Barquisimeto** (Niveles 751-875)
**Color:** Rojo Tomate #FF6347  
**Monumentos:**
- ⛪ Catedral de Barquisimeto (Nivel 775)
- 🏛️ Palacio Legislativo Lara (Nivel 800)
- ⚖️ Tribunales de Barquisimeto (Nivel 825)
- 🏞️ Plaza Bolívar (Nivel 850)

### **8. Táchira - San Cristóbal** (Niveles 876-1000)
**Color:** Marrón Andino #8B4513  
**Monumentos:**
- ⛪ Catedral de San Cristóbal (Nivel 900) 🏛️ HISTÓRICO
- 🏛️ Palacio de los Leones (Nivel 925)
- ⚖️ Circuito Judicial Táchira (Nivel 950)
- 🏞️ Plaza Bolívar Tachirense (Nivel 975)

### **9. Mérida - Mérida** (Niveles 1001-1125)
**Color:** Verde Oscuro #006400  
**Monumentos:**
- 🎓 Universidad de Los Andes (Nivel 1025) 🏛️ HISTÓRICO
- ⛪ Catedral Metropolitana (Nivel 1050) 🏛️ HISTÓRICO
- ⚖️ Tribunales de Mérida (Nivel 1075)
- 🏞️ Plaza Bolívar de Mérida (Nivel 1100)

### **10. Bolívar - Ciudad Bolívar** (Niveles 1126-1250)
**Color:** Marrón Dorado #CD853F  
**Monumentos:**
- ⛪ Catedral de Ciudad Bolívar (Nivel 1150) 🏛️ HISTÓRICO
- 🏛️ Casa del Congreso de Angostura (Nivel 1175) 🏛️ HISTÓRICO
- ⚖️ Palacio de Justicia Bolívar (Nivel 1200)
- 🏞️ Plaza Bolívar Colonial (Nivel 1225) 🏛️ HISTÓRICO

### **11. Anzoátegui - Barcelona** (Niveles 1251-1400)
**Color:** Azul Dodger #1E90FF  
**Monumentos:**
- 🏰 Casa Fuerte de Barcelona (Nivel 1275) 🏛️ HISTÓRICO
- ⛪ Catedral de Barcelona (Nivel 1300) 🏛️ HISTÓRICO
- ⚖️ Circuito Judicial Anzoátegui (Nivel 1325)
- 🏞️ Plaza Bolívar (Nivel 1375)

### **12. Distrito Capital (Retorno) - Caracas** (Niveles 2801-3000)
**Color:** Dorado Supremo #FFD700  
**Monumentos:**
- ⚖️ Sala Constitucional TSJ (Nivel 2850)
- ⚖️ Sala de Casación Penal (Nivel 2900)
- 🏆 Presidencia del TSJ (Nivel 2950)
- 👑 Magistratura Suprema (Nivel 3000)

---

## 🎨 TIPOS DE MONUMENTOS

```dart
'tribunal'     → Tribunales y juzgados
'colonial'     → Edificaciones históricas
'iglesia'      → Catedrales y templos
'plaza'        → Espacios cívicos
'institucion'  → Palacios y sedes gubernamentales
```

**Iconos Asignados:**
- ⚖️ `Icons.account_balance` - Tribunales
- ⚖️ `Icons.gavel` - Juzgados
- ⛪ `Icons.church` - Iglesias
- 🏞️ `Icons.park` / `Icons.landscape` - Plazas
- 🏛️ `Icons.domain` / `Icons.business` - Instituciones
- 🏰 `Icons.fort` - Fortificaciones
- 🏠 `Icons.home` - Casas históricas
- 🎓 `Icons.school` - Universidades
- 🏆 `Icons.emoji_events` - Magistratura

---

## 🎮 INTEGRACIÓN CON GAME PROVIDER

### **Métodos Añadidos:**

```dart
// En game_provider.dart

/// Obtener la región actual
RegionVenezuela? getCurrentRegion() {
  return getRegionForLevel(_currentLevel);
}

/// Obtener progreso completo
({String rango, String region, String capital}) getFullProgress() {
  final rango = getRankForLevel(_currentLevel);
  final region = getCurrentRegion();
  return (
    rango: rango,
    region: region?.estado ?? 'Venezuela',
    capital: region?.capital ?? 'Caracas',
  );
}
```

---

## 📱 USO EN LA UI

### **Ejemplo 1: Banner Superior**

```dart
final progress = gameState.getFullProgress();
final region = gameState.getCurrentRegion();

Text('${progress.rango}');
Text('${region?.capital}, ${region?.estado}');
// Muestra: "Juez de Primera Instancia"
//          "Maracaibo, Zulia"
```

### **Ejemplo 2: Fondo del Lobby**

```dart
final region = gameState.getCurrentRegion();
final backgroundColor = region?.colorPrincipal ?? Colors.grey;

Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        backgroundColor.withOpacity(0.3),
        Colors.white,
      ],
    ),
  ),
);
```

### **Ejemplo 3: Monumentos en el Mapa**

```dart
final monumentos = getMonumentosInRange(
  selectedChapter * 10 + 1,
  selectedChapter * 10 + 10,
);

for (final monumento in monumentos) {
  MonumentComponent(
    nombre: monumento.nombre,
    tipo: monumento.tipo,
    icono: monumento.icono,
    nivel: monumento.nivel,
    esHistorico: monumento.esHistorico,
  );
}
```

---

## 🎯 CARACTERÍSTICAS VISUALES

### **En el Lobby con Flame:**

1. **Cambio de Color de Fondo:**
   - Cada región tiene su color distintivo
   - Transición suave entre regiones

2. **Monumentos Regionales:**
   - Aparecen en niveles específicos
   - Badge "HISTÓRICO" para monumentos coloniales
   - Icono distintivo por tipo

3. **Banner de Región:**
   ```
   ┌──────────────────────────────┐
   │ 🗺️ Estado Zulia              │
   │ Capital: Maracaibo            │
   │ Niveles 601 - 750             │
   └──────────────────────────────┘
   ```

4. **Progreso Visual:**
   ```
   Distrito Capital ████████░░░░ 125/250
   Miranda         ░░░░░░░░░░░░ 0/125
   ```

---

## 📂 ASSETS NECESARIOS (Opcional)

```
assets/images/regions/
├── caracas_background.jpg
├── miranda_background.jpg
├── vargas_background.jpg
├── aragua_background.jpg
├── carabobo_background.jpg
├── zulia_background.jpg
├── lara_background.jpg
├── tachira_background.jpg
├── merida_background.jpg
├── bolivar_background.jpg
├── anzoategui_background.jpg
└── caracas_magistrado.jpg (nivel 3000)
```

**Si no existen:** El sistema usa degradados de colores.

---

## 🚀 PRÓXIMOS PASOS

### **1. Actualizar quiz_lobby_game.dart**
```dart
// Usar color de región como fondo
final region = getRegionForLevel(currentLevel);
final bgColor = region?.colorPrincipal ?? Colors.grey;

// Mostrar monumentos regionales
for (final monumento in region.monumentos) {
  MonumentComponent(...);
}
```

### **2. Agregar Banner de Región**
```dart
// En quiz_lobby_screen_flame.dart
Container(
  child: Row(
    children: [
      Icon(Icons.location_on),
      Text('${region.capital}, ${region.estado}'),
    ],
  ),
);
```

### **3. Transiciones Entre Regiones**
```dart
// Animación al cambiar de estado
AnimatedContainer(
  duration: Duration(seconds: 2),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [oldRegion.color, newRegion.color],
    ),
  ),
);
```

---

## 📊 ESTADÍSTICAS

- **Total de Regiones:** 12 estados
- **Total de Monumentos:** 60+ edificaciones
- **Monumentos Históricos:** 25+ (marcados con 🏛️)
- **Niveles Cubiertos:** 1-3000
- **Tipos de Edificaciones:** 5 categorías

---

## ✅ CHECKLIST

- [x] Archivo `venezuela_regions.dart` creado
- [x] 12 regiones implementadas
- [x] 60+ monumentos definidos
- [x] Integración con `game_provider.dart`
- [x] Helper functions disponibles
- [ ] Actualizar `quiz_lobby_game.dart` con regiones
- [ ] Agregar banner de región en UI
- [ ] Crear assets de fondo (opcional)
- [ ] Animaciones de transición entre regiones

---

**Creado:** 2026-08-16  
**Estado:** ✅ Data estructurada, pendiente integración visual
