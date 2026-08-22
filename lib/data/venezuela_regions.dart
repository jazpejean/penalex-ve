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

/// Lista completa de regiones de Venezuela (24 estados + retorno a Capital)
/// Del nivel 1 al 3000 sin gaps
final List<RegionVenezuela> regionesVenezuela = [
  
  // DISTRITO CAPITAL - Niveles 1-125
  RegionVenezuela(
    estado: 'Distrito Capital',
    capital: 'Caracas',
    descripcion: 'Sede del Poder Judicial Nacional y centro histórico del país',
    nivelInicio: 1,
    nivelFin: 125,
    colorPrincipal: const Color(0xFFCF142B),
    imagenFondo: 'regions/caracas_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Tribunal Supremo de Justicia', tipo: 'tribunal', descripcion: 'Máxima instancia judicial de Venezuela', icono: Icons.account_balance, nivel: 10),
      MonumentoRegional(nombre: 'Palacio Federal Legislativo', tipo: 'institucion', descripcion: 'Sede de la Asamblea Nacional', icono: Icons.domain, nivel: 25, esHistorico: true),
      MonumentoRegional(nombre: 'Catedral de Caracas', tipo: 'iglesia', descripcion: 'Construcción colonial del siglo XVII', icono: Icons.church, nivel: 40, esHistorico: true),
      MonumentoRegional(nombre: 'Plaza Bolívar', tipo: 'plaza', descripcion: 'Corazón histórico de la capital', icono: Icons.landscape, nivel: 50, esHistorico: true),
      MonumentoRegional(nombre: 'Palacio de Justicia', tipo: 'tribunal', descripcion: 'Sede de tribunales capitalinos', icono: Icons.gavel, nivel: 75),
      MonumentoRegional(nombre: 'Casa Natal del Libertador', tipo: 'colonial', descripcion: 'Lugar de nacimiento de Simón Bolívar', icono: Icons.home, nivel: 100, esHistorico: true),
    ],
  ),

  // MIRANDA - Niveles 126-250
  RegionVenezuela(estado: 'Miranda', capital: 'Los Teques', descripcion: 'Estado central con importante actividad judicial', nivelInicio: 126, nivelFin: 250, colorPrincipal: const Color(0xFF003893), imagenFondo: 'regions/miranda_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Circuito Judicial Penal de Miranda', tipo: 'tribunal', descripcion: 'Tribunales de primera instancia', icono: Icons.business, nivel: 150),
      MonumentoRegional(nombre: 'Plaza Bolívar de Los Teques', tipo: 'plaza', descripcion: 'Centro histórico de la capital', icono: Icons.park, nivel: 175, esHistorico: true),
      MonumentoRegional(nombre: 'Corte de Apelaciones Miranda', tipo: 'tribunal', descripcion: 'Segunda instancia judicial', icono: Icons.account_balance, nivel: 225),
    ],
  ),

  // VARGAS - Niveles 251-350
  RegionVenezuela(estado: 'Vargas', capital: 'La Guaira', descripcion: 'Puerto histórico y entrada de Venezuela', nivelInicio: 251, nivelFin: 350, colorPrincipal: const Color(0xFFFCDD09), imagenFondo: 'regions/vargas_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Fuerte San Carlos', tipo: 'colonial', descripcion: 'Fortificación colonial del siglo XVIII', icono: Icons.fort, nivel: 275, esHistorico: true),
      MonumentoRegional(nombre: 'Tribunal del Puerto', tipo: 'tribunal', descripcion: 'Tribunales marítimos y aduaneros', icono: Icons.anchor, nivel: 300),
    ],
  ),

  // ARAGUA - Niveles 351-475
  RegionVenezuela(estado: 'Aragua', capital: 'Maracay', descripcion: 'Ciudad jardín y sede militar', nivelInicio: 351, nivelFin: 475, colorPrincipal: const Color(0xFF228B22), imagenFondo: 'regions/aragua_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Circuito Judicial Aragua', tipo: 'tribunal', descripcion: 'Sistema judicial estatal', icono: Icons.account_balance, nivel: 400),
    ],
  ),

  // CARABOBO - Niveles 476-600
  RegionVenezuela(estado: 'Carabobo', capital: 'Valencia', descripcion: 'Cuna de la batalla de Carabobo', nivelInicio: 476, nivelFin: 600, colorPrincipal: const Color(0xFFD4AF37), imagenFondo: 'regions/carabobo_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Campo de Carabobo', tipo: 'colonial', descripcion: 'Sitio histórico de la batalla', icono: Icons.flag, nivel: 500, esHistorico: true),
      MonumentoRegional(nombre: 'Palacio de Justicia Carabobo', tipo: 'tribunal', descripcion: 'Centro judicial del estado', icono: Icons.gavel, nivel: 575),
    ],
  ),

  // ZULIA - Niveles 601-750
  RegionVenezuela(estado: 'Zulia', capital: 'Maracaibo', descripcion: 'Capital petrolera y ciudad del sol amado', nivelInicio: 601, nivelFin: 750, colorPrincipal: const Color(0xFF4169E1), imagenFondo: 'regions/zulia_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Basílica de Chiquinquirá', tipo: 'iglesia', descripcion: 'Templo patronal de Maracaibo', icono: Icons.church, nivel: 625, esHistorico: true),
      MonumentoRegional(nombre: 'Circuito Judicial Zulia', tipo: 'tribunal', descripcion: 'Mayor circuito judicial del occidente', icono: Icons.account_balance, nivel: 700),
    ],
  ),

  // LARA - Niveles 751-875
  RegionVenezuela(estado: 'Lara', capital: 'Barquisimeto', descripcion: 'Ciudad musical y crepuscular', nivelInicio: 751, nivelFin: 875, colorPrincipal: const Color(0xFFFF6347), imagenFondo: 'regions/lara_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Tribunales de Barquisimeto', tipo: 'tribunal', descripcion: 'Centro judicial larense', icono: Icons.gavel, nivel: 800),
    ],
  ),

  // TÁCHIRA - Niveles 876-1000
  RegionVenezuela(estado: 'Táchira', capital: 'San Cristóbal', descripcion: 'Estado fronterizo de los Andes', nivelInicio: 876, nivelFin: 1000, colorPrincipal: const Color(0xFF8B4513), imagenFondo: 'regions/tachira_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Circuito Judicial Táchira', tipo: 'tribunal', descripcion: 'Tribunales fronterizos', icono: Icons.account_balance, nivel: 900),
    ],
  ),

  // MÉRIDA - Niveles 1001-1125
  RegionVenezuela(estado: 'Mérida', capital: 'Mérida', descripcion: 'Ciudad de los caballeros y sede universitaria', nivelInicio: 1001, nivelFin: 1125, colorPrincipal: const Color(0xFF006400), imagenFondo: 'regions/merida_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Universidad de Los Andes', tipo: 'institucion', descripcion: 'Alma mater andina', icono: Icons.school, nivel: 1025, esHistorico: true),
      MonumentoRegional(nombre: 'Tribunales de Mérida', tipo: 'tribunal', descripcion: 'Circuito judicial andino', icono: Icons.gavel, nivel: 1075),
    ],
  ),

  // BOLÍVAR - Niveles 1126-1250
  RegionVenezuela(estado: 'Bolívar', capital: 'Ciudad Bolívar', descripcion: 'Puerta de entrada a la Gran Sabana', nivelInicio: 1126, nivelFin: 1250, colorPrincipal: const Color(0xFFCD853F), imagenFondo: 'regions/bolivar_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Casa del Congreso de Angostura', tipo: 'colonial', descripcion: 'Sitio histórico independentista', icono: Icons.account_balance, nivel: 1175, esHistorico: true),
      MonumentoRegional(nombre: 'Palacio de Justicia Bolívar', tipo: 'tribunal', descripcion: 'Centro judicial guayanés', icono: Icons.gavel, nivel: 1200),
    ],
  ),

  // ANZOÁTEGUI - Niveles 1251-1400
  RegionVenezuela(estado: 'Anzoátegui', capital: 'Barcelona', descripcion: 'Estado oriental con historia independentista', nivelInicio: 1251, nivelFin: 1400, colorPrincipal: const Color(0xFF1E90FF), imagenFondo: 'regions/anzoategui_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Casa Fuerte de Barcelona', tipo: 'colonial', descripcion: 'Sitio del martirio patriótico', icono: Icons.fort, nivel: 1275, esHistorico: true),
      MonumentoRegional(nombre: 'Circuito Judicial Anzoátegui', tipo: 'tribunal', descripcion: 'Tribunales del oriente', icono: Icons.account_balance, nivel: 1325),
    ],
  ),

  // SUCRE - Niveles 1401-1525
  RegionVenezuela(estado: 'Sucre', capital: 'Cumaná', descripcion: 'Primogénita del continente americano', nivelInicio: 1401, nivelFin: 1525, colorPrincipal: const Color(0xFFFF4500), imagenFondo: 'regions/sucre_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Castillo de San Antonio', tipo: 'colonial', descripcion: 'Fortificación colonial de Cumaná', icono: Icons.castle, nivel: 1425, esHistorico: true),
      MonumentoRegional(nombre: 'Tribunales de Sucre', tipo: 'tribunal', descripcion: 'Circuito judicial oriental', icono: Icons.gavel, nivel: 1475),
    ],
  ),

  // MONAGAS - Niveles 1526-1650
  RegionVenezuela(estado: 'Monagas', capital: 'Maturín', descripcion: 'Tierra de José Tadeo y José Gregorio Monagas', nivelInicio: 1526, nivelFin: 1650, colorPrincipal: const Color(0xFF32CD32), imagenFondo: 'regions/monagas_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Circuito Judicial Monagas', tipo: 'tribunal', descripcion: 'Tribunales del estado', icono: Icons.account_balance, nivel: 1600),
    ],
  ),

  // DELTA AMACURO - Niveles 1651-1775
  RegionVenezuela(estado: 'Delta Amacuro', capital: 'Tucupita', descripcion: 'Delta del Orinoco y tierra Warao', nivelInicio: 1651, nivelFin: 1775, colorPrincipal: const Color(0xFF20B2AA), imagenFondo: 'regions/delta_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Tribunales Delta Amacuro', tipo: 'tribunal', descripcion: 'Justicia en el delta', icono: Icons.gavel, nivel: 1700),
    ],
  ),

  // AMAZONAS - Niveles 1776-1900
  RegionVenezuela(estado: 'Amazonas', capital: 'Puerto Ayacucho', descripcion: 'Pulmón vegetal de Venezuela', nivelInicio: 1776, nivelFin: 1900, colorPrincipal: const Color(0xFF228B22), imagenFondo: 'regions/amazonas_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Tribunales de Amazonas', tipo: 'tribunal', descripcion: 'Justicia en la selva', icono: Icons.gavel, nivel: 1825),
    ],
  ),

  // APURE - Niveles 1901-2025
  RegionVenezuela(estado: 'Apure', capital: 'San Fernando de Apure', descripcion: 'Llanos venezolanos y tierra de José Antonio Páez', nivelInicio: 1901, nivelFin: 2025, colorPrincipal: const Color(0xFFDEB887), imagenFondo: 'regions/apure_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Circuito Judicial Apure', tipo: 'tribunal', descripcion: 'Tribunales llaneros', icono: Icons.account_balance, nivel: 1975),
    ],
  ),

  // BARINAS - Niveles 2026-2150
  RegionVenezuela(estado: 'Barinas', capital: 'Barinas', descripcion: 'Tierra de los llanos altos', nivelInicio: 2026, nivelFin: 2150, colorPrincipal: const Color(0xFFFF8C00), imagenFondo: 'regions/barinas_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Tribunales de Barinas', tipo: 'tribunal', descripcion: 'Circuito judicial', icono: Icons.gavel, nivel: 2100),
    ],
  ),

  // PORTUGUESA - Niveles 2151-2275
  RegionVenezuela(estado: 'Portuguesa', capital: 'Guanare', descripcion: 'Granero de Venezuela', nivelInicio: 2151, nivelFin: 2275, colorPrincipal: const Color(0xFFFFD700), imagenFondo: 'regions/portuguesa_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Santuario de Coromoto', tipo: 'iglesia', descripcion: 'Basílica patronal de Venezuela', icono: Icons.church, nivel: 2175, esHistorico: true),
      MonumentoRegional(nombre: 'Circuito Judicial Portuguesa', tipo: 'tribunal', descripcion: 'Tribunales del granero', icono: Icons.account_balance, nivel: 2225),
    ],
  ),

  // COJEDES - Niveles 2276-2400
  RegionVenezuela(estado: 'Cojedes', capital: 'San Carlos', descripcion: 'Estado central de Venezuela', nivelInicio: 2276, nivelFin: 2400, colorPrincipal: const Color(0xFF9370DB), imagenFondo: 'regions/cojedes_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Tribunales de Cojedes', tipo: 'tribunal', descripcion: 'Circuito judicial', icono: Icons.gavel, nivel: 2325),
    ],
  ),

  // GUÁRICO - Niveles 2401-2525
  RegionVenezuela(estado: 'Guárico', capital: 'San Juan de los Morros', descripcion: 'Corazón de los llanos centrales', nivelInicio: 2401, nivelFin: 2525, colorPrincipal: const Color(0xFF8B4513), imagenFondo: 'regions/guarico_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Morros de San Juan', tipo: 'colonial', descripcion: 'Formación geológica emblemática', icono: Icons.landscape, nivel: 2425, esHistorico: true),
      MonumentoRegional(nombre: 'Circuito Judicial Guárico', tipo: 'tribunal', descripcion: 'Tribunales llaneros', icono: Icons.account_balance, nivel: 2475),
    ],
  ),

  // YARACUY - Niveles 2526-2650
  RegionVenezuela(estado: 'Yaracuy', capital: 'San Felipe', descripcion: 'Tierra de María Lionza', nivelInicio: 2526, nivelFin: 2650, colorPrincipal: const Color(0xFF9932CC), imagenFondo: 'regions/yaracuy_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Santuario de María Lionza', tipo: 'colonial', descripcion: 'Monumento místico', icono: Icons.self_improvement, nivel: 2575, esHistorico: true),
      MonumentoRegional(nombre: 'Tribunales de Yaracuy', tipo: 'tribunal', descripcion: 'Circuito judicial', icono: Icons.gavel, nivel: 2600),
    ],
  ),

  // FALCÓN - Niveles 2651-2800
  RegionVenezuela(estado: 'Falcón', capital: 'Coro', descripcion: 'Patrimonio histórico de la humanidad', nivelInicio: 2651, nivelFin: 2800, colorPrincipal: const Color(0xFFE9967A), imagenFondo: 'regions/falcon_background.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Catedral de Coro', tipo: 'iglesia', descripcion: 'Primera catedral continental', icono: Icons.church, nivel: 2675, esHistorico: true),
      MonumentoRegional(nombre: 'Tribunales de Falcón', tipo: 'tribunal', descripcion: 'Circuito judicial patrimonial', icono: Icons.account_balance, nivel: 2750),
    ],
  ),

  // DISTRITO CAPITAL (RETORNO) - Niveles 2801-3000
  RegionVenezuela(estado: 'Distrito Capital', capital: 'Caracas', descripcion: 'Retorno a la capital como Magistrado Supremo', nivelInicio: 2801, nivelFin: 3000, colorPrincipal: const Color(0xFFFFD700), imagenFondo: 'regions/caracas_magistrado.jpg',
    monumentos: [
      MonumentoRegional(nombre: 'Sala Constitucional TSJ', tipo: 'tribunal', descripcion: 'Máxima instancia constitucional', icono: Icons.gavel, nivel: 2850),
      MonumentoRegional(nombre: 'Sala de Casación Penal', tipo: 'tribunal', descripcion: 'Última instancia penal', icono: Icons.balance, nivel: 2900),
      MonumentoRegional(nombre: 'Presidencia del TSJ', tipo: 'tribunal', descripcion: 'Cúspide del Poder Judicial', icono: Icons.emoji_events, nivel: 2950),
      MonumentoRegional(nombre: 'Magistratura Suprema', tipo: 'tribunal', descripcion: 'Cumbre de la carrera judicial', icono: Icons.workspace_premium, nivel: 3000),
    ],
  ),
];

/// Obtener la región actual según el nivel
RegionVenezuela? getRegionForLevel(int nivel) {
  try {
    return regionesVenezuela.firstWhere((region) => region.contieneNivel(nivel));
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
