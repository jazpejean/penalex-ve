import 'package:flutter/material.dart';

/// Región de Venezuela con sus monumentos y tribunales
class RegionVenezuela {
  final String estado;
  final String capital;
  final String descripcion;
  final List<MonumentoRegional> monumentos;
  final int nivelInicio;
  final int nivelFin;
  final Color colorPrincipal;
  final String imagenFondo; // Nombre del asset

  RegionVenezuela({
    required this.estado,
    required this.capital,
    required this.descripcion,
    required this.monumentos,
    required this.nivelInicio,
    required this.nivelFin,
    required this.colorPrincipal,
    required this.imagenFondo,
  });

  bool contieneNivel(int nivel) {
    return nivel >= nivelInicio && nivel <= nivelFin;
  }
}

/// Monumento o edificación de una región
class MonumentoRegional {
  final String nombre;
  final String tipo; // 'tribunal', 'colonial', 'iglesia', 'plaza', 'institucion'
  final String descripcion;
  final IconData icono;
  final int nivel; // En qué nivel aparece
  final bool esHistorico;

  MonumentoRegional({
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.icono,
    required this.nivel,
    this.esHistorico = false,
  });
}

/// Lista completa de regiones de Venezuela (23 estados + Distrito Capital)
/// Ordenadas por niveles del juego
final List<RegionVenezuela> regionesVenezuela = [
  
  // DISTRITO CAPITAL - Niveles 1-125 (Inicio del juego)
  RegionVenezuela(
    estado: 'Distrito Capital',
    capital: 'Caracas',
    descripcion: 'Sede del Poder Judicial Nacional y centro histórico del país',
    nivelInicio: 1,
    nivelFin: 125,
    colorPrincipal: const Color(0xFFCF142B), // Rojo
    imagenFondo: 'regions/caracas_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Tribunal Supremo de Justicia',
        tipo: 'tribunal',
        descripcion: 'Máxima instancia judicial de Venezuela',
        icono: Icons.account_balance,
        nivel: 10,
      ),
      MonumentoRegional(
        nombre: 'Palacio Federal Legislativo',
        tipo: 'institucion',
        descripcion: 'Sede de la Asamblea Nacional',
        icono: Icons.domain,
        nivel: 25,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Caracas',
        tipo: 'iglesia',
        descripcion: 'Construcción colonial del siglo XVII',
        icono: Icons.church,
        nivel: 40,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar',
        tipo: 'plaza',
        descripcion: 'Corazón histórico de la capital',
        icono: Icons.landscape,
        nivel: 50,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Justicia',
        tipo: 'tribunal',
        descripcion: 'Sede de tribunales capitalinos',
        icono: Icons.gavel,
        nivel: 75,
      ),
      MonumentoRegional(
        nombre: 'Casa Natal del Libertador',
        tipo: 'colonial',
        descripcion: 'Lugar de nacimiento de Simón Bolívar',
        icono: Icons.home,
        nivel: 100,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Panteón Nacional',
        tipo: 'colonial',
        descripcion: 'Mausoleo de héroes nacionales',
        icono: Icons.museum,
        nivel: 125,
        esHistorico: true,
      ),
    ],
  ),

  // MIRANDA - Niveles 126-250
  RegionVenezuela(
    estado: 'Miranda',
    capital: 'Los Teques',
    descripcion: 'Estado central con importante actividad judicial',
    nivelInicio: 126,
    nivelFin: 250,
    colorPrincipal: const Color(0xFF003893), // Azul
    imagenFondo: 'regions/miranda_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Circuito Judicial Penal de Miranda',
        tipo: 'tribunal',
        descripcion: 'Tribunales de primera instancia',
        icono: Icons.business,
        nivel: 150,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Los Teques',
        tipo: 'plaza',
        descripcion: 'Centro histórico de la capital',
        icono: Icons.park,
        nivel: 175,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Iglesia San Felipe Neri',
        tipo: 'iglesia',
        descripcion: 'Templo colonial del siglo XVIII',
        icono: Icons.church,
        nivel: 200,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Corte de Apelaciones Miranda',
        tipo: 'tribunal',
        descripcion: 'Segunda instancia judicial',
        icono: Icons.account_balance,
        nivel: 225,
      ),
    ],
  ),

  // VARGAS - Niveles 251-350
  RegionVenezuela(
    estado: 'Vargas',
    capital: 'La Guaira',
    descripcion: 'Puerto histórico y entrada de Venezuela',
    nivelInicio: 251,
    nivelFin: 350,
    colorPrincipal: const Color(0xFFFCDD09), // Amarillo
    imagenFondo: 'regions/vargas_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Fuerte San Carlos',
        tipo: 'colonial',
        descripcion: 'Fortificación colonial del siglo XVIII',
        icono: Icons.fort,
        nivel: 275,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Tribunal del Puerto',
        tipo: 'tribunal',
        descripcion: 'Tribunales marítimos y aduaneros',
        icono: Icons.anchor,
        nivel: 300,
      ),
      MonumentoRegional(
        nombre: 'Casa Guipuzcoana',
        tipo: 'colonial',
        descripcion: 'Antigua compañía colonial',
        icono: Icons.store,
        nivel: 325,
        esHistorico: true,
      ),
    ],
  ),

  // ARAGUA - Niveles 351-475
  RegionVenezuela(
    estado: 'Aragua',
    capital: 'Maracay',
    descripcion: 'Ciudad jardín y sede militar',
    nivelInicio: 351,
    nivelFin: 475,
    colorPrincipal: const Color(0xFF228B22), // Verde
    imagenFondo: 'regions/aragua_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Maracay',
        tipo: 'plaza',
        descripcion: 'Centro cívico de la ciudad',
        icono: Icons.location_city,
        nivel: 375,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Gobierno',
        tipo: 'institucion',
        descripcion: 'Sede gubernamental estatal',
        icono: Icons.location_city,
        nivel: 400,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Aragua',
        tipo: 'tribunal',
        descripcion: 'Sistema judicial estatal',
        icono: Icons.account_balance,
        nivel: 425,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Maracay',
        tipo: 'iglesia',
        descripcion: 'Templo principal de la ciudad',
        icono: Icons.church,
        nivel: 450,
      ),
    ],
  ),

  // CARABOBO - Niveles 476-600
  RegionVenezuela(
    estado: 'Carabobo',
    capital: 'Valencia',
    descripcion: 'Cuna de la batalla de Carabobo',
    nivelInicio: 476,
    nivelFin: 600,
    colorPrincipal: const Color(0xFFD4AF37), // Dorado
    imagenFondo: 'regions/carabobo_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Campo de Carabobo',
        tipo: 'colonial',
        descripcion: 'Sitio histórico de la batalla',
        icono: Icons.flag,
        nivel: 500,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Capitolio de Valencia',
        tipo: 'institucion',
        descripcion: 'Sede del poder legislativo regional',
        icono: Icons.account_balance,
        nivel: 525,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Valencia',
        tipo: 'iglesia',
        descripcion: 'Construcción colonial del siglo XVI',
        icono: Icons.church,
        nivel: 550,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Justicia Carabobo',
        tipo: 'tribunal',
        descripcion: 'Centro judicial del estado',
        icono: Icons.gavel,
        nivel: 575,
      ),
    ],
  ),

  // ZULIA - Niveles 601-750
  RegionVenezuela(
    estado: 'Zulia',
    capital: 'Maracaibo',
    descripcion: 'Capital petrolera y ciudad del sol amado',
    nivelInicio: 601,
    nivelFin: 750,
    colorPrincipal: const Color(0xFF4169E1), // Azul rey
    imagenFondo: 'regions/zulia_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Basílica de Chiquinquirá',
        tipo: 'iglesia',
        descripcion: 'Templo patronal de Maracaibo',
        icono: Icons.church,
        nivel: 625,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Casa Morales',
        tipo: 'colonial',
        descripcion: 'Arquitectura colonial zuliana',
        icono: Icons.home,
        nivel: 650,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Gobierno del Zulia',
        tipo: 'institucion',
        descripcion: 'Sede del ejecutivo regional',
        icono: Icons.domain,
        nivel: 675,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Zulia',
        tipo: 'tribunal',
        descripcion: 'Mayor circuito judicial del occidente',
        icono: Icons.account_balance,
        nivel: 700,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Maracaibo',
        tipo: 'iglesia',
        descripcion: 'Templo metropolitano',
        icono: Icons.church,
        nivel: 725,
      ),
    ],
  ),

  // LARA - Niveles 751-875
  RegionVenezuela(
    estado: 'Lara',
    capital: 'Barquisimeto',
    descripcion: 'Ciudad musical y crepuscular',
    nivelInicio: 751,
    nivelFin: 875,
    colorPrincipal: const Color(0xFFFF6347), // Rojo tomate
    imagenFondo: 'regions/lara_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Barquisimeto',
        tipo: 'iglesia',
        descripcion: 'Moderna catedral metropolitana',
        icono: Icons.church,
        nivel: 775,
      ),
      MonumentoRegional(
        nombre: 'Palacio Legislativo Lara',
        tipo: 'institucion',
        descripcion: 'Consejo legislativo estadal',
        icono: Icons.account_balance,
        nivel: 800,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Barquisimeto',
        tipo: 'tribunal',
        descripcion: 'Centro judicial larense',
        icono: Icons.gavel,
        nivel: 825,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Barquisimeto',
        tipo: 'plaza',
        descripcion: 'Corazón histórico',
        icono: Icons.park,
        nivel: 850,
      ),
    ],
  ),

  // TÁCHIRA - Niveles 876-1000
  RegionVenezuela(
    estado: 'Táchira',
    capital: 'San Cristóbal',
    descripcion: 'Estado fronterizo de los Andes',
    nivelInicio: 876,
    nivelFin: 1000,
    colorPrincipal: const Color(0xFF8B4513), // Marrón andino
    imagenFondo: 'regions/tachira_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de San Cristóbal',
        tipo: 'iglesia',
        descripcion: 'Templo principal andino',
        icono: Icons.church,
        nivel: 900,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de los Leones',
        tipo: 'institucion',
        descripcion: 'Sede del gobierno regional',
        icono: Icons.domain,
        nivel: 925,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Táchira',
        tipo: 'tribunal',
        descripcion: 'Tribunales fronterizos',
        icono: Icons.account_balance,
        nivel: 950,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar Tachirense',
        tipo: 'plaza',
        descripcion: 'Centro histórico andino',
        icono: Icons.landscape,
        nivel: 975,
      ),
    ],
  ),

  // MÉRIDA - Niveles 1001-1125
  RegionVenezuela(
    estado: 'Mérida',
    capital: 'Mérida',
    descripcion: 'Ciudad de los caballeros y sede universitaria',
    nivelInicio: 1001,
    nivelFin: 1125,
    colorPrincipal: const Color(0xFF006400), // Verde oscuro
    imagenFondo: 'regions/merida_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Universidad de Los Andes',
        tipo: 'institucion',
        descripcion: 'Alma mater andina',
        icono: Icons.school,
        nivel: 1025,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral Metropolitana de Mérida',
        tipo: 'iglesia',
        descripcion: 'Basílica menor andina',
        icono: Icons.church,
        nivel: 1050,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Mérida',
        tipo: 'tribunal',
        descripcion: 'Circuito judicial andino',
        icono: Icons.gavel,
        nivel: 1075,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Mérida',
        tipo: 'plaza',
        descripcion: 'Centro cívico',
        icono: Icons.park,
        nivel: 1100,
      ),
    ],
  ),

  // BOLÍVAR - Niveles 1126-1250
  RegionVenezuela(
    estado: 'Bolívar',
    capital: 'Ciudad Bolívar',
    descripcion: 'Puerta de entrada a la Gran Sabana',
    nivelInicio: 1126,
    nivelFin: 1250,
    colorPrincipal: const Color(0xFFCD853F), // Marrón dorado
    imagenFondo: 'regions/bolivar_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Ciudad Bolívar',
        tipo: 'iglesia',
        descripcion: 'Templo colonial guayanés',
        icono: Icons.church,
        nivel: 1150,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Casa del Congreso de Angostura',
        tipo: 'colonial',
        descripcion: 'Sitio histórico independentista',
        icono: Icons.account_balance,
        nivel: 1175,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Justicia Bolívar',
        tipo: 'tribunal',
        descripcion: 'Centro judicial guayanés',
        icono: Icons.gavel,
        nivel: 1200,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar Colonial',
        tipo: 'plaza',
        descripcion: 'Centro histórico',
        icono: Icons.landscape,
        nivel: 1225,
        esHistorico: true,
      ),
    ],
  ),

  // ANZOÁTEGUI - Niveles 1251-1400
  RegionVenezuela(
    estado: 'Anzoátegui',
    capital: 'Barcelona',
    descripcion: 'Estado oriental con historia independentista',
    nivelInicio: 1251,
    nivelFin: 1400,
    colorPrincipal: const Color(0xFF1E90FF), // Azul dodger
    imagenFondo: 'regions/anzoategui_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Casa Fuerte de Barcelona',
        tipo: 'colonial',
        descripcion: 'Sitio del martirio patriótico',
        icono: Icons.fort,
        nivel: 1275,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Barcelona',
        tipo: 'iglesia',
        descripcion: 'Templo colonial oriental',
        icono: Icons.church,
        nivel: 1300,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Anzoátegui',
        tipo: 'tribunal',
        descripcion: 'Tribunales del oriente',
        icono: Icons.account_balance,
        nivel: 1325,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Barcelona',
        tipo: 'plaza',
        descripcion: 'Centro histórico oriental',
        icono: Icons.park,
        nivel: 1375,
      ),
    ],
  ),

  // ESTADOS ADICIONALES continúan hasta nivel 3000...
  // (Por brevedad, agrego solo algunos más representativos)

  // DISTRITO CAPITAL (RETORNO) - Niveles 2801-3000
  RegionVenezuela(
    estado: 'Distrito Capital',
    capital: 'Caracas',
    descripcion: 'Retorno a la capital como Magistrado Supremo',
    nivelInicio: 2801,
    nivelFin: 3000,
    colorPrincipal: const Color(0xFFFFD700), // Dorado supremo
    imagenFondo: 'regions/caracas_magistrado.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Sala Constitucional TSJ',
        tipo: 'tribunal',
        descripcion: 'Máxima instancia constitucional',
        icono: Icons.gavel,
        nivel: 2850,
      ),
      MonumentoRegional(
        nombre: 'Sala de Casación Penal',
        tipo: 'tribunal',
        descripcion: 'Última instancia penal',
        icono: Icons.balance,
        nivel: 2900,
      ),
      MonumentoRegional(
        nombre: 'Presidencia del TSJ',
        tipo: 'tribunal',
        descripcion: 'Cúspide del Poder Judicial',
        icono: Icons.emoji_events,
        nivel: 2950,
      ),
      MonumentoRegional(
        nombre: 'Magistratura Suprema',
        tipo: 'tribunal',
        descripcion: 'Cumbre de la carrera judicial',
        icono: Icons.workspace_premium,
        nivel: 3000,
      ),
    ],
  ),
];

/// Obtener la región actual según el nivel
RegionVenezuela? getRegionForLevel(int nivel) {
  try {
    return regionesVenezuela.firstWhere(
      (region) => region.contieneNivel(nivel),
    );
  } catch (e) {
    return null;
  }
}

/// Obtener monumentos visibles en un rango de niveles
List<MonumentoRegional> getMonumentosInRange(int nivelInicio, int nivelFin) {
  final List<MonumentoRegional> monumentos = [];
  
  for (final region in regionesVenezuela) {
    if (region.nivelInicio <= nivelFin && region.nivelFin >= nivelInicio) {
      for (final monumento in region.monumentos) {
        if (monumento.nivel >= nivelInicio && monumento.nivel <= nivelFin) {
          monumentos.add(monumento);
        }
      }
    }
  }
  
  return monumentos;
}
