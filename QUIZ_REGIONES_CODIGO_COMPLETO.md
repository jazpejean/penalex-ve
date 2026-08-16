# 🗺️ CÓDIGO COMPLETO - SISTEMA DE REGIONES VENEZUELA

## ⚡ INSTRUCCIONES RÁPIDAS:

1. Copia cada archivo completo
2. Pégalo en la ubicación indicada
3. Guarda y listo

---

## 📄 ARCHIVO 1: `lib/models/region_venezuela.dart`

```dart
import 'package:flutter/material.dart';

class RegionVenezuela {
  final String id;
  final String nombre;
  final String capital;
  final int nivelInicio;
  final int nivelFin;
  final Color colorPrincipal;
  final List<String> monumentos;
  final String descripcion;
  
  RegionVenezuela({
    required this.id,
    required this.nombre,
    required this.capital,
    required this.nivelInicio,
    required this.nivelFin,
    required this.colorPrincipal,
    required this.monumentos,
    required this.descripcion,
  });
  
  int get totalNiveles => nivelFin - nivelInicio + 1;
  
  bool contieneNivel(int nivel) {
    return nivel >= nivelInicio && nivel <= nivelFin;
  }
  
  double calcularProgreso(int nivelActual) {
    if (nivelActual < nivelInicio) return 0.0;
    if (nivelActual > nivelFin) return 1.0;
    return (nivelActual - nivelInicio + 1) / totalNiveles;
  }
  
  String getMonumentoPrincipal() => monumentos.isNotEmpty ? monumentos.first : capital;
}
```

---

## 📄 ARCHIVO 2: `lib/config/regiones_quiz.dart`

```dart
import 'package:flutter/material.dart';
import '../models/region_venezuela.dart';

class RegionesQuiz {
  static final List<RegionVenezuela> regiones = [
    // REGIÓN 1: DISTRITO CAPITAL
    RegionVenezuela(
      id: 'caracas',
      nombre: 'Distrito Capital',
      capital: 'Caracas',
      nivelInicio: 1,
      nivelFin: 125,
      colorPrincipal: const Color(0xFFCF142B), // Rojo
      monumentos: [
        'Tribunal Supremo de Justicia',
        'Palacio Federal Legislativo',
        'Catedral de Caracas',
        'Plaza Bolívar',
        'Casa Natal del Libertador',
        'Panteón Nacional',
      ],
      descripcion: 'Capital de la República, sede del poder judicial',
    ),
    
    // REGIÓN 2: MIRANDA
    RegionVenezuela(
      id: 'miranda',
      nombre: 'Miranda',
      capital: 'Los Teques',
      nivelInicio: 126,
      nivelFin: 250,
      colorPrincipal: const Color(0xFF003893), // Azul
      monumentos: [
        'Circuito Judicial de Miranda',
        'Plaza Bolívar Los Teques',
        'Iglesia San Felipe Neri',
        'Corte de Apelaciones',
      ],
      descripcion: 'Estado Miranda, cuna del Libertador',
    ),
    
    // REGIÓN 3: VARGAS
    RegionVenezuela(
      id: 'vargas',
      nombre: 'Vargas',
      capital: 'La Guaira',
      nivelInicio: 251,
      nivelFin: 350,
      colorPrincipal: const Color(0xFFFCDD09), // Amarillo
      monumentos: [
        'Fortín San Carlos',
        'Tribunal del Puerto',
        'Casa Guipuzcoana',
        'Puerto de La Guaira',
      ],
      descripcion: 'Puerto histórico y fortaleza colonial',
    ),
    
    // REGIÓN 4: ARAGUA
    RegionVenezuela(
      id: 'aragua',
      nombre: 'Aragua',
      capital: 'Maracay',
      nivelInicio: 351,
      nivelFin: 475,
      colorPrincipal: const Color(0xFF228B22), // Verde
      monumentos: [
        'Plaza Bolívar Maracay',
        'Palacio de Gobierno',
        'Circuito Judicial Aragua',
        'Catedral de Maracay',
      ],
      descripcion: 'Ciudad jardín con tribunales y naturaleza',
    ),
    
    // REGIÓN 5: CARABOBO
    RegionVenezuela(
      id: 'carabobo',
      nombre: 'Carabobo',
      capital: 'Valencia',
      nivelInicio: 476,
      nivelFin: 600,
      colorPrincipal: const Color(0xFFD4AF37), // Dorado
      monumentos: [
        'Campo de Carabobo',
        'Capitolio de Valencia',
        'Catedral de Valencia',
        'Palacio de Justicia Carabobo',
      ],
      descripcion: 'Cuna de la batalla de independencia',
    ),
    
    // REGIÓN 6: ZULIA
    RegionVenezuela(
      id: 'zulia',
      nombre: 'Zulia',
      capital: 'Maracaibo',
      nivelInicio: 601,
      nivelFin: 750,
      colorPrincipal: const Color(0xFF4169E1), // Azul Rey
      monumentos: [
        'Basílica de Chiquinquirá',
        'Casa Morales',
        'Palacio de Gobierno del Zulia',
        'Circuito Judicial Zulia',
        'Catedral de Maracaibo',
      ],
      descripcion: 'Ciudad del sol amado, capital petrolera',
    ),
    
    // REGIÓN 7: LARA
    RegionVenezuela(
      id: 'lara',
      nombre: 'Lara',
      capital: 'Barquisimeto',
      nivelInicio: 751,
      nivelFin: 875,
      colorPrincipal: const Color(0xFFFF6347), // Rojo Tomate
      monumentos: [
        'Catedral de Barquisimeto',
        'Palacio Legislativo de Lara',
        'Tribunales de Barquisimeto',
        'Plaza Bolívar Barquisimeto',
      ],
      descripcion: 'Ciudad musical y de los crepúsculos',
    ),
    
    // REGIÓN 8: TÁCHIRA
    RegionVenezuela(
      id: 'tachira',
      nombre: 'Táchira',
      capital: 'San Cristóbal',
      nivelInicio: 876,
      nivelFin: 1000,
      colorPrincipal: const Color(0xFF8B4513), // Marrón Andino
      monumentos: [
        'Catedral de San Cristóbal',
        'Palacio de los Leones',
        'Circuito Judicial Táchira',
        'Plaza Bolívar Tachirense',
      ],
      descripcion: 'Estado andino fronterizo, dignidad de montaña',
    ),
    
    // REGIÓN 9: MÉRIDA
    RegionVenezuela(
      id: 'merida',
      nombre: 'Mérida',
      capital: 'Mérida',
      nivelInicio: 1001,
      nivelFin: 1125,
      colorPrincipal: const Color(0xFF006400), // Verde Oscuro
      monumentos: [
        'Universidad de Los Andes (ULA)',
        'Catedral Metropolitana de Mérida',
        'Tribunales de Mérida',
        'Plaza Bolívar con vista al Pico Bolívar',
      ],
      descripcion: 'Ciudad de los caballeros, cúspide andina',
    ),
    
    // REGIÓN 10: BOLÍVAR
    RegionVenezuela(
      id: 'bolivar',
      nombre: 'Bolívar',
      capital: 'Ciudad Bolívar',
      nivelInicio: 1126,
      nivelFin: 1250,
      colorPrincipal: const Color(0xFFCD853F), // Marrón Dorado
      monumentos: [
        'Catedral de Ciudad Bolívar',
        'Casa del Congreso de Angostura',
        'Palacio de Justicia Bolívar',
        'Plaza Bolívar colonial',
      ],
      descripcion: 'Puerta de la Gran Sabana, congreso de Angostura',
    ),
    
    // REGIÓN 11: ANZOÁTEGUI
    RegionVenezuela(
      id: 'anzoategui',
      nombre: 'Anzoátegui',
      capital: 'Barcelona',
      nivelInicio: 1251,
      nivelFin: 1400,
      colorPrincipal: const Color(0xFF1E90FF), // Azul Dodger
      monumentos: [
        'Casa Fuerte de Barcelona',
        'Catedral de Barcelona',
        'Circuito Judicial Anzoátegui',
        'Plaza Bolívar Barcelona',
      ],
      descripcion: 'Martirio de la independencia, oriente venezolano',
    ),
    
    // REGIÓN 12: RETORNO A CARACAS (NIVEL SUPREMO)
    RegionVenezuela(
      id: 'caracas_supremo',
      nombre: 'Tribunal Supremo',
      capital: 'Caracas',
      nivelInicio: 2801,
      nivelFin: 3000,
      colorPrincipal: const Color(0xFFFFD700), // Dorado Supremo
      monumentos: [
        'Sala Constitucional TSJ',
        'Sala de Casación Penal',
        'Presidencia del TSJ',
        'Magistratura Suprema',
      ],
      descripcion: 'Cúspide de la justicia venezolana',
    ),
  ];
  
  static RegionVenezuela getRegionPorNivel(int nivel) {
    return regiones.firstWhere(
      (region) => region.contieneNivel(nivel),
      orElse: () => regiones.first,
    );
  }
  
  static int getIndiceRegion(RegionVenezuela region) {
    return regiones.indexOf(region);
  }
  
  static RegionVenezuela? getRegionSiguiente(RegionVenezuela regionActual) {
    final indice = getIndiceRegion(regionActual);
    if (indice < regiones.length - 1) {
      return regiones[indice + 1];
    }
    return null;
  }
}
```

---

## 📄 ARCHIVO 3: Actualización en `lib/providers/game_provider.dart`

**AGREGAR estos métodos al final de la clase `GameState` (antes del último `}`):**

```dart
  // ========== MÉTODOS DE REGIONES ==========
  
  RegionVenezuela getRegionActual() {
    return RegionesQuiz.getRegionPorNivel(_currentLevel);
  }
  
  double getProgresoRegionActual() {
    final region = getRegionActual();
    return region.calcularProgreso(_currentLevel);
  }
  
  int getNivelesCompletadosRegion() {
    final region = getRegionActual();
    if (_currentLevel < region.nivelInicio) return 0;
    if (_currentLevel > region.nivelFin) return region.totalNiveles;
    return _currentLevel - region.nivelInicio + 1;
  }
  
  RegionVenezuela? getRegionSiguiente() {
    final regionActual = getRegionActual();
    return RegionesQuiz.getRegionSiguiente(regionActual);
  }
  
  bool regionCompletada(RegionVenezuela region) {
    return _currentLevel > region.nivelFin;
  }
```

**AGREGAR estos imports al inicio del archivo:**

```dart
import '../models/region_venezuela.dart';
import '../config/regiones_quiz.dart';
```

---

## 📄 ARCHIVO 4: Actualización en `lib/pages/quiz_lobby_screen.dart`

**REEMPLAZAR el método `build()` completo con este:**

```dart
@override
Widget build(BuildContext context) {
  final gameState = Provider.of<GameState>(context);
  final userState = Provider.of<UserState>(context, listen: false);
  
  final userName = userState.user?.nombre ?? 'Usuario';
  final currentLevel = gameState.currentLevel;
  final score = gameState.score;
  final apelaciones = gameState.apelaciones;
  
  // ✅ NUEVO: Obtener región actual
  final regionActual = gameState.getRegionActual();
  final progresoRegion = gameState.getProgresoRegionActual();
  final nivelesRegion = gameState.getNivelesCompletadosRegion();

  return Scaffold(
    body: Stack(
      children: [
        // Fondo con color de región
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  regionActual.colorPrincipal.withOpacity(0.3),
                  const Color(0xFF0B101B),
                  const Color(0xFF1a1a2e),
                ],
              ),
            ),
          ),
        ),
        
        // Camino dorado
        Positioned.fill(
          child: CustomPaint(
            painter: CaminoDoradoPainter(
              scrollOffset: scrollOffset,
              currentLevel: currentLevel,
              totalNiveles: totalNiveles,
              rioTexture: rioDoradoTexture,
            ),
          ),
        ),
        
        // UI
        SafeArea(
          child: Column(
            children: [
              _buildTopBanner(userName, currentLevel, score, apelaciones),
              
              // ✅ NUEVO: Card de región
              _buildRegionCard(regionActual, progresoRegion, nivelesRegion),
              
              const Spacer(),
              _buildPlayButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        
        _buildRankingButton(),
      ],
    ),
  );
}
```

**AGREGAR este nuevo método después de `_buildTopBanner()`:**

```dart
Widget _buildRegionCard(RegionVenezuela region, double progreso, int nivelesCompletados) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          region.colorPrincipal.withOpacity(0.9),
          region.colorPrincipal.withOpacity(0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFC5A059), width: 2),
      boxShadow: [
        BoxShadow(
          color: region.colorPrincipal.withOpacity(0.4),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.location_city,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.nombre.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    region.capital,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Niveles ${region.nivelInicio}-${region.nivelFin}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Monumento principal
        Row(
          children: [
            const Icon(Icons.account_balance, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                region.getMonumentoPrincipal(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Barra de progreso
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso: $nivelesCompletados/${region.totalNiveles}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${(progreso * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC5A059),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A059)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

**AGREGAR estos imports al inicio:**

```dart
import '../models/region_venezuela.dart';
import '../config/regiones_quiz.dart';
```

---

## ✅ LISTO

Con estos 4 cambios tendrás el sistema de regiones completo funcionando.

**Total de archivos:**
- 2 archivos nuevos (model + config)
- 2 archivos actualizados (provider + lobby screen)

**¿Necesitas ayuda con algo más?**
